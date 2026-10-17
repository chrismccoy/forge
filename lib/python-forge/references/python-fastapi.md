# Python FastAPI

Production FastAPI patterns: project layout, Pydantic schemas, dependency injection, async database access, error handling, and Docker/Gunicorn deployment.

## Contents

- Quick Reference
- Overview
- Project Structure
- Configuration
- Pydantic Schemas
- Async Best Practices
- Dependencies
- Error Handling
- Production Deployment
- Security
- Testing
- Additional References
- Related References

## Quick Reference

| Layer | File | Purpose |
|-------|------|---------|
| Entrypoint | `main.py` | App factory, lifespan |
| Config | `config.py` | pydantic-settings |
| Routes | `api/v1/endpoints/` | Endpoint handlers |
| Schemas | `schemas/` | Pydantic models |
| Models | `models/` | SQLAlchemy models |
| Services | `services/` | Business logic |
| Deps | `api/deps.py` | Dependency injection |

| Pydantic Pattern | Use Case |
|------------------|----------|
| `UserCreate` | Input for creation |
| `UserUpdate` | Input for updates |
| `UserResponse` | API output |
| `UserInDB` | Internal with hash |

| Dependency | Code |
|------------|------|
| DB session | `db: Annotated[AsyncSession, Depends(get_db)]` |
| Current user | `user: Annotated[User, Depends(get_current_user)]` |
| Type alias | `CurrentUser = Annotated[User, Depends(...)]` |

| Production | Config |
|------------|--------|
| Server | `gunicorn -w 4 -k uvicorn.workers.UvicornWorker` |
| Workers | `CPU cores` for async |

## Overview

FastAPI is a modern, high-performance web framework for building APIs. Built on Starlette and Pydantic, it provides automatic validation, serialization, and OpenAPI documentation.

## Project Structure

### Scalable Structure (Recommended)

```text
src/
├── app/
│   ├── __init__.py
│   ├── main.py              # Application factory
│   ├── config.py            # Settings management
│   ├── database.py          # Database setup
│   ├── dependencies.py      # Shared dependencies
│   ├── api/
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── router.py    # API router
│   │   │   └── endpoints/
│   │   │       ├── users.py
│   │   │       ├── items.py
│   │   │       └── auth.py
│   │   └── deps.py          # API dependencies
│   ├── core/
│   │   ├── __init__.py
│   │   ├── security.py      # Auth/JWT
│   │   └── exceptions.py    # Custom exceptions
│   ├── models/              # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── item.py
│   ├── schemas/             # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── item.py
│   └── services/            # Business logic
│       ├── __init__.py
│       ├── user.py
│       └── item.py
├── tests/
├── pyproject.toml
└── Dockerfile
```

## Configuration

### Settings with pydantic-settings

```python
# app/config.py
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Application
    app_name: str = "My API"
    debug: bool = False
    environment: str = "production"

    # Database
    database_url: str
    database_pool_size: int = 5
    database_max_overflow: int = 10

    # Security
    secret_key: str
    access_token_expire_minutes: int = 30
    algorithm: str = "HS256"

    # External services
    redis_url: str | None = None


@lru_cache
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
```

### Application Factory

```python
# app/main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.api.v1.router import api_router
from app.database import engine, Base


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Shutdown
    await engine.dispose()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        openapi_url="/api/v1/openapi.json" if settings.debug else None,
        docs_url="/api/docs" if settings.debug else None,
        redoc_url="/api/redoc" if settings.debug else None,
        lifespan=lifespan,
    )

    # Middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"] if settings.debug else ["https://myapp.com"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Routes
    app.include_router(api_router, prefix="/api/v1")

    return app


app = create_app()
```

## Pydantic Schemas

### Input/Output Separation

```python
# app/schemas/user.py
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field

# Base schema with shared fields
class UserBase(BaseModel):
    email: EmailStr
    full_name: str | None = None

# Input schema for creation
class UserCreate(UserBase):
    password: str = Field(min_length=8)

# Input schema for updates
class UserUpdate(BaseModel):
    email: EmailStr | None = None
    full_name: str | None = None
    password: str | None = Field(None, min_length=8)

# Output schema (what API returns)
class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}

# Internal schema with password hash
class UserInDB(UserBase):
    id: int
    hashed_password: str
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
```

### Validation Examples

```python
from typing import Annotated
from pydantic import BaseModel, Field, field_validator, model_validator

class ItemCreate(BaseModel):
    name: Annotated[str, Field(min_length=1, max_length=100)]
    price: Annotated[float, Field(gt=0, description="Price must be positive")]
    quantity: Annotated[int, Field(ge=0, le=10000)]
    tags: list[str] = Field(default_factory=list, max_length=10)

    @field_validator("name")
    @classmethod
    def name_must_not_be_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Name cannot be empty or whitespace")
        return v.strip()

    @field_validator("tags")
    @classmethod
    def tags_must_be_unique(cls, v: list[str]) -> list[str]:
        if len(v) != len(set(v)):
            raise ValueError("Tags must be unique")
        return v

    @model_validator(mode="after")
    def validate_price_quantity(self) -> "ItemCreate":
        if self.quantity > 0 and self.price < 0.01:
            raise ValueError("Price too low for available items")
        return self
```

## Async Best Practices

### Correct Async Usage

```python
from fastapi import FastAPI, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import httpx

from app.models import User

app = FastAPI()

# GOOD: Async database operations
async def get_user(db: AsyncSession, user_id: int):
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()

# GOOD: Async HTTP calls
async def fetch_external_data(url: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        return response.json()

# BAD: Blocking call in async route
@app.get("/bad")
async def bad_endpoint():
    import time
    time.sleep(5)  # Blocks entire event loop!
    return {"status": "done"}

# GOOD: Use asyncio.sleep or run in executor
@app.get("/good")
async def good_endpoint():
    import asyncio
    await asyncio.sleep(5)  # Non-blocking
    return {"status": "done"}

# GOOD: Run blocking (sync I/O) code in a worker thread
@app.get("/blocking")
async def blocking_io():
    import asyncio
    result = await asyncio.to_thread(blocking_library_call)
    return {"result": result}

# GOOD: Run CPU-bound code in a process pool (threads still contend for the GIL)
from concurrent.futures import ProcessPoolExecutor

process_pool = ProcessPoolExecutor()

@app.get("/cpu-bound")
async def cpu_bound():
    import asyncio
    loop = asyncio.get_running_loop()
    result = await loop.run_in_executor(process_pool, heavy_computation)
    return {"result": result}
```

### Sync vs Async Routes

```python
# Async route - for I/O-bound operations
@app.get("/async-users")
async def get_users(db: AsyncSession = Depends(get_db)):
    # Uses async database session
    users = await db.execute(select(User))
    return users.scalars().all()

# Sync route - FastAPI runs in thread pool
@app.get("/sync-compute")
def compute_heavy():
    # OK for CPU-bound operations
    # FastAPI automatically runs this in thread pool
    return {"result": heavy_cpu_computation()}
```

## Dependencies

### Dependency Injection

```python
# app/api/deps.py
from typing import Annotated
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
import jwt
from jwt.exceptions import InvalidTokenError

from app.database import get_db
from app.config import settings
from app.models import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        subject: str | None = payload.get("sub")
        if subject is None:
            raise credentials_exception
        user_id = int(subject)
    except (InvalidTokenError, ValueError):
        raise credentials_exception

    user = await db.get(User, user_id)
    if user is None:
        raise credentials_exception
    return user

async def get_current_active_user(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

# Type aliases for cleaner signatures
CurrentUser = Annotated[User, Depends(get_current_active_user)]
DbSession = Annotated[AsyncSession, Depends(get_db)]
```

### Using Dependencies

```python
# app/api/v1/endpoints/users.py
from fastapi import APIRouter, HTTPException
from app.api.deps import CurrentUser, DbSession
from app.schemas.user import UserResponse, UserUpdate

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def read_current_user(current_user: CurrentUser):
    return current_user

@router.patch("/me", response_model=UserResponse)
async def update_current_user(
    update_data: UserUpdate,
    current_user: CurrentUser,
    db: DbSession,
):
    for field, value in update_data.model_dump(exclude_unset=True).items():
        setattr(current_user, field, value)
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    return current_user
```

## Error Handling

### Custom Exception Handlers

```python
# app/core/exceptions.py
import logging

from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.status import HTTP_500_INTERNAL_SERVER_ERROR

class AppException(Exception):
    def __init__(self, status_code: int, detail: str, error_code: str | None = None):
        self.status_code = status_code
        self.detail = detail
        self.error_code = error_code

class NotFoundError(AppException):
    def __init__(self, resource: str, id: int):
        super().__init__(
            status_code=404,
            detail=f"{resource} with id {id} not found",
            error_code="NOT_FOUND",
        )

class ValidationError(AppException):
    def __init__(self, detail: str):
        super().__init__(
            status_code=422,
            detail=detail,
            error_code="VALIDATION_ERROR",
        )

# app/main.py
logger = logging.getLogger(__name__)

async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": exc.detail,
            "error_code": exc.error_code,
        },
    )

async def unhandled_exception_handler(request: Request, exc: Exception):
    # Log the error
    logger.exception("Unhandled error: %s", exc)
    return JSONResponse(
        status_code=HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"},
    )

app.add_exception_handler(AppException, app_exception_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)
```

## Production Deployment

### Docker

```dockerfile
# Dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install uv (pin a specific version instead of :latest for reproducible builds)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# Install dependencies only (cached layer; the project itself is not installed yet)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-dev --no-install-project

# Copy the project (pyproject.toml, uv.lock, README, src/), then install it.
# Exclude .venv, .git, and caches via .dockerignore.
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Use the project virtualenv directly (no re-sync at runtime)
ENV PATH="/app/.venv/bin:$PATH"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Gunicorn with Uvicorn Workers

```python
# gunicorn.conf.py
import multiprocessing

# Workers = CPU cores (for async)
workers = multiprocessing.cpu_count()
worker_class = "uvicorn.workers.UvicornWorker"

# Timeouts
timeout = 120
keepalive = 5

# Logging
accesslog = "-"
errorlog = "-"
loglevel = "info"

# Binding
bind = "0.0.0.0:8000"
```

```bash
# Run in production
gunicorn app.main:app -c gunicorn.conf.py
```

### Health Checks

```python
from fastapi import APIRouter, HTTPException
from sqlalchemy import text

from app.api.deps import DbSession

router = APIRouter(tags=["health"])

@router.get("/health")
async def health_check():
    return {"status": "healthy"}

@router.get("/ready")
async def readiness_check(db: DbSession):
    try:
        await db.execute(text("SELECT 1"))
        return {"status": "ready", "database": "connected"}
    except Exception:
        raise HTTPException(status_code=503, detail="Database not ready")
```

## Security

### JWT Authentication

```python
# app/core/security.py
# Dependencies: uv add pyjwt "pwdlib[bcrypt]"
from datetime import UTC, datetime, timedelta

import jwt
from pwdlib import PasswordHash
from pwdlib.hashers.bcrypt import BcryptHasher

from app.config import settings

# bcrypt via pwdlib (passlib is unmaintained and breaks with bcrypt 5.x).
# FastAPI's docs default to PasswordHash.recommended() (Argon2, needs "pwdlib[argon2]").
password_hash = PasswordHash((BcryptHasher(),))

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return password_hash.verify(plain_password, hashed_password)

def hash_password(password: str) -> str:
    return password_hash.hash(password)

def create_access_token(subject: int | str, expires_delta: timedelta | None = None) -> str:
    if expires_delta:
        expire = datetime.now(UTC) + expires_delta
    else:
        expire = datetime.now(UTC) + timedelta(minutes=settings.access_token_expire_minutes)

    to_encode = {"exp": expire, "sub": str(subject)}
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
```

### Rate Limiting

```python
from fastapi import Request
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.get("/limited")
@limiter.limit("10/minute")
async def limited_endpoint(request: Request):
    return {"message": "This endpoint is rate limited"}
```

## Testing

Examples assume pytest-asyncio auto mode (`asyncio_mode = "auto"` under `[tool.pytest.ini_options]` in `pyproject.toml`), so async tests and fixtures need no `@pytest.mark.asyncio` marker. In strict mode, decorate the async fixtures with `@pytest_asyncio.fixture` and mark the tests with `@pytest.mark.asyncio`. See [Python Testing](python-testing.md) for the full configuration.

```python
# tests/conftest.py
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.database import get_db

@pytest.fixture
async def client():
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as client:
        yield client

@pytest.fixture
async def authenticated_client(client: AsyncClient, test_user_token: str):
    client.headers["Authorization"] = f"Bearer {test_user_token}"
    yield client

# tests/test_users.py
from httpx import AsyncClient

async def test_create_user(client: AsyncClient):
    response = await client.post("/api/v1/users", json={
        "email": "test@example.com",
        "password": "testpassword123",
    })
    assert response.status_code == 201
    assert response.json()["email"] == "test@example.com"
```

## Additional References

For advanced patterns beyond this guide, see:

- **[Dependency Injection Patterns](dependency-injection-patterns.md)** - Type aliases (DbSession, CurrentUser, AdminUser), pagination dependencies, sorting/filtering, service layer patterns, request context, feature flags, rate limiting, caching dependencies

## Related References

- [`python-asyncio.md`](python-asyncio.md) - Async patterns
- [`python-testing.md`](python-testing.md) - Testing
- [`python-type-hints.md`](python-type-hints.md) - Type hints
