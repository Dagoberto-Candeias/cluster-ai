"""
Shared Pydantic models for Cluster AI Dashboard API
"""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: str | None = None


class User(BaseModel):
    username: str
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    disabled: Optional[bool] = None


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
