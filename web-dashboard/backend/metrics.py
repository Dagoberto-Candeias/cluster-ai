"""
Metrics router for Cluster AI Dashboard API
Provides additional metrics endpoints
"""

from datetime import datetime, timedelta
from typing import Any, Dict, List

from dependencies import (
    ALGORITHM,
    SECRET_KEY,
    get_current_active_user,
    get_db,
    pwd_context,
)
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from models import User

router = APIRouter(prefix="/metrics", tags=["metrics"])


# Additional metrics endpoints
@router.get("/performance")
async def get_performance_metrics(
    current_user: User = Depends(get_current_active_user),
):
    """Get performance metrics for the cluster"""
    from monitoring_data_provider import get_cluster_metrics, get_system_metrics

    cluster = get_cluster_metrics()
    system = get_system_metrics()[-1] if get_system_metrics() else {}

    return {
        "timestamp": datetime.now().isoformat(),
        "cluster_performance": {
            "throughput": cluster.get("dask_task_throughput", 0),
            "avg_task_time": cluster.get("dask_avg_task_time", 0),
            "tasks_completed": cluster.get("dask_tasks_completed", 0),
            "tasks_failed": cluster.get("dask_tasks_failed", 0),
            "error_rate": round(
                cluster.get("dask_tasks_failed", 0)
                / max(1, cluster.get("dask_tasks_completed", 1))
                * 100,
                2,
            ),
        },
        "system_performance": {
            "cpu_load": system.get("cpu_percent", 0),
            "memory_load": system.get("memory_percent", 0),
            "disk_load": system.get("disk_percent", 0),
            "network_iops": {
                "rx": system.get("network_rx", 0),
                "tx": system.get("network_tx", 0),
            },
        },
        "health_score": 85.5,  # Simulated health score
    }


@router.get("/trends")
async def get_metric_trends(
    days: int = 7, current_user: User = Depends(get_current_active_user)
):
    """Get trend data for the last N days"""
    from monitoring_data_provider import get_system_metrics

    metrics = get_system_metrics()
    trends = {"cpu_trend": [], "memory_trend": [], "disk_trend": [], "timestamp": []}

    # Simulate trend data
    now = datetime.now()
    for i in range(days):
        day_metrics = {
            "cpu_avg": 45.0 + (i * 2),
            "memory_avg": 60.0 + i,
            "disk_avg": 30.0 + (i * 0.5),
        }
        trends["cpu_trend"].append(day_metrics["cpu_avg"])
        trends["memory_trend"].append(day_metrics["memory_avg"])
        trends["disk_trend"].append(day_metrics["disk_avg"])
        trends["timestamp"].append((now - timedelta(days=i)).isoformat())

    return trends


@router.get("/anomalies")
async def get_anomalies(current_user: User = Depends(get_current_active_user)):
    """Get detected anomalies in the system"""
    # Simulate anomaly detection
    anomalies = [
        {
            "id": "anom-001",
            "timestamp": datetime.now().isoformat(),
            "type": "cpu_spike",
            "severity": "warning",
            "description": "Unusual CPU spike detected on worker-001",
            "affected_components": ["worker-001", "dask"],
            "resolved": False,
        },
        {
            "id": "anom-002",
            "timestamp": (datetime.now() - timedelta(hours=3)).isoformat(),
            "type": "memory_leak",
            "severity": "critical",
            "description": "Potential memory leak in Ollama service",
            "affected_components": ["ollama"],
            "resolved": True,
        },
    ]

    return {
        "anomalies": anomalies,
        "total_detected": len(anomalies),
        "unresolved": len([a for a in anomalies if not a["resolved"]]),
        "detection_method": "ML-based anomaly detection",
    }
