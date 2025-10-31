#!/usr/bin/env python3
"""End-to-end check of the drone API using the built-in HTTP server."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Dict, Tuple

HOST = os.environ.get("HOST", "127.0.0.1")
PORT = int(os.environ.get("PORT", 8090))
BASE_URL = f"http://{HOST}:{PORT}"
OWNER_MOBILE = "9800000000"
FARMER_MOBILE = "9900000000"
ROOT_DIR = Path(__file__).resolve().parents[1]
API_ENTRY = ROOT_DIR / "api" / "main.py"


def http_json(
    method: str, path: str, payload: Dict[str, Any] | None = None, token: str | None = None
) -> Tuple[int, Any]:
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = None
    if payload is not None:
        body = json.dumps(payload).encode()
    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            data = response.read().decode()
            return response.getcode(), json.loads(data) if data else None
    except urllib.error.HTTPError as exc:
        message = exc.read().decode()
        detail: Any
        try:
            detail = json.loads(message) if message else None
        except json.JSONDecodeError:
            detail = message
        raise RuntimeError(f"{method} {path} failed: {exc.code} {detail}") from exc


@contextmanager
def run_server(env: Dict[str, str]):
    proc = subprocess.Popen(
        [sys.executable, str(API_ENTRY)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=env,
        cwd=ROOT_DIR,
    )
    try:
        deadline = time.time() + 10
        while time.time() < deadline:
            try:
                code, _ = http_json("GET", "/")
                if code == 200:
                    break
            except Exception:
                time.sleep(0.5)
        else:
            proc.terminate()
            raise RuntimeError("Server did not start within 10 seconds")
        yield proc
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


def main() -> None:
    env = os.environ.copy()
    env.setdefault("TZ", "UTC")
    env.setdefault("HOST", HOST)
    env.setdefault("PORT", str(PORT))

    print("Running built-in selftest ...", flush=True)
    subprocess.run([sys.executable, str(API_ENTRY), "--selftest"], check=True, env=env, cwd=ROOT_DIR)

    results: Dict[str, Any] = {}
    with run_server(env):
        print("Server ready at", BASE_URL, flush=True)

        _, results["root"] = http_json("GET", "/")

        _, owner_otp = http_json(
            "POST", "/auth/request_otp", {"mobile": OWNER_MOBILE}
        )
        results["request_owner_otp"] = owner_otp

        _, owner_verify = http_json(
            "POST",
            "/auth/verify_otp",
            {
                "mobile": OWNER_MOBILE,
                "otp": owner_otp["demo_otp"],
                "role": "owner",
                "name": "Demo Owner",
                "lat": 12.91,
                "lon": 77.58,
            },
        )
        results["verify_owner"] = {
            "token_type": owner_verify["token_type"],
            "role": owner_verify["role"],
        }
        owner_token = owner_verify["access_token"]

        drone_name = f"Field Scout {int(time.time())}"
        _, drone = http_json(
            "POST",
            "/drones/",
            {
                "name": drone_name,
                "type": "Survey",
                "lat": 12.90,
                "lon": 77.60,
                "price_per_hr": 750,
                "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuDw3EbDprqmgL5vEuv4kwV7bhY5RFilj_p4P9AERyMOGxEO9ITL2XwDoRxkOCeZU50jnu7xne0FiHdLTlZIJB2dSTbp5_gBfA9WhmdLVWHyzFhQPe9Jo7PD0vv6-dCgt1g3YnnLe_4opFr9BIXJD-p-r7l65ouwI6eKBN_tab8Q4oytcXmTfJKtZPo96ZyZBBKPv-Yl8VUVDIdXXHOjtU-0zaOCLGIftg3o6XJFk_BsV4qxQ2s1a4dLiDN_VwiqtFc-ZlezlDK97q2r",
                "battery_mah": 9500,
                "capacity_liters": 40,
            },
            token=owner_token,
        )
        results["create_drone"] = drone
        drone_id = drone["id"]

        _, drone_list = http_json("GET", "/drones/?sort_by=price")
        results["list_drones"] = drone_list

        _, farmer_otp = http_json(
            "POST", "/auth/request_otp", {"mobile": FARMER_MOBILE}
        )
        results["request_farmer_otp"] = farmer_otp

        _, farmer_verify = http_json(
            "POST",
            "/auth/verify_otp",
            {
                "mobile": FARMER_MOBILE,
                "otp": farmer_otp["demo_otp"],
                "role": "farmer",
                "name": "Demo Farmer",
                "lat": 12.95,
                "lon": 77.60,
            },
        )
        results["verify_farmer"] = {
            "token_type": farmer_verify["token_type"],
            "role": farmer_verify["role"],
        }
        farmer_token = farmer_verify["access_token"]

        farmer_name = f"Farmer {int(time.time())}"
        _, booking = http_json(
            "POST",
            "/bookings/",
            {
                "drone_id": drone_id,
                "farmer_name": farmer_name,
                "duration_hrs": 3,
            },
            token=farmer_token,
        )
        results["create_booking"] = booking
        booking_id = booking["id"]

        _, booking_update = http_json(
            "PATCH",
            f"/bookings/{booking_id}",
            {"status": "Accepted"},
            token=owner_token,
        )
        results["update_booking"] = booking_update

    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
