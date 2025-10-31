from __future__ import annotations

import sqlite3
from dataclasses import dataclass
from typing import Generator

from fastapi import Depends, Header, HTTPException, status

from .db import db_connect
from .models import UserRole
from .security import jwt_decode


async def get_db() -> Generator[sqlite3.Connection, None, None]:
    con = db_connect()
    try:
        yield con
    finally:
        con.close()


@dataclass
class Identity:
    mobile: str
    role: UserRole


def get_identity(
    authorization: str | None = Header(None),
    db: sqlite3.Connection = Depends(get_db),
) -> Identity:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")
    token = authorization.split(" ", 1)[1].strip()
    payload = jwt_decode(token)
    sub = payload.get("sub")
    if not sub:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")
    role_value = payload.get("role")
    try:
        role = UserRole(role_value)
    except Exception as exc:  # ValueError for invalid role
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid role") from exc

    if role is UserRole.farmer:
        row = db.execute("SELECT 1 FROM farmers WHERE mobile=?", (sub,)).fetchone()
        if not row:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Farmer profile not found")
    elif role is UserRole.owner:
        row = db.execute("SELECT 1 FROM owners WHERE mobile=?", (sub,)).fetchone()
        if not row:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Owner profile not found")

    return Identity(mobile=sub, role=role)


def require_owner(identity: Identity = Depends(get_identity)) -> Identity:
    if identity.role is not UserRole.owner:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Owner access required")
    return identity


def require_farmer(identity: Identity = Depends(get_identity)) -> Identity:
    if identity.role is not UserRole.farmer:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Farmer access required")
    return identity
