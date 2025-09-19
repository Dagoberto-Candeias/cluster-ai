#!/usr/bin/env python3
import sys
import time
import socket
from distributed import Worker
import logging

logging.basicConfig(level=logging.INFO)

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

def start_worker(scheduler_ip, scheduler_port=8786):
    local_ip = get_local_ip()
    worker = Worker(f"tcp://{scheduler_ip}:{scheduler_port}")
    print(f"Worker started on {local_ip}, connected to {scheduler_ip}:{scheduler_port}")
    worker.start()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python worker_service.py <scheduler_ip> [scheduler_port]")
        sys.exit(1)

    scheduler_ip = sys.argv[1]
    scheduler_port = int(sys.argv[2]) if len(sys.argv) > 2 else 8786

    try:
        start_worker(scheduler_ip, scheduler_port)
    except KeyboardInterrupt:
        print("Worker stopped")
    except Exception as e:
        print(f"Error starting worker: {e}")
        sys.exit(1)
