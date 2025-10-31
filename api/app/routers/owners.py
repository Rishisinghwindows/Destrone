from __future__ import annotations

import sqlite3
from typing import List

from fastapi import APIRouter, Depends

from ..dependencies import Identity, get_db, require_owner
from ..models import OwnerOut


router = APIRouter()


@router.get("/", response_model=List[OwnerOut])
def list_owners(
    _: Identity = Depends(require_owner),
    db: sqlite3.Connection = Depends(get_db),
) -> List[OwnerOut]:
    rows = db.execute("SELECT id,name,mobile,lat,lon FROM owners").fetchall()
    return [OwnerOut(**dict(row)) for row in rows]
