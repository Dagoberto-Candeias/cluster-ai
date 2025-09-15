from fastapi import APIRouter, Query
import psutil
import subprocess
import json
import time
from datetime import datetime, timedelta
from typing import List, Optional
import os

router = APIRouter()

# In-memory storage for metrics (in production, use a database)
metrics_store = []

def get_dask_status():
    try:
        result = subprocess.run(['ss', '-tlnp'], capture_output=True, text=True)
        if ':8786' in result.stdout:
            return "active"
        else:
            return "inactive"
    except Exception:
        return "unknown"

def get_gpu_info():
    try:
        import torch
        if torch.cuda.is_available():
            gpu_name = torch.cuda.get_device_name(0)
            return {"available": True, "name": gpu_name}
        else:
            return {"available": False, "name": None}
    except ImportError:
        return {"available": False, "name": None}

def collect_system_metrics():
    """Collect current system metrics"""
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')

    # Network stats (basic)
    net_io = psutil.net_io_counters()
    network_rx = net_io.bytes_recv
    network_tx = net_io.bytes_sent

    metrics = {
        "timestamp": datetime.now().isoformat(),
        "cpu_percent": cpu_percent,
        "memory_percent": memory.percent,
        "memory_available_gb": round(memory.available / (1024**3), 2),
        "disk_percent": disk.percent,
        "disk_free_gb": round(disk.free / (1024**3), 2),
        "network_rx": network_rx,
        "network_tx": network_tx,
        "dask_status": get_dask_status(),
        "gpu_info": get_gpu_info()
    }

    # Store metrics (keep last 1000 entries)
    global metrics_store
    metrics_store.append(metrics)
    if len(metrics_store) > 1000:
        metrics_store = metrics_store[-1000:]

    return metrics

@router.get("/api/metrics/system")
def get_system_metrics(limit: int = Query(50, ge=1, le=100)):
    """Get historical system metrics"""
    global metrics_store

    # If no metrics collected yet, collect some
    if len(metrics_store) == 0:
        for _ in range(min(limit, 10)):
            collect_system_metrics()
            time.sleep(0.1)  # Small delay between collections

    # Return the most recent metrics
    recent_metrics = metrics_store[-limit:] if len(metrics_store) >= limit else metrics_store

    return recent_metrics

@router.get("/api/metrics/system/current")
def get_current_system_metrics():
    """Get current system metrics"""
    return collect_system_metrics()

@router.post("/api/metrics/system/collect")
def trigger_metrics_collection():
    """Manually trigger metrics collection"""
    metrics = collect_system_metrics()
    return {"status": "collected", "timestamp": metrics["timestamp"]}

# Auto-collect metrics every 30 seconds
def start_metrics_collection():
    """Start background metrics collection"""
    import threading

    def collect_loop():
        while True:
            try:
                collect_system_metrics()
            except Exception as e:
                print(f"Error collecting metrics: {e}")
            time.sleep(30)  # Collect every 30 seconds

    thread = threading.Thread(target=collect_loop, daemon=True)
    thread.start()
    print("Metrics collection started")

# Initialize metrics collection when module is imported
start_metrics_collection()
