from fastapi import APIRouter, HTTPException
import subprocess
import json
from datetime import datetime
import psutil

router = APIRouter()

@router.get("/alerts")
async def get_alerts():
    """
    Get system alerts and notifications
    """
    alerts = []

    try:
        # Check CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        if cpu_percent > 80:
            alerts.append({
                'id': 'cpu_high',
                'title': 'High CPU Usage',
                'message': f'CPU usage is at {cpu_percent:.1f}%',
                'timestamp': datetime.now().isoformat(),
                'severity': 'warning'
            })

        # Check memory usage
        memory = psutil.virtual_memory()
        if memory.percent > 85:
            alerts.append({
                'id': 'memory_high',
                'title': 'High Memory Usage',
                'message': f'Memory usage is at {memory.percent:.1f}%',
                'timestamp': datetime.now().isoformat(),
                'severity': 'warning'
            })

        # Check disk usage
        disk = psutil.disk_usage('/')
        if disk.percent > 90:
            alerts.append({
                'id': 'disk_high',
                'title': 'High Disk Usage',
                'message': f'Disk usage is at {disk.percent:.1f}%',
                'timestamp': datetime.now().isoformat(),
                'severity': 'critical'
            })

        # Check Dask status
        try:
            from dask.distributed import Client
            client = Client('tcp://localhost:8786', timeout=5)
            client.close()
        except Exception:
            alerts.append({
                'id': 'dask_down',
                'title': 'Dask Scheduler Down',
                'message': 'Dask scheduler is not responding',
                'timestamp': datetime.now().isoformat(),
                'severity': 'critical'
            })

        # Check Ollama status
        try:
            import requests
            response = requests.get('http://localhost:11434/api/tags', timeout=5)
            if response.status_code != 200:
                alerts.append({
                    'id': 'ollama_down',
                    'title': 'Ollama API Down',
                    'message': 'Ollama API is not responding',
                    'timestamp': datetime.now().isoformat(),
                    'severity': 'warning'
                })
        except Exception:
            alerts.append({
                'id': 'ollama_down',
                'title': 'Ollama API Down',
                'message': 'Ollama API is not responding',
                'timestamp': datetime.now().isoformat(),
                'severity': 'warning'
            })

        # Check OpenWebUI status
        try:
            import requests
            response = requests.get('http://localhost:3000', timeout=5)
            if response.status_code != 200:
                alerts.append({
                    'id': 'openwebui_down',
                    'title': 'OpenWebUI Down',
                    'message': 'OpenWebUI is not responding',
                    'timestamp': datetime.now().isoformat(),
                    'severity': 'warning'
                })
        except Exception:
            alerts.append({
                'id': 'openwebui_down',
                'title': 'OpenWebUI Down',
                'message': 'OpenWebUI is not responding',
                'timestamp': datetime.now().isoformat(),
                'severity': 'warning'
            })

        # If no alerts, add a success message
        if not alerts:
            alerts.append({
                'id': 'system_ok',
                'title': 'System OK',
                'message': 'All systems are operating normally',
                'timestamp': datetime.now().isoformat(),
                'severity': 'info'
            })

    except Exception as e:
        alerts.append({
            'id': 'monitoring_error',
            'title': 'Monitoring Error',
            'message': f'Error checking system status: {str(e)}',
            'timestamp': datetime.now().isoformat(),
            'severity': 'error'
        })

    return {"alerts": alerts}
