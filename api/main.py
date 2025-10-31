#!/usr/bin/env python3
import argparse
import json
import logging
import os

import uvicorn

from app import app
from app.selftest import run_selftest


def main() -> None:
    logging.basicConfig(
        level=os.environ.get("LOG_LEVEL", "INFO"),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )

    parser = argparse.ArgumentParser(description="Drone-as-a-Service FastAPI server")
    parser.add_argument("--selftest", action="store_true", help="Run internal diagnostics and exit")
    parser.add_argument("--host", default=os.environ.get("HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("PORT", 8080)))
    args = parser.parse_args()

    if args.selftest:
        result = run_selftest()
        print(json.dumps(result))
        return

    uvicorn.run(
        app,
        host=args.host,
        port=args.port,
        reload=False,
        log_level="info",
    )


if __name__ == "__main__":
    main()
