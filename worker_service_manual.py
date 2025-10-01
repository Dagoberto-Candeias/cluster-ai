#!/usr/bin/env python3
import sys
import asyncio
import signal
import socket
from distributed import Worker
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"


async def start_worker_async(scheduler_ip, scheduler_port=8786):
    """Start worker asynchronously"""
    local_ip = get_local_ip()
    logger.info(
        f"Worker starting on {local_ip}, connecting to {scheduler_ip}:{scheduler_port}"
    )

    try:
        # Create worker
        worker = Worker(f"tcp://{scheduler_ip}:{scheduler_port}")

        # Start the worker
        await worker.start()

        logger.info(
            f"✅ Worker successfully started and connected to {scheduler_ip}:{scheduler_port}"
        )

        # Keep the worker running
        while True:
            await asyncio.sleep(1)

    except Exception as e:
        logger.error(f"Error in worker: {e}")
        raise


def signal_handler(signum, frame):
    """Handle shutdown signals"""
    logger.info(f"Received signal {signum}, shutting down worker...")
    sys.exit(0)


async def main():
    if len(sys.argv) < 2:
        print("Usage: python worker_service.py <scheduler_ip> [scheduler_port]")
        sys.exit(1)

    scheduler_ip = sys.argv[1]
    scheduler_port = int(sys.argv[2]) if len(sys.argv) > 2 else 8786

    # Setup signal handlers for graceful shutdown
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    try:
        await start_worker_async(scheduler_ip, scheduler_port)
    except KeyboardInterrupt:
        logger.info("Worker stopped by user")
    except Exception as e:
        logger.error(f"Error starting worker: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
