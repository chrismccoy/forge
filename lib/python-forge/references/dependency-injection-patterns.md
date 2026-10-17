# FastAPI Dependency Injection Patterns

Advanced dependency injection patterns for production FastAPI applications. Snippets build on each other: names such as `router`, `DbSession`, `CurrentUser`, and the `User`/`Item` models come from earlier sections or the application package.

## Contents

- Type Aliases for Clean Signatures
- Pagination Dependency
- Sorting and Filtering
- Service Layer Dependencies
- Request Context / Scope Dependency
- Feature Flags Dependency
- Rate Limiting Dependency
- Caching Dependency

## Type Aliases for Clean Signatures

```python
from collections.abc import AsyncIterator
from typing import Annotated

import jwt
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import async_session
from app.models import User
from app.schemas.user import UserResponse

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

# Database session
async def get_db() -> AsyncIterator[AsyncSession]:
    async with async_session() as session:
        yield session

DbSession = Annotated[AsyncSession, Depends(get_db)]

# Current user
async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: DbSession,
) -> User:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id = int(payload["sub"])
    except (jwt.InvalidTokenError, KeyError, ValueError):
        raise HTTPException(401, "Invalid token", headers={"WWW-Authenticate": "Bearer"})
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(401, "Invalid token", headers={"WWW-Authenticate": "Bearer"})
    return user

CurrentUser = Annotated[User, Depends(get_current_user)]

# Active user (verified, not banned)
async def get_active_user(user: CurrentUser) -> User:
    if not user.is_active:
        raise HTTPException(403, "User is inactive")
    return user

ActiveUser = Annotated[User, Depends(get_active_user)]

# Admin user
async def get_admin_user(user: ActiveUser) -> User:
    if not user.is_admin:
        raise HTTPException(403, "Admin access required")
    return user

AdminUser = Annotated[User, Depends(get_admin_user)]


# Usage - clean endpoint signatures
@router.get("/users/me")
async def get_me(user: CurrentUser) -> UserResponse:
    return user

@router.delete("/users/{user_id}")
async def delete_user(user_id: int, admin: AdminUser, db: DbSession) -> None:
    await db.execute(delete(User).where(User.id == user_id))
    await db.commit()
```

## Pagination Dependency

```python
from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, Query
from pydantic import BaseModel
from sqlalchemy import func, select

@dataclass
class PaginationParams:
    page: int
    size: int
    offset: int

    @property
    def limit(self) -> int:
        return self.size


def get_pagination(
    page: Annotated[int, Query(ge=1, description="Page number")] = 1,
    size: Annotated[int, Query(ge=1, le=100, description="Items per page")] = 20,
) -> PaginationParams:
    return PaginationParams(
        page=page,
        size=size,
        offset=(page - 1) * size,
    )

Pagination = Annotated[PaginationParams, Depends(get_pagination)]


class PagedResponse[T](BaseModel):
    items: list[T]
    total: int
    page: int
    size: int
    pages: int


# Usage
@router.get("/users", response_model=PagedResponse[UserResponse])
async def list_users(
    db: DbSession,
    pagination: Pagination,
) -> PagedResponse[UserResponse]:
    # Count total
    total = await db.scalar(select(func.count()).select_from(User)) or 0

    # Get page
    query = select(User).offset(pagination.offset).limit(pagination.limit)
    result = await db.execute(query)
    users = result.scalars().all()

    return PagedResponse[UserResponse](
        items=[UserResponse.model_validate(u) for u in users],
        total=total,
        page=pagination.page,
        size=pagination.size,
        pages=(total + pagination.size - 1) // pagination.size,
    )
```

## Sorting and Filtering

```python
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from typing import Annotated

from fastapi import Depends, Query
from sqlalchemy import func, select

from app.models import Item
from app.schemas.item import ItemResponse

class SortOrder(StrEnum):
    ASC = "asc"
    DESC = "desc"

@dataclass
class SortParams:
    field: str
    order: SortOrder

def get_sort(
    sort_by: Annotated[str, Query(description="Field to sort by")] = "created_at",
    order: Annotated[SortOrder, Query(description="Sort order")] = SortOrder.DESC,
) -> SortParams:
    return SortParams(field=sort_by, order=order)

Sort = Annotated[SortParams, Depends(get_sort)]


@dataclass
class FilterParams:
    search: str | None
    status: str | None
    created_after: datetime | None
    created_before: datetime | None

def get_filters(
    search: Annotated[str | None, Query(description="Search term")] = None,
    status: Annotated[str | None, Query(description="Status filter")] = None,
    created_after: Annotated[datetime | None, Query()] = None,
    created_before: Annotated[datetime | None, Query()] = None,
) -> FilterParams:
    return FilterParams(
        search=search,
        status=status,
        created_after=created_after,
        created_before=created_before,
    )

Filters = Annotated[FilterParams, Depends(get_filters)]


# Usage
@router.get("/items")
async def list_items(
    db: DbSession,
    pagination: Pagination,
    sort: Sort,
    filters: Filters,
) -> PagedResponse[ItemResponse]:
    query = select(Item)
    count_query = select(func.count()).select_from(Item)

    # Apply filters (built once, applied to both queries)
    conditions = []
    if filters.search:
        conditions.append(Item.name.ilike(f"%{filters.search}%"))
    if filters.status:
        conditions.append(Item.status == filters.status)
    if filters.created_after:
        conditions.append(Item.created_at >= filters.created_after)
    if filters.created_before:
        conditions.append(Item.created_at <= filters.created_before)
    if conditions:
        query = query.where(*conditions)
        count_query = count_query.where(*conditions)

    total = await db.scalar(count_query) or 0

    # Apply sorting (allowlist the column to avoid exposing arbitrary attributes)
    allowed_sort = {"created_at", "name", "status"}
    sort_column = getattr(Item, sort.field if sort.field in allowed_sort else "created_at")
    if sort.order == SortOrder.DESC:
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())

    # Apply pagination
    query = query.offset(pagination.offset).limit(pagination.limit)

    result = await db.execute(query)
    return PagedResponse[ItemResponse](
        items=[ItemResponse.model_validate(i) for i in result.scalars().all()],
        total=total,
        page=pagination.page,
        size=pagination.size,
        pages=(total + pagination.size - 1) // pagination.size,
    )
```

## Service Layer Dependencies

```python
from typing import Annotated, Protocol

from fastapi import Depends, HTTPException
from sqlalchemy import delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models import User
from app.schemas.user import UserCreate, UserResponse, UserUpdate

# Service protocol
class UserServiceProtocol(Protocol):
    async def get_by_id(self, user_id: int) -> User | None: ...
    async def create(self, data: UserCreate) -> User: ...
    async def update(self, user_id: int, data: UserUpdate) -> User: ...
    async def delete(self, user_id: int) -> bool: ...


# Service implementation
class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, user_id: int) -> User | None:
        return await self.db.get(User, user_id)

    async def create(self, data: UserCreate) -> User:
        user = User(**data.model_dump(exclude={"password"}))
        user.hashed_password = hash_password(data.password)
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def update(self, user_id: int, data: UserUpdate) -> User:
        user = await self.get_by_id(user_id)
        if not user:
            raise HTTPException(404, "User not found")
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(user, field, value)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def delete(self, user_id: int) -> bool:
        result = await self.db.execute(
            delete(User).where(User.id == user_id)
        )
        await self.db.commit()
        return result.rowcount > 0


# Dependency
def get_user_service(db: DbSession) -> UserService:
    return UserService(db)

UserSvc = Annotated[UserService, Depends(get_user_service)]


# Usage
@router.get("/users/{user_id}")
async def get_user(user_id: int, service: UserSvc) -> UserResponse:
    user = await service.get_by_id(user_id)
    if not user:
        raise HTTPException(404, "User not found")
    return user

@router.post("/users", status_code=201)
async def create_user(data: UserCreate, service: UserSvc) -> UserResponse:
    return await service.create(data)
```

## Request Context / Scope Dependency

```python
from contextvars import ContextVar
from typing import Annotated
from uuid import uuid4

from fastapi import Depends, Request

# Context variables
request_id_ctx: ContextVar[str] = ContextVar("request_id", default="")
user_ctx: ContextVar[User | None] = ContextVar("current_user", default=None)


# Middleware to set request context
@app.middleware("http")
async def request_context_middleware(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID", str(uuid4()))
    request_id_ctx.set(request_id)

    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response


# Access context anywhere
def get_request_id() -> str:
    return request_id_ctx.get()

RequestId = Annotated[str, Depends(get_request_id)]


# Usage in logging
import structlog

def get_logger() -> structlog.BoundLogger:
    return structlog.get_logger().bind(request_id=request_id_ctx.get())

Logger = Annotated[structlog.BoundLogger, Depends(get_logger)]


@router.post("/orders")
async def create_order(
    data: OrderCreate,
    db: DbSession,
    user: CurrentUser,
    request_id: RequestId,
    logger: Logger,
) -> OrderResponse:
    logger.info("Creating order", user_id=user.id)
    # ... create order
```

## Feature Flags Dependency

```python
from dataclasses import dataclass
from typing import Annotated

import jwt
from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer

from app.config import settings

# auto_error=False: a missing Authorization header yields None instead of a 401
optional_oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token", auto_error=False)


async def get_optional_user(
    token: Annotated[str | None, Depends(optional_oauth2_scheme)],
    db: DbSession,
) -> User | None:
    """Return the authenticated user, or None for anonymous requests."""
    if token is None:
        return None
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id = int(payload["sub"])
    except (jwt.InvalidTokenError, KeyError, ValueError):
        return None
    return await db.get(User, user_id)

OptionalUser = Annotated[User | None, Depends(get_optional_user)]


@dataclass
class FeatureFlags:
    new_dashboard: bool
    beta_api: bool
    dark_mode: bool


async def get_feature_flags(user: OptionalUser) -> FeatureFlags:
    """Get feature flags for current user."""
    # Could fetch from database, config, or feature flag service
    base_flags = FeatureFlags(
        new_dashboard=True,
        beta_api=False,
        dark_mode=True,
    )

    # User-specific overrides
    if user and user.is_beta_tester:
        base_flags.beta_api = True

    return base_flags

Features = Annotated[FeatureFlags, Depends(get_feature_flags)]


@router.get("/dashboard")
async def get_dashboard(features: Features) -> dict:
    if features.new_dashboard:
        return {"version": "v2", "data": [...]}
    return {"version": "v1", "data": [...]}
```

## Rate Limiting Dependency

```python
import time
from dataclasses import dataclass
from uuid import uuid4

import redis.asyncio as redis
from fastapi import Depends, HTTPException, Request

@dataclass
class RateLimitResult:
    allowed: bool
    remaining: int
    reset_at: int


class RateLimiter:
    def __init__(self, redis_client: redis.Redis, limit: int, window: int):
        self.redis = redis_client
        self.limit = limit
        self.window = window

    async def check(self, key: str) -> RateLimitResult:
        now = time.time()
        window_start = now - self.window
        # Unique member per request: a timestamp-only member would collapse
        # concurrent/same-second requests into one zset entry.
        member = f"{time.time_ns()}-{uuid4()}"

        pipe = self.redis.pipeline()
        pipe.zremrangebyscore(key, 0, window_start)
        pipe.zadd(key, {member: now})
        pipe.zcard(key)
        pipe.expire(key, self.window)
        _, _, count, _ = await pipe.execute()

        return RateLimitResult(
            allowed=count <= self.limit,
            remaining=max(0, self.limit - count),
            reset_at=int(now) + self.window,
        )


def rate_limit(limit: int = 100, window: int = 60):
    """Rate limit dependency factory."""
    async def dependency(request: Request) -> None:
        limiter = RateLimiter(request.app.state.redis, limit, window)
        client_host = request.client.host if request.client else "unknown"
        key = f"rate_limit:{client_host}:{request.url.path}"

        result = await limiter.check(key)
        if not result.allowed:
            raise HTTPException(
                status_code=429,
                detail="Too many requests",
                headers={
                    "X-RateLimit-Remaining": str(result.remaining),
                    "X-RateLimit-Reset": str(result.reset_at),
                },
            )

    return Depends(dependency)


# Usage
@router.post("/api/expensive-operation", dependencies=[rate_limit(10, 60)])
async def expensive_operation() -> dict:
    # Limited to 10 requests per minute
    return {"status": "ok"}
```

## Caching Dependency

```python
import hashlib
import json
from collections.abc import Awaitable, Callable
from functools import wraps
from typing import Any

from fastapi import Request
from pydantic import TypeAdapter
from sqlalchemy import select

from app.models import Product
from app.schemas.product import ProductResponse


def cached(response_type: Any, ttl: int = 300, key_prefix: str = ""):
    """Cache decorator for endpoints.

    `response_type` (e.g. `list[ProductResponse]`) drives serialization, so ORM
    objects are converted through Pydantic instead of `json.dumps`, which would
    fail on them. Cache hits return the same validated type as misses.
    """
    adapter = TypeAdapter(response_type)

    def decorator(func: Callable[..., Awaitable[Any]]):
        @wraps(func)  # FastAPI follows __wrapped__ to read the original signature
        async def wrapper(*args: Any, request: Request, **kwargs: Any) -> Any:
            # Generate cache key
            key_data = {
                "path": request.url.path,
                "query": str(request.query_params),
                "prefix": key_prefix,
            }
            cache_key = "cache:" + hashlib.sha256(
                json.dumps(key_data, sort_keys=True).encode()
            ).hexdigest()

            # Check cache
            redis_client = request.app.state.redis
            hit = await redis_client.get(cache_key)
            if hit is not None:
                return adapter.validate_json(hit)

            # Execute, validate (from_attributes handles ORM objects), and cache
            result = adapter.validate_python(
                await func(*args, request=request, **kwargs), from_attributes=True
            )
            await redis_client.setex(cache_key, ttl, adapter.dump_json(result))
            return result

        return wrapper
    return decorator


# Usage
@router.get("/products")
@cached(list[ProductResponse], ttl=60, key_prefix="products")
async def list_products(request: Request, db: DbSession) -> list[ProductResponse]:
    result = await db.execute(select(Product))
    return result.scalars().all()
```
