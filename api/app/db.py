from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from datetime import datetime
from typing import Sequence

from .config import get_settings


def db_connect() -> sqlite3.Connection:
    settings = get_settings()
    con = sqlite3.connect(settings.database_path, check_same_thread=False)
    con.row_factory = sqlite3.Row
    return con


def init_db() -> None:
    with db_cursor() as cur:
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS owners (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                mobile TEXT NOT NULL UNIQUE,
                lat REAL,
                lon REAL
            );
            """
        )
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS drones (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                type TEXT NOT NULL,
                lat REAL NOT NULL,
                lon REAL NOT NULL,
                status TEXT NOT NULL DEFAULT 'Available',
                price_per_hr REAL NOT NULL DEFAULT 500.0,
                image_url TEXT,
                battery_mah REAL,
                capacity_liters REAL,
                owner_id INTEGER NOT NULL,
                FOREIGN KEY(owner_id) REFERENCES owners(id) ON DELETE CASCADE
            );
            """
        )
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS bookings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                drone_id INTEGER NOT NULL,
                farmer_name TEXT NOT NULL,
                booking_date TEXT NOT NULL,
                duration_hrs INTEGER NOT NULL,
                status TEXT NOT NULL DEFAULT 'Pending',
                FOREIGN KEY(drone_id) REFERENCES drones(id) ON DELETE CASCADE
            );
            """
        )

        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS farmers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                mobile TEXT NOT NULL UNIQUE,
                lat REAL,
                lon REAL
            );
            """
        )

        # Ensure bookings table has farmer_mobile column for role-based lookups
        existing_columns = {row["name"] for row in cur.execute("PRAGMA table_info(bookings)")}
        if "farmer_mobile" not in existing_columns:
            cur.execute("ALTER TABLE bookings ADD COLUMN farmer_mobile TEXT")

        drone_columns = {row["name"] for row in cur.execute("PRAGMA table_info(drones)")}
        if "image_url" not in drone_columns:
            cur.execute("ALTER TABLE drones ADD COLUMN image_url TEXT")
        if "battery_mah" not in drone_columns:
            cur.execute("ALTER TABLE drones ADD COLUMN battery_mah REAL")
        if "capacity_liters" not in drone_columns:
            cur.execute("ALTER TABLE drones ADD COLUMN capacity_liters REAL")


def seed_demo_data() -> None:
    demo_bookings = _demo_bookings()

    with db_cursor() as cur:
        current_rows = cur.execute("SELECT COUNT(*) FROM bookings").fetchone()[0]
        if current_rows >= len(demo_bookings):
            return

        cur.execute("DELETE FROM bookings")
        cur.execute("DELETE FROM drones")
        cur.execute("DELETE FROM owners")
        cur.execute("DELETE FROM farmers")
        cur.execute("DELETE FROM sqlite_sequence WHERE name IN ('bookings','drones','owners','farmers')")

        for owner in _demo_owners():
            cur.execute(
                "INSERT INTO owners(id,name,mobile,lat,lon) VALUES(?,?,?,?,?)",
                owner,
            )

        for farmer in _demo_farmers():
            cur.execute(
                "INSERT INTO farmers(id,name,mobile,lat,lon) VALUES(?,?,?,?,?)",
                farmer,
            )

        for drone in _demo_drones():
            cur.execute(
                (
                    "INSERT INTO drones("
                    "id,name,type,lat,lon,status,price_per_hr,image_url,battery_mah,capacity_liters,owner_id"
                    ") VALUES(?,?,?,?,?,?,?,?,?,?,?)"
                ),
                drone,
            )

        for booking in demo_bookings:
            cur.execute(
                (
                    "INSERT INTO bookings(" \
                    "id,drone_id,farmer_name,farmer_mobile,booking_date,duration_hrs,status" \
                    ") VALUES(?,?,?,?,?,?,?)"
                ),
                booking,
            )


@contextmanager
def db_cursor() -> sqlite3.Cursor:
    con = db_connect()
    cur = con.cursor()
    try:
        yield cur
        con.commit()
    finally:
        con.close()


def truncate_tables() -> None:
    with db_cursor() as cur:
        cur.execute("DELETE FROM bookings")
        cur.execute("DELETE FROM drones")
        cur.execute("DELETE FROM owners")
        cur.execute("DELETE FROM farmers")


def _demo_owners() -> Sequence[tuple[int, str, str, float, float]]:
    return (
        (1, "Rajesh Kumar", "7000000000", 25.610, 85.140),
        (2, "Neha Sharma", "7000000001", 25.620, 85.135),
        (3, "Aman Verma", "7000000002", 25.635, 85.120),
        (4, "Priya Singh", "7000000003", 25.645, 85.125),
        (5, "Ravi Ranjan", "7000000004", 25.630, 85.110),
        (6, "Pooja Das", "7000000005", 25.650, 85.140),
        (7, "Ankit Patel", "7000000006", 25.660, 85.150),
        (8, "Vivek Thakur", "7000000007", 25.670, 85.160),
        (9, "Deepak Mishra", "7000000008", 25.640, 85.130),
        (10, "Kiran Kumari", "7000000009", 25.615, 85.155),
        (11, "Sandeep Yadav", "7000000010", 25.605, 85.145),
        (12, "Manish Kumar", "7000000011", 25.625, 85.115),
        (13, "Anjali Devi", "7000000012", 25.655, 85.175),
        (14, "Harsh Singh", "7000000013", 25.675, 85.180),
        (15, "Mohit Sharma", "7000000014", 25.685, 85.190),
        (16, "Rina Gupta", "7000000015", 25.695, 85.200),
        (17, "Vikas Jain", "7000000016", 25.705, 85.210),
        (18, "Sneha Raj", "7000000017", 25.715, 85.220),
        (19, "Aarav Mehta", "7000000018", 25.725, 85.230),
        (20, "Simran Kaur", "7000000019", 25.735, 85.240),
    )


def _demo_farmers() -> Sequence[tuple[int, str, str, float, float]]:
    return (
        (1, "Ramesh Patel", "7100000000", 25.600, 85.150),
        (2, "Sunita Devi", "7100000001", 25.602, 85.152),
        (3, "Ajay Singh", "7100000002", 25.604, 85.154),
        (4, "Meena Kumari", "7100000003", 25.606, 85.156),
        (5, "Anil Kumar", "7100000004", 25.608, 85.158),
        (6, "Rekha Sinha", "7100000005", 25.610, 85.160),
        (7, "Mohammad Irfan", "7100000006", 25.612, 85.162),
        (8, "Sita Ram", "7100000007", 25.614, 85.164),
        (9, "Vivek Singh", "7100000008", 25.616, 85.166),
        (10, "Asha Devi", "7100000009", 25.618, 85.168),
        (11, "Hari Prasad", "7100000010", 25.620, 85.170),
        (12, "Maya Devi", "7100000011", 25.622, 85.172),
        (13, "Santosh Rai", "7100000012", 25.624, 85.174),
        (14, "Pawan Gupta", "7100000013", 25.626, 85.176),
        (15, "Manju Sharma", "7100000014", 25.628, 85.178),
        (16, "Kishor Singh", "7100000015", 25.630, 85.180),
        (17, "Reena Das", "7100000016", 25.632, 85.182),
        (18, "Suresh Kumar", "7100000017", 25.634, 85.184),
        (19, "Anita Singh", "7100000018", 25.636, 85.186),
        (20, "Vikram Yadav", "7100000019", 25.638, 85.188),
    )


def _demo_drones() -> Sequence[tuple[int, str, str, float, float, str, float, str, float | None, float | None, int]]:
    image_pool = (
        "https://lh3.googleusercontent.com/aida-public/AB6AXuDw3EbDprqmgL5vEuv4kwV7bhY5RFilj_p4P9AERyMOGxEO9ITL2XwDoRxkOCeZU50jnu7xne0FiHdLTlZIJB2dSTbp5_gBfA9WhmdLVWHyzFhQPe9Jo7PD0vv6-dCgt1g3YnnLe_4opFr9BIXJD-p-r7l65ouwI6eKBN_tab8Q4oytcXmTfJKtZPo96ZyZBBKPv-Yl8VUVDIdXXHOjtU-0zaOCLGIftg3o6XJFk_BsV4qxQ2s1a4dLiDN_VwiqtFc-ZlezlDK97q2r",
        "https://lh3.googleusercontent.com/aida-public/AB6AXuBbQpz0KL1ynDcCeDlxxU0iJP73fczMcGFo3NBOqhsVXoZtRr-9m0gOY6vwHKPhl3EVjIF-mHOO715dHto5iVz6HO8Kww4aO4Kpu0Xue5herY4uz8f0w6XoGkZ1wRHhndBRjEmYKdvTcc9w0oHSOsd51csZCuP_NqhNu4h5BhtWGsosG4lZRIHC9xrgtETbluNf-z7I920qQYeAnWnsX2ttuIKyPORdSlNNPWtcrx9CQ_I7N9qB0NUv4019CjwJ0MmujouabufXln_S",
        "https://lh3.googleusercontent.com/aida-public/AB6AXuAmpV08bzFkSosB8mv2e8SgWObi7jdK2vPsg4xOd0rnpB5iQKwBMT2nhKmmJzADOFATT-94zILucmYeMRczuMhZqxr9fG4pZ4_zBP3jyEwTf7E6QeyD5aOW52TrpQwfhpBT-UJgZd3f5DhQJRUSsnv29DxSNtudUMMiHABADHu5W3N_2WeaGa4OIpG_mDysO_QKDcshJtmSSNQz2-2plPA0x2QzpOIhZlsv_TrNJjdlvtSXxvpc1VbspB-aA_oURxGIIbHj1OS8oS1j",
    )

    def image_for(index: int) -> str:
        return image_pool[index % len(image_pool)]

    base_data = (
        (1, "Agri-Bot X4", "Spray", 25.615, 85.130, "Available", 12500.0, 9500.0, 40.0, 1),
        (2, "FieldMapper Pro", "Survey", 25.625, 85.145, "Available", 10000.0, 7000.0, 20.0, 2),
        (3, "SeedStorm X1", "Spray", 25.640, 85.150, "Booked", 15000.0, 12000.0, 50.0, 3),
        (4, "AgriMax Pro", "Spray", 25.600, 85.110, "Available", 8500.0, 9000.0, 35.0, 4),
        (5, "SoilSense Z1", "Mapping", 25.605, 85.135, "Available", 9600.0, 7200.0, 18.0, 5),
        (6, "CropView R9", "Survey", 25.610, 85.120, "Available", 10800.0, 7800.0, 22.0, 6),
        (7, "AgroFlyer S3", "Spray", 25.620, 85.140, "Booked", 11200.0, 8200.0, 26.0, 7),
        (8, "FarmBot T5", "Spray", 25.630, 85.160, "Available", 11800.0, 8800.0, 30.0, 8),
        (9, "SkyMap Q8", "Survey", 25.640, 85.135, "Available", 9900.0, 7600.0, 16.0, 9),
        (10, "DronePro X1", "Surveillance", 25.650, 85.145, "Available", 13400.0, 10200.0, 32.0, 10),
        (11, "AgriBot A9", "Spray", 25.655, 85.165, "Available", 8900.0, 9300.0, 28.0, 11),
        (12, "CropWatcher Z3", "Survey", 25.660, 85.155, "Available", 9800.0, 7800.0, 24.0, 12),
        (13, "FieldEye M2", "Mapping", 25.670, 85.160, "Booked", 12200.0, 10800.0, 38.0, 13),
        (14, "SkyFarm 7X", "Spray", 25.675, 85.175, "Available", 9300.0, 8400.0, 20.0, 14),
        (15, "DroneScan V1", "Survey", 25.680, 85.185, "Available", 9700.0, 7600.0, 18.0, 15),
        (16, "AgriSurv B5", "Spray", 25.685, 85.190, "Available", 9100.0, 8200.0, 24.0, 16),
        (17, "CropLink G4", "Mapping", 25.690, 85.195, "Available", 10400.0, 8600.0, 26.0, 17),
        (18, "TerraDrone X9", "Survey", 25.695, 85.200, "Booked", 13900.0, 11000.0, 36.0, 18),
        (19, "AgroVision C3", "Spray", 25.700, 85.205, "Available", 9400.0, 7800.0, 22.0, 19),
        (20, "FarmDrone L2", "Survey", 25.705, 85.210, "Available", 10100.0, 8000.0, 24.0, 20),
    )

    return tuple(
        (
            row[0],
            row[1],
            row[2],
            row[3],
            row[4],
            row[5],
            row[6],
            image_for(idx),
            row[7],
            row[8],
            row[9],
        )
        for idx, row in enumerate(base_data)
    )


def _demo_bookings() -> Sequence[tuple[int, int, str, str | None, str, int, str]]:
    raw = [
        (1, 3, "Ramesh Patel", "7100000000", "2025-10-20T09:30:00Z", 2, "Accepted"),
        (2, 1, "Sunita Devi", "7100000001", "2025-10-21T10:00:00Z", 3, "Pending"),
        (3, 2, "Ajay Singh", "7100000002", "2025-10-22T11:00:00Z", 1, "Rejected"),
        (4, 4, "Meena Kumari", "7100000003", "2025-10-22T15:00:00Z", 2, "Pending"),
        (5, 5, "Anil Kumar", "7100000004", "2025-10-23T09:45:00Z", 3, "Accepted"),
        (6, 6, "Rekha Sinha", "7100000005", "2025-10-23T13:30:00Z", 2, "Pending"),
        (7, 7, "Mohammad Irfan", "7100000006", "2025-10-24T08:15:00Z", 4, "Accepted"),
        (8, 8, "Sita Ram", "7100000007", "2025-10-24T11:30:00Z", 1, "Rejected"),
        (9, 9, "Vivek Singh", "7100000008", "2025-10-24T14:00:00Z", 3, "Pending"),
        (10, 10, "Asha Devi", "7100000009", "2025-10-25T09:00:00Z", 2, "Accepted"),
        (11, 11, "Hari Prasad", "7100000010", "2025-10-25T13:00:00Z", 2, "Rejected"),
        (12, 12, "Maya Devi", "7100000011", "2025-10-26T10:30:00Z", 3, "Pending"),
        (13, 13, "Santosh Rai", "7100000012", "2025-10-26T12:45:00Z", 1, "Accepted"),
        (14, 14, "Pawan Gupta", "7100000013", "2025-10-27T09:15:00Z", 2, "Pending"),
        (15, 15, "Manju Sharma", "7100000014", "2025-10-27T11:30:00Z", 2, "Accepted"),
        (16, 16, "Kishor Singh", "7100000015", "2025-10-28T10:00:00Z", 3, "Rejected"),
        (17, 17, "Reena Das", "7100000016", "2025-10-28T13:15:00Z", 1, "Pending"),
        (18, 18, "Suresh Kumar", "7100000017", "2025-10-28T15:00:00Z", 2, "Accepted"),
        (19, 19, "Anita Singh", "7100000018", "2025-10-29T09:30:00Z", 2, "Pending"),
        (20, 20, "Vikram Yadav", "7100000019", "2025-10-29T12:00:00Z", 4, "Accepted"),
    ]

    return tuple(
        (
            booking_id,
            drone_id,
            farmer_name,
            farmer_mobile,
            datetime.fromisoformat(timestamp.replace("Z", "+00:00")).isoformat().replace("+00:00", "Z"),
            duration,
            status,
        )
        for booking_id, drone_id, farmer_name, farmer_mobile, timestamp, duration, status in raw
    )
