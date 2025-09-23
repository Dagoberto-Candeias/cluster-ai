"""
Cluster AI Dashboard API
FastAPI backend for the Cluster AI monitoring dashboard
"""

import psutil
import subprocess

from fastapi import FastAPI, HTTPException, Depends, status, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from contextlib import asynccontextmanager
import uvicorn
import os
from datetime import datetime, timedelta
import jwt
from passlib.context import CryptContext
from pydantic import BaseModel
import logging
import asyncio
import json
from typing import List, Dict
from monitoring_data_provider import get_cluster_metrics, get_system_metrics, get_alerts, get_workers_info
from metrics import router as metrics_router
from cache_manager import cache_manager, cached_async

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Security
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

# Pydantic models
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: str | None = None

class User(BaseModel):
    username: str
    email: str | None = None
    full_name: str | None = None
    disabled: bool | None = None

class UserInDB(User):
    hashed_password: str

class LoginRequest(BaseModel):
    username: str
    password: str

class WorkerInfo(BaseModel):
    id: str
    name: str
    status: str
    ip_address: str
    cpu_usage: float
    memory_usage: float
    last_seen: datetime

class SystemMetrics(BaseModel):
    timestamp: datetime
    cpu_percent: float
    memory_percent: float
    disk_percent: float
    network_rx: float
    network_tx: float

class ClusterStatus(BaseModel):
    total_workers: int
    active_workers: int
    total_cpu: float
    total_memory: float
    status: str
    ollama_running: bool = False
    dask_running: bool = False
    webui_running: bool = False
    dask_tasks_completed: int = 0
    dask_tasks_failed: int = 0
    dask_tasks_pending: int = 0
    dask_tasks_processing: int = 0
    dask_task_throughput: float = 0.0
    dask_avg_task_time: float = 0.0

class AlertInfo(BaseModel):
    timestamp: str
    severity: str
    component: str
    message: str

class DetailedMetrics(BaseModel):
    timestamp: datetime
    cpu_percent: float
    memory_percent: float
    disk_percent: float
    network_rx: float
    network_tx: float
    cpu_user: float = 0.0
    cpu_system: float = 0.0
    cpu_idle: float = 0.0
    memory_total: int = 0
    memory_used: int = 0
    memory_free: int = 0
    disk_total: int = 0
    disk_used: int = 0
    disk_available: int = 0

# Mock data for development
MOCK_USERS_DB = {
    "admin": {
        "username": "admin",
        "full_name": "Administrator",
        "email": "admin@cluster-ai.local",
        "hashed_password": pwd_context.hash("admin123"),
        "disabled": False,
    }
}

MOCK_WORKERS = [
    {
        "id": "worker-001",
        "name": "Worker Node 1",
        "status": "active",
        "ip_address": "192.168.1.101",
        "cpu_usage": 45.2,
        "memory_usage": 67.8,
        "last_seen": datetime.now()
    },
    {
        "id": "worker-002",
        "name": "Worker Node 2",
        "status": "active",
        "ip_address": "192.168.1.102",
        "cpu_usage": 32.1,
        "memory_usage": 54.3,
        "last_seen": datetime.now()
    }
]

# Utility functions
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def get_user(db, username: str):
    if username in db:
        user_dict = db[username]
        return UserInDB(**user_dict)

def authenticate_user(fake_db, username: str, password: str):
    user = get_user(fake_db, username)
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except jwt.PyJWTError:
        raise credentials_exception
    user = get_user(MOCK_USERS_DB, username=token_data.username)
    if user is None:
        raise credentials_exception
    return user

async def get_current_active_user(current_user: User = Depends(get_current_user)):
    if current_user.disabled:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.client_data: Dict[str, Dict] = {}

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections.append(websocket)
        self.client_data[client_id] = {"websocket": websocket, "connected_at": datetime.now()}
        logger.info(f"Client {client_id} connected. Total connections: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket, client_id: str):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        if client_id in self.client_data:
            del self.client_data[client_id]
        logger.info(f"Client {client_id} disconnected. Total connections: {len(self.active_connections)}")

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
    # Import hashlib and json here to keep them local to the task
    import hashlib
    import json

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
                    "active_workers": len([w for w in workers_data if w.get("status") == "active"])
                }
            }

            # Calculate hash of current data to detect changes
            current_hash = hashlib.md5(json.dumps(update_message["data"], sort_keys=True).encode()).hexdigest()

            # Only broadcast if data has changed
            if manager.active_connections and current_hash != last_update_hash: # This was line 285
                # Broadcast to all connected clients
                await manager.broadcast(update_message)
                last_update_hash = current_hash
                logger.debug("Broadcasted real-time update with new data")
            else:
                logger.debug("Skipped broadcast - no data changes or no active connections")

        except Exception as e:
            logger.error(f"Error in realtime updates: {e}")

        # Wait 3 seconds before next update (reduced from 5 for better responsiveness)
        await asyncio.sleep(3)

# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("🚀 Starting Cluster AI Dashboard API")

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
    lifespan=lifespan
)

app.include_router(metrics_router)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],  # Frontend URLs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# GZip compression middleware for better performance
app.add_middleware(GZipMiddleware, minimum_size=1000)  # Compress responses > 1KB

# Routes
@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Cluster AI Dashboard API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now()}

@app.post("/auth/login", response_model=Token)
async def login(login_data: LoginRequest):
    """Authenticate user and return access token"""
    user = authenticate_user(MOCK_USERS_DB, login_data.username, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/auth/me", response_model=User)
async def read_users_me(current_user: User = Depends(get_current_active_user)):
    """Get current user information"""
    return current_user

@cached_async(ttl_seconds=20, namespace="workers")
async def get_workers_cached_data():
    """Get all workers information"""
    workers_data = get_workers_info()
    return [WorkerInfo(**worker) for worker in workers_data]

@app.get("/workers/{worker_id}", response_model=WorkerInfo)
async def get_worker(worker_id: str, current_user: User = Depends(get_current_active_user)):
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

async def get_system_metrics_data(limit: int = 100):
    """Get system metrics history with caching"""
    # Get real metrics from monitoring logs
    real_metrics = get_system_metrics()

    if real_metrics:
        # Convert to SystemMetrics format
        metrics = []
        for m in real_metrics[-limit:]:  # Get last 'limit' entries
            metrics.append(SystemMetrics(
                timestamp=datetime.fromtimestamp(m["timestamp"]),
                cpu_percent=m["cpu_percent"],
                memory_percent=m["memory_percent"],
                disk_percent=m["disk_percent"],
                network_rx=m["network_rx"],
                network_tx=0.0  # Network TX not available in current log format
            ))
        return metrics
    else:
        # Fallback to mock data if no real metrics available
        metrics = []
        base_time = datetime.now()
        for i in range(min(limit, 50)):  # Limit mock data
            metrics.append(SystemMetrics(
                timestamp=base_time - timedelta(minutes=i),
                cpu_percent=45.0 + (i % 20),
                memory_percent=60.0 + (i % 15),
                disk_percent=25.0 + (i % 10),
                network_rx=1000.0 + (i * 10),
                network_tx=800.0 + (i * 8)
            ))
        return metrics

@app.get("/metrics/system", response_model=list[SystemMetrics])
async def get_system_metrics_endpoint(
    limit: int = 100,
    current_user: User = Depends(get_current_active_user)
):
    """Get system metrics history with caching"""
    return await cached_async(get_system_metrics_data, ttl_seconds=15, namespace="metrics")(limit=limit)

@app.post("/workers/{worker_id}/restart")
async def restart_worker(worker_id: str, current_user: User = Depends(get_current_active_user)):
    """Restart a specific worker"""
    workers_data = get_workers_info()
    worker = next((w for w in workers_data if w["id"] == worker_id), None)
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    try:
        # Stop the worker first
        import subprocess
        import os

        # Find and kill existing worker process
        try:
            result = subprocess.run(['pkill', '-f', f'dask-worker.*{worker_id}'],
                                  capture_output=True, text=True, timeout=10)
            logger.info(f"Stopped worker {worker_id}: {result.stdout}")
        except subprocess.TimeoutExpired:
            logger.warning(f"Timeout stopping worker {worker_id}")
        except Exception as e:
            logger.error(f"Error stopping worker {worker_id}: {e}")

        # Wait a moment
        await asyncio.sleep(2)

        # Start the worker again
        worker_cmd = [
            'dask-worker',
            'tcp://localhost:8786',  # Scheduler address
            '--name', worker_id,
            '--nthreads', '2',
            '--memory-limit', '1GB'
        ]

        # Start in background
        process = subprocess.Popen(worker_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        logger.info(f"Started worker {worker_id} with PID {process.pid}")

        return {"message": f"Worker {worker_id} restart initiated successfully"}

    except Exception as e:
        logger.error(f"Failed to restart worker {worker_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to restart worker: {str(e)}")

# New endpoint to stop a worker
@app.post("/workers/{worker_id}/stop")
async def stop_worker(worker_id: str, current_user: User = Depends(get_current_active_user)):
    """Stop a specific worker"""
    workers_data = get_workers_info()
    worker = next((w for w in workers_data if w["id"] == worker_id), None)
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    try:
        import subprocess

        # Find and kill the worker process
        result = subprocess.run(['pkill', '-f', f'dask-worker.*{worker_id}'],
                              capture_output=True, text=True, timeout=10)

        if result.returncode == 0:
            logger.info(f"Successfully stopped worker {worker_id}")
            return {"message": f"Worker {worker_id} stopped successfully"}
        else:
            logger.warning(f"Worker {worker_id} may not have been running: {result.stderr}")
            return {"message": f"Worker {worker_id} was not running or already stopped"}

    except subprocess.TimeoutExpired:
        logger.error(f"Timeout stopping worker {worker_id}")
        raise HTTPException(status_code=500, detail="Timeout stopping worker")
    except Exception as e:
        logger.error(f"Failed to stop worker {worker_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to stop worker: {str(e)}")

# New endpoint to start a worker
@app.post("/workers/{worker_id}/start")
async def start_worker(worker_id: str, current_user: User = Depends(get_current_active_user)):
    """Start a specific worker"""
    workers_data = get_workers_info()
    worker = next((w for w in workers_data if w["id"] == worker_id), None)
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    try:
        import subprocess

        # Start the worker process
        worker_cmd = [
            'dask-worker',
            'tcp://localhost:8786',  # Scheduler address
            '--name', worker_id,
            '--nthreads', '2',
            '--memory-limit', '1GB'
        ]

        process = subprocess.Popen(worker_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        logger.info(f"Started worker {worker_id} with PID {process.pid}")
        return {"message": f"Worker {worker_id} started successfully"}

    except Exception as e:
        logger.error(f"Failed to start worker {worker_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to start worker: {str(e)}")

async def get_alerts_data(limit: int = 50):
    """Get recent alerts from monitoring system with caching"""
    alerts_data = get_alerts()

    alerts = []
    for alert_line in alerts_data[-limit:]:  # Get last 'limit' alerts
        # Parse alert format: [timestamp] [severity] [component] message
        if alert_line.startswith('[') and ']' in alert_line:
            try:
                parts = alert_line.split('] ')
                if len(parts) >= 4:
                    timestamp = parts[0].strip('[')
                    severity = parts[1].strip('[')
                    component = parts[2].strip('[')
                    message = '] '.join(parts[3:])

                    alerts.append(AlertInfo(
                        timestamp=timestamp,
                        severity=severity,
                        component=component,
                        message=message
                    ))
            except:
                # If parsing fails, add as generic alert
                alerts.append(AlertInfo(
                    timestamp=datetime.now().isoformat(),
                    severity="INFO",
                    component="SYSTEM",
                    message=alert_line
                ))

    return alerts

@app.get("/alerts", response_model=list[AlertInfo])
async def get_alerts_endpoint(
    limit: int = 50,
    current_user: User = Depends(get_current_active_user)
):
    """Get recent alerts from monitoring system with caching"""
    return await cached_async(get_alerts_data, ttl_seconds=10, namespace="alerts")(limit=limit)

@app.get("/monitoring/status")
async def get_monitoring_status(current_user: User = Depends(get_current_active_user)):
    """Get overall monitoring system status"""
    cluster_data = get_cluster_metrics()
    alerts_data = get_alerts()

    # Count alerts by severity
    critical_count = sum(1 for alert in alerts_data if '[CRITICAL]' in alert)
    warning_count = sum(1 for alert in alerts_data if '[WARNING]' in alert)
    info_count = sum(1 for alert in alerts_data if '[INFO]' in alert)

    return {
        "monitoring_active": True,
        "last_update": datetime.now().isoformat(),
        "alerts_summary": {
            "critical": critical_count,
            "warning": warning_count,
            "info": info_count,
            "total": len(alerts_data)
        },
        "services_status": {
            "ollama": cluster_data.get("ollama_running", False),
            "dask": cluster_data.get("dask_running", False),
            "webui": cluster_data.get("webui_running", False)
        },
        "cluster_health": "healthy" if all([
            cluster_data.get("ollama_running", False),
            cluster_data.get("dask_running", False),
            cluster_data.get("webui_running", False)
        ]) else "degraded"
    }

@app.get("/logs", response_model=list[dict])
async def get_logs(
    limit: int = 100,
    level: str = None,
    component: str = None,
    current_user: User = Depends(get_current_active_user)
):
    """Get system logs with optional filtering"""
    try:
        # Read from logs directory
        logs_dir = os.path.join(os.path.dirname(__file__), "../../logs")
        if not os.path.exists(logs_dir):
            return []

        log_files = [f for f in os.listdir(logs_dir) if f.endswith('.log')]
        all_logs = []

        for log_file in log_files:
            log_path = os.path.join(logs_dir, log_file)
            try:
                with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
                    lines = f.readlines()[-limit:]  # Get last N lines

                    for line in lines:
                        line = line.strip()
                        if line:
                            # Parse log line format: [timestamp] [level] [component] message
                            log_entry = parse_log_line(line)
                            if log_entry:
                                # Apply filters
                                if level and log_entry.get('level') != level.upper():
                                    continue
                                if component and log_entry.get('component') != component.upper():
                                    continue
                                all_logs.append(log_entry)
            except Exception as e:
                logger.error(f"Error reading log file {log_file}: {e}")

        # Sort by timestamp (newest first) and limit results
        all_logs.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        return all_logs[:limit]

    except Exception as e:
        logger.error(f"Error retrieving logs: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve logs: {str(e)}")

def parse_log_line(line):
    """Parse a log line into structured data"""
    try:
        if not line.startswith('['):
            return None

        parts = line.split('] ')
        if len(parts) < 4:
            return None

        timestamp = parts[0].strip('[')
        level = parts[1].strip('[')
        component = parts[2].strip('[')
        message = '] '.join(parts[3:])

        return {
            "timestamp": timestamp,
            "level": level,
            "component": component,
            "message": message,
            "raw": line
        }
    except:
        return {
            "timestamp": datetime.now().isoformat(),
            "level": "UNKNOWN",
            "component": "SYSTEM",
            "message": line,
            "raw": line
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
    "backup_interval": 24
}

@app.get("/settings", response_model=dict)
async def get_settings(current_user: User = Depends(get_current_active_user)):
    """Get current system settings"""
    return settings_store

@app.post("/settings")
async def update_settings(settings: dict, current_user: User = Depends(get_current_active_user)):
    """Update system settings"""
    global settings_store

    # Validate settings
    if 'update_interval' in settings:
        if not (1 <= settings['update_interval'] <= 60):
            raise HTTPException(status_code=400, detail="Update interval must be between 1 and 60 seconds")

    if 'alert_threshold_cpu' in settings:
        if not (50 <= settings['alert_threshold_cpu'] <= 100):
            raise HTTPException(status_code=400, detail="CPU threshold must be between 50 and 100")

    if 'alert_threshold_memory' in settings:
        if not (50 <= settings['alert_threshold_memory'] <= 100):
            raise HTTPException(status_code=400, detail="Memory threshold must be between 50 and 100")

    if 'alert_threshold_disk' in settings:
        if not (70 <= settings['alert_threshold_disk'] <= 100):
            raise HTTPException(status_code=400, detail="Disk threshold must be between 70 and 100")

    # Update settings
    settings_store.update(settings)

    # Apply settings to running system
    if 'log_level' in settings:
        logging.getLogger().setLevel(getattr(logging, settings['log_level']))

    logger.info(f"Settings updated by user {current_user.username}")
    return {"message": "Settings updated successfully", "settings": settings_store}

# Cluster status endpoint
@app.get("/cluster/status", response_model=ClusterStatus)
async def get_cluster_status(current_user: User = Depends(get_current_active_user)):
    """Get comprehensive cluster status"""
    try:
        # Get system metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')

        # Get network info
        network = psutil.net_io_counters()

        # Check service status
        dask_running = check_service_running("dask-scheduler")
        ollama_running = check_service_running("ollama")
        webui_running = check_service_running("open-webui")

        # Get workers info (simplified for demo)
        workers_data = get_workers_info()
        workers_count = len(workers_data)
        active_workers = len([w for w in workers_data if w["status"] == "active"])

        # Get alerts count
        alerts_db = get_alerts()
        alerts_count = len(alerts_db) if 'alerts_db' in globals() else 0

        cluster_status = {
            "timestamp": datetime.now().isoformat(),
            "system_metrics": {
                "cpu_percent": cpu_percent,
                "memory_percent": memory.percent,
                "disk_percent": disk.percent,
                "network_rx": network.bytes_recv,
                "network_tx": network.bytes_sent
            },
            "services": {
                "dask_running": dask_running,
                "ollama_running": ollama_running,
                "webui_running": webui_running
            },
            "workers": {
                "total_workers": workers_count,
                "active_workers": active_workers,
                "total_cpu": sum(w["cpu_usage"] for w in workers_data),
                "total_memory": sum(w["memory_usage"] for w in workers_data)
            },
            "performance": {
                "dask_tasks_completed": 0,
                "dask_tasks_pending": 0,
                "dask_tasks_failed": 0,
                "dask_task_throughput": 0.0
            },
            "alerts_count": alerts_count,
            "health_score": calculate_health_score({
                "dask_running": dask_running,
                "ollama_running": ollama_running,
                "webui_running": webui_running,
                "cpu_percent": cpu_percent,
                "memory_percent": memory.percent,
                "disk_percent": disk.percent
            })
        }

        # Convert to Pydantic model
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
            dask_task_throughput=cluster_status["performance"]["dask_task_throughput"]
        )

    except Exception as e:
        logger.error(f"Failed to get cluster status: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve cluster status")

def check_service_running(service_name):
    """Check if a service is running"""
    try:
        result = subprocess.run(
            ["pgrep", "-f", service_name],
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.returncode == 0
    except:
        return False

def calculate_health_score(status_data):
    """Calculate overall health score (0-100)"""
    score = 0
    total_checks = 0

    # Service checks (40% weight)
    services = ['dask_running', 'ollama_running', 'webui_running']
    for service in services:
        total_checks += 1
        if status_data.get(service, False):
            score += 40 / len(services)

    # Resource checks (60% weight)
    resources = ['cpu_percent', 'memory_percent', 'disk_percent']
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
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(websocket, client_id)
    try:
        while True:
            # Keep connection alive and listen for client messages
            data = await websocket.receive_text()

            # Handle client messages if needed
            try:
                message = json.loads(data)
                logger.info(f"Received message from {client_id}: {message}")

                # Echo back acknowledgment
                await manager.send_personal_message({
                    "type": "ack",
                    "message": "Message received",
                    "timestamp": datetime.now().isoformat()
                }, client_id)

            except json.JSONDecodeError:
                # Invalid JSON, send error
                await manager.send_personal_message({
                    "type": "error",
                    "message": "Invalid JSON format",
                    "timestamp": datetime.now().isoformat()
                }, client_id)

    except WebSocketDisconnect:
        manager.disconnect(websocket, client_id)
    except Exception as e:
        logger.error(f"WebSocket error for client {client_id}: {e}")
        manager.disconnect(websocket, client_id)

@app.get("/ws/connections")
async def get_websocket_connections(current_user: User = Depends(get_current_active_user)):
    """Get information about active WebSocket connections"""
    return {
        "active_connections": len(manager.active_connections),
        "clients": [
            {
                "client_id": client_id,
                "connected_at": data["connected_at"].isoformat()
            }
            for client_id, data in manager.client_data.items()
        ]
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
