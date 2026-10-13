from unittest.mock import Mock

import pytest

import config
import create_initial_owner
import database
import security


def test_load_environment_reads_a_supplied_env_file_without_overriding_existing_values(tmp_path, monkeypatch):
    env_file = tmp_path / ".env"
    env_file.write_text("FUELGUARD_TEST_SETTING=loaded-value\n", encoding="utf-8")
    monkeypatch.delenv("FUELGUARD_TEST_SETTING", raising=False)

    assert config.load_environment(env_file) is True
    assert config.os.environ["FUELGUARD_TEST_SETTING"] == "loaded-value"

    monkeypatch.setenv("FUELGUARD_TEST_SETTING", "already-set")
    config.load_environment(env_file)
    assert config.os.environ["FUELGUARD_TEST_SETTING"] == "already-set"


def test_missing_database_setting_has_a_clear_error(monkeypatch):
    monkeypatch.delenv("DATABASE_USER", raising=False)
    monkeypatch.setenv("DATABASE_PASSWORD", "test-password")

    with pytest.raises(RuntimeError, match="DATABASE_USER must be set in backend/.env"):
        database.get_db_connection()


def test_jwt_secret_requires_a_non_placeholder_value_of_at_least_32_characters(monkeypatch):
    monkeypatch.setenv("JWT_SECRET", "replace_with_a_long_random_secret_at_least_32_characters")

    with pytest.raises(RuntimeError, match="JWT_SECRET must be set in backend/.env"):
        security.get_jwt_secret()

    monkeypatch.setenv("JWT_SECRET", "too-short")
    with pytest.raises(RuntimeError, match="JWT_SECRET in backend/.env must be at least 32 characters"):
        security.get_jwt_secret()


class OwnerCursor:
    def __init__(self, existing_owner=False):
        self.existing_owner = existing_owner
        self.calls = []
        self.lastrowid = 7

    def execute(self, statement, params=()):
        self.calls.append((statement, params))

    def fetchone(self):
        return {"id": 1} if self.existing_owner else None

    def close(self):
        pass


class OwnerConnection:
    def __init__(self, cursor):
        self.cursor_value = cursor
        self.committed = False
        self.closed = False

    def cursor(self, **kwargs):
        return self.cursor_value

    def commit(self):
        self.committed = True

    def close(self):
        self.closed = True


def test_initial_owner_setup_does_not_create_a_second_owner(monkeypatch):
    cursor = OwnerCursor(existing_owner=True)
    connection = OwnerConnection(cursor)
    monkeypatch.setattr(create_initial_owner, "get_db_connection", lambda: connection)

    created = create_initial_owner.create_initial_owner("owner", "secret-password", "Station Owner", None)

    assert created is False
    assert len(cursor.calls) == 1
    assert connection.committed is False
    assert connection.closed is True


def test_initial_owner_setup_hashes_password_before_insert(monkeypatch):
    cursor = OwnerCursor(existing_owner=False)
    connection = OwnerConnection(cursor)
    audit_log = Mock()
    monkeypatch.setattr(create_initial_owner, "get_db_connection", lambda: connection)
    monkeypatch.setattr(create_initial_owner, "hash_password", lambda password: "hashed-password")
    monkeypatch.setattr(create_initial_owner, "write_audit_log", audit_log)

    created = create_initial_owner.create_initial_owner("owner", "secret-password", "Station Owner", None)

    insert_params = cursor.calls[1][1]
    assert created is True
    assert "secret-password" not in insert_params
    assert insert_params[3] == "hashed-password"
    assert connection.committed is True
    audit_log.assert_called_once()
