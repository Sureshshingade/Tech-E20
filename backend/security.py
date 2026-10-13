"""Password and JWT helpers used by FastAPI dependencies."""

import os
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import jwt
from jwt.exceptions import InvalidTokenError
from pwdlib import PasswordHash

from config import required_setting

password_hasher = PasswordHash.recommended()
ALGORITHM = "HS256"


def get_jwt_secret() -> str:
    secret = required_setting("JWT_SECRET")
    if len(secret) < 32:
        raise RuntimeError("JWT_SECRET in backend/.env must be at least 32 characters long.")
    return secret


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return password_hasher.verify(password, password_hash)


def create_access_token(user_id: int, role: str) -> tuple[str, str, datetime]:
    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=int(os.environ.get("JWT_EXPIRE_MINUTES", "480"))
    )
    token_id = str(uuid4())
    token = jwt.encode(
        {"sub": str(user_id), "role": role, "jti": token_id, "exp": expires_at},
        get_jwt_secret(),
        algorithm=ALGORITHM,
    )
    return token, token_id, expires_at


def decode_access_token(token: str) -> dict:
    try:
        return jwt.decode(token, get_jwt_secret(), algorithms=[ALGORITHM])
    except (InvalidTokenError, RuntimeError) as error:
        raise ValueError("Invalid or expired session token.") from error
