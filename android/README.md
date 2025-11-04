# EDrone Android Client

This module delivers a Kotlin + Jetpack Compose companion to the existing SwiftUI app. It targets the same FastAPI backend under `api/` and reuses the OTP-first authentication flow, drone catalog, and booking lifecycle.

## Project Layout

- `app/` – Android application module with Compose UI, Retrofit networking, and shared state.
  - `data/` – Retrofit interface, repository, and token storage.
  - `model/` – Kotlinx-serializable DTOs mirroring the FastAPI schemas.
  - `ui/` – Compose screens for onboarding, authentication, farmer/owner dashboards, and shared components.
  - `ui/theme/` – Material 3 theme definitions aligned with the iOS palette.
- `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties` – Kotlin DSL Gradle configuration using Compose, Retrofit, and Coil.

## Feature Parity

- **OTP Auth:** Request and verify OTP codes, auto-provisioning profiles if a name is supplied for new accounts.
- **Role Switching:** Persisted Farmer/Owner roles with quick chips to flip between dashboards at runtime.
- **Drone Catalog:** Price-sorted browser for farmers plus owner inventory sourced from `/owners/me/drones`.
- **Bookings:** Farmers create bookings from drone cards; owners review and update booking status.
- **Local Persistence:** Tokens, selected role, and onboarding flag stored via `SharedPreferences`, mirroring the Swift `TokenManager` behavior.

## Getting Started

1. Ensure the FastAPI service is running (e.g., `python api/main.py --selftest` followed by `python api/main.py`).
2. Open the `android/` directory in Android Studio (Giraffe/Koala or newer).
3. Let Studio generate the Gradle wrapper if prompted, then sync the project.
4. Choose an emulator or device running Android 7.0 (API 24) or later and press **Run**.

### Environment Tweaks

- Override the backend base URL by editing `build.gradle.kts` (`BuildConfig.BASE_URL`) or by adding a product flavor if you need multiple endpoints.
- Demo OTP (`1357`) is compiled into `BuildConfig.DEMO_OTP` for quick testing; replace or externalize it before production.

## Testing Notes

- The module currently relies on manual QA (request OTP, sign in, exercise drone/booking flows). Consider adding instrumented tests around repository calls with MockWebServer for deeper coverage.
- Run `scripts/run_checks.sh` to validate backend smoke tests before exercising the Android client.

## Next Steps

- Add Hilt/Room if you need offline caching or a more structured DI layer.
- Expand compose previews and UI tests for the booking and drone cards.
- Wire push notifications or background refresh if owners require live booking updates.
