"""
Cluster AI Dashboard API
FastAPI backend for the Cluster AI monitoring dashboard
"""

import asyncio
import hashlib
import json
import logging
import os
import secrets
import subprocess
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from typing import Dict, List, Optional, Set, Union

import jwt
import psutil
import uvicorn
from cache_manager import cache_manager, cached_async
from dependencies import *
from fastapi import (
    Depends,
    FastAPI,
    HTTPException,
    Query,
    Request,
    WebSocket,
    WebSocketDisconnect,
    status,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from monitoring_data_provider import (
    get_alerts,
    get_cluster_metrics,
    get_system_metrics,
    get_workers_info,
)

# Rate limiting
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from metrics import router as metrics_router
from models import *

limiter = Limiter(key_func=get_remote_address)


# WebSocket connection manager with CSRF protection
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.client_data: Dict[str, Dict] = {}
        self.csrf_tokens: Set[str] = set()

    def generate_csrf_token(self) -> str:
        """Generate a CSRF token for WebSocket connections"""
        token = secrets.token_urlsafe(32)
        self.csrf_tokens.add(token)
        return token

    def validate_csrf_token(self, token: str) -> bool:
        """Validate CSRF token"""
        if token in self.csrf_tokens:
            self.csrf_tokens.discard(token)  # One-time use
            return True
        return False

    async def connect(
        self, websocket: WebSocket, client_id: str, csrf_token: str = None
    ):
        # Validate CSRF token for security
        if csrf_token and not self.validate_csrf_token(csrf_token):
            await websocket.close(code=1008)  # Policy violation
            return

        await websocket.accept()
        self.active_connections.append(websocket)
        self.client_data[client_id] = {
            "websocket": websocket,
            "connected_at": datetime.now(),
        }
        logger.info(
            f"Client {client_id} connected. Total connections: {len(self.active_connections)}"
        )

    def disconnect(self, websocket: WebSocket, client_id: str):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        if client_id in self.client_data:
            del self.client_data[client_id]
        logger.info(
            f"Client {client_id} disconnected. Total connections: {len(self.active_connections)}"
        )

    async def broadcast(self, message: dict):
        """Broadcast message to all connected clients"""
        disconnected = []
        for websocket in self.active_connections:
            try:
                await websocket.send_json(message)
            except Exception as e:
                logger.error(f"Failed to send message to client: {e}")
                disconnected.append(websocket)

        # Clean up disconnected clients
        for websocket in disconnected:
            if websocket in self.active_connections:
                self.active_connections.remove(websocket)

    async def send_personal_message(self, message: dict, client_id: str):
        """Send message to specific client"""
        if client_id in self.client_data:
            websocket = self.client_data[client_id]["websocket"]
            try:
                await websocket.send_json(message)
            except Exception as e:
                logger.error(f"Failed to send personal message to {client_id}: {e}")
                self.disconnect(websocket, client_id)


# Global connection manager
manager = ConnectionManager()


# Background task for real-time updates
async def broadcast_realtime_updates():
    """Background task to broadcast real-time updates to all connected clients"""
    last_update_hash = None
    last_broadcast_time = datetime.now()
    debounce_interval = 5  # seconds

    while True:
        try:
            # Get current system metrics
            system_metrics = get_system_metrics()
            cluster_data = get_cluster_metrics()
            alerts_data = get_alerts()
            workers_data = get_workers_info()

            # Prepare update message
            update_message = {
                "type": "realtime_update",
                "timestamp": datetime.now().isoformat(),
                "data": {
                    "system_metrics": system_metrics[-1] if system_metrics else None,
                    "cluster_status": cluster_data,
                    "alerts_count": len(alerts_data),
                    "workers_count": len(workers_data),
                    "active_workers": len(
                        [w for w in workers_data if w.get("status") == "active"]
                    ),
                },
            }

            # Calculate hash of current data to detect changes
            current_hash = hashlib.md5(
                json.dumps(update_message["data"], sort_keys=True).encode()
            ).hexdigest()

            # Broadcast if data changed and debounce time passed
            time_since_last_broadcast = (
                datetime.now() - last_broadcast_time
            ).total_seconds()
            if manager.active_connections and (
                current_hash != last_update_hash
                or time_since_last_broadcast >= debounce_interval
            ):
                await manager.broadcast(update_message)
                last_update_hash = current_hash
                last_broadcast_time = datetime.now()
                logger.debug("Broadcasted real-time update with new data")
            else:
                logger.debug(
                    "Skipped broadcast - no significant changes or debounce active"
                )

        except Exception as e:
            logger.error(f"Error in realtime updates: {e}")

        await asyncio.sleep(3)


# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("🚀 Starting Cluster AI Dashboard API")

    # Initialize default user
    init_default_user()

    # Start background task for real-time updates
    realtime_task = asyncio.create_task(broadcast_realtime_updates())
    logger.info("📡 Started real-time updates broadcaster")

    yield

    # Shutdown
    logger.info("🛑 Shutting down Cluster AI Dashboard API")
    realtime_task.cancel()
    try:
        await realtime_task
    except asyncio.CancelledError:
        pass


# FastAPI app
app = FastAPI(
    title="Cluster AI Dashboard API",
    description="REST API for Cluster AI monitoring and management dashboard",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(metrics_router)
# Also expose metrics under '/api' for consistency
app.include_router(metrics_router, prefix="/api")

# Rate limiting exception handler
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# GZip compression middleware for better performance
app.add_middleware(GZipMiddleware, minimum_size=1000)


# Routes
@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Cluster AI Dashboard API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now()}


# Alias under '/api' for compatibility/unification
@app.get("/api/health")
async def api_health_check():
    return {"status": "healthy", "timestamp": datetime.now()}


@app.post("/auth/login", response_model=Token)
@limiter.limit("5/minute")
async def login(
    request: Request, login_data: LoginRequest, db: Session = Depends(get_db)
):
    """Authenticate user and return access token"""
    user = authenticate_user(db, login_data.username, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )


# Alias under '/api' for compatibility
@app.get("/api/cluster/status", response_model=ClusterStatus)
async def api_get_cluster_status(current_user: User = Depends(get_current_active_user)):
    return await get_cluster_status(current_user)


@app.get("/auth/me", response_model=User)
async def read_users_me(current_user: User = Depends(get_current_active_user)):
    """Get current user information"""
    return current_user


@app.get("/auth/csrf-token")
async def get_csrf_token(current_user: User = Depends(get_current_active_user)):
    """Get CSRF token for WebSocket connections"""
    token = manager.generate_csrf_token()
    return {"csrf_token": token}


@cached_async(ttl_seconds=30, namespace="workers")
async def get_workers_cached_data():
    """Get all workers information with validation"""
    workers_data = get_workers_info()
    validated_workers = []
    for worker in workers_data:
        try:
            validated_workers.append(WorkerInfo(**worker))
        except Exception as e:
            logger.warning(f"Invalid worker data: {worker}, error: {e}")
            continue
    return validated_workers


@app.get("/workers/{worker_id}", response_model=WorkerInfo)
async def get_worker(
    worker_id: str, current_user: User = Depends(get_current_active_user)
):
    """Get specific worker information"""
    workers_data = get_workers_info()
    worker = next((w for w in workers_data if w["id"] == worker_id), None)
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    return WorkerInfo(**worker)


@app.get("/workers", response_model=List[WorkerInfo])
async def get_workers(current_user: User = Depends(get_current_active_user)):
    """Get all workers information"""
    return await get_workers_cached_data()


# Alias under '/api' for compatibility
@app.get("/api/workers", response_model=List[WorkerInfo])
async def api_get_workers(current_user: User = Depends(get_current_active_user)):
    return await get_workers_cached_data()


async def get_system_metrics_data(limit: int = 100):
    """Get system metrics history with caching"""
    real_metrics = get_system_metrics()

    if real_metrics:
        metrics = []
        for m in real_metrics[-limit:]:
            metrics.append(
                SystemMetrics(
                    timestamp=datetime.fromtimestamp(m["timestamp"]),
                    cpu_percent=m["cpu_percent"],
                    memory_percent=m["memory_percent"],
                    disk_percent=m["disk_percent"],
                    network_rx=m["network_rx"],
                    network_tx=m.get("network_tx", 0.0),
                )
            )
        return metrics
    else:
        metrics = []
        base_time = datetime.now()
        for i in range(min(limit, 50)):
            metrics.append(
                SystemMetrics(
                    timestamp=base_time - timedelta(minutes=i),
                    cpu_percent=45.0 + (i % 20),
                    memory_percent=60.0 + (i % 15),
                    disk_percent=25.0 + (i % 10),
                    network_rx=1000.0 + (i * 10),
                    network_tx=800.0 + (i * 8),
                )
            )
        return metrics


@app.get("/metrics/system", response_model=list[SystemMetrics])
async def get_system_metrics_endpoint(
    limit: int = 100, current_user: User = Depends(get_current_active_user)
):
    """Get system metrics history with caching"""
    return await cached_async(ttl_seconds=15, namespace="metrics")(
        get_system_metrics_data
    )(limit=limit)


@app.post("/workers/{worker_id}/restart")
async def restart_worker(
    worker_id: str, current_user: User = Depends(get_current_active_user)
):
    """Restart a specific worker"""
    workers_data = get_workers_info()
    worker = next((w for w in workers_data if w["id"] == worker_id), None)
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    try:
        # Stop the worker first
        try:
            process = await asyncio.create_subprocess_exec(
                "pkill",
                "-f",
                f"dask-worker.*{worker_id}",
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.DEVNULL,
            )
            await asyncio.wait_for(process.wait(), timeout=10)
            logger.info(f"Stopped worker {worker_id}")
        except asyncio.TimeoutError:
            logger.warning(f"Timeout stopping worker {worker_id}")
        except Exception as e:
            logger.error(f"Error stopping worker {worker_id}: {e}")

        await asyncio.sleep(2)

        # Start the worker again
        worker_cmd = [
            "dask-worker",
            "tcp://localhost:8786",
            "--name",
            worker_id,
            "--nthreads",
            "2",
            "--memory-limit",
            "1GB",
        ]

        process = await asyncio.create_subprocess_exec(
            *worker_cmd,
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.DEVNULL,
        )
        logger.info(f"Started worker {worker_id} with PID {process.pid}")

        return {"message": f"Worker {worker_id} restart initiated successfully"}

    except Exception as e:
        logger.error(f"Failed to restart worker {worker_id}: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to restart worker: {str(e)}"
        )


@app.post("/workers/{worker_id}/stop")
async def stop_worker(
    worker_id: str, current_user: User = Depends(get_current_active_user)
):
    """Stop a specific worker"""
    workers_data = get_workers_info()
    worker = next((w for w in workers_data if w["id"] == worker_id), None)
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    try:
        process = await asyncio.create_subprocess_exec(
            "pkill",
            "-f",
            f"dask-worker.*{worker_id}",
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.DEVNULL,
        )
        await asyncio.wait_for(process.wait(), timeout=10)

        if process.returncode == 0:
            logger.info(f"Successfully stopped worker {worker_id}")
            return {"message": f"Worker {worker_id} stopped successfully"}
        else:
            logger.warning(f"Worker {worker_id} may not have been running")
            return {"message": f"Worker {worker_id} was not running or already stopped"}

    except asyncio.TimeoutError:
        logger.error(f"Timeout stopping worker {worker_id}")
        raise HTTPException(status_code=500, detail="Timeout stopping worker")
    except Exception as e:
        logger.error(f"Failed to stop worker {worker_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to stop worker: {str(e)}")


@app.post("/workers/{worker_id}/start")
async def start_worker(
    worker_id: str, current_user: User = Depends(get_current_active_user)
):
    """Start a specific worker"""
    workers_data = get_workers_info()
    worker = next((w for w in workers_data if w["id"] == worker_id), None)
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    try:
        worker_cmd = [
            "dask-worker",
            "tcp://localhost:8786",
            "--name",
            worker_id,
            "--nthreads",
            "2",
            "--memory-limit",
            "1GB",
        ]

        process = await asyncio.create_subprocess_exec(
            *worker_cmd,
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.DEVNULL,
        )
        logger.info(f"Started worker {worker_id} with PID {process.pid}")
        return {"message": f"Worker {worker_id} started successfully"}

    except Exception as e:
        logger.error(f"Failed to start worker {worker_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to start worker: {str(e)}")


async def get_alerts_data(limit: int = 50):
    """Get recent alerts from monitoring system with caching"""
    alerts_data = get_alerts()

    alerts = []
    for alert_line in alerts_data[-limit:]:
        if alert_line.startswith("[") and "]" in alert_line:
            try:
                parts = alert_line.split("] ")
                if len(parts) >= 4:
                    timestamp = parts[0].strip("[")
                    severity = parts[1].strip("[")
                    component = parts[2].strip("[")
                    message = "] ".join(parts[3:])

                    alerts.append(
                        AlertInfo(
                            timestamp=timestamp,
                            severity=severity,
                            component=component,
                            message=message,
                        )
                    )
            except:
                alerts.append(
                    AlertInfo(
                        timestamp=datetime.now().isoformat(),
                        severity="INFO",
                        component="SYSTEM",
                        message=alert_line,
                    )
                )

    return alerts


@app.get("/alerts", response_model=list[AlertInfo])
async def get_alerts_endpoint(
    limit: int = 50, current_user: User = Depends(get_current_active_user)
):
    """Get recent alerts from monitoring system with caching"""
    return await cached_async(ttl_seconds=10, namespace="alerts")(get_alerts_data)(
        limit=limit
    )


# Alias under '/api' for compatibility
@app.get("/api/alerts", response_model=list[AlertInfo])
async def api_get_alerts_endpoint(
    limit: int = 50, current_user: User = Depends(get_current_active_user)
):
    return await cached_async(ttl_seconds=10, namespace="alerts")(get_alerts_data)(
        limit=limit
    )


@app.get("/monitoring/status")
async def get_monitoring_status(current_user: User = Depends(get_current_active_user)):
    """Get overall monitoring system status"""
    cluster_data = get_cluster_metrics()
    alerts_data = get_alerts()

    critical_count = sum(1 for alert in alerts_data if "[CRITICAL]" in alert)
    warning_count = sum(1 for alert in alerts_data if "[WARNING]" in alert)
    info_count = sum(1 for alert in alerts_data if "[INFO]" in alert)

    return {
        "monitoring_active": True,
        "last_update": datetime.now().isoformat(),
        "alerts_summary": {
            "critical": critical_count,
            "warning": warning_count,
            "info": info_count,
            "total": len(alerts_data),
        },
        "services_status": {
            "ollama": cluster_data.get("ollama_running", False),
            "dask": cluster_data.get("dask_running", False),
            "webui": cluster_data.get("webui_running", False),
        },
        "cluster_health": (
            "healthy"
            if all(
                [
                    cluster_data.get("ollama_running", False),
                    cluster_data.get("dask_running", False),
                    cluster_data.get("webui_running", False),
                ]
            )
            else "degraded"
        ),
    }


# Legacy-compatible endpoint within canonical app (mirrors old backend/api/system_metrics.py)
@app.get("/api/system_metrics")
async def legacy_system_metrics(current_user: User = Depends(get_current_active_user)):
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage("/")

        # Dask scheduler port check
        dask_status = "unknown"
        try:
            result = subprocess.run(["ss", "-tlnp"], capture_output=True, text=True)
            dask_status = "active" if ":8786" in result.stdout else "inactive"
        except Exception:
            dask_status = "unknown"

        # Basic GPU info
        gpu_info = {"available": False, "name": None}
        try:
            import torch  # type: ignore

            if torch.cuda.is_available():
                gpu_info = {"available": True, "name": torch.cuda.get_device_name(0)}
        except Exception:
            gpu_info = {"available": False, "name": None}

        return {
            "cpu_percent": cpu_percent,
            "memory_percent": memory.percent,
            "memory_available_gb": round(memory.available / (1024**3), 2),
            "disk_percent": disk.percent,
            "disk_free_gb": round(disk.free / (1024**3), 2),
            "dask_status": dask_status,
            "gpu_info": gpu_info,
        }
    except Exception as e:
        logger.error(f"Failed to build legacy system metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve system metrics")


@app.get("/logs", response_model=list[dict])
async def get_logs(
    limit: int = 100,
    level: str = None,
    component: str = None,
    current_user: User = Depends(get_current_active_user),
):
    """Get system logs with optional filtering"""
    try:
        logs_dir = os.path.join(os.path.dirname(__file__), "../../logs")
        if not os.path.exists(logs_dir):
            return []

        log_files = [f for f in os.listdir(logs_dir) if f.endswith(".log")]
        all_logs = []

        for log_file in log_files:
            log_path = os.path.join(logs_dir, log_file)
            try:
                with open(log_path, "r", encoding="utf-8", errors="ignore") as f:
                    lines = f.readlines()[-limit:]

                    for line in lines:
                        line = line.strip()
                        if line:
                            log_entry = parse_log_line(line)
                            if log_entry:
                                if level and log_entry.get("level") != level.upper():
                                    continue
                                if (
                                    component
                                    and log_entry.get("component") != component.upper()
                                ):
                                    continue
                                all_logs.append(log_entry)
            except Exception as e:
                logger.error(f"Error reading log file {log_file}: {e}")

        all_logs.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        return all_logs[:limit]

    except Exception as e:
        logger.error(f"Error retrieving logs: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to retrieve logs: {str(e)}"
        )


def parse_log_line(line):
    """Parse a log line into structured data"""
    try:
        if not line.startswith("["):
            return None

        parts = line.split("] ")
        if len(parts) < 4:
            return None

        timestamp = parts[0].strip("[")
        level = parts[1].strip("[")
        component = parts[2].strip("[")
        message = "] ".join(parts[3:])

        return {
            "timestamp": timestamp,
            "level": level,
            "component": component,
            "message": message,
            "raw": line,
        }
    except:
        return {
            "timestamp": datetime.now().isoformat(),
            "level": "UNKNOWN",
            "component": "SYSTEM",
            "message": line,
            "raw": line,
        }


# Settings management
settings_store = {
    "monitoring_enabled": True,
    "update_interval": 5,
    "alert_threshold_cpu": 80,
    "alert_threshold_memory": 80,
    "alert_threshold_disk": 90,
    "email_notifications": False,
    "slack_notifications": False,
    "notification_email": "",
    "session_timeout": 30,
    "max_login_attempts": 5,
    "log_level": "INFO",
    "backup_enabled": True,
    "backup_interval": 24,
}


@app.get("/settings", response_model=dict)
async def get_settings(current_user: User = Depends(get_current_active_user)):
    """Get current system settings"""
    return settings_store


@app.post("/settings")
async def update_settings(
    settings: dict, current_user: User = Depends(get_current_active_user)
):
    """Update system settings"""

    # Validate settings
    if "update_interval" in settings:
        if not (1 <= settings["update_interval"] <= 60):
            raise HTTPException(
                status_code=400,
                detail="Update interval must be between 1 and 60 seconds",
            )

    if "alert_threshold_cpu" in settings:
        if not (50 <= settings["alert_threshold_cpu"] <= 100):
            raise HTTPException(
                status_code=400, detail="CPU threshold must be between 50 and 100"
            )

    if "alert_threshold_memory" in settings:
        if not (50 <= settings["alert_threshold_memory"] <= 100):
            raise HTTPException(
                status_code=400, detail="Memory threshold must be between 50 and 100"
            )

    if "alert_threshold_disk" in settings:
        if not (70 <= settings["alert_threshold_disk"] <= 100):
            raise HTTPException(
                status_code=400, detail="Disk threshold must be between 70 and 100"
            )

    # Update settings
    settings_store.update(settings)

    # Apply settings to running system
    if "log_level" in settings:
        logging.getLogger().setLevel(getattr(logging, settings["log_level"]))

    logger.info(f"Settings updated by user {current_user.username}")
    return {"message": "Settings updated successfully", "settings": settings_store}


# Cluster status endpoint
@app.get("/cluster/status", response_model=ClusterStatus)
async def get_cluster_status(current_user: User = Depends(get_current_active_user)):
    """Get comprehensive cluster status"""
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage("/")

        network = psutil.net_io_counters()

        dask_running = check_service_running("dask-scheduler")
        ollama_running = check_service_running("ollama")
        webui_running = check_service_running("open-webui")

        workers_data = get_workers_info()
        workers_count = len(workers_data)
        active_workers = len([w for w in workers_data if w["status"] == "active"])

        alerts_db = get_alerts()
        alerts_count = len(alerts_db)

        cluster_status = {
            "timestamp": datetime.now().isoformat(),
            "system_metrics": {
                "cpu_percent": cpu_percent,
                "memory_percent": memory.percent,
                "disk_percent": disk.percent,
                "network_rx": network.bytes_recv,
                "network_tx": network.bytes_sent,
            },
            "services": {
                "dask_running": dask_running,
                "ollama_running": ollama_running,
                "webui_running": webui_running,
            },
            "workers": {
                "total_workers": workers_count,
                "active_workers": active_workers,
                "total_cpu": sum(w["cpu_usage"] for w in workers_data),
                "total_memory": sum(w["memory_usage"] for w in workers_data),
            },
            "performance": {
                "dask_tasks_completed": 0,
                "dask_tasks_pending": 0,
                "dask_tasks_failed": 0,
                "dask_task_throughput": 0.0,
            },
            "alerts_count": alerts_count,
            "health_score": calculate_health_score(
                {
                    "dask_running": dask_running,
                    "ollama_running": ollama_running,
                    "webui_running": webui_running,
                    "cpu_percent": cpu_percent,
                    "memory_percent": memory.percent,
                    "disk_percent": disk.percent,
                }
            ),
        }

        return ClusterStatus(
            total_workers=cluster_status["workers"]["total_workers"],
            active_workers=cluster_status["workers"]["active_workers"],
            total_cpu=cluster_status["workers"]["total_cpu"],
            total_memory=cluster_status["workers"]["total_memory"],
            status="healthy" if active_workers > 0 else "degraded",
            ollama_running=cluster_status["services"]["ollama_running"],
            dask_running=cluster_status["services"]["dask_running"],
            webui_running=cluster_status["services"]["webui_running"],
            dask_tasks_completed=cluster_status["performance"]["dask_tasks_completed"],
            dask_tasks_failed=cluster_status["performance"]["dask_tasks_failed"],
            dask_tasks_pending=cluster_status["performance"]["dask_tasks_pending"],
            dask_task_throughput=cluster_status["performance"]["dask_task_throughput"],
        )

    except Exception as e:
        logger.error(f"Failed to get cluster status: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve cluster status")


def check_service_running(service_name):
    """Check if a service is running"""
    try:
        result = subprocess.run(
            ["pgrep", "-f", service_name], capture_output=True, text=True, timeout=5
        )
        return result.returncode == 0
    except:
        return False


def calculate_health_score(status_data):
    """Calculate overall health score (0-100)"""
    score = 0
    total_checks = 0

    # Service checks (40% weight)
    services = ["dask_running", "ollama_running", "webui_running"]
    for service in services:
        total_checks += 1
        if status_data.get(service, False):
            score += 40 / len(services)

    # Resource checks (60% weight)
    resources = ["cpu_percent", "memory_percent", "disk_percent"]
    for resource in resources:
        total_checks += 1
        value = status_data.get(resource, 0)
        if value < 70:
            score += 60 / len(resources)
        elif value < 85:
            score += (60 / len(resources)) * 0.5

    return min(100, score)


# WebSocket endpoints
@app.websocket("/ws/{client_id}")
async def websocket_endpoint(
    websocket: WebSocket, client_id: str, csrf_token: str = Query(None)
):
    """WebSocket endpoint for real-time updates with CSRF protection"""
    await manager.connect(websocket, client_id, csrf_token)
    try:
        while True:
            data = await websocket.receive_text()

            try:
                message = json.loads(data)
                logger.info(f"Received message from {client_id}: {message}")

                await manager.send_personal_message(
                    {
                        "type": "ack",
                        "message": "Message received",
                        "timestamp": datetime.now().isoformat(),
                    },
                    client_id,
                )

            except json.JSONDecodeError:
                await manager.send_personal_message(
                    {
                        "type": "error",
                        "message": "Invalid JSON format",
                        "timestamp": datetime.now().isoformat(),
                    },
                    client_id,
                )

    except WebSocketDisconnect:
        manager.disconnect(websocket, client_id)
    except Exception as e:
        logger.error(f"WebSocket error for client {client_id}: {e}")
        manager.disconnect(websocket, client_id)


@app.get("/ws/connections")
async def get_websocket_connections(
    current_user: User = Depends(get_current_active_user),
):
    """Get information about active WebSocket connections"""
    return {
        "active_connections": len(manager.active_connections),
        "clients": [
            {"client_id": client_id, "connected_at": data["connected_at"].isoformat()}
            for client_id, data in manager.client_data.items()
        ],
    }


if __name__ == "__main__":
    uvicorn.run(
        "main_fixed:app", host="0.0.0.0", port=8000, reload=True, log_level="info"
    )
