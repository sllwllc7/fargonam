"""
Fargonam Backend — asosiy kirish nuqtasi.
FastAPI ilovasi shu yerda yaratiladi va barcha route'lar ulanadi.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api import addresses as addresses_api
from app.api import admin as admin_api
from app.api import auth as auth_api
from app.api import favorites as favorites_api
from app.api import feed as feed_api
from app.api import news as news_api
from app.api import profile as profile_api
from app.api import reviews as reviews_api
from app.api import ride_ratings as ride_ratings_api
from app.api import rides as rides_api
from app.api import cart as cart_api
from app.api import categories as categories_api
from app.api import products as products_api
from app.api import seller as seller_api
from app.api import shops as shops_api
from app.core.storage import UPLOAD_ROOT, ensure_dirs

# admin_web papkasi (loyiha ildizidan)
from pathlib import Path as _Path
ADMIN_WEB_DIR = _Path(__file__).resolve().parents[2] / "admin_web"

app = FastAPI(
    title="Fargonam API",
    description="Farg'ona vodiysi super-app uchun backend",
    version="0.1.0",
)

# CORS — mobil ilova va admin web'dan so'rov qabul qilish uchun
# MVP davrida hammaga ruxsat, productionda aniq domenlar yoziladi
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


ensure_dirs()
app.mount("/static", StaticFiles(directory=UPLOAD_ROOT), name="static")

app.include_router(auth_api.router)
app.include_router(shops_api.router)
app.include_router(categories_api.router)
app.include_router(products_api.router)
app.include_router(cart_api.router)
app.include_router(addresses_api.router)
app.include_router(favorites_api.router)
app.include_router(feed_api.router)
app.include_router(news_api.router)
app.include_router(profile_api.router)
app.include_router(reviews_api.router)
app.include_router(ride_ratings_api.router)
app.include_router(rides_api.router)
app.include_router(seller_api.router)
app.include_router(admin_api.router)

# Admin web — same-origin xizmat (CORS muammosi yo'q)
if ADMIN_WEB_DIR.exists():
    app.mount("/admin-web", StaticFiles(directory=ADMIN_WEB_DIR, html=True), name="admin_web")


@app.get("/")
async def root():
    """Salomlashish endpointi — server ishlayotganini tekshirish uchun."""
    return {
        "app": "Fargonam",
        "status": "ishlayapti",
        "version": "0.1.0",
    }


@app.get("/health")
async def health_check():
    """Health check — keyinroq DB va Redis ulanishini ham tekshiradi."""
    return {"status": "ok"}
