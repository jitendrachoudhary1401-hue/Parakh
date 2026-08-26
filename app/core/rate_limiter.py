"""
Project PARAKH — Rate Limiting

Protects sensitive endpoints per §35:
login, upload, analysis, evidence commitment, citizen reports.
"""

from __future__ import annotations

try:
    from slowapi import Limiter
    from slowapi.util import get_remote_address

    def _key_func(request):
        return get_remote_address(request)

    limiter = Limiter(
        key_func=_key_func,
        default_limits=["60/minute"],
        storage_uri=get_settings().redis_url if get_settings().redis_url else "memory://",
    )
except ImportError:
    class DummyLimiter:
        def limit(self, *args, **kwargs):
            def decorator(func):
                return func
            return decorator

    limiter = DummyLimiter()


def get_rate_limit_string(endpoint_type: str) -> str:
    """
    Get the rate limit string for a specific endpoint type.

    Args:
        endpoint_type: One of 'login', 'upload', 'analysis', 'evidence',
                       'citizen_report', 'default'.
    """
    settings = get_settings()
    limits = {
        "login": settings.rate_limit_login,
        "upload": settings.rate_limit_upload,
        "analysis": settings.rate_limit_analysis,
        "evidence": settings.rate_limit_evidence,
        "citizen_report": settings.rate_limit_citizen_report,
        "default": settings.rate_limit_default,
    }
    return limits.get(endpoint_type, settings.rate_limit_default)
