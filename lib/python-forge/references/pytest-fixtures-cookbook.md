# Pytest Fixtures Cookbook

Production-ready pytest fixtures for common testing scenarios.

## Contents

- Configuration
- Database Fixtures
- Factory Fixtures
- Authentication Fixtures
- Mock Fixtures
- Environment Fixtures
- File Fixtures
- Parametrized Fixtures
- Cleanup Fixtures
- Redis Fixtures

## Configuration

All examples assume pytest-asyncio 1.x in auto mode, so async tests and async fixtures need no `@pytest.mark.asyncio` marker. Session-scoped async resources (engines, pools, clients) are bound to the event loop that created them, so the fixtures and the tests that use them run in one session-scoped loop:

```toml
# pyproject.toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "session"
asyncio_default_test_loop_scope = "session"
```

Do not override the `event_loop` fixture: it was deprecated and then removed in pytest-asyncio 1.0. Choose the loop with `loop_scope` instead, either per fixture (`@pytest_asyncio.fixture(loop_scope="session")`), per test (`@pytest.mark.asyncio(loop_scope="session")`), or globally with the options above. To keep the default function-scoped loop for tests, drop the two `*_loop_scope` lines and make the session-scoped async fixtures function-scoped.

## Database Fixtures

### SQLAlchemy Async Session

```python
# tests/conftest.py
import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base
from app.main import app
from app.dependencies import get_db


@pytest_asyncio.fixture(scope="session", loop_scope="session")
async def engine():
    """Create test database engine."""
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield engine

    await engine.dispose()


@pytest.fixture
async def db_session(engine):
    """Database session with automatic rollback."""
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        async with session.begin():
            yield session
            await session.rollback()


@pytest.fixture
async def client(db_session):
    """FastAPI test client with database override."""
    from httpx import AsyncClient, ASGITransport

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as client:
        yield client

    app.dependency_overrides.clear()
```

### PostgreSQL with Docker

```python
import pytest
import pytest_asyncio
import asyncpg
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="session")
def postgres_container():
    """Start PostgreSQL container for tests."""
    with PostgresContainer("postgres:16-alpine") as postgres:
        yield postgres


@pytest_asyncio.fixture(scope="session", loop_scope="session")
async def pg_pool(postgres_container):
    """PostgreSQL connection pool."""
    # get_connection_url() defaults to "postgresql+psycopg2://..." (SQLAlchemy style);
    # driver=None yields a plain "postgresql://..." DSN that asyncpg accepts.
    # For a SQLAlchemy async engine, use get_connection_url(driver="asyncpg") instead.
    pool = await asyncpg.create_pool(
        postgres_container.get_connection_url(driver=None)
    )
    yield pool
    await pool.close()


@pytest.fixture
async def pg_connection(pg_pool):
    """PostgreSQL connection with transaction rollback."""
    async with pg_pool.acquire() as conn:
        tr = conn.transaction()
        await tr.start()
        yield conn
        await tr.rollback()
```

## Factory Fixtures

### User Factory

```python
from dataclasses import dataclass, field
from typing import Any

import pytest
from faker import Faker
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User

fake = Faker()

@dataclass
class UserFactory:
    """Factory for creating test users."""
    db_session: AsyncSession
    defaults: dict[str, Any] = field(default_factory=dict)

    async def create(self, **overrides) -> User:
        data = {
            "email": fake.email(),
            "full_name": fake.name(),
            "hashed_password": "hashed_test_password",
            "is_active": True,
            **self.defaults,
            **overrides,
        }
        user = User(**data)
        self.db_session.add(user)
        await self.db_session.flush()
        return user

    async def create_batch(self, count: int, **overrides) -> list[User]:
        return [await self.create(**overrides) for _ in range(count)]


@pytest.fixture
def user_factory(db_session):
    """User factory fixture."""
    return UserFactory(db_session)


# Usage
async def test_list_users(client, user_factory):
    await user_factory.create_batch(5)

    response = await client.get("/users")

    assert response.status_code == 200
    assert len(response.json()) == 5
```

### Generic Factory

```python
from collections.abc import Callable
from typing import Any

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Order, User


class ModelFactory[T]:
    """Generic factory for SQLAlchemy models."""

    def __init__(
        self, session: AsyncSession, model: type[T], defaults: dict[str, Any] | None = None
    ):
        self.session = session
        self.model = model
        self.defaults = defaults or {}

    async def create(self, **overrides) -> T:
        data = {**self.defaults, **overrides}
        instance = self.model(**data)
        self.session.add(instance)
        await self.session.flush()
        return instance


@pytest.fixture
def model_factory(db_session):
    """Generic model factory."""
    def factory[T](model: type[T], defaults: dict[str, Any] | None = None) -> ModelFactory[T]:
        return ModelFactory(db_session, model, defaults)
    return factory


# Usage
async def test_orders(client, model_factory):
    user_factory = model_factory(User, {"email": "test@test.com"})
    order_factory = model_factory(Order, {"status": "pending"})

    user = await user_factory.create()
    order = await order_factory.create(user_id=user.id)
    assert order.user_id == user.id
```

## Authentication Fixtures

```python
from datetime import UTC, datetime, timedelta

import jwt
import pytest

from app.config import settings


@pytest.fixture
def auth_token():
    """Generate authentication token signed with the app's own secret."""
    def _generate(user_id: int, **extra) -> str:
        payload = {
            "sub": str(user_id),
            "exp": datetime.now(UTC) + timedelta(hours=1),
            **extra,
        }
        return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)
    return _generate


@pytest.fixture
async def authenticated_user(user_factory, auth_token):
    """Create user and return with auth token."""
    user = await user_factory.create()
    token = auth_token(user.id)
    return user, token


@pytest.fixture
async def auth_client(client, authenticated_user):
    """Client with authentication headers."""
    user, token = authenticated_user
    client.headers["Authorization"] = f"Bearer {token}"
    return client, user


# Usage
async def test_protected_endpoint(auth_client):
    client, user = auth_client
    response = await client.get("/users/me")
    assert response.status_code == 200
    assert response.json()["id"] == user.id
```

## Mock Fixtures

### External API Mock

```python
import pytest
from unittest.mock import AsyncMock, MagicMock
from httpx import Response

@pytest.fixture
def mock_external_api(mocker):
    """Mock external API calls."""
    mock = AsyncMock()

    def _setup(responses: dict[str, dict]):
        async def mock_get(url, **kwargs):
            for pattern, data in responses.items():
                if pattern in url:
                    return Response(
                        status_code=data.get("status", 200),
                        json=data.get("json", {}),
                    )
            raise ValueError(f"Unexpected URL: {url}")

        mock.get = mock_get
        return mock

    return _setup


# Usage
async def test_fetch_user_data(mock_external_api):
    mock = mock_external_api({
        "/users/123": {"json": {"name": "John", "email": "john@example.com"}},
        "/users/456": {"status": 404, "json": {"error": "Not found"}},
    })

    result = await fetch_user(123, client=mock)
    assert result["name"] == "John"
```

### Time Freezing

```python
from datetime import UTC, datetime, timedelta

import pytest
from freezegun import freeze_time


@pytest.fixture
def frozen_time():
    """Freeze time for tests."""
    with freeze_time("2024-01-15 12:00:00") as frozen:
        yield frozen


def make_audit_stamp() -> dict[str, datetime]:
    """Example code under test."""
    return {"created_at": datetime.now(UTC)}


# Usage
def test_audit_stamp(frozen_time):
    assert make_audit_stamp()["created_at"] == datetime(2024, 1, 15, 12, 0, tzinfo=UTC)

    frozen_time.tick(timedelta(hours=1))
    assert make_audit_stamp()["created_at"] == datetime(2024, 1, 15, 13, 0, tzinfo=UTC)
```

## Environment Fixtures

```python
import os
import pytest

@pytest.fixture
def env_vars(monkeypatch):
    """Set environment variables for test."""
    def _set(**vars):
        for key, value in vars.items():
            monkeypatch.setenv(key, value)
    return _set


@pytest.fixture
def temp_settings(env_vars):
    """Override settings for test."""
    def _override(**settings):
        env_vars(**{k.upper(): str(v) for k, v in settings.items()})
        # Reload settings
        from app.config import settings
        settings.__init__()
    return _override


# Usage
def test_debug_mode(temp_settings):
    temp_settings(debug=True, log_level="DEBUG")

    from app.config import settings
    assert settings.debug is True
```

## File Fixtures

```python
import pytest
from pathlib import Path
import tempfile

@pytest.fixture
def temp_dir():
    """Temporary directory for test files."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


@pytest.fixture
def sample_file(temp_dir):
    """Create sample file."""
    def _create(name: str, content: str) -> Path:
        path = temp_dir / name
        path.write_text(content)
        return path
    return _create


@pytest.fixture
def sample_csv(sample_file):
    """Create sample CSV file."""
    content = """id,name,email
1,John,john@example.com
2,Jane,jane@example.com
3,Bob,bob@example.com"""
    return sample_file("data.csv", content)


# Usage
async def test_import_csv(client, sample_csv):
    with open(sample_csv, "rb") as f:
        response = await client.post(
            "/import",
            files={"file": ("data.csv", f, "text/csv")}
        )
    assert response.status_code == 200
```

## Parametrized Fixtures

```python
@pytest.fixture(params=["sqlite", "postgresql"])
def database_url(request):
    """Test with multiple databases."""
    if request.param == "sqlite":
        return "sqlite+aiosqlite:///:memory:"
    elif request.param == "postgresql":
        # Would need a real PostgreSQL for this
        pytest.skip("PostgreSQL not available")
    return None


@pytest.fixture(params=[
    ("admin", True),
    ("user", False),
    ("guest", False),
])
async def user_with_role(request, user_factory):
    """Test with different user roles (async fixture: create() is a coroutine)."""
    role, is_admin = request.param
    return await user_factory.create(role=role, is_admin=is_admin)
```

## Cleanup Fixtures

```python
from collections.abc import Awaitable, Callable

import pytest


@pytest.fixture
async def cleanup(client):
    """Register async cleanup callbacks.

    Depending on `client` guarantees this fixture tears down first, while the
    client is still open, and the callbacks are awaited on the same event loop.
    """
    cleanups: list[Callable[[], Awaitable[object]]] = []

    def _register(func: Callable[[], Awaitable[object]]) -> None:
        cleanups.append(func)

    yield _register

    for func in reversed(cleanups):
        await func()


# Usage
async def test_create_resource(cleanup, client):
    response = await client.post("/resources", json={"name": "test"})
    resource_id = response.json()["id"]

    # Register cleanup: a zero-argument callable returning an awaitable
    cleanup(lambda: client.delete(f"/resources/{resource_id}"))

    # Test continues...
    assert response.status_code == 201
```

## Redis Fixtures

```python
import pytest
import pytest_asyncio
import redis.asyncio as redis

@pytest_asyncio.fixture(scope="session", loop_scope="session")
async def redis_client():
    """Redis client for tests."""
    client = redis.from_url("redis://localhost:6379/15")  # Use test database
    await client.flushdb()  # Clean before tests
    yield client
    await client.flushdb()  # Clean after tests
    await client.aclose()  # redis-py 5+: close() is deprecated


@pytest.fixture
async def clean_redis(redis_client):
    """Redis with cleanup after each test."""
    yield redis_client
    await redis_client.flushdb()


# Usage
async def test_caching(clean_redis):
    await clean_redis.set("key", "value")
    result = await clean_redis.get("key")
    assert result == b"value"
```
