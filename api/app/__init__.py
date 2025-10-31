from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .db import init_db, seed_demo_data
from .routers import auth, drones, bookings, owners


def create_app() -> FastAPI:
    settings = get_settings()
    init_db()
    seed_demo_data()

    app = FastAPI(
        title="Drone-as-a-Service API",
        version="1.0.0",
        summary="OTP-based API for drone discovery and bookings",
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"]
    )

    @app.get("/")
    def root() -> dict[str, object]:
        return {"status": "ok", "otp_demo": settings.otp_code, "jwt": True}

    app.include_router(auth.router, prefix="/auth", tags=["auth"])
    app.include_router(drones.router, prefix="/drones", tags=["drones"])
    app.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
    app.include_router(owners.router, prefix="/owners", tags=["owners"])

    return app


app = create_app()
