"""
Cache Manager for Cluster AI Dashboard
Provides Redis-based caching with fallback to in-memory cache
"""

import redis
import json
import asyncio
import logging
from typing import Any, Optional, Dict, List
from datetime import datetime, timedelta
import hashlib
import pickle
import os

logger = logging.getLogger(__name__)

class CacheManager:
    """Redis-based cache manager with fallback to memory cache"""

    def __init__(self, redis_url: str = os.getenv("REDIS_URL", "redis://redis:6379"), db: int = 0):
        self.redis_url = redis_url
        self.db = db
        self.redis_client = None
        self.memory_cache: Dict[str, Dict] = {}
        self._connect_redis()

    def _connect_redis(self):
        """Connect to Redis with error handling"""
        try:
            self.redis_client = redis.Redis.from_url(
                self.redis_url,
                db=self.db,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
                retry_on_timeout=True
            )
            # Test connection
            self.redis_client.ping()
            logger.info("✅ Redis cache connected successfully")
        except redis.ConnectionError as e:
            logger.warning(f"⚠️ Redis connection failed: {e}. Using memory cache.")
            self.redis_client = None
        except Exception as e:
            logger.error(f"❌ Redis error: {e}. Using memory cache.")
            self.redis_client = None

    def _get_cache_key(self, key: str, namespace: str = "default") -> str:
        """Generate namespaced cache key"""
        return f"cluster_ai:{namespace}:{key}"

    def _serialize_value(self, value: Any) -> str:
        """Serialize value for Redis storage"""
        def convert_pydantic(obj):
            """Recursively convert Pydantic models to dict"""
            if hasattr(obj, 'model_dump'):
                return obj.model_dump()
            elif isinstance(obj, list):
                return [convert_pydantic(item) for item in obj]
            elif isinstance(obj, dict):
                return {k: convert_pydantic(v) for k, v in obj.items()}
            else:
                return obj

        try:
            # Try JSON first with Pydantic conversion
            converted = convert_pydantic(value)
            return json.dumps(converted)
        except (TypeError, ValueError):
            # Fallback to pickle for complex objects
            return pickle.dumps(value).decode('latin1')

    def _deserialize_value(self, value: str, is_pickle: bool = False) -> Any:
        """Deserialize value from Redis storage"""
        if is_pickle:
            return pickle.loads(value.encode('latin1'))
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            # Try pickle for complex objects
            return pickle.loads(value.encode('latin1'))

    def _memory_get(self, key: str) -> Optional[Any]:
        """Get value from memory cache"""
        if key in self.memory_cache:
            entry = self.memory_cache[key]
            if datetime.now() < entry['expires_at']:
                return entry['value']
            else:
                # Expired, remove it
                del self.memory_cache[key]
        return None

    def _memory_set(self, key: str, value: Any, ttl_seconds: int):
        """Set value in memory cache"""
        expires_at = datetime.now() + timedelta(seconds=ttl_seconds)
        self.memory_cache[key] = {
            'value': value,
            'expires_at': expires_at
        }

    def _memory_delete(self, key: str):
        """Delete value from memory cache"""
        if key in self.memory_cache:
            del self.memory_cache[key]

    def get(self, key: str, namespace: str = "default") -> Optional[Any]:
        """Get value from cache"""
        cache_key = self._get_cache_key(key, namespace)

        if self.redis_client:
            try:
                value = self.redis_client.get(cache_key)
                if value is not None:
                    return self._deserialize_value(value)
            except Exception as e:
                logger.error(f"Redis get error: {e}")

        # Fallback to memory cache
        return self._memory_get(cache_key)

    def set(self, key: str, value: Any, ttl_seconds: int = 300, namespace: str = "default"):
        """Set value in cache with TTL"""
        cache_key = self._get_cache_key(key, namespace)
        serialized_value = self._serialize_value(value)

        if self.redis_client:
            try:
                self.redis_client.setex(cache_key, ttl_seconds, serialized_value)
                return True
            except Exception as e:
                logger.error(f"Redis set error: {e}")

        # Fallback to memory cache
        self._memory_set(cache_key, value, ttl_seconds)
        return True

    def delete(self, key: str, namespace: str = "default") -> bool:
        """Delete value from cache"""
        cache_key = self._get_cache_key(key, namespace)

        if self.redis_client:
            try:
                return bool(self.redis_client.delete(cache_key))
            except Exception as e:
                logger.error(f"Redis delete error: {e}")

        # Fallback to memory cache
        self._memory_delete(cache_key)
        return True

    def exists(self, key: str, namespace: str = "default") -> bool:
        """Check if key exists in cache"""
        cache_key = self._get_cache_key(key, namespace)

        if self.redis_client:
            try:
                return bool(self.redis_client.exists(cache_key))
            except Exception as e:
                logger.error(f"Redis exists error: {e}")

        # Fallback to memory cache
        return cache_key in self.memory_cache and datetime.now() < self.memory_cache[cache_key]['expires_at']

    def clear_namespace(self, namespace: str) -> int:
        """Clear all keys in a namespace"""
        pattern = self._get_cache_key("*", namespace)

        if self.redis_client:
            try:
                keys = self.redis_client.keys(pattern)
                if keys:
                    return self.redis_client.delete(*keys)
                return 0
            except Exception as e:
                logger.error(f"Redis clear namespace error: {e}")

        # Fallback to memory cache
        deleted_count = 0
        keys_to_delete = [k for k in self.memory_cache.keys() if k.startswith(pattern[:-1])]  # Remove *
        for key in keys_to_delete:
            del self.memory_cache[key]
            deleted_count += 1
        return deleted_count

    def get_stats(self) -> Dict:
        """Get cache statistics"""
        stats = {
            'redis_connected': self.redis_client is not None,
            'memory_cache_size': len(self.memory_cache),
            'timestamp': datetime.now().isoformat()
        }

        if self.redis_client:
            try:
                info = self.redis_client.info()
                stats.update({
                    'redis_used_memory': info.get('used_memory_human', 'N/A'),
                    'redis_connected_clients': info.get('connected_clients', 0),
                    'redis_uptime_days': info.get('uptime_in_days', 0)
                })
            except Exception as e:
                logger.error(f"Redis stats error: {e}")

        return stats

    async def cleanup_expired(self):
        """Cleanup expired entries from memory cache"""
        current_time = datetime.now()
        expired_keys = [
            key for key, entry in self.memory_cache.items()
            if current_time >= entry['expires_at']
        ]

        for key in expired_keys:
            del self.memory_cache[key]

        if expired_keys:
            logger.info(f"Cleaned up {len(expired_keys)} expired cache entries")

# Global cache instance
cache_manager = CacheManager()

# Convenience functions
def get_cached_data(key: str, namespace: str = "default") -> Optional[Any]:
    """Get cached data"""
    return cache_manager.get(key, namespace)

def set_cached_data(key: str, value: Any, ttl_seconds: int = 300, namespace: str = "default") -> bool:
    """Set cached data"""
    return cache_manager.set(key, value, ttl_seconds, namespace)

def invalidate_cache(key: str, namespace: str = "default") -> bool:
    """Invalidate cache entry"""
    return cache_manager.delete(key, namespace)

def clear_cache_namespace(namespace: str) -> int:
    """Clear entire cache namespace"""
    return cache_manager.clear_namespace(namespace)

# Cache decorators
def cached(ttl_seconds: int = 300, namespace: str = "default"):
    """Decorator to cache function results"""
    def decorator(func):
        def wrapper(*args, **kwargs):
            # Create cache key from function name and arguments
            key_data = f"{func.__name__}:{str(args)}:{str(sorted(kwargs.items()))}"
            cache_key = hashlib.md5(key_data.encode()).hexdigest()

            # Try to get from cache first
            cached_result = get_cached_data(cache_key, namespace)
            if cached_result is not None:
                logger.debug(f"Cache hit for {func.__name__}")
                return cached_result

            # Execute function and cache result
            result = func(*args, **kwargs)
            set_cached_data(cache_key, result, ttl_seconds, namespace)
            logger.debug(f"Cache miss for {func.__name__}, stored result")
            return result

        return wrapper
    return decorator

def cached_async(ttl_seconds: int = 300, namespace: str = "default"):
    """Decorator to cache async function results"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # Create cache key from function name and arguments
            key_data = f"{func.__name__}:{str(args)}:{str(sorted(kwargs.items()))}"
            cache_key = hashlib.md5(key_data.encode()).hexdigest()

            # Try to get from cache first
            cached_result = get_cached_data(cache_key, namespace)
            if cached_result is not None:
                logger.debug(f"Cache hit for {func.__name__}")
                return cached_result

            # Execute function and cache result
            result = await func(*args, **kwargs)
            set_cached_data(cache_key, result, ttl_seconds, namespace)
            logger.debug(f"Cache miss for {func.__name__}, stored result")
            return result

        return wrapper
    return decorator
