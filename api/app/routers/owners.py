from __future__ import annotations

import sqlite3
from typing import List

from fastapi import APIRouter, Depends

from ..dependencies import Identity, get_db, require_owner
from ..models import OwnerOut, DroneOut
from .drones import _fetch_drone_images, _insert_drone_images


router = APIRouter()


@router.get("/", response_model=List[OwnerOut])
def list_owners(
    _: Identity = Depends(require_owner),
    db: sqlite3.Connection = Depends(get_db),
) -> List[OwnerOut]:
    rows = db.execute("SELECT id,name,mobile,lat,lon FROM owners").fetchall()
    return [OwnerOut(**dict(row)) for row in rows]


@router.get("/me/drones", response_model=List[DroneOut])
def list_my_drones(
    identity: Identity = Depends(require_owner),
    db: sqlite3.Connection = Depends(get_db),
) -> List[DroneOut]:
    owner = db.execute("SELECT id,name,lat,lon FROM owners WHERE mobile=?", (identity.mobile,)).fetchone()
    if not owner:
        return []

    existing = db.execute(
        "SELECT id,name,type,lat,lon,status,price_per_hr,image_url,battery_mah,capacity_liters,owner_id "
        "FROM drones WHERE owner_id=?",
        (owner["id"],),
    ).fetchall()

    if not existing:
        _seed_owner_demo_drones(db, owner)
        existing = db.execute(
            "SELECT id,name,type,lat,lon,status,price_per_hr,image_url,battery_mah,capacity_liters,owner_id "
            "FROM drones WHERE owner_id=?",
            (owner["id"],),
        ).fetchall()

    image_map = _fetch_drone_images(db, [row["id"] for row in existing])
    return [DroneOut(**dict(row), image_urls=image_map.get(row["id"])) for row in existing]


def _seed_owner_demo_drones(db: sqlite3.Connection, owner_row: sqlite3.Row) -> None:
    templates = [
        {
            "name": "AgriTek ProFlyer X",
            "type": "Spray",
            "price": 150.0,
            "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuCuHeU8mijsvSMSJvpaLMIBUlY7GfslFAZZ_O2ASIQJqnwmMsWx4dW4KjqJArtAUcDuhP2PnXAs2Lnv5opv-w_jH_I_cUTXP2TtU0DiBTC83Z8PCW64JlSKDHM43wnDtLWUIXtrsXOvU1iKUg7SKQPhRypuqlXsddv43-XE6srL-cdcYvxE6BZdTdXwQ9r4MVmP_lWg_1y31kvMuMd6izcbleiKUBu7Mb7XOQ3Pb8z8beyEb24UA_zqrkFx_Xg6jz7qHMSgB82EU7wo",
            "battery": 9600.0,
            "capacity": 40.0,
            "status": "Available",
        },
        {
            "name": "FieldMapper V2",
            "type": "Survey",
            "price": 120.0,
            "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuBKB3h-_zRAeBiUbZPUi0buk8cveGokg11zk5NibMx-jbo0D9MpVqfkLUdRGeam7x6KIOU4xMRszPuZrBxz-nFcFWGhf5JxtXKHwZnno9PvDD7MGiSlfV_-KUdHUKzcNAXEFya6A8tZX4HNUYHiv-KF70jC236Y2754ktgamIspjKwjBzo_kemhu1sLeVXIaHQdEyUSJoa7YsMggIO7JDeWDW4X4PzLwxl8rUZbElRtAb1gdW3NZpO68xgVZL8gOLfDd-w36SvVPbim",
            "battery": 7800.0,
            "capacity": 18.0,
            "status": "Rented",
        },
        {
            "name": "CropScanner 3000",
            "type": "Mapping",
            "price": 180.0,
            "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuBaW9C1wqw_l-QZYF-VWYgAu-oHG0N6wa-Tj56DkYgekx0g9uIKxkRj4EeEm_C6PBIt7L1w8049OhiaEmD-6Cc64zq6kIClJ1wTaUufFg-uQZeeL7PvdOrMJorQsrjtcIADq4YlPiXNl0TTvW0DNcAP7wPAaqBTX85aWD5dNYzJwgQFpk-ioYCg3eMVJpADOy-e7luAPaKfCrgJ4FM3AuIreJlUeNrnoaO9ZSLoGGfP3OOGsC-rjBdOQwVg6vlM0KdxDfUl0PBA2rHJ",
            "battery": 8500.0,
            "capacity": 22.0,
            "status": "Maintenance",
        },
    ]
    base_lat = owner_row["lat"] or 25.62
    base_lon = owner_row["lon"] or 85.14

    for idx, template in enumerate(templates):
        lat_offset = (idx % 2) * 0.01
        lon_offset = (idx % 3) * 0.015
        cursor = db.execute(
            (
                "INSERT INTO drones(name,type,lat,lon,status,price_per_hr,image_url,battery_mah,capacity_liters,owner_id) "
                "VALUES(?,?,?,?,?,?,?,?,?,?)"
            ),
            (
                template["name"],
                template["type"],
                base_lat + lat_offset,
                base_lon + lon_offset,
                template.get("status", "Available"),
                template["price"],
                template["image"],
                template["battery"],
                template["capacity"],
                owner_row["id"],
            ),
        )
        new_id = cursor.lastrowid
        _insert_drone_images(db, new_id, [template["image"]])
    db.commit()
