from datetime import date, datetime, timezone
from decimal import Decimal
import json

from fastapi import Depends, FastAPI, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
import mysql.connector
from pydantic import BaseModel, Field, field_validator

from auth import Role, get_current_user, require_roles, write_audit_log
from database import get_db_connection
from security import create_access_token, decode_access_token, hash_password, verify_password

app = FastAPI(title="Tech-E20 API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT"],
    allow_headers=["Authorization", "Content-Type"],
)


class FuelInput(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    price: Decimal = Field(gt=0, max_digits=10, decimal_places=2)
    stock_litres: Decimal = Field(ge=0, max_digits=10, decimal_places=2)

    @field_validator("name")
    @classmethod
    def clean_name(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Fuel name cannot be blank.")
        return value


class LoginInput(BaseModel):
    username_or_email: str = Field(min_length=3, max_length=100)
    password: str = Field(min_length=3, max_length=128)


class UserResponse(BaseModel):
    id: int
    username: str
    email: str | None
    full_name: str
    role: Role
    is_active: bool = True
    default_shift: str | None = None


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class ManagedUserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=50)
    full_name: str = Field(min_length=1, max_length=100)
    email: str | None = Field(default=None, max_length=100)
    password: str = Field(min_length=3, max_length=128)
    role: Role
    default_shift: str | None = Field(default=None, max_length=30)

    @field_validator("username", "full_name")
    @classmethod
    def clean_required_text(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("This field cannot be blank.")
        return value

    @field_validator("email")
    @classmethod
    def clean_email(cls, value: str | None) -> str | None:
        if value is None or not value.strip():
            return None
        value = value.strip()
        if "@" not in value:
            raise ValueError("Enter a valid email address.")
        return value

    @field_validator("default_shift")
    @classmethod
    def clean_default_shift(cls, value: str | None) -> str | None:
        if value is None or not value.strip():
            return None
        value = value.strip().title()
        if value not in {"Morning", "Evening"}:
            raise ValueError("Shift must be Morning or Evening.")
        return value


class ManagedUserUpdate(BaseModel):
    username: str | None = Field(default=None, min_length=3, max_length=50)
    full_name: str | None = Field(default=None, min_length=1, max_length=100)
    email: str | None = Field(default=None, max_length=100)
    password: str | None = Field(default=None, min_length=3, max_length=128)
    role: Role | None = None
    is_active: bool | None = None
    default_shift: str | None = Field(default=None, max_length=30)

    @field_validator("full_name")
    @classmethod
    def clean_optional_name(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        if not value:
            raise ValueError("Full name cannot be blank.")
        return value

    @field_validator("username")
    @classmethod
    def clean_optional_username(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        if len(value) < 3:
            raise ValueError("Username must have at least 3 characters.")
        return value

    @field_validator("email")
    @classmethod
    def clean_optional_email(cls, value: str | None) -> str | None:
        return ManagedUserCreate.clean_email(value)

    @field_validator("default_shift")
    @classmethod
    def clean_optional_default_shift(cls, value: str | None) -> str | None:
        return ManagedUserCreate.clean_default_shift(value)


class StationSettingsInput(BaseModel):
    station_name: str = Field(min_length=2, max_length=120)

    @field_validator("station_name")
    @classmethod
    def clean_station_name(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Petrol pump name cannot be blank.")
        return value


class TankerDeliveryInput(BaseModel):
    fuel_id: int = Field(gt=0)
    tank_id: int | None = Field(default=None, gt=0)
    quantity_litres: Decimal = Field(gt=0, max_digits=12, decimal_places=2)
    received_at: datetime
    supplier_name: str | None = Field(default=None, max_length=120)
    challan_number: str | None = Field(default=None, max_length=80)
    notes: str | None = Field(default=None, max_length=500)

    @field_validator("supplier_name", "challan_number", "notes")
    @classmethod
    def clean_optional_text(cls, value: str | None) -> str | None:
        return value.strip() if value and value.strip() else None


class AttendanceInput(BaseModel):
    user_id: int = Field(gt=0)
    attendance_date: date
    template_id: int = Field(gt=0)
    status: str = Field(pattern="^(PRESENT|ABSENT|LEAVE)$")
    correction_reason: str | None = Field(default=None, max_length=500)

    @field_validator("correction_reason")
    @classmethod
    def clean_reason(cls, value: str | None) -> str | None:
        return value.strip() if value and value.strip() else None


def public_user(user: dict) -> dict:
    return {
        "id": user["id"],
        "username": user["username"],
        "email": user["email"],
        "full_name": user["full_name"],
        "role": user["role"],
        "is_active": user.get("is_active", True),
        "default_shift": user.get("default_shift"),
    }


@app.get("/")
def home():
    return {"message": "Tech-E20 API"}


@app.get("/api/test-db")
def test_database(current_user: dict = Depends(require_roles(Role.OWNER))):
    connection = get_db_connection()
    try:
        return {"message": "MySQL connection successful"}
    finally:
        connection.close()


@app.post("/api/auth/login", response_model=LoginResponse)
def login(credentials: LoginInput):
    identifier = credentials.username_or_email.strip()
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT id, username, email, full_name, role, password_hash, is_active
            FROM users WHERE username = %s OR email = %s
            """,
            (identifier, identifier),
        )
        user = cursor.fetchone()
        if not user or not user["is_active"] or not verify_password(credentials.password, user["password_hash"]):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid username/email or password.")

        token, _, _ = create_access_token(user["id"], user["role"])
        write_audit_log(cursor, user["id"], "AUTH_LOGIN", "user", user["id"])
        connection.commit()
        return {"access_token": token, "user": public_user(user)}
    finally:
        cursor.close()
        connection.close()


@app.post("/api/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(
    current_user: dict = Depends(get_current_user),
    authorization: str | None = Header(default=None),
):
    """Revoke the current JWT so it cannot be reused after sign-out."""
    token = authorization.removeprefix("Bearer ").strip() if authorization else ""
    try:
        payload = decode_access_token(token)
        expires_at = datetime.fromtimestamp(payload["exp"], tz=timezone.utc).replace(tzinfo=None)
        token_id = payload["jti"]
    except (KeyError, TypeError, ValueError):
        raise HTTPException(status_code=401, detail="Your session is invalid or has expired.")

    connection = get_db_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            "INSERT IGNORE INTO revoked_tokens (token_id, expires_at) VALUES (%s, %s)",
            (token_id, expires_at),
        )
        write_audit_log(cursor, current_user["id"], "AUTH_LOGOUT", "user", current_user["id"])
        connection.commit()
    finally:
        cursor.close()
        connection.close()


@app.get("/api/auth/me", response_model=UserResponse)
def current_profile(current_user: dict = Depends(get_current_user)):
    return public_user(current_user)


@app.get("/api/users", response_model=list[UserResponse])
def get_users(current_user: dict = Depends(require_roles(Role.OWNER))):
    """List staff accounts without exposing password hashes."""
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT u.id, u.username, u.email, u.full_name, u.role, u.is_active, p.default_shift
            FROM users u LEFT JOIN employee_profiles p ON p.user_id = u.id ORDER BY u.role, u.full_name
            """
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        connection.close()


@app.post("/api/users", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_managed_user(user: ManagedUserCreate, current_user: dict = Depends(require_roles(Role.OWNER))):
    """Owners may create manager and employee accounts, never another owner."""
    if user.role == Role.OWNER:
        raise HTTPException(status_code=403, detail="Owner accounts can only be created through the initial owner setup process.")
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            INSERT INTO users (username, email, full_name, password_hash, role)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (user.username, user.email, user.full_name, hash_password(user.password), user.role),
        )
        new_id = cursor.lastrowid
        cursor.execute("INSERT INTO employee_profiles (user_id, default_shift) VALUES (%s, %s)", (new_id, user.default_shift))
        write_audit_log(cursor, current_user["id"], "USER_CREATED", "user", new_id, f"Created {user.role.lower()} account")
        connection.commit()
        return {"id": new_id, "username": user.username, "email": user.email, "full_name": user.full_name, "role": user.role, "is_active": True, "default_shift": user.default_shift}
    except mysql.connector.IntegrityError as error:
        connection.rollback()
        raise HTTPException(status_code=409, detail="That username or email is already in use.") from error
    finally:
        cursor.close()
        connection.close()


@app.put("/api/users/{user_id}", response_model=UserResponse)
def update_managed_user(user_id: int, changes: ManagedUserUpdate, current_user: dict = Depends(require_roles(Role.OWNER))):
    """Owner-managed profile updates, with owner role and active state protected."""
    if not changes.model_fields_set:
        raise HTTPException(status_code=422, detail="Provide at least one account change.")
    if changes.role == Role.OWNER:
        raise HTTPException(status_code=403, detail="Users cannot be promoted to owner through this endpoint.")

    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT u.id, u.username, u.email, u.full_name, u.role, u.is_active, p.default_shift FROM users u LEFT JOIN employee_profiles p ON p.user_id = u.id WHERE u.id = %s", (user_id,))
        existing_user = cursor.fetchone()
        if not existing_user:
            raise HTTPException(status_code=404, detail="User account not found.")
        if existing_user["role"] == Role.OWNER and user_id != current_user["id"]:
            raise HTTPException(status_code=403, detail="An owner may edit only their own owner account.")
        if existing_user["role"] == Role.OWNER and (changes.role is not None or changes.is_active is not None):
            raise HTTPException(status_code=403, detail="The active owner role cannot be changed or disabled.")

        columns, values, audit_changes = [], [], []
        before_values, after_values = {}, {}
        for field_name in ("username", "full_name", "email", "role", "is_active"):
            if field_name in changes.model_fields_set:
                columns.append(f"{field_name} = %s")
                values.append(getattr(changes, field_name))
                audit_changes.append(field_name)
                before_values[field_name] = existing_user[field_name]
                after_values[field_name] = getattr(changes, field_name)
        if "password" in changes.model_fields_set:
            columns.append("password_hash = %s")
            values.append(hash_password(changes.password))
            audit_changes.append("password")
        if "default_shift" in changes.model_fields_set:
            before_values["default_shift"] = existing_user.get("default_shift")
            after_values["default_shift"] = changes.default_shift
            audit_changes.append("default_shift")
            cursor.execute("INSERT INTO employee_profiles (user_id, default_shift) VALUES (%s, %s) ON DUPLICATE KEY UPDATE default_shift = VALUES(default_shift)", (user_id, changes.default_shift))
        if columns:
            values.append(user_id)
            cursor.execute(f"UPDATE users SET {', '.join(columns)} WHERE id = %s", tuple(values))
        cursor.execute("SELECT u.id, u.username, u.email, u.full_name, u.role, u.is_active, p.default_shift FROM users u LEFT JOIN employee_profiles p ON p.user_id = u.id WHERE u.id = %s", (user_id,))
        updated_user = cursor.fetchone()
        write_audit_log(cursor, current_user["id"], "USER_UPDATED", "user", user_id, json.dumps({"changed": audit_changes, "before": before_values, "after": after_values}))
        connection.commit()
        return updated_user
    except mysql.connector.IntegrityError as error:
        connection.rollback()
        raise HTTPException(status_code=409, detail="That email is already in use.") from error
    finally:
        cursor.close()
        connection.close()


@app.get("/api/settings/station")
def get_station_settings(current_user: dict = Depends(get_current_user)):
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT station_name, updated_at FROM station_settings WHERE id = 1")
        settings = cursor.fetchone()
        return settings or {"station_name": "My Petrol Pump", "updated_at": None}
    finally:
        cursor.close()
        connection.close()


@app.put("/api/settings/station")
def update_station_settings(settings: StationSettingsInput, current_user: dict = Depends(require_roles(Role.OWNER))):
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT station_name FROM station_settings WHERE id = 1 FOR UPDATE")
        existing = cursor.fetchone() or {"station_name": "My Petrol Pump"}
        cursor.execute("INSERT INTO station_settings (id, station_name, updated_by) VALUES (1, %s, %s) ON DUPLICATE KEY UPDATE station_name = VALUES(station_name), updated_by = VALUES(updated_by)", (settings.station_name, current_user["id"]))
        write_audit_log(cursor, current_user["id"], "STATION_NAME_UPDATED", "station_settings", 1, json.dumps({"before": existing["station_name"], "after": settings.station_name}))
        connection.commit()
        return {"station_name": settings.station_name}
    except Exception:
        connection.rollback()
        raise
    finally:
        cursor.close()
        connection.close()


@app.get("/api/attendance")
def get_attendance(attendance_date: date, current_user: dict = Depends(require_roles(Role.OWNER, Role.MANAGER))):
    """Return active pump staff and their recorded status for one selected date."""
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT u.id AS user_id, u.full_name, u.username, u.role, p.default_shift,
                   t.id AS template_id, t.name AS shift_name, t.starts_at, t.ends_at,
                   a.id AS attendance_id, COALESCE(a.status, 'NOT_MARKED') AS attendance_status,
                   a.updated_at, a.correction_reason, recorder.full_name AS recorded_by_name
            FROM users u
            LEFT JOIN employee_profiles p ON p.user_id = u.id
            LEFT JOIN shift_templates t ON t.name = p.default_shift AND t.is_active = TRUE
            LEFT JOIN attendance a ON a.user_id = u.id AND a.attendance_date = %s AND a.template_id = t.id
            LEFT JOIN users recorder ON recorder.id = a.recorded_by
            WHERE u.is_active = TRUE AND u.role IN ('MANAGER', 'EMPLOYEE')
            ORDER BY FIELD(p.default_shift, 'Morning', 'Evening'), u.full_name
            """,
            (attendance_date,),
        )
        rows = cursor.fetchall()
        return {"attendance_date": attendance_date, "records": rows, "has_recorded_attendance": any(row["attendance_id"] for row in rows)}
    finally:
        cursor.close()
        connection.close()


@app.put("/api/attendance")
def save_attendance(attendance: AttendanceInput, current_user: dict = Depends(require_roles(Role.OWNER, Role.MANAGER))):
    """Create or correct attendance; the unique key prevents duplicates per person and shift."""
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT id, full_name, is_active FROM users WHERE id = %s AND role IN ('MANAGER', 'EMPLOYEE') FOR UPDATE", (attendance.user_id,))
        staff = cursor.fetchone()
        if not staff or not staff["is_active"]:
            raise HTTPException(status_code=404, detail="Active staff account not found.")
        cursor.execute("SELECT id, name FROM shift_templates WHERE id = %s AND is_active = TRUE", (attendance.template_id,))
        shift_template = cursor.fetchone()
        if not shift_template:
            raise HTTPException(status_code=404, detail="Active shift template not found.")
        cursor.execute("SELECT id, status, correction_reason FROM attendance WHERE user_id = %s AND attendance_date = %s AND template_id = %s FOR UPDATE", (attendance.user_id, attendance.attendance_date, attendance.template_id))
        existing = cursor.fetchone()
        if existing:
            cursor.execute("UPDATE attendance SET status = %s, recorded_by = %s, correction_reason = %s WHERE id = %s", (attendance.status, current_user["id"], attendance.correction_reason, existing["id"]))
            action = "ATTENDANCE_CORRECTED"
            details = {"before": {"status": existing["status"], "reason": existing["correction_reason"]}, "after": {"status": attendance.status, "reason": attendance.correction_reason}}
            attendance_id = existing["id"]
        else:
            cursor.execute("INSERT INTO attendance (user_id, attendance_date, template_id, status, recorded_by, correction_reason) VALUES (%s, %s, %s, %s, %s, %s)", (attendance.user_id, attendance.attendance_date, attendance.template_id, attendance.status, current_user["id"], attendance.correction_reason))
            action = "ATTENDANCE_RECORDED"
            details = {"after": {"status": attendance.status, "reason": attendance.correction_reason}}
            attendance_id = cursor.lastrowid
        write_audit_log(cursor, current_user["id"], action, "attendance", attendance_id, json.dumps({"staff": staff["full_name"], "date": attendance.attendance_date.isoformat(), "shift": shift_template["name"], **details}))
        connection.commit()
        return {"id": attendance_id, "message": "Attendance saved successfully."}
    except Exception:
        connection.rollback()
        raise
    finally:
        cursor.close()
        connection.close()


@app.get("/api/fuels")
def get_fuels(current_user: dict = Depends(get_current_user)):
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT id, name, price, stock_litres FROM fuels ORDER BY id DESC")
        return cursor.fetchall()
    finally:
        cursor.close()
        connection.close()


@app.post("/api/fuels", status_code=status.HTTP_201_CREATED)
def add_fuel(fuel: FuelInput, current_user: dict = Depends(require_roles(Role.OWNER))):
    connection = get_db_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            "INSERT INTO fuels (name, price, stock_litres) VALUES (%s, %s, %s)",
            (fuel.name, fuel.price, fuel.stock_litres),
        )
        new_id = cursor.lastrowid
        write_audit_log(cursor, current_user["id"], "FUEL_CREATED", "fuel", new_id, f"Created {fuel.name}")
        connection.commit()
        return {"message": "Fuel added successfully", "id": new_id}
    except Exception as error:
        connection.rollback()
        if isinstance(error, HTTPException):
            raise
        raise HTTPException(status_code=500, detail="Could not save fuel to database") from error
    finally:
        cursor.close()
        connection.close()


@app.put("/api/fuels/{fuel_id}")
def update_fuel(fuel_id: int, fuel: FuelInput, current_user: dict = Depends(require_roles(Role.OWNER))):
    connection = get_db_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(
            "UPDATE fuels SET name = %s, price = %s, stock_litres = %s WHERE id = %s",
            (fuel.name, fuel.price, fuel.stock_litres, fuel_id),
        )
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Fuel record not found")
        write_audit_log(cursor, current_user["id"], "FUEL_UPDATED", "fuel", fuel_id, f"Updated {fuel.name}")
        connection.commit()
        return {"message": "Fuel updated successfully"}
    except Exception as error:
        connection.rollback()
        if isinstance(error, HTTPException):
            raise
        raise HTTPException(status_code=500, detail="Could not update fuel record") from error
    finally:
        cursor.close()
        connection.close()


@app.get("/api/inventory/deliveries")
def get_tanker_deliveries(current_user: dict = Depends(require_roles(Role.OWNER, Role.MANAGER))):
    """List delivery history including the stock before and after each authorised receipt."""
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT d.id, d.fuel_id, f.name AS fuel_name, d.tank_id, d.quantity_litres,
                   d.stock_before_litres, d.stock_after_litres, d.received_at,
                   d.supplier_name, d.challan_number, d.notes, d.created_at,
                   u.full_name AS recorded_by_name
            FROM tanker_deliveries d
            JOIN fuels f ON f.id = d.fuel_id
            JOIN users u ON u.id = d.created_by
            ORDER BY d.received_at DESC, d.id DESC
            """
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        connection.close()


@app.post("/api/inventory/deliveries", status_code=status.HTTP_201_CREATED)
def record_tanker_delivery(delivery: TankerDeliveryInput, current_user: dict = Depends(require_roles(Role.OWNER, Role.MANAGER))):
    """Record an authorised tanker receipt and update recorded stock atomically."""
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT id, name, stock_litres FROM fuels WHERE id = %s FOR UPDATE", (delivery.fuel_id,))
        fuel = cursor.fetchone()
        if not fuel:
            raise HTTPException(status_code=404, detail="Fuel record not found.")
        if delivery.tank_id:
            cursor.execute("SELECT id, fuel_id FROM tanks WHERE id = %s AND is_active = TRUE", (delivery.tank_id,))
            tank = cursor.fetchone()
            if not tank:
                raise HTTPException(status_code=404, detail="Active tank not found.")
            if tank["fuel_id"] != delivery.fuel_id:
                raise HTTPException(status_code=422, detail="The selected tank is configured for another fuel type.")

        before = Decimal(fuel["stock_litres"])
        after = before + delivery.quantity_litres
        cursor.execute("UPDATE fuels SET stock_litres = %s WHERE id = %s", (after, delivery.fuel_id))
        cursor.execute(
            """INSERT INTO tanker_deliveries
            (fuel_id, tank_id, quantity_litres, stock_before_litres, stock_after_litres, received_at, supplier_name, challan_number, notes, created_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
            (delivery.fuel_id, delivery.tank_id, delivery.quantity_litres, before, after, delivery.received_at,
             delivery.supplier_name, delivery.challan_number, delivery.notes, current_user["id"]),
        )
        delivery_id = cursor.lastrowid
        cursor.execute(
            """INSERT INTO inventory_transactions (tank_id, fuel_id, transaction_type, quantity_litres, reference_type, reference_id, reason, created_by)
            VALUES (%s, %s, 'DELIVERY', %s, 'TANKER_DELIVERY', %s, %s, %s)""",
            (delivery.tank_id, delivery.fuel_id, delivery.quantity_litres, delivery_id, delivery.challan_number or delivery.notes, current_user["id"]),
        )
        write_audit_log(cursor, current_user["id"], "TANKER_DELIVERY_RECORDED", "tanker_delivery", delivery_id,
                        f"Fuel {fuel['name']}; stock {before} L -> {after} L; quantity {delivery.quantity_litres} L")
        connection.commit()
        return {"id": delivery_id, "message": "Tanker delivery recorded securely.", "stock_before_litres": before, "stock_after_litres": after}
    except Exception:
        connection.rollback()
        raise
    finally:
        cursor.close()
        connection.close()
