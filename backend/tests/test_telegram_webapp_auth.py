"""Telegram Mini App `initData` HMAC-SHA256 tekshiruvi uchun testlar.

DB'siz, sof funksiya testi — `_validate_webapp_init_data` faqat imzoni
tekshiradi, hech qanday tashqi bog'liqlik yo'q.
"""
import hashlib
import hmac
import time
from urllib.parse import urlencode

import pytest
from fastapi import HTTPException

from app.api.telegram_auth import _validate_webapp_init_data

BOT_TOKEN = "123456789:test-bot-token-for-unit-tests"


def _sign(fields: dict, bot_token: str = BOT_TOKEN) -> str:
    data_check_string = "\n".join(f"{k}={v}" for k, v in sorted(fields.items()))
    secret_key = hmac.new(b"WebAppData", bot_token.encode(), hashlib.sha256).digest()
    return hmac.new(secret_key, data_check_string.encode(), hashlib.sha256).hexdigest()


def _init_data(auth_date: int | None = None, bot_token: str = BOT_TOKEN, **extra) -> str:
    fields = {
        "user": '{"id":123,"first_name":"Test"}',
        "auth_date": str(auth_date if auth_date is not None else int(time.time())),
        **extra,
    }
    fields["hash"] = _sign(fields, bot_token)
    return urlencode(fields)


def test_valid_init_data_passes():
    init_data = _init_data()
    result = _validate_webapp_init_data(init_data, BOT_TOKEN)
    assert result["auth_date"] is not None
    assert "id" in result["user"]


def test_missing_hash_rejected():
    with pytest.raises(HTTPException) as exc:
        _validate_webapp_init_data("user=%7B%7D&auth_date=123", BOT_TOKEN)
    assert exc.value.status_code == 401


def test_tampered_payload_rejected():
    init_data = _init_data()
    # Imzo hisoblangandan keyin user maydonini almashtiramiz — hash endi mos kelmaydi
    tampered = init_data.replace("Test", "Hacker")
    with pytest.raises(HTTPException) as exc:
        _validate_webapp_init_data(tampered, BOT_TOKEN)
    assert exc.value.status_code == 401


def test_wrong_bot_token_rejected():
    init_data = _init_data(bot_token="000000000:different-token")
    with pytest.raises(HTTPException) as exc:
        _validate_webapp_init_data(init_data, BOT_TOKEN)
    assert exc.value.status_code == 401


def test_expired_auth_date_rejected():
    old_timestamp = int(time.time()) - 90000  # 25 soat oldin (limit 24 soat)
    init_data = _init_data(auth_date=old_timestamp)
    with pytest.raises(HTTPException) as exc:
        _validate_webapp_init_data(init_data, BOT_TOKEN)
    assert exc.value.status_code == 401
    assert "muddati tugagan" in exc.value.detail


def test_fresh_auth_date_within_24h_accepted():
    recent_timestamp = int(time.time()) - 3600  # 1 soat oldin
    init_data = _init_data(auth_date=recent_timestamp)
    result = _validate_webapp_init_data(init_data, BOT_TOKEN)
    assert result is not None
