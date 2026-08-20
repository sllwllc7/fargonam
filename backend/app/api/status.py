"""Ochiq holat sahifasi — deploy sog'ligini va oxirgi release'ni ko'rsatadi.

`scripts/release.sh` har chiqarishdan keyin `STATUS_FILE`ni (standart
`/app/status.json`) yangilaydi; bu endpoint uni DB ulanish tekshiruvi
bilan birga qaytaradi.
"""
import json
import os

from fastapi import APIRouter
from sqlalchemy import text

from app.db.session import AsyncSessionLocal

router = APIRouter(tags=["status"])

_STATUS_FILE = os.environ.get("STATUS_FILE", "/app/status.json")


@router.get("/status")
async def get_status():
    db_ok = True
    try:
        async with AsyncSessionLocal() as db:
            await db.execute(text("SELECT 1"))
    except Exception:
        db_ok = False

    last_release = None
    try:
        with open(_STATUS_FILE) as f:
            last_release = json.load(f).get("last_release")
    except (FileNotFoundError, json.JSONDecodeError):
        pass

    return {
        "backend": "ok",
        "database": "ok" if db_ok else "error",
        "last_release": last_release,
    }
