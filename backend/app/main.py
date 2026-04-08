"""
Fargonam Backend — asosiy kirish nuqtasi.
FastAPI ilovasi shu yerda yaratiladi va barcha route'lar ulanadi.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

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
