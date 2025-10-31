# Repository Guidelines

## Project Structure & Module Organization
- `api/` contains the FastAPI service (`main.py` entrypoint plus the `app/` package for config, DB helpers, routers, and self-tests).
- Group new backend logic within the existing module layout (`config`, `db`, `security`, `routers`, `selftest`) rather than adding ad-hoc scripts.
- Runtime data lives in `drones_demo.sqlite`; delete it when you need a clean slate or reproducible run.

## Build, Test, and Development Commands
- `python3 api/main.py` starts the HTTP server, honoring `HOST` and `PORT` environment variables (default `127.0.0.1:8080`).
- `python3 api/main.py --selftest` bootstraps the database and executes smoke checks without binding a socket.
- `scripts/create_venv.sh` provisions a `.venv` using the system Python and installs project requirements.
- `scripts/run_checks.sh` activates the virtualenv, runs the self-test, and executes the end-to-end integration demo.
- `rm -f drones_demo.sqlite` resets local state; rerun `python3 api/main.py --selftest` afterward to regenerate fixtures.

## Coding Style & Naming Conventions
- Use Python 3.10+ with 4-space indentation and a trailing newline; keep line length under 100 characters.
- Prefer descriptive snake_case names for functions, variables, and SQLite columns; mirror existing naming in SQL schemas.
- Follow FastAPI conventions: pydantic models in `models.py`, route handlers in `routers/`, shared helpers in `dependencies.py` or `utils.py`.

## Testing Guidelines
- Extend the built-in `selftest()` with focused assertions when adding helpers or endpoints.
- Name future test functions `test_<feature>` and place them alongside implementations or in a `tests/` directory if introduced.
- Run `python3 api/main.py --selftest` before every commit; ensure tables are truncated to avoid flaky row counts.

## Commit & Pull Request Guidelines
- Write commit subjects in present tense, capitalize the first word, and keep them ≤72 characters (e.g., `Add OTP validation guard`).
- Add a short body summarizing impacted areas and manual test notes whenever functionality changes.
- Pull requests should reference related issues, summarize API or schema changes, and attach screenshots or curl samples for new endpoints.

## Security & Configuration Tips
- Override `SECRET_KEY` (env var) before deploying; treat the committed value as development-only.
- Store the SQLite database in a secure, writable location and restrict file permissions in shared environments.
- Validate and sanitize incoming payloads via Pydantic models; reuse shared dependencies for auth.
