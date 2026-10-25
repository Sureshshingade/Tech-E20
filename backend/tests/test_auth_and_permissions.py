import asyncio
from unittest.mock import Mock

from fastapi.testclient import TestClient
import httpx

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


def test_unauthenticated_ai_chat_is_rejected():
    response = client_for().post("/api/ai/chat", json={"message": "How should I check a tanker delivery?"})
    assert response.status_code == 401


def test_all_active_roles_can_use_ai_chat(monkeypatch):
    async def fake_chat(chat, attendance_lookup=None):
        assert chat.message == "How should I check a tanker delivery?"
        return "Check the delivery documents and recorded stock."

    monkeypatch.setattr(main, "chat_with_ollama", fake_chat)
    for role in Role:
        response = client_for(role).post("/api/ai/chat", json={"message": "How should I check a tanker delivery?"})
        assert response.status_code == 200
        assert response.json()["message"] == "Check the delivery documents and recorded stock."


def test_ai_chat_rejects_overlong_or_blank_messages():
    response = client_for(Role.EMPLOYEE).post("/api/ai/chat", json={"message": "   "})
    assert response.status_code == 422


def test_cloud_ai_requires_an_explicit_hosted_endpoint(monkeypatch):
    monkeypatch.setenv("TECH_E20_ENV", "cloud")
    monkeypatch.delenv("OLLAMA_API_URL", raising=False)
    monkeypatch.delenv("GROQ_API_KEY", raising=False)

    response = client_for(Role.OWNER).post("/api/ai/chat", json={"message": "How should I check a tanker delivery?"})

    assert response.status_code == 503
    assert "unavailable in this deployment" in response.json()["detail"]


def test_groq_is_preferred_when_its_api_key_is_configured(monkeypatch):
    captured = {}

    async def fake_groq(messages, api_key):
        captured["messages"] = messages
        captured["api_key"] = api_key
        return "Groq guidance"

    monkeypatch.setenv("GROQ_API_KEY", "test-groq-key")
    monkeypatch.setenv("OLLAMA_API_URL", "http://example.test/ollama")
    monkeypatch.setattr(main, "chat_with_groq", fake_groq)

    result = asyncio.run(main.chat_with_ollama(main.AiChatInput(message="How should I check a tanker delivery?")))

    assert result == "Groq guidance"
    assert captured["api_key"] == "test-groq-key"
    assert captured["messages"][-1] == {"role": "user", "content": "How should I check a tanker delivery?"}


def test_groq_success_uses_configured_model_and_openai_compatible_response(monkeypatch):
    calls = []

    class FakeResponse:
        def raise_for_status(self):
            pass

        def json(self):
            return {"choices": [{"message": {"content": "  Check seals before unloading.  "}}]}

    class FakeClient:
        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            pass

        async def post(self, url, headers, json):
            calls.append((url, headers, json))
            return FakeResponse()

    monkeypatch.setenv("GROQ_MODEL", "openai/gpt-oss-20b")
    monkeypatch.setattr(main.httpx, "AsyncClient", lambda **kwargs: FakeClient())

    result = asyncio.run(main.chat_with_groq([{"role": "user", "content": "Help"}], "test-groq-key"))

    assert result == "Check seals before unloading."
    assert calls == [(
        "https://api.groq.com/openai/v1/chat/completions",
        {"Authorization": "Bearer test-groq-key"},
        {"model": "openai/gpt-oss-20b", "messages": [{"role": "user", "content": "Help"}]},
    )]


def test_groq_provider_errors_return_safe_messages(monkeypatch):
    class FakeResponse:
        def raise_for_status(self):
            raise httpx.HTTPStatusError(
                "rate limited by provider", request=httpx.Request("POST", "https://example.test"), response=httpx.Response(429)
            )

    class FakeClient:
        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            pass

        async def post(self, *args, **kwargs):
            return FakeResponse()

    monkeypatch.setattr(main.httpx, "AsyncClient", lambda **kwargs: FakeClient())

    try:
        asyncio.run(main.chat_with_groq([{"role": "user", "content": "Help"}], "test-groq-key"))
        assert False, "Expected a safe HTTPException"
    except main.HTTPException as error:
        assert error.status_code == 503
        assert error.detail == "The AI service is busy. Please try again shortly."
        assert "provider" not in error.detail.lower()


def test_attendance_question_dates_are_unambiguous_and_year_is_required():
    assert main.parse_attendance_question_date("attendance for 13/10/2026") == (__import__("datetime").date(2026, 10, 13), None)
    assert main.parse_attendance_question_date("attendance for 2026-10-13") == (__import__("datetime").date(2026, 10, 13), None)
    assert main.parse_attendance_question_date("attendance for yesterday", __import__("datetime").date(2026, 10, 14)) == (__import__("datetime").date(2026, 10, 13), None)
    parsed_date, error = main.parse_attendance_question_date("attendance for 13/10")
    assert parsed_date is None
    assert "include the year" in error


def test_attendance_lookup_returns_correct_counts_and_uses_bound_date_parameter(monkeypatch):
    rows = [
        {"full_name": "Present Person", "default_shift": "Morning", "attendance_status": "PRESENT"},
        {"full_name": "Absent Person", "default_shift": "Morning", "attendance_status": "ABSENT"},
        {"full_name": "Leave Person", "default_shift": "Evening", "attendance_status": "LEAVE"},
        {"full_name": "Unmarked Person", "default_shift": "Evening", "attendance_status": "NOT_MARKED"},
    ]

    class CapturingCursor(FakeCursor):
        def __init__(self):
            super().__init__(rows=rows)
            self.calls = []

        def execute(self, statement, params=()):
            self.calls.append((statement, params))

    cursor = CapturingCursor()
    monkeypatch.setattr(main, "get_db_connection", lambda: FakeConnection(cursor))
    response = client_for(Role.MANAGER).get("/api/ai/attendance?attendance_date=2026-10-13")

    assert response.status_code == 200
    assert response.json()["counts"] == {"PRESENT": 1, "ABSENT": 1, "LEAVE": 1, "NOT_MARKED": 1}
    assert response.json()["total_active_staff"] == 4
    statement, params = cursor.calls[0]
    assert "a.attendance_date = %s" in statement
    assert params == (__import__("datetime").date(2026, 10, 13),)


def test_attendance_lookup_handles_no_active_staff(monkeypatch):
    monkeypatch.setattr(main, "get_db_connection", lambda: FakeConnection(FakeCursor(rows=[])))
    response = client_for(Role.OWNER).get("/api/ai/attendance?attendance_date=2026-10-13")

    assert response.status_code == 200
    assert response.json()["records"] == []
    assert response.json()["counts"] == {"PRESENT": 0, "ABSENT": 0, "LEAVE": 0, "NOT_MARKED": 0}


def test_employee_cannot_access_attendance_lookup_or_ask_ai_for_attendance():
    response = client_for(Role.EMPLOYEE).get("/api/ai/attendance?attendance_date=2026-10-13")
    assert response.status_code == 403

    response = client_for(Role.EMPLOYEE).post("/api/ai/chat", json={"message": "How many employees were present yesterday?"})
    assert response.status_code == 403


def test_authorised_ai_attendance_question_passes_only_lookup_data_to_formatter(monkeypatch):
    lookup = {"attendance_date": "2026-10-13", "records": [], "counts": {"PRESENT": 0, "ABSENT": 0, "LEAVE": 0, "NOT_MARKED": 0}, "total_active_staff": 0}
    captured = {}

    monkeypatch.setattr(main, "read_attendance_lookup", lambda attendance_date: lookup)

    async def fake_chat(chat, attendance_lookup=None):
        captured["lookup"] = attendance_lookup
        captured["history"] = chat.history
        return "There were no active staff records for 13 October 2026."

    monkeypatch.setattr(main, "chat_with_ollama", fake_chat)
    response = client_for(Role.MANAGER).post("/api/ai/chat", json={"message": "Give me the attendance for 13/10/2026"})

    assert response.status_code == 200
    assert captured["lookup"] == lookup
    assert captured["history"] == []
    assert response.json()["attendance"] == lookup


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
