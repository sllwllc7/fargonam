"""Geografik hisob-kitoblar — masofa, narx."""
import math
from decimal import Decimal

# Tarif sozlamalari (so'mda)
BASE_FARE = Decimal("5000")       # Minimal narx (chaqiruv uchun)
PER_KM_RATE = Decimal("3000")     # Har km uchun
MIN_FARE = Decimal("8000")        # Eng past narx


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Ikki nuqta orasidagi masofa (km). Haversine formula."""
    R = 6371.0  # Yer radiusi km da
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(d_lng / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def calculate_fare(
    pickup_lat: float | None,
    pickup_lng: float | None,
    dest_lat: float | None,
    dest_lng: float | None,
) -> Decimal:
    """Sayohat narxini hisoblash. Koordinatalar yo'q bo'lsa bazaviy narx."""
    if pickup_lat is None or dest_lat is None:
        return MIN_FARE

    km = haversine_km(pickup_lat, pickup_lng or 0, dest_lat, dest_lng or 0)
    fare = BASE_FARE + PER_KM_RATE * Decimal(str(round(km, 1)))
    return max(fare, MIN_FARE)
