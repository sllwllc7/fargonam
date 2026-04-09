"""
Barcha SQLAlchemy modellari uchun umumiy Base klass.
Modellar shu Base'dan meros oladi va Alembic shu orqali ularni topadi.
"""
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass
