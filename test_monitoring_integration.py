#!/usr/bin/env python3
"""
Test script to verify the monitoring integration works correctly
"""

import sys
import os
sys.path.append('web-dashboard/backend')

from monitoring_data_provider import get_cluster_metrics, get_system_metrics, get_alerts, get_workers_info

def test_monitoring_functions():
    """Test all monitoring data provider functions"""
    print("🧪 Testing Monitoring Integration")
    print("=" * 50)

    # Test cluster metrics
    print("\n1. Testing cluster metrics...")
    try:
        cluster_data = get_cluster_metrics()
        print(f"✅ Cluster metrics: {len(cluster_data)} fields")
        print(f"   - Ollama running: {cluster_data.get('ollama_running', 'N/A')}")
        print(f"   - Dask running: {cluster_data.get('dask_running', 'N/A')}")
        print(f"   - WebUI running: {cluster_data.get('webui_running', 'N/A')}")
    except Exception as e:
        print(f"❌ Cluster metrics failed: {e}")

    # Test system metrics
    print("\n2. Testing system metrics...")
    try:
        system_metrics = get_system_metrics()
        print(f"✅ System metrics: {len(system_metrics)} entries")
        if system_metrics:
            latest = system_metrics[-1]
            print(f"   - Latest CPU: {latest.get('cpu_percent', 'N/A')}%")
            print(f"   - Latest Memory: {latest.get('memory_percent', 'N/A')}%")
    except Exception as e:
        print(f"❌ System metrics failed: {e}")

    # Test alerts
    print("\n3. Testing alerts...")
    try:
        alerts = get_alerts()
        print(f"✅ Alerts: {len(alerts)} entries")
        if alerts:
            print(f"   - Latest alert: {alerts[-1][:100]}...")
    except Exception as e:
        print(f"❌ Alerts failed: {e}")

    # Test workers info
    print("\n4. Testing workers info...")
    try:
        workers = get_workers_info()
        print(f"✅ Workers: {len(workers)} workers")
        if workers:
            worker = workers[0]
            print(f"   - Sample worker: {worker.get('name', 'N/A')} ({worker.get('status', 'N/A')})")
    except Exception as e:
        print(f"❌ Workers info failed: {e}")

    print("\n" + "=" * 50)
    print("🎉 Monitoring integration test completed!")

if __name__ == "__main__":
    test_monitoring_functions()
