"""Create the first owner exactly once, using environment variables only."""

import os
import sys

from auth import Role, write_audit_log
from config import required_setting
from database import get_db_connection
from security import hash_password


def required(name: str) -> str:
    try:
        return required_setting(name)
    except RuntimeError as error:
        raise ValueError(str(error)) from error


def create_initial_owner(username: str, password: str, full_name: str, email: str | None) -> bool:
    """Create one owner account, returning False when an owner already exists."""
    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute("SELECT id FROM users WHERE role = %s LIMIT 1", (Role.OWNER,))
            if cursor.fetchone():
                return False
            cursor.execute(
                """
                INSERT INTO users (username, email, full_name, password_hash, role)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (username, email, full_name, hash_password(password), Role.OWNER),
            )
            owner_id = cursor.lastrowid
            write_audit_log(cursor, owner_id, "OWNER_CREATED", "user", owner_id, "Initial owner account created")
            connection.commit()
            return True
        finally:
            cursor.close()
    finally:
        connection.close()


def main():
    username = required("INITIAL_OWNER_USERNAME")
    password = required("INITIAL_OWNER_PASSWORD")
    full_name = required("INITIAL_OWNER_NAME")
    email = os.environ.get("INITIAL_OWNER_EMAIL", "").strip()
    email = None if not email or email.startswith("replace_with_") else email
    if len(password) < 3:
        raise ValueError("INITIAL_OWNER_PASSWORD must be at least 3 characters long.")

    if create_initial_owner(username, password, full_name, email):
        print("Initial owner account created successfully.")
    else:
        print("An owner account already exists; no account was created.")


if __name__ == "__main__":
    try:
        main()
    except ValueError as error:
        print(f"Setup error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
