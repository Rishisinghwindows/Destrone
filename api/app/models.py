from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional, List

from pydantic import BaseModel, Field


class UserRole(str, Enum):
    farmer = "farmer"
    owner = "owner"


class OTPRequest(BaseModel):
    mobile: str


class OTPVerify(BaseModel):
    mobile: str
    otp: str
    role: UserRole = UserRole.owner
    name: Optional[str] = None
    lat: Optional[float] = None
    lon: Optional[float] = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: UserRole
    roles: list[UserRole]
    profile_name: Optional[str] = None


class OTPRequestResponse(BaseModel):
    mobile: str
    otp_sent: bool = True
    demo_otp: Optional[str] = None


class OwnerOut(BaseModel):
    id: int
    name: str
    mobile: str
    lat: Optional[float]
    lon: Optional[float]


class DroneBase(BaseModel):
    name: str
    type: str
    lat: float
    lon: float


class DroneCreate(DroneBase):
    price_per_hr: float = Field(gt=0)
    image_url: Optional[str] = None
    image_urls: Optional[List[str]] = None
    battery_mah: Optional[float] = None
    capacity_liters: Optional[float] = None


class DroneOut(DroneBase):
    id: int
    status: str
    price_per_hr: float
    owner_id: int
    image_url: Optional[str] = None
    image_urls: Optional[List[str]] = None
    battery_mah: Optional[float] = None
    capacity_liters: Optional[float] = None


class BookingCreate(BaseModel):
    drone_id: int
    farmer_name: Optional[str] = None
    duration_hrs: int = Field(gt=0)


class BookingOut(BaseModel):
    id: int
    drone_id: int
    farmer_name: str
    farmer_mobile: Optional[str] = None
    booking_date: datetime
    duration_hrs: int
    status: str


class AvailabilityUpdate(BaseModel):
    status: str


class BookingStatusUpdate(BaseModel):
    status: str


class AssetUploadRequest(BaseModel):
    data: str
    filename: Optional[str] = None
    extension: Optional[str] = None


class AssetUploadResponse(BaseModel):
    url: str
