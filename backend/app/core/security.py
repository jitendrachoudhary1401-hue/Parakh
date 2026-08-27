"""
Project PARAKH — Security Utilities

JWT token management, OAuth2 password bearer, and password hashing.
Per §10: OAuth2, JWT, secure password handling, token expiration, refresh.
Never stores plaintext passwords. Never hardcodes JWT secrets.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import APIKeyHeader, OAuth2PasswordBearer

from app.config import get_settings

try:
    from jose import JWTError, jwt
except ImportError:
    import jwt
    class JWTError(Exception):
        pass

import hashlib
import hmac

try:
    from passlib.context import CryptContext
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

    def hash_password(password: str) -> str:
        return pwd_context.hash(password)

    def verify_password(plain_password: str, hashed_password: str) -> bool:
        if hashed_password.startswith("$pbkdf2$") or hashed_password.startswith("$sha256$"):
            # Internal fallback hash
            parts = hashed_password.split("$")
            if len(parts) == 4:
                salt = parts[2]
                computed = hashlib.sha256((salt + plain_password).encode()).hexdigest()
                return hmac.compare_digest(computed, parts[3])
        return pwd_context.verify(plain_password, hashed_password)
except ImportError:
    import secrets

    def hash_password(password: str) -> str:
        salt = secrets.token_hex(16)
        hashed = hashlib.sha256((salt + password).encode()).hexdigest()
        return f"$sha256${salt}${hashed}"

    def verify_password(plain_password: str, hashed_password: str) -> bool:
        parts = hashed_password.split("$")
        if len(parts) == 4 and parts[1] == "sha256":
            salt = parts[2]
            computed = hashlib.sha256((salt + plain_password).encode()).hexdigest()
            return hmac.compare_digest(computed, parts[3])
        return False


# --- Security Schemes ---
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


async def verify_api_key(api_key: Optional[str] = Depends(api_key_header)) -> str:
    """
    FastAPI dependency that validates the X-API-Key header.
    """
    settings = get_settings()
    if not api_key or api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or missing API Key (X-API-Key)",
        )
    return api_key



# --- JWT Token Management ---

def create_access_token(
    data: dict[str, Any],
    expires_delta: Optional[timedelta] = None,
) -> str:
    """
    Create a JWT access token.

    Args:
        data: Claims to encode in the token (must include "sub" for user ID).
        expires_delta: Custom expiration delta. Defaults to settings value.
    """
    settings = get_settings()
    to_encode = data.copy()

    if expires_delta is None:
        expires_delta = timedelta(minutes=settings.jwt_access_token_expire_minutes)

    expire = datetime.now(timezone.utc) + expires_delta
    to_encode.update({
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "access",
    })

    return jwt.encode(
        to_encode,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def create_refresh_token(
    data: dict[str, Any],
    expires_delta: Optional[timedelta] = None,
) -> str:
    """
    Create a JWT refresh token with a longer expiration.

    Args:
        data: Claims to encode (must include "sub" for user ID).
        expires_delta: Custom expiration delta. Defaults to settings value.
    """
    settings = get_settings()
    to_encode = data.copy()

    if expires_delta is None:
        expires_delta = timedelta(days=settings.jwt_refresh_token_expire_days)

    expire = datetime.now(timezone.utc) + expires_delta
    to_encode.update({
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "refresh",
    })

    return jwt.encode(
        to_encode,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def decode_token(token: str) -> dict[str, Any]:
    """
    Decode and validate a JWT token.

    Raises HTTPException 401 if the token is invalid or expired.
    """
    settings = get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
        return payload
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


async def get_current_user_payload(
    token: str = Depends(oauth2_scheme),
) -> dict[str, Any]:
    """
    FastAPI dependency that extracts and validates the JWT payload.

    Returns the decoded token payload containing user claims.
    """
    payload = decode_token(token)

    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject claim",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token_type = payload.get("type", "access")
    if token_type != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type; access token required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return payload
