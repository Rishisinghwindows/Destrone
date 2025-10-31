from __future__ import annotations

from datetime import datetime, timedelta

from .config import get_settings
from .db import db_connect, init_db, seed_demo_data, truncate_tables
from .security import generate_token, jwt_decode
from .utils import haversine_km


def run_selftest() -> dict[str, str]:
    settings = get_settings()
    init_db()

    token = generate_token("7000000000", "owner")
    payload = jwt_decode(token)
    assert payload["sub"] == "7000000000"
    assert payload["role"] == "owner"

    assert round(haversine_km(0, 0, 0, 0), 6) == 0.0

    con = db_connect()
    try:
        truncate_tables()
        con.execute(
            "INSERT INTO owners(name,mobile,lat,lon) VALUES(?,?,?,?)",
            ("Owner", "7000000000", 25.6, 85.1),
        )
        con.commit()
        owner_id = con.execute(
            "SELECT id FROM owners WHERE mobile=?",
            ("7000000000",),
        ).fetchone()[0]
        con.execute(
            "INSERT INTO drones(name,type,lat,lon,price_per_hr,image_url,battery_mah,capacity_liters,owner_id) VALUES(?,?,?,?,?,?,?,?,?)",
            (
                "D1",
                "Spray",
                25.6,
                85.1,
                500.0,
                "https://images.unsplash.com/photo-1523966211575-eb4a01e7dd51?auto=format&fit=crop&w=800&q=80",
                8000,
                24,
                owner_id,
            ),
        )
        con.commit()
        drone_id = con.execute("SELECT id FROM drones").fetchone()[0]
        con.execute(
            "INSERT INTO bookings(drone_id,farmer_name,booking_date,duration_hrs,status) VALUES(?,?,?,?,?)",
            (
                drone_id,
                "Farmer",
                datetime.utcnow().isoformat(),
                2,
                "Pending",
            ),
        )
        con.commit()

        assert con.execute("SELECT COUNT(1) FROM owners").fetchone()[0] == 1
        assert con.execute("SELECT COUNT(1) FROM drones").fetchone()[0] == 1
        assert con.execute("SELECT COUNT(1) FROM bookings").fetchone()[0] == 1
    finally:
        con.close()

    seed_demo_data()

    return {"selftest": "ok"}
