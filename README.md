# Tech-E20

Tech-E20 is a role-aware petrol pump management system for a single fuel station. It is a BCA final-year project designed to bring fuel inventory, tanker receipts, staff accounts, shift assignment, and attendance into one web application instead of paper registers and scattered spreadsheets.

The application is under active development. This release documents the functionality that is currently implemented and deliberately identifies the modules that are still planned.

## Currently implemented

- Secure username/email and password login with JWT bearer tokens and logout token revocation.
- Owner, Manager, and Employee roles enforced by the FastAPI backend.
- Owner account management: create, edit, enable/disable, assign roles, change usernames, assign default shifts, and reset passwords for staff.
- Owner self-profile editing, while preventing the active Owner account from being demoted or disabled through the normal UI.
- Station name setting shown below the Tech-E20 product name.
- Authenticated fuel inventory view; only the Owner can create or directly edit fuel records.
- Tanker delivery workflow for Owners and Managers, with stock-before/stock-after values, supplier/challan details, inventory transactions, and audit entries.
- Owner-managed city reference rates for Petrol and Diesel; they support local price display and never change saved station inventory prices.
- Attendance screen for Owners and Managers: select current or earlier dates, assign Present/Absent/Leave, and correct recorded attendance.
- Morning and Afternoon/Evening default pump-shift assignment for Managers and Employees.
- Audit records for key authentication, account, station-name, tanker-delivery, and attendance changes.
- Three client-side themes: Ocean, Midnight, and Ember.
- Clearly labelled demonstration fuel/delivery data created by the local seed script.

## Technology stack

| Area | Technology confirmed in this repository |
| --- | --- |
| Frontend | React 19, Vite 8, JavaScript, CSS |
| Backend | Python, FastAPI, Uvicorn, Pydantic |
| Database | MySQL via `mysql-connector-python` |
| Authentication | Argon2 password hashing (`pwdlib`) and JWT (`PyJWT`) |
| Testing | pytest, FastAPI TestClient |
| Local AI guidance | Ollama (`qwen2.5:3b`) through the FastAPI backend |

## Architecture

```text
React + Vite browser app
        │  Bearer token JSON requests
        ▼
FastAPI API (backend/main.py)
        │  role dependencies + validation + transactions
        ▼
MySQL (fuel_station_db)
```

- The frontend stores the active JWT in browser session storage and sends it in the `Authorization: Bearer <token>` header.
- FastAPI verifies the token, checks whether it was revoked, loads the active user, and applies endpoint-level role checks.
- Passwords are stored as Argon2 hashes. Password hashes and existing passwords are never returned by the API.
- Related writes such as tanker delivery/stock updates and attendance/audit events use database transactions.

## Project structure

```text
fuel-station-system/
├── backend/
│   ├── main.py                    # FastAPI routes and application logic
│   ├── auth.py                    # JWT user and role dependencies
│   ├── security.py                # Password hashing and JWT helpers
│   ├── database.py                # MySQL connection helper
│   ├── create_initial_owner.py    # One-time initial Owner setup
│   ├── seed_demo_data.py          # Idempotent labelled demo data seed
│   ├── migrations/                # Additive MySQL migrations
│   ├── tests/                     # Backend test suite
│   ├── requirements.txt
│   └── .env.example
├── frontend/
│   ├── src/                       # React UI
│   ├── public/                    # Static assets
│   ├── package.json
│   └── vite.config.js
├── backups/                       # Local-only database backups; ignored by Git
├── PROJECT_PLAN.md
├── .gitignore
└── README.md
```

## Prerequisites

For a Windows development setup, install:

- Python 3.12 or another version compatible with the dependencies in `backend/requirements.txt`.
- Node.js and npm compatible with the Vite version in `frontend/package.json`.
- MySQL Server 8+ and, optionally, the `mysql` command-line client.

## Installation and setup (Windows)

Open PowerShell in the project directory:

```powershell
cd C:\Users\sures\Desktop\fuel-station-system
```

### 1. Configure the backend virtual environment

```powershell
cd backend
py -3.12 -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

### 2. Configure environment variables

Create your local environment file from the safe template:

```powershell
Copy-Item .env.example .env
notepad .env
```

Set valid local MySQL credentials and a unique `JWT_SECRET` of at least 32 characters. The `INITIAL_OWNER_*` values are used only when creating the first Owner account.

To enable the AI Assistant, install and start Ollama locally, then download its required model:

```powershell
ollama pull qwen2.5:3b
ollama serve
```

The backend uses `http://localhost:11434` by default. Set `OLLAMA_API_URL` in `backend/.env` only when Ollama is running at another local address.

The Owner can set the station city and manually record local Petrol and Diesel reference rates in Settings. These reference rates are informational only and never overwrite saved inventory prices or historical records.

Never commit `backend/.env`, real credentials, JWT secrets, or initial passwords.

### 3. Database setup and migrations

The app expects a MySQL database named `fuel_station_db` and an existing `fuels` table. The original local backup contains the legacy `fuels` table only and is intentionally ignored by Git.

For an existing station database, back it up first, then apply the migrations in numeric order. They are additive and must not be used to reset a production/development database.

```powershell
Get-Content .\migrations\001_auth_foundation.sql | mysql -u root -p fuel_station_db
Get-Content .\migrations\002_tech_e20_operations.sql | mysql -u root -p fuel_station_db
Get-Content .\migrations\003_tanker_deliveries.sql | mysql -u root -p fuel_station_db
Get-Content .\migrations\004_station_settings.sql | mysql -u root -p fuel_station_db
Get-Content .\migrations\005_station_city.sql | mysql -u root -p fuel_station_db
Get-Content .\migrations\006_manual_city_rates.sql | mysql -u root -p fuel_station_db
```

For a fresh local demonstration database, create the database and the foundational `fuels` table first:

```sql
CREATE DATABASE fuel_station_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fuel_station_db;

CREATE TABLE fuels (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock_litres DECIMAL(12,2) NOT NULL DEFAULT 0
) ENGINE=InnoDB;
```

Then run migrations `001` through `004` in order. Create the initial Owner once:

```powershell
python .\create_initial_owner.py
```

Optional: create the project’s clearly labelled demonstration fuel and tanker delivery records for 13 October 2026:

```powershell
python .\seed_demo_data.py
```

### 4. Start the backend

From `backend/` with the virtual environment activated:

```powershell
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

### 5. Start the frontend

Open a second PowerShell window:

```powershell
cd C:\Users\sures\Desktop\fuel-station-system\frontend
npm ci
npm run dev
```

The frontend defaults to `http://127.0.0.1:8000/api`. To target a different API base URL, create a local `frontend/.env` file containing `VITE_API_URL=<your-api-url>`; do not commit it.

## Vercel services deployment preparation

The repository includes a root `vercel.json` with two public services: the Vite frontend at `/` and the FastAPI backend at `/api/*`. The API rewrite is deliberately listed before the frontend catch-all, so API requests are never handled by the React fallback. No service binding is configured because the browser calls the same-origin public `/api` URL directly.

Do not deploy until the production infrastructure is ready. In Vercel Project Settings, create the following backend environment variables for **Preview** and **Production** as appropriate; do not commit their real values:

```text
TECH_E20_ENV=cloud
DATABASE_HOST=<production MySQL hostname>
DATABASE_PORT=<production MySQL port>
DATABASE_NAME=<production database name>
DATABASE_USER=<production database username>
DATABASE_PASSWORD=<production database password>
JWT_SECRET=<unique production secret, at least 32 characters>
JWT_EXPIRE_MINUTES=480
```

`TECH_E20_ENV=cloud` makes the backend require explicit database host and database name values rather than falling back to local defaults. Leave `OLLAMA_API_URL` unset in cloud environments to disable AI assistance safely. If a secure hosted Ollama-compatible endpoint is later available, configure its URL as `OLLAMA_API_URL` in Vercel instead. Never point it at a personal local Ollama instance.

For a combined local services check after installing the Vercel CLI and linking the project, run:

```powershell
vercel dev
```

The local application can continue using its existing backend and frontend commands; its default API URL remains `http://127.0.0.1:8000/api`.

## Accessing the application

- Application: [http://localhost:5173](http://localhost:5173)
- Interactive API documentation (Swagger UI): [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- OpenAPI schema: [http://127.0.0.1:8000/openapi.json](http://127.0.0.1:8000/openapi.json)

Sign in with the Owner account created by `create_initial_owner.py`, or with an account created by the Owner from Employee Management.

## Implemented permissions

Backend authorization is the source of truth; hiding a UI element is not relied upon for protection.

| Capability | Owner | Manager | Employee |
| --- | :---: | :---: | :---: |
| Sign in and read fuel records | Yes | Yes | Yes |
| Create/edit fuel records directly | Yes | No | No |
| Manage users and station name | Yes | No | No |
| Record/view tanker delivery history | Yes | Yes | No |
| Mark or correct attendance | Yes | Yes | No |
| Access `/api/test-db` | Yes | No | No |

The Owner can edit their own name, username, email, and password. The normal account-management flow protects an Owner role from accidental demotion or deactivation.

## API endpoints currently implemented

- `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/auth/me`
- `GET|POST /api/users`, `PUT /api/users/{user_id}`
- `GET|PUT /api/settings/station`
- `GET|PUT /api/attendance`
- `GET|POST /api/fuels`, `PUT /api/fuels/{fuel_id}`
- `GET|POST /api/inventory/deliveries`
- `POST /api/ai/chat` (authenticated guidance; Owner/Manager attendance lookup is read-only)
- `GET /api/ai/attendance?attendance_date=YYYY-MM-DD` (Owner/Manager-only, parameterized read-only lookup)
- `GET /api/test-db`

## Testing

Run backend tests from `backend/`:

```powershell
.\venv\Scripts\python.exe -m pytest
```

If your Windows temporary directory has permission restrictions, use a writable temporary location and disable pytest’s cache provider:

```powershell
.\venv\Scripts\python.exe -m pytest --basetemp C:\Temp\tech-e20-pytest -p no:cacheprovider
```

Build the frontend production bundle from `frontend/`:

```powershell
npm run build
```

The current automated tests cover authentication/permissions, configuration, initial Owner setup, fuel/user authorization, and AI attendance date/access/counting behaviour. Attendance and tanker delivery workflows should still be exercised manually through the running application.

### AI Assistant test

After signing in, open **AI Assistant** in the sidebar. Any active Owner, Manager, or Employee can ask a general question such as “What should I check before accepting a tanker delivery?” Owners and Managers can additionally ask “Give me the attendance for 13/10/2026” or “How many employees were present yesterday?”

Attendance dates must be `DD/MM/YYYY`, `YYYY-MM-DD`, `today`, or `yesterday`. A date without a year triggers a clarification; Tech-E20 does not guess the year. The attendance lookup uses the existing active Manager/Employee attendance view: an absent `attendance` row is displayed and counted as **Not Marked**, never as Absent. Only the date-specific names, assigned shifts, statuses, and aggregate counts from that authorized lookup are sent to local Ollama for wording. No passwords, JWTs, unrelated records, or database access are provided to the model. Employees receive a backend `403` for attendance lookup requests.

## Security notes

- Keep real values only in local `.env` files; use `.env.example` for placeholders.
- Do not commit database passwords, JWT secrets, initial Owner passwords, token files, private keys, or database exports.
- `backups/` is intentionally ignored because SQL files can contain live operational records.
- Use a strong password and a unique JWT secret outside a classroom demonstration environment. The current UI accepts a minimum three-character password for local demonstration convenience; this is not suitable for a production deployment.
- Use a test database when experimenting with migrations or demo data. Do not reset a live database.

## Current limitations and future improvements

The following items are intentionally incomplete in this release:

- A full monthly/weekly visual calendar and employee self-service attendance view.
- Tank calibration charts, dipstick entry, tank diagrams, and physical-stock variance calculations.
- Pump/dispenser/nozzle creation, opening/closing meter readings, and calculated sales.
- Complete shift-open/close workflow, payment-method allocation, reconciliation, refunds, and discrepancy diary.
- Reports, CSV export, audit-history viewer, and printable operational reports.
- WebAuthn/passkey attendance evaluation and implementation.
- Dedicated automated tests for attendance, tanker delivery, and the remaining operational modules.
- The AI Assistant requires a separately running local Ollama service with `qwen2.5:3b` already pulled. Its only live-data capability is the Owner/Manager-authorized, date-specific attendance lookup; it cannot modify records or access other station data.

## Author

Developed by [Sureshshingade](https://github.com/Sureshshingade) as a Bachelor of Computer Application final-year project and software developer portfolio project.
