#!/usr/bin/env python3
"""
Cluster AI Web Demo Launcher

This script launches the Cluster AI web dashboard demo locally.
It starts the backend (FastAPI) and frontend (React/Vite) servers,
then opens the web interface in the default browser.

Requirements:
- Python 3.8+ with dependencies installed (pip install -r requirements.txt)
- Node.js and npm for the frontend
- SECRET_KEY environment variable (auto-generated if not set)

Usage:
    python web_demo.py

The demo will be available at:
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000

Press Ctrl+C to stop the demo.
"""

import os
import sys
import time
import subprocess
import webbrowser
import signal
import secrets
from pathlib import Path

def check_requirements():
    """Check if required tools are available"""
    print("🔍 Checking requirements...")

    # Check Python
    if sys.version_info < (3, 8):
        print("❌ Python 3.8+ required")
        return False

    # Check if backend directory exists
    backend_dir = Path("web-dashboard/backend")
    if not backend_dir.exists():
        print("❌ Backend directory not found")
        return False

    # Check if frontend directory exists
    frontend_dir = Path("web-dashboard/frontend")
    if not frontend_dir.exists():
        print("❌ Frontend directory not found")
        return False

    # Check if npm is available
    try:
        subprocess.run(["npm", "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ npm not found. Please install Node.js and npm.")
        return False

    print("✅ Requirements check passed")
    return True

def setup_environment():
    """Setup environment variables"""
    print("🔧 Setting up environment...")

    # Set SECRET_KEY if not set
    if not os.getenv("SECRET_KEY"):
        secret_key = secrets.token_urlsafe(32)
        os.environ["SECRET_KEY"] = secret_key
        print(f"🔑 Generated SECRET_KEY: {secret_key[:16]}...")

    # Set other env vars if needed
    os.environ.setdefault("DATABASE_URL", "sqlite:///./users.db")

def start_backend():
    """Start the FastAPI backend server"""
    print("🚀 Starting backend server...")

    backend_dir = Path("web-dashboard/backend")
    cmd = [sys.executable, "main_fixed.py"]

    try:
        process = subprocess.Popen(
            cmd,
            cwd=backend_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        print("✅ Backend server started on http://localhost:8000")
        return process
    except Exception as e:
        print(f"❌ Failed to start backend: {e}")
        return None

def start_frontend():
    """Start the React frontend development server"""
    print("🎨 Starting frontend server...")

    frontend_dir = Path("web-dashboard/frontend")
    cmd = ["npm", "run", "dev"]

    try:
        process = subprocess.Popen(
            cmd,
            cwd=frontend_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        print("✅ Frontend server started on http://localhost:3000")
        return process
    except Exception as e:
        print(f"❌ Failed to start frontend: {e}")
        return None

def wait_for_servers(backend_process, frontend_process, timeout=30):
    """Wait for servers to be ready"""
    print("⏳ Waiting for servers to be ready...")

    start_time = time.time()
    backend_ready = False
    frontend_ready = False

    while time.time() - start_time < timeout:
        if not backend_ready and backend_process.poll() is None:
            # Check if backend is responding
            try:
                import requests
                response = requests.get("http://localhost:8000/health", timeout=1)
                if response.status_code == 200:
                    backend_ready = True
                    print("✅ Backend is ready")
            except:
                pass

        if not frontend_ready and frontend_process.poll() is None:
            # Check if frontend is responding
            try:
                import requests
                response = requests.get("http://localhost:3000", timeout=1)
                if response.status_code == 200:
                    frontend_ready = True
                    print("✅ Frontend is ready")
            except:
                pass

        if backend_ready and frontend_ready:
            break

        time.sleep(1)

    if not backend_ready:
        print("⚠️  Backend may not be ready yet")
    if not frontend_ready:
        print("⚠️  Frontend may not be ready yet")

def open_browser():
    """Open the web demo in the default browser"""
    print("🌐 Opening web demo in browser...")
    try:
        webbrowser.open("http://localhost:3000")
        print("✅ Browser opened to http://localhost:3000")
    except Exception as e:
        print(f"⚠️  Could not open browser: {e}")
        print("Please manually open http://localhost:3000")

def cleanup_processes(processes):
    """Clean up running processes"""
    print("🧹 Cleaning up processes...")
    for process in processes:
        if process and process.poll() is None:
            try:
                process.terminate()
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
    print("✅ Cleanup complete")

def main():
    """Main demo launcher function"""
    print("🎯 Cluster AI Web Demo Launcher")
    print("=" * 40)

    # Check requirements
    if not check_requirements():
        sys.exit(1)

    # Setup environment
    setup_environment()

    processes = []

    try:
        # Start backend
        backend_process = start_backend()
        if not backend_process:
            sys.exit(1)
        processes.append(backend_process)

        # Give backend a moment to start
        time.sleep(2)

        # Start frontend
        frontend_process = start_frontend()
        if not frontend_process:
            cleanup_processes(processes)
            sys.exit(1)
        processes.append(frontend_process)

        # Wait for servers
        wait_for_servers(backend_process, frontend_process)

        # Open browser
        open_browser()

        print("\n🎉 Cluster AI Web Demo is running!")
        print("📊 Dashboard: http://localhost:3000")
        print("🔗 API Docs: http://localhost:8000/docs")
        print("\n💡 Features to explore:")
        print("   - Login with admin/admin123")
        print("   - View cluster status and metrics")
        print("   - Monitor workers and system health")
        print("   - Check alerts and logs")
        print("\nPress Ctrl+C to stop the demo")

        # Wait for user interrupt
        try:
            while True:
                time.sleep(1)
                # Check if processes are still running
                for process in processes:
                    if process.poll() is not None:
                        print(f"⚠️  Process {process.pid} exited")
                        raise KeyboardInterrupt()
        except KeyboardInterrupt:
            print("\n🛑 Stopping demo...")

    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        cleanup_processes(processes)

    print("👋 Demo stopped. Thank you for trying Cluster AI!")

if __name__ == "__main__":
    main()
