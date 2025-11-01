from __future__ import annotations

import base64
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status

from ..config import get_settings
from ..models import AssetUploadRequest, AssetUploadResponse


router = APIRouter()


def _ensure_upload_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


@router.post("/upload", response_model=AssetUploadResponse)
def upload_asset(payload: AssetUploadRequest, settings=Depends(get_settings)) -> AssetUploadResponse:
    upload_root = Path(settings.upload_dir)
    _ensure_upload_dir(upload_root)

    try:
        data = base64.b64decode(payload.data)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid base64 data") from exc

    suffix = (payload.extension or "jpg").lstrip(".")
    filename = payload.filename or f"drone-{uuid4().hex}.{suffix}"
    target = upload_root / filename

    with target.open("wb") as fp:
        fp.write(data)

    relative_url = f"/static/uploads/{filename}"
    return AssetUploadResponse(url=relative_url)
