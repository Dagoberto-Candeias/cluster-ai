"""
Cache manager for Cluster AI Dashboard API
Provides caching functionality using in-memory cache
"""

import asyncio
import functools
import time
from threading import Lock
from typing import Any, Callable, Optional


class CacheManager:
    """Simple in-memory cache manager"""

    def __init__(self):
        self._cache = {}
        self._locks = {}
        self._default_ttl = 300  # 5 minutes default TTL

    def get(self, key: str, default: Any = None) -> Any:
        """Get item from cache"""
        if key in self._cache:
            item = self._cache[key]
            if time.time() > item["expires"]:
                del self._cache[key]
                return default
            return item["value"]
        return default

    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """Set item in cache"""
        expires = time.time() + (ttl or self._default_ttl)
        self._cache[key] = {"value": value, "expires": expires}

    def delete(self, key: str) -> None:
        """Delete item from cache"""
        self._cache.pop(key, None)

    def clear(self) -> None:
        """Clear all cache"""
        self._cache.clear()

    def has(self, key: str) -> bool:
        """Check if key exists and is not expired"""
        return self.get(key) is not None


# Global cache instance
cache_manager = CacheManager()


def cached(ttl_seconds: int = 300, namespace: str = "default"):
    """Decorator for synchronous functions"""

    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key
            key = (
                f"{namespace}:{func.__name__}:{hash((args, frozenset(kwargs.items())))}"
            )

            # Check cache
            cached_value = cache_manager.get(key)
            if cached_value is not None:
                return cached_value

            # Execute function
            result = func(*args, **kwargs)

            # Cache result
            cache_manager.set(key, result, ttl_seconds)

            return result

        return wrapper

    return decorator


def cached_async(ttl_seconds: int = 300, namespace: str = "default"):
    """Decorator for asynchronous functions"""

    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            # Generate cache key
            key = (
                f"{namespace}:{func.__name__}:{hash((args, frozenset(kwargs.items())))}"
            )

            # Check cache
            cached_value = cache_manager.get(key)
            if cached_value is not None:
                return cached_value

            # Execute function
            result = await func(*args, **kwargs)

            # Cache result
            cache_manager.set(key, result, ttl_seconds)

            return result

        return wrapper

    return decorator


# Cache statistics
def get_cache_stats() -> dict:
    """Get cache statistics"""
    now = time.time()
    active = 0
    expired = 0

    for key, item in list(cache_manager._cache.items()):
        if now > item["expires"]:
            expired += 1
            del cache_manager._cache[key]
        else:
            active += 1

    return {
        "total_entries": len(cache_manager._cache) + expired,
        "active_entries": active,
        "expired_entries": expired,
        "hit_rate": 0.0,  # Would need tracking to calculate real hit rate
        "cache_size_bytes": sum(
            len(str(v["value"])) for v in cache_manager._cache.values()
        ),
    }


# Background cache cleanup task
async def cache_cleanup_task(interval: int = 60):
    """Background task to clean expired cache entries"""
    while True:
        await asyncio.sleep(interval)
        get_cache_stats()  # This triggers cleanup
