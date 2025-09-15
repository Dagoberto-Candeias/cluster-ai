from fastapi import FastAPI
import psutil
import subprocess
import json

app = FastAPI()

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
    # Placeholder for GPU info, can be expanded for AMD/NVIDIA detection
    try:
        import torch
        if torch.cuda.is_available():
            gpu_name = torch.cuda.get_device_name(0)
            return {"available": True, "name": gpu_name}
        else:
            return {"available": False, "name": None}
    except ImportError:
        return {"available": False, "name": None}

@app.get("/api/system_metrics")
def system_metrics():
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    dask_status = get_dask_status()
    gpu_info = get_gpu_info()

    return {
        "cpu_percent": cpu_percent,
        "memory_percent": memory.percent,
        "memory_available_gb": round(memory.available / (1024**3), 2),
        "disk_percent": disk.percent,
        "disk_free_gb": round(disk.free / (1024**3), 2),
        "dask_status": dask_status,
        "gpu_info": gpu_info
    }
