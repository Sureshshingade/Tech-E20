"""Authentication dependencies and small database helpers."""

from enum import StrEnum
from typing import Callable

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from database import get_db_connection
from security import decode_access_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


class Role(StrEnum):
    OWNER = "OWNER"
    MANAGER = "MANAGER"
    EMPLOYEE = "EMPLOYEE"


def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    """Return an active user for a valid, non-revoked bearer token."""
    try:
        payload = decode_access_token(token)
        user_id = int(payload["sub"])
        token_id = payload["jti"]
    except (KeyError, TypeError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Your session is invalid or has expired. Please sign in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    connection = get_db_connection()
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT 1 FROM revoked_tokens WHERE token_id = %s", (token_id,))
        if cursor.fetchone():
            raise HTTPException(status_code=401, detail="This session has been signed out.")
        cursor.execute(
            """
            SELECT id, username, email, full_name, role, is_active, created_at
            FROM users WHERE id = %s
            """,
            (user_id,),
        )
        user = cursor.fetchone()
        if not user or not user["is_active"]:
            raise HTTPException(status_code=401, detail="This account is not active.")
        return user
    finally:
        cursor.close()
        connection.close()


def require_roles(*allowed_roles: Role) -> Callable:
    """Create a dependency that permits only the supplied roles."""
    def role_guard(current_user: dict = Depends(get_current_user)) -> dict:
        if current_user["role"] not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to perform this action.",
            )
        return current_user

    return role_guard


def write_audit_log(cursor, actor_id: int, action: str, entity_type: str, entity_id: int | None, details: str | None = None):
    cursor.execute(
        """
        INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, details)
        VALUES (%s, %s, %s, %s, %s)
        """,
        (actor_id, action, entity_type, entity_id, details),
    )
