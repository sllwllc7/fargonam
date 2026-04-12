"""Taksi uchun Pydantic sxemalari."""
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.models.ride import RideStatus


class RideRequest(BaseModel):
    pickup_address: str = Field(min_length=3, max_length=300)
    destination_address: str = Field(min_length=3, max_length=300)
    pickup_lat: float | None = None
    pickup_lng: float | None = None
    dest_lat: float | None = None
    dest_lng: float | None = None


class RideOut(BaseModel):
    id: int
    passenger_id: int
    driver_id: int | None
    status: RideStatus
    pickup_address: str
    destination_address: str
    pickup_lat: float | None = None
    pickup_lng: float | None = None
    dest_lat: float | None = None
    dest_lng: float | None = None
    fare: Decimal | None
    created_at: datetime
    accepted_at: datetime | None
    completed_at: datetime | None
    # Haydovchi ma'lumotlari (agar bor bo'lsa)
    driver_name: str | None = None
    driver_phone: str | None = None
    car_model: str | None = None
    car_number: str | None = None
    car_color: str | None = None
    # Haydovchining real-time koordinatalari WebSocket orqali yuboriladi,
    # REST response'da null qoladi. Frontend uni WebSocket listener'dan oladi.
    driver_lat: float | None = None
    driver_lng: float | None = None
    model_config = {"from_attributes": True}


class DriverProfileCreate(BaseModel):
    car_model: str = Field(min_length=2, max_length=100)
    car_number: str = Field(min_length=3, max_length=20)
    car_color: str | None = None


class DriverProfileOut(BaseModel):
    id: int
    user_id: int
    car_model: str
    car_number: str
    car_color: str | None
    is_online: bool
    model_config = {"from_attributes": True}


class RideStatusUpdate(BaseModel):
    status: RideStatus
