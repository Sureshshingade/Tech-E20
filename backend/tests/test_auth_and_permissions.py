from unittest.mock import Mock

from fastapi.testclient import TestClient

import main
from auth import Role, get_current_user
from security import hash_password


class FakeCursor:
    def __init__(self, row=None, rows=None):
        self.row = row
        self.rows = rows or []
        self.rowcount = 1
        self.lastrowid = 8

    def execute(self, *args, **kwargs):
        pass

    def fetchone(self):
        return self.row

    def fetchall(self):
        return self.rows

    def close(self):
        pass


class FakeConnection:
    def __init__(self, cursor):
        self.cursor_value = cursor

    def cursor(self, **kwargs):
        return self.cursor_value

    def commit(self):
        pass

    def rollback(self):
        pass

    def close(self):
        pass


def make_user(role: Role):
    return {"id": 1, "username": "testuser", "email": None, "full_name": "Test User", "role": role, "is_active": True}


def client_for(role: Role | None = None):
    main.app.dependency_overrides.clear()
    if role:
        main.app.dependency_overrides[get_current_user] = lambda: make_user(role)
    return TestClient(main.app)


def test_unauthenticated_fuel_request_is_rejected():
    response = client_for().get("/api/fuels")
    assert response.status_code == 401


def test_owner_can_create_fuel_record(monkeypatch):
    cursor = FakeCursor()
    monkeypatch.setattr(main, "get_db_connection", lambda: FakeConnection(cursor))
    response = client_for(Role.OWNER).post("/api/fuels", json={"name": "Petrol", "price": "102.50", "stock_litres": "500.00"})
    assert response.status_code == 201
    assert response.json()["id"] == 8


def test_manager_cannot_change_fuel_prices_or_stock():
    response = client_for(Role.MANAGER).post("/api/fuels", json={"name": "Petrol", "price": "102.50", "stock_litres": "500.00"})
    assert response.status_code == 403


def test_employee_cannot_change_fuel_prices_or_stock():
    response = client_for(Role.EMPLOYEE).post("/api/fuels", json={"name": "Petrol", "price": "102.50", "stock_litres": "500.00"})
    assert response.status_code == 403


def test_all_roles_can_view_permitted_fuel_information(monkeypatch):
    cursor = FakeCursor(rows=[{"id": 1, "name": "Diesel", "price": "90.00", "stock_litres": "100.00"}])
    monkeypatch.setattr(main, "get_db_connection", lambda: FakeConnection(cursor))
    for role in Role:
        response = client_for(role).get("/api/fuels")
        assert response.status_code == 200
        assert response.json()[0]["name"] == "Diesel"


def test_invalid_login_is_rejected(monkeypatch):
    monkeypatch.setattr(main, "get_db_connection", lambda: FakeConnection(FakeCursor(row=None)))
    response = client_for().post("/api/auth/login", json={"username_or_email": "missing", "password": "not-the-right-password"})
    assert response.status_code == 401


def test_valid_login_returns_an_access_token(monkeypatch):
    password = "a-safe-test-password"
    user = {
        "id": 1,
        "username": "testowner",
        "email": "owner@example.test",
        "full_name": "Test Owner",
        "role": Role.OWNER,
        "is_active": True,
        "password_hash": hash_password(password),
    }
    monkeypatch.setattr(main, "get_db_connection", lambda: FakeConnection(FakeCursor(row=user)))

    response = client_for().post("/api/auth/login", json={"username_or_email": "testowner", "password": password})

    assert response.status_code == 200
    assert response.json()["access_token"]
    assert response.json()["user"]["username"] == "testowner"


def test_owner_can_create_an_employee_account(monkeypatch):
    cursor = FakeCursor()
    monkeypatch.setattr(main, "get_db_connection", lambda: FakeConnection(cursor))
    response = client_for(Role.OWNER).post(
        "/api/users",
        json={
            "username": "attendant1",
            "full_name": "Pump Attendant",
            "email": "attendant@example.com",
            "password": "A-safe-test-password",
            "role": "EMPLOYEE",
        },
    )
    assert response.status_code == 201
    assert response.json()["role"] == "EMPLOYEE"
    assert "password" not in response.json()


def test_manager_cannot_manage_user_accounts():
    response = client_for(Role.MANAGER).get("/api/users")
    assert response.status_code == 403


def test_owner_cannot_create_another_owner_account():
    response = client_for(Role.OWNER).post(
        "/api/users",
        json={
            "username": "anotherowner",
            "full_name": "Another Owner",
            "password": "A-safe-test-password",
            "role": "OWNER",
        },
    )
    assert response.status_code == 403
