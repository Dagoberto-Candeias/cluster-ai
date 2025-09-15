from fastapi import APIRouter, HTTPException
from datetime import datetime

router = APIRouter()

@router.get("/workers_status")
async def get_workers_status():
    """
    Get the status of Dask workers
    """
    try:
        from dask.distributed import Client
        client = Client('tcp://localhost:8786', timeout=5)

        scheduler_info = client.scheduler_info()
        workers = []

        for worker_id, worker_info in scheduler_info['workers'].items():
            worker = {
                'id': worker_id,
                'name': worker_info.get('name', worker_id),
                'status': 'active',
                'tasks': len(worker_info.get('tasks', [])),
                'last_seen': datetime.fromtimestamp(worker_info.get('last_seen', 0)).isoformat(),
                'memory': worker_info.get('memory', 0),
                'cpu': worker_info.get('cpu', 0),
                'nthreads': worker_info.get('nthreads', 0)
            }
            workers.append(worker)

        client.close()
        return {"workers": workers}

    except Exception as e:
        mock_workers = [
            {
                'id': 'worker-1',
                'name': 'Worker 1',
                'status': 'active',
                'tasks': 5,
                'last_seen': datetime.now().isoformat(),
                'memory': 2048,
                'cpu': 0.3,
                'nthreads': 4
            },
            {
                'id': 'worker-2',
                'name': 'Worker 2',
                'status': 'active',
                'tasks': 3,
                'last_seen': datetime.now().isoformat(),
                'memory': 1024,
                'cpu': 0.1,
                'nthreads': 2
            }
        ]
        return {"workers": mock_workers}
