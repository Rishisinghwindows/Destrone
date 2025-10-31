from functools import lru_cache
from pathlib import Path
import os

from pydantic import BaseModel


class Settings(BaseModel):
    secret_key: str = os.environ.get("SECRET_KEY", "demo_secret_key")
    token_expire_minutes: int = int(os.environ.get("TOKEN_EXPIRE_MINUTES", 60 * 24))
    otp_code: str = os.environ.get("OTP_CODE", "1357")
    database_path: str = os.environ.get(
        "DB_PATH",
        str((Path(__file__).resolve().parent.parent / ".." / "drones_demo.sqlite").resolve()),
    )


@lru_cache()
def get_settings() -> Settings:
    return Settings()

