"""Umumiy sxemalar — pagination va h.k."""
from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class Page(BaseModel, Generic[T]):
    """Generic pagination javob konverti."""
    items: list[T]
    total: int
    limit: int
    offset: int
