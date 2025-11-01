from __future__ import annotations

import sqlite3
from collections import defaultdict
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query

from ..dependencies import Identity, get_db, require_owner
from ..models import AvailabilityUpdate, DroneCreate, DroneOut
from ..utils import haversine_km


DRONE_IMAGE_POOL = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuDw3EbDprqmgL5vEuv4kwV7bhY5RFilj_p4P9AERyMOGxEO9ITL2XwDoRxkOCeZU50jnu7xne0FiHdLTlZIJB2dSTbp5_gBfA9WhmdLVWHyzFhQPe9Jo7PD0vv6-dCgt1g3YnnLe_4opFr9BIXJD-p-r7l65ouwI6eKBN_tab8Q4oytcXmTfJKtZPo96ZyZBBKPv-Yl8VUVDIdXXHOjtU-0zaOCLGIftg3o6XJFk_BsV4qxQ2s1a4dLiDN_VwiqtFc-ZlezlDK97q2r",
    "https://lh3.googleusercontent.com/aida-public/AB6AXuBbQpz0KL1ynDcCeDlxxU0iJP73fczMcGFo3NBOqhsVXoZtRr-9m0gOY6vwHKPhl3EVjIF-mHOO715dHto5iVz6HO8Kww4aO4Kpu0Xue5herY4uz8f0w6XoGkZ1wRHhndBRjEmYKdvTcc9w0oHSOsd51csZCuP_NqhNu4h5BhtWGsosG4lZRIHC9xrgtETbluNf-z7I920qQYeAnWnsX2ttuIKyPORdSlNNPWtcrx9CQ_I7N9qB0NUv4019CjwJ0MmujouabufXln_S",
    "https://lh3.googleusercontent.com/aida-public/AB6AXuAmpV08bzFkSosB8mv2e8SgWObi7jdK2vPsg4xOd0rnpB5iQKwBMT2nhKmmJzADOFATT-94zILucmYeMRczuMhZqxr9fG4pZ4_zBP3jyEwTf7E6QeyD5aOW52TrpQwfhpBT-UJgZd3f5DhQJRUSsnv29DxSNtudUMMiHABADHu5W3N_2WeaGa4OIpG_mDysO_QKDcshJtmSSNQz2-2plPA0x2QzpOIhZlsv_TrNJjdlvtSXxvpc1VbspB-aA_oURxGIIbHj1OS8oS1j",
)


router = APIRouter()


@router.get("/", response_model=List[DroneOut])
def list_drones(
    lat: float | None = Query(default=None),
    lon: float | None = Query(default=None),
    max_dist_km: float | None = Query(default=None),
    min_price: float | None = Query(default=None),
    max_price: float | None = Query(default=None),
    sort_by: str | None = Query(default=None),
    db: sqlite3.Connection = Depends(get_db),
) -> List[DroneOut]:
    rows = db.execute(
        "SELECT id,name,type,lat,lon,status,price_per_hr,image_url,battery_mah,capacity_liters,owner_id FROM drones"
    ).fetchall()
    id_list = [row["id"] for row in rows]
    image_map = _fetch_drone_images(db, id_list)
    drones = [DroneOut(**dict(row), image_urls=image_map.get(row["id"])) for row in rows]

    if min_price is not None:
        drones = [d for d in drones if d.price_per_hr >= min_price]
    if max_price is not None:
        drones = [d for d in drones if d.price_per_hr <= max_price]
    if lat is not None and lon is not None and max_dist_km is not None:
        drones = [
            d
            for d in drones
            if haversine_km(lat, lon, d.lat, d.lon) <= max_dist_km
        ]

    if sort_by == "price":
        drones.sort(key=lambda d: d.price_per_hr)
    elif sort_by == "distance" and lat is not None and lon is not None:
        drones.sort(key=lambda d: haversine_km(lat, lon, d.lat, d.lon))

    return drones


@router.get("/{drone_id}", response_model=DroneOut)
def get_drone(drone_id: int, db: sqlite3.Connection = Depends(get_db)) -> DroneOut:
    row = db.execute(
        "SELECT id,name,type,lat,lon,status,price_per_hr,image_url,battery_mah,capacity_liters,owner_id FROM drones WHERE id=?",
        (drone_id,),
    ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Drone not found")
    image_map = _fetch_drone_images(db, [row["id"]])
    return DroneOut(**dict(row), image_urls=image_map.get(row["id"]))


@router.post("/", response_model=DroneOut)
def create_drone(
    payload: DroneCreate,
    identity: Identity = Depends(require_owner),
    db: sqlite3.Connection = Depends(get_db),
) -> DroneOut:
    owner = db.execute("SELECT id FROM owners WHERE mobile=?", (identity.mobile,)).fetchone()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")

    primary_image = payload.image_url or (payload.image_urls[0] if payload.image_urls else None) or _default_image(db)

    db.execute(
        "INSERT INTO drones(name,type,lat,lon,price_per_hr,image_url,battery_mah,capacity_liters,owner_id) VALUES(?,?,?,?,?,?,?,?,?)",
        (
            payload.name,
            payload.type,
            float(payload.lat),
            float(payload.lon),
            float(payload.price_per_hr),
            primary_image,
            payload.battery_mah,
            payload.capacity_liters,
            int(owner["id"]),
        ),
    )
    db.commit()
    new_id = db.execute("SELECT last_insert_rowid()").fetchone()[0]

    if payload.image_urls:
        _insert_drone_images(db, new_id, payload.image_urls)
        db.commit()

    row = db.execute(
        "SELECT id,name,type,lat,lon,status,price_per_hr,image_url,battery_mah,capacity_liters,owner_id FROM drones WHERE id=?",
        (new_id,),
    ).fetchone()
    image_map = _fetch_drone_images(db, [new_id])
    return DroneOut(**dict(row), image_urls=image_map.get(new_id))


@router.patch("/{drone_id}/availability")
def update_availability(
    drone_id: int,
    payload: AvailabilityUpdate,
    identity: Identity = Depends(require_owner),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    if not payload.status:
        raise HTTPException(status_code=400, detail="status required")
    owner = db.execute("SELECT id FROM owners WHERE mobile=?", (identity.mobile,)).fetchone()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    row = db.execute("SELECT owner_id FROM drones WHERE id=?", (drone_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Drone not found")
    if row["owner_id"] != owner["id"]:
        raise HTTPException(status_code=403, detail="Cannot modify another owner's drone")
    db.execute("UPDATE drones SET status=? WHERE id=?", (payload.status, drone_id))
    db.commit()
    return {"message": "Availability updated", "status": payload.status}


def _default_image(db: sqlite3.Connection) -> str:
    count = db.execute("SELECT COUNT(*) FROM drones").fetchone()[0]
    return DRONE_IMAGE_POOL[count % len(DRONE_IMAGE_POOL)]


def _fetch_drone_images(db: sqlite3.Connection, drone_ids: List[int]) -> dict[int, List[str]]:
    if not drone_ids:
        return {}
    placeholders = ",".join("?" for _ in drone_ids)
    rows = db.execute(
        f"SELECT drone_id,url FROM drone_images WHERE drone_id IN ({placeholders}) ORDER BY id",
        tuple(drone_ids),
    ).fetchall()
    mapping: dict[int, List[str]] = defaultdict(list)
    for row in rows:
        mapping[row["drone_id"]].append(row["url"])
    return dict(mapping)


def _insert_drone_images(db: sqlite3.Connection, drone_id: int, urls: List[str]) -> None:
    trimmed = [url for url in urls if url]
    for url in trimmed[:3]:
        db.execute("INSERT INTO drone_images(drone_id,url) VALUES(?,?)", (drone_id, url))
