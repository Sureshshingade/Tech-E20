import os

# Test-only configuration. Production secrets are never stored in source code.
os.environ.setdefault("DATABASE_USER", "test_user")
os.environ.setdefault("DATABASE_PASSWORD", "test_password")
os.environ.setdefault("JWT_SECRET", "test-secret-that-is-long-enough-for-jwt-validation")
