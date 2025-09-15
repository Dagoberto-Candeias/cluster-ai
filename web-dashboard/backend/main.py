"""
Cluster AI Dashboard API
FastAPI backend for the Cluster AI monitoring dashboard
"""

from fastapi import FastAPI, HTTPException, Depends, status, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
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

            # Broadcast to all connected clients
            await manager.broadcast(update_message)

        except Exception as e:
            logger.error(f"Error in realtime updates: {e}")

        # Wait 5 seconds before next update
        await asyncio.sleep(5)

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

@app.get("/cluster/status", response_model=ClusterStatus)
async def get_cluster_status(current_user: User = Depends(get_current_active_user)):
    """Get overall cluster status"""
    cluster_data = get_cluster_metrics()
    workers_data = get_workers_info()

    active_workers = len([w for w in workers_data if w["status"] == "active"])
    total_cpu = sum(w["cpu_usage"] for w in workers_data)
    total_memory = sum(w["memory_usage"] for w in workers_data)

    return ClusterStatus(
        total_workers=len(workers_data),
        active_workers=active_workers,
        total_cpu=total_cpu,
        total_memory=total_memory,
        status="healthy" if active_workers > 0 else "degraded",
        ollama_running=cluster_data.get("ollama_running", False),
        dask_running=cluster_data.get("dask_running", False),
        webui_running=cluster_data.get("webui_running", False),
        dask_tasks_completed=cluster_data.get("dask_tasks_completed", 0),
        dask_tasks_failed=cluster_data.get("dask_tasks_failed", 0),
        dask_tasks_pending=cluster_data.get("dask_tasks_pending", 0),
        dask_tasks_processing=cluster_data.get("dask_tasks_processing", 0),
        dask_task_throughput=cluster_data.get("dask_task_throughput", 0.0),
        dask_avg_task_time=cluster_data.get("dask_avg_task_time", 0.0)
    )

@app.get("/workers", response_model=list[WorkerInfo])
async def get_workers(current_user: User = Depends(get_current_active_user)):
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

@app.get("/metrics/system", response_model=list[SystemMetrics])
async def get_system_metrics_endpoint(
    limit: int = 100,
    current_user: User = Depends(get_current_active_user)
):
    """Get system metrics history"""
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

@app.post("/workers/{worker_id}/restart")
async def restart_worker(worker_id: str, current_user: User = Depends(get_current_active_user)):
    """Restart a specific worker"""
    workers_data = get_workers_info()
    worker = next((w for w in workers_data if w["id"] == worker_id), None)
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    # In a real implementation, this would trigger the actual restart
    logger.info(f"Restarting worker {worker_id}")
    return {"message": f"Worker {worker_id} restart initiated"}

@app.get("/alerts", response_model=list[AlertInfo])
async def get_alerts_endpoint(
    limit: int = 50,
    current_user: User = Depends(get_current_active_user)
):
    """Get recent alerts from monitoring system"""
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
