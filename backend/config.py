"""Local environment configuration for Tech-E20's backend."""

import os
from pathlib import Path

from dotenv import load_dotenv


ENV_FILE = Path(__file__).with_name(".env")


def load_environment(env_file: Path = ENV_FILE) -> bool:
    """Load the local .env file without overriding explicitly set environment values."""
    return load_dotenv(env_file, override=False)


def required_setting(name: str) -> str:
    """Return a configured value or a safe, actionable error message."""
    value = os.environ.get(name, "").strip()
    if not value or value.startswith("replace_with_"):
        raise RuntimeError(f"{name} must be set in backend/.env before starting Tech-E20.")
    return value


load_environment()
