from __future__ import annotations

import sqlite3
from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query

from ..dependencies import Identity, get_db, get_identity, require_farmer, require_owner
from ..models import BookingCreate, BookingOut, BookingStatusUpdate, UserRole


router = APIRouter()


@router.get("/", response_model=List[BookingOut])
def list_bookings(
    status: str | None = Query(default=None),
    identity: Identity = Depends(get_identity),
    db: sqlite3.Connection = Depends(get_db),
) -> List[BookingOut]:
    params: list = []
    if identity.role is UserRole.owner:
        owner = db.execute("SELECT id FROM owners WHERE mobile=?", (identity.mobile,)).fetchone()
        if not owner:
            raise HTTPException(status_code=404, detail="Owner not found")
        query = (
            "SELECT b.id,b.drone_id,b.farmer_name,b.farmer_mobile,b.booking_date,b.duration_hrs,b.status "
            "FROM bookings b JOIN drones d ON b.drone_id = d.id WHERE d.owner_id=?"
        )
        params.append(owner["id"])
        if status:
            query += " AND b.status=?"
            params.append(status)
    else:
        query = (
            "SELECT id,drone_id,farmer_name,farmer_mobile,booking_date,duration_hrs,status "
            "FROM bookings WHERE farmer_mobile=?"
        )
        params.append(identity.mobile)
        if status:
            query += " AND status=?"
            params.append(status)

    query += " ORDER BY booking_date DESC"
    rows = db.execute(query, tuple(params)).fetchall()
    return [BookingOut(**dict(row)) for row in rows]


@router.post("/", response_model=BookingOut)
def create_booking(
    payload: BookingCreate,
    identity: Identity = Depends(require_farmer),
    db: sqlite3.Connection = Depends(get_db),
) -> BookingOut:
    drone = db.execute("SELECT id FROM drones WHERE id=?", (payload.drone_id,)).fetchone()
    if not drone:
        raise HTTPException(status_code=404, detail="Drone not found")
    farmer = db.execute("SELECT name FROM farmers WHERE mobile=?", (identity.mobile,)).fetchone()
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")
    now = datetime.utcnow().isoformat()
    farmer_name = payload.farmer_name or farmer["name"]
    db.execute(
        "INSERT INTO bookings(drone_id,farmer_name,farmer_mobile,booking_date,duration_hrs,status) "
        "VALUES(?,?,?,?,?, 'Pending')",
        (
            payload.drone_id,
            farmer_name,
            identity.mobile,
            now,
            payload.duration_hrs,
        ),
    )
    db.commit()
    new_id = db.execute("SELECT last_insert_rowid()").fetchone()[0]
    row = db.execute(
        "SELECT id,drone_id,farmer_name,farmer_mobile,booking_date,duration_hrs,status FROM bookings WHERE id=?",
        (new_id,),
    ).fetchone()
    return BookingOut(**dict(row))


@router.patch("/{booking_id}")
def update_booking(
    booking_id: int,
    payload: BookingStatusUpdate,
    identity: Identity = Depends(require_owner),
    db: sqlite3.Connection = Depends(get_db),
) -> dict:
    if payload.status not in {"Pending", "Accepted", "Rejected"}:
        raise HTTPException(status_code=400, detail="status must be Pending/Accepted/Rejected")
    owner = db.execute("SELECT id FROM owners WHERE mobile=?", (identity.mobile,)).fetchone()
    if not owner:
        raise HTTPException(status_code=404, detail="Owner not found")
    booking = db.execute(
        "SELECT drone_id FROM bookings WHERE id=?",
        (booking_id,),
    ).fetchone()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    drone = db.execute("SELECT owner_id FROM drones WHERE id=?", (booking["drone_id"],)).fetchone()
    if not drone:
        raise HTTPException(status_code=404, detail="Drone not found")
    if drone["owner_id"] != owner["id"]:
        raise HTTPException(status_code=403, detail="Cannot update another owner's booking")

    db.execute("UPDATE bookings SET status=? WHERE id=?", (payload.status, booking_id))
    if payload.status == "Accepted":
        db.execute(
            "UPDATE drones SET status='Booked' WHERE id=?",
            (booking["drone_id"],),
        )
    elif payload.status in {"Pending", "Rejected"}:
        db.execute(
            "UPDATE drones SET status='Available' WHERE id=?",
            (booking["drone_id"],),
        )
    db.commit()
    return {"message": f"Booking {payload.status}"}
