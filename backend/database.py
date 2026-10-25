"""Small MySQL connection helper. Credentials always come from environment variables."""

import os

import mysql.connector

from config import is_cloud_deployment, required_setting


def get_db_connection():
    """Create a new connection for one request or command."""
    try:
        port = int(os.environ.get("DATABASE_PORT", "3306"))
    except ValueError as error:
        raise RuntimeError("DATABASE_PORT in backend/.env must be a valid number.") from error

    host = required_setting("DATABASE_HOST") if is_cloud_deployment() else os.environ.get("DATABASE_HOST", "127.0.0.1")
    database_name = required_setting("DATABASE_NAME") if is_cloud_deployment() else os.environ.get("DATABASE_NAME", "fuel_station_db")
    return mysql.connector.connect(
        host=host,
        port=port,
        user=required_setting("DATABASE_USER"),
        password=required_setting("DATABASE_PASSWORD"),
        database=database_name,
    )
