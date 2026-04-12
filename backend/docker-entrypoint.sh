#!/bin/sh
set -e

echo "Alembic migratsiyalar ishga tushirilmoqda..."
alembic upgrade head

echo "Uvicorn serveri ishga tushirilmoqda..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
