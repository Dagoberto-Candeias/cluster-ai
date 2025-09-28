"""
Mock monitoring data provider for Cluster AI demo
Provides simulated metrics, alerts, and worker information
"""

import random
import time
from datetime import datetime, timedelta

import psutil


def get_system_metrics():
    """Get simulated system metrics history"""
    metrics = []
    now = datetime.now()

    # Generate 100 data points over the last hour
    for i in range(100):
        timestamp = now - timedelta(minutes=i)
        cpu = random.uniform(10, 80)
        memory = random.uniform(20, 70)
        disk = random.uniform(15, 50)
        network_rx = random.uniform(500, 2000)

        metrics.append(
            {
                "timestamp": timestamp.timestamp(),
                "cpu_percent": cpu,
                "memory_percent": memory,
                "disk_percent": disk,
                "network_rx": network_rx,
                "network_tx": network_rx * 0.8,  # Simulate TX as 80% of RX
            }
        )

    return metrics


def get_cluster_metrics():
    """Get simulated cluster status"""
    cpu_percent = psutil.cpu_percent(interval=0.1)
    memory = psutil.virtual_memory()

    return {
        "total_workers": 2,
        "active_workers": 2,
        "total_cpu": cpu_percent,
        "total_memory": memory.percent,
        "status": "healthy",
        "ollama_running": True,
        "dask_running": True,
        "webui_running": True,
        "dask_tasks_completed": random.randint(100, 500),
        "dask_tasks_failed": random.randint(0, 5),
        "dask_tasks_pending": random.randint(10, 50),
        "dask_tasks_processing": random.randint(5, 20),
        "dask_task_throughput": round(random.uniform(10, 50), 2),
        "dask_avg_task_time": round(random.uniform(1.5, 5.0), 2),
    }


def get_alerts():
    """Get simulated alerts"""
    alerts = [
        f"[{datetime.now().isoformat()}] [INFO] [SYSTEM] Cluster health check passed",
        f"[{ (datetime.now() - timedelta(minutes=5)).isoformat() }] [WARNING] [DASK] Worker load increased to 75%",
        f"[{ (datetime.now() - timedelta(hours=1)).isoformat() }] [INFO] [OLLAMA] Model inference completed successfully",
        f"[{ (datetime.now() - timedelta(hours=2)).isoformat() }] [CRITICAL] [MEMORY] High memory usage detected - 85%",
    ]
    return alerts


def get_workers_info():
    """Get simulated workers information"""
    now = datetime.now()
    workers = [
        {
            "id": "worker-001",
            "name": "Worker Node 1",
            "status": "active",
            "ip_address": "192.168.1.101",
            "cpu_usage": round(random.uniform(20, 60), 1),
            "memory_usage": round(random.uniform(30, 70), 1),
            "last_seen": now,
        },
        {
            "id": "worker-002",
            "name": "Worker Node 2",
            "status": "active" if random.random() > 0.1 else "maintenance",
            "ip_address": "192.168.1.102",
            "cpu_usage": round(random.uniform(15, 50), 1),
            "memory_usage": round(random.uniform(40, 80), 1),
            "last_seen": now - timedelta(minutes=random.randint(0, 10)),
        },
    ]
    return workers
