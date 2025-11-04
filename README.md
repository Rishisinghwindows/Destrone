# Drone-as-a-Service Demo

This repository contains a lightweight Drone-as-a-Service (DaaS) platform consisting of:

- A FastAPI backend (`api/main.py` with the `app/` package) that exposes OTP-based authentication, drone discovery, booking, and owner management APIs on top of SQLite.
- A SwiftUI client (`EDrone` app) that consumes the live API to showcase farmer and owner workflows, including MapKit visualization and booking management.

The project is intentionally dependency-light so it can run on macOS without extra package managers.

## Repository Layout

- `api/` – FastAPI backend (`main.py` entry point plus the `app/` package for config, DB, routers, and self-tests).
- `scripts/` – Helper utilities (`create_venv.sh`, `integration_demo.py`, `run_checks.sh`).
- `EDrone/` – Xcode workspace for the SwiftUI client app (models, networking, and views).
- `android/` – Jetpack Compose Android client mirroring the SwiftUI flows (OTP auth, drones, bookings).
- `drones_demo.sqlite` – Generated SQLite database (safe to delete when reseeding state).

## Backend Setup & Usage

1. Create or update the virtual environment (installs FastAPI + uvicorn from `api/requirements.txt`):
   ```bash
   scripts/create_venv.sh
   source .venv/bin/activate
   ```
2. Run health checks and sample API flows:
   ```bash
   scripts/run_checks.sh
   ```
3. Launch the API server with uvicorn (defaults to `http://127.0.0.1:8080`):
   ```bash
   python api/main.py
   ```

Environment variables:
- `HOST` and `PORT` override the bind address/port.
- `SECRET_KEY` should be replaced before deploying outside development.

Useful endpoints (all JSON): `/auth/request_otp`, `/auth/verify_otp`, `/drones`, `/bookings`, `/owners`, `/drones/{id}/availability`, `/bookings/{id}`.

## SwiftUI Client

1. Open `EDrone/EDrone.xcodeproj` in Xcode 15+.
2. Ensure the backend is running locally (or adjust `Constants.baseURL` for device testing).
3. Build & run the `EDrone` target on an iOS 17+ simulator or device.

Core flows:
- **Sign In** – Request OTP (demo code `1357`), verify, and pick Farmer or Owner role.
- **Farmer Dashboard** – Filter and sort drones, view maps, create bookings, track status.
- **Owner Console** – Register drones, update availability, accept/reject bookings.
- **Profile** – Review account details, trigger data refresh, sign out.

## Automation & Testing

- `python api/main.py --selftest` – Smoke tests (JWT, DB schema, seed data).
- `scripts/integration_demo.py` – End-to-end API exercise from OTP to booking.
- `scripts/run_checks.sh` – Runs self-test + integration flow inside the virtual env.
- Android app uses the same backend fixtures; open `android/` in Android Studio and update `BuildConfig.BASE_URL` if you are not targeting localhost.

For Swift, use Xcode’s build/run and previews. The app relies on the live backend, so keep the Python server running during UI testing.

## Resetting State

Delete `drones_demo.sqlite` to wipe all data, then rerun `python api/main.py --selftest` or `scripts/run_checks.sh` to regenerate fixtures (owner, drone, booking).

## Contributing

Follow the guidelines in `AGENTS.md` for coding style, testing expectations, and security considerations. Submit focused changes backed by self-test results or integration runs.
