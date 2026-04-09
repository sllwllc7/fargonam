"""
Async SQLAlchemy engine va session factory.
FastAPI dependency `get_db` orqali har so'rovga yangi session beriladi.
"""
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_pre_ping=True,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency — endpoint'larda `Depends(get_db)` orqali ishlatiladi."""
    async with AsyncSessionLocal() as session:
        yield session
