from __future__ import annotations

import base64
import hmac
import hashlib
import json
import time
from datetime import datetime, timedelta

from fastapi import HTTPException, status

from .config import get_settings


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _b64url_decode(segment: str) -> bytes:
    return base64.urlsafe_b64decode(segment + "=" * (-len(segment) % 4))


def jwt_encode(payload: dict) -> str:
    settings = get_settings()
    header = {"alg": "HS256", "typ": "JWT"}
    body = dict(payload)
    if isinstance(body.get("exp"), datetime):
        body["exp"] = int(body["exp"].timestamp())
    header_b64 = _b64url(json.dumps(header, separators=(",", ":")).encode())
    payload_b64 = _b64url(json.dumps(body, separators=(",", ":")).encode())
    signing_input = f"{header_b64}.{payload_b64}".encode()
    sig = hmac.new(settings.secret_key.encode(), signing_input, hashlib.sha256).digest()
    return f"{header_b64}.{payload_b64}.{_b64url(sig)}"


def jwt_decode(token: str) -> dict:
    settings = get_settings()
    parts = token.split(".")
    if len(parts) != 3:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    signing_input = f"{parts[0]}.{parts[1]}".encode()
    sig = _b64url_decode(parts[2])
    expected = hmac.new(settings.secret_key.encode(), signing_input, hashlib.sha256).digest()
    if not hmac.compare_digest(sig, expected):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid signature")
    payload = json.loads(_b64url_decode(parts[1]))
    if "exp" in payload and int(payload["exp"]) < int(time.time()):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired")
    return payload


def generate_token(subject: str, role: str) -> str:
    settings = get_settings()
    expiry = datetime.utcnow() + timedelta(minutes=settings.token_expire_minutes)
    return jwt_encode({"sub": subject, "role": role, "exp": expiry})
