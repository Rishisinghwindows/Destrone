from __future__ import annotations

import logging

from fastapi import APIRouter, HTTPException, status

from ..config import get_settings
from ..db import db_connect
from ..models import OTPRequest, OTPRequestResponse, OTPVerify, TokenResponse, UserRole
from ..security import generate_token


router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/request_otp", response_model=OTPRequestResponse)
def request_otp(payload: OTPRequest) -> OTPRequestResponse:
    settings = get_settings()
    logger.info("OTP requested for mobile %s", payload.mobile)
    return OTPRequestResponse(mobile=payload.mobile, demo_otp=settings.otp_code)


@router.post("/verify_otp", response_model=TokenResponse)
def verify_otp(payload: OTPVerify) -> TokenResponse:
    settings = get_settings()
    if payload.otp != settings.otp_code:
        logger.warning("OTP verification failed for %s: invalid OTP", payload.mobile)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid OTP")

    logger.info("OTP verification attempt for mobile %s as %s", payload.mobile, payload.role.value)

    profile_name: str | None = None
    con = db_connect()
    try:
        owner_row = con.execute("SELECT id,name FROM owners WHERE mobile=?", (payload.mobile,)).fetchone()
        farmer_row = con.execute("SELECT id,name FROM farmers WHERE mobile=?", (payload.mobile,)).fetchone()

        target_table = "owners" if payload.role is UserRole.owner else "farmers"
        target_row = owner_row if payload.role is UserRole.owner else farmer_row

        if not target_row:
            if not payload.name:
                logger.warning(
                    "OTP verification failed for %s: name required for role %s",
                    payload.mobile,
                    payload.role.value,
                )
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Name required")
            con.execute(
                f"INSERT INTO {target_table}(name,mobile,lat,lon) VALUES(?,?,?,?)",
                (payload.name, payload.mobile, payload.lat, payload.lon),
            )
            con.commit()
            logger.info("Provisioned new %s profile for %s", payload.role.value, payload.mobile)
            target_row = con.execute(
                f"SELECT id,name FROM {target_table} WHERE mobile=?",
                (payload.mobile,),
            ).fetchone()
        elif payload.lat is not None and payload.lon is not None:
            con.execute(
                f"UPDATE {target_table} SET lat=?, lon=? WHERE mobile=?",
                (payload.lat, payload.lon, payload.mobile),
            )
            con.commit()
            logger.info("Updated %s profile location for %s", payload.role.value, payload.mobile)
            target_row = con.execute(
                f"SELECT id,name FROM {target_table} WHERE mobile=?",
                (payload.mobile,),
            ).fetchone()

        if target_row:
            profile_name = target_row["name"]

        owner_row = owner_row or con.execute("SELECT id FROM owners WHERE mobile=?", (payload.mobile,)).fetchone()
        farmer_row = farmer_row or con.execute("SELECT id FROM farmers WHERE mobile=?", (payload.mobile,)).fetchone()

        roles: list[UserRole] = []
        if owner_row:
            roles.append(UserRole.owner)
        if farmer_row:
            roles.append(UserRole.farmer)
    finally:
        con.close()

    token = generate_token(payload.mobile, payload.role.value)
    logger.info(
        "OTP verification succeeded for %s; requested=%s, roles=%s",
        payload.mobile,
        payload.role.value,
        ",".join(role.value for role in roles),
    )
    return TokenResponse(access_token=token, role=payload.role, roles=roles, profile_name=profile_name)
