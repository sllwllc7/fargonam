"""Ilova versiyasi — mobil ilovalar ishga tushganda so'raydi.

Qiymatlar DB emas, JSON fayldan o'qiladi (`APP_VERSION_FILE`, standart
`/app/app_version.json`) — operator konteyner qayta ishga tushirmasdan,
faylni to'g'ridan-to'g'ri tahrirlab yangi versiya e'lon qila oladi.
"""
import json
import os

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

router = APIRouter(prefix="/app", tags=["app-version"])

_VERSION_FILE = os.environ.get("APP_VERSION_FILE", "/app/app_version.json")


class AppVersionOut(BaseModel):
    version: str
    build: int
    apk_url: str
    notes: str = ""
    force: bool = False


@router.get("/version", response_model=AppVersionOut)
async def get_app_version(app: str):
    if app not in ("user", "seller"):
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="app 'user' yoki 'seller' bo'lishi kerak")
    try:
        with open(_VERSION_FILE) as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Versiya ma'lumoti topilmadi")
    entry = data.get(app)
    if entry is None:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Versiya ma'lumoti topilmadi")
    return AppVersionOut(**entry)
