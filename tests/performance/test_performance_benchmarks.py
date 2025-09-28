"""
Performance benchmarks for Cluster AI components

This module contains performance tests and benchmarks for various
components of the Cluster AI system.
"""

import os
import sys
import time
from pathlib import Path

import psutil
import pytest

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


class TestPerformanceBenchmarks:
    """Performance benchmarks for system components"""

    def test_cpu_usage_baseline(self):
        """Test baseline CPU usage"""
        cpu_percent = psutil.cpu_percent(interval=1)
        assert cpu_percent >= 0
        assert cpu_percent <= 100

    def test_memory_usage_baseline(self):
        """Test baseline memory usage"""
        memory = psutil.virtual_memory()
        assert memory.percent >= 0
        assert memory.percent <= 100
        assert memory.used > 0
        assert memory.total > 0

    def test_disk_io_performance(self):
        """Test disk I/O performance"""
        disk_usage = psutil.disk_usage("/")
        assert disk_usage.total > 0
        assert disk_usage.used >= 0
        assert disk_usage.free >= 0

    @pytest.mark.performance
    def test_file_operations_performance(self, benchmark):
        """Benchmark file operations"""
        test_file = PROJECT_ROOT / "test_temp_file.txt"
        test_data = "x" * 1000  # 1KB of data

        def file_ops():
            # Write operation
            with open(test_file, "w") as f:
                f.write(test_data)

            # Read operation
            with open(test_file, "r") as f:
                data = f.read()

            # Cleanup
            test_file.unlink(missing_ok=True)
            return len(data)

        result = benchmark(file_ops)
        assert result == 1000

    @pytest.mark.performance
    def test_string_operations_performance(self, benchmark):
        """Benchmark string operations"""
        test_string = "test_string_" * 100

        def string_ops():
            # String concatenation
            result = ""
            for i in range(100):
                result += f"item_{i}_"

            # String search
            found = "item_50" in result

            # String split
            parts = result.split("_")

            return len(parts), found

        count, found = benchmark(string_ops)
        assert count > 0
        assert found

    @pytest.mark.performance
    def test_list_operations_performance(self, benchmark):
        """Benchmark list operations"""

        def list_ops():
            # List creation and population
            data = list(range(1000))

            # List comprehension
            squares = [x * x for x in data]

            # List filtering
            evens = [x for x in squares if x % 2 == 0]

            # List sorting
            sorted_evens = sorted(evens)

            return len(sorted_evens)

        result = benchmark(list_ops)
        assert result > 0

    @pytest.mark.performance
    def test_dict_operations_performance(self, benchmark):
        """Benchmark dictionary operations"""

        def dict_ops():
            # Dictionary creation
            data = {f"key_{i}": i * i for i in range(1000)}

            # Dictionary access
            total = sum(data.values())

            # Dictionary update
            data.update({"new_key": 9999})

            # Dictionary search
            exists = "key_500" in data

            return total, exists

        total, exists = benchmark(dict_ops)
        assert total > 0
        assert exists

    @pytest.mark.performance
    def test_math_operations_performance(self, benchmark):
        """Benchmark mathematical operations"""

        def math_ops():
            result = 0
            for i in range(10000):
                result += i * i + i / 2.0
            return result

        result = benchmark(math_ops)
        assert result > 0

    @pytest.mark.performance
    def test_regex_operations_performance(self, benchmark):
        """Benchmark regex operations"""
        import re

        test_strings = ["test123", "hello456", "world789"] * 100
        pattern = re.compile(r"\d+")

        def regex_ops():
            matches = []
            for s in test_strings:
                match = pattern.search(s)
                if match:
                    matches.append(match.group())
            return len(matches)

        result = benchmark(regex_ops)
        assert result > 0

    @pytest.mark.performance
    def test_json_operations_performance(self, benchmark):
        """Benchmark JSON operations"""
        import json

        test_data = {"key": "value", "number": 42, "list": list(range(100))}

        def json_ops():
            # Serialize
            json_str = json.dumps(test_data)

            # Deserialize
            parsed_data = json.loads(json_str)

            # Access data
            return parsed_data["number"] + len(parsed_data["list"])

        result = benchmark(json_ops)
        assert result == 142

    @pytest.mark.performance
    def test_system_call_performance(self, benchmark):
        """Benchmark system calls"""

        def system_ops():
            # Simple system calls
            result1 = os.getcwd()
            result2 = os.path.exists("/tmp")
            result3 = len(os.listdir("/tmp"))
            return len(result1), result2, result3

        length, exists, count = benchmark(system_ops)
        assert length > 0
        assert exists
        assert count >= 0


class TestResourceMonitoring:
    """Tests for resource monitoring capabilities"""

    def test_process_monitoring(self):
        """Test process monitoring"""
        current_process = psutil.Process()
        cpu_times = current_process.cpu_times()
        memory_info = current_process.memory_info()

        assert cpu_times.user >= 0
        assert memory_info.rss > 0

    def test_network_monitoring(self):
        """Test network monitoring"""
        network_stats = psutil.net_io_counters()
        assert network_stats.bytes_sent >= 0
        assert network_stats.bytes_recv >= 0

    @pytest.mark.performance
    def test_memory_allocation_performance(self, benchmark):
        """Benchmark memory allocation"""

        def memory_ops():
            # Allocate memory
            data = [0] * 10000

            # Modify data
            for i in range(len(data)):
                data[i] = i * 2

            # Sum data
            total = sum(data)

            return total

        result = benchmark(memory_ops)
        assert result > 0

    @pytest.mark.performance
    def test_context_switch_performance(self, benchmark):
        """Benchmark context switching"""

        def context_ops():
            results = []
            for i in range(1000):
                # Simulate context switch with function calls
                results.append(self._helper_function(i))
            return sum(results)

        result = benchmark(context_ops)
        assert result > 0

    def _helper_function(self, x):
        """Helper function for context switching test"""
        return x * x + 1


class TestScalabilityBenchmarks:
    """Tests for scalability under different loads"""

    @pytest.mark.performance
    def test_linear_scalability(self, benchmark):
        """Test linear scalability with increasing data size"""

        def scalability_test():
            sizes = [100, 500, 1000, 2000]
            results = []

            for size in sizes:
                data = list(range(size))
                squares = [x * x for x in data]
                results.append(sum(squares))

            return results

        result = benchmark(scalability_test)
        assert len(result) == 4
        assert all(r > 0 for r in result)

    @pytest.mark.performance
    def test_concurrent_operations(self, benchmark):
        """Test concurrent operations performance"""
        import threading

        def concurrent_ops():
            results = []
            lock = threading.Lock()

            def worker(worker_id):
                local_result = 0
                for i in range(1000):
                    local_result += i * worker_id

                with lock:
                    results.append(local_result)

            threads = []
            for i in range(4):  # 4 worker threads
                t = threading.Thread(target=worker, args=(i,))
                threads.append(t)
                t.start()

            for t in threads:
                t.join()

            return sum(results)

        result = benchmark(concurrent_ops)
        assert result > 0

    @pytest.mark.performance
    def test_io_bound_operations(self, benchmark):
        """Test I/O bound operations performance"""

        def io_ops():
            temp_files = []

            # Create multiple files
            for i in range(10):
                temp_file = PROJECT_ROOT / f"temp_test_{i}.txt"
                with open(temp_file, "w") as f:
                    f.write(f"Test data {i}\n" * 100)
                temp_files.append(temp_file)

            # Read all files
            total_content = ""
            for temp_file in temp_files:
                with open(temp_file, "r") as f:
                    total_content += f.read()

            # Cleanup
            for temp_file in temp_files:
                temp_file.unlink(missing_ok=True)

            return len(total_content)

        result = benchmark(io_ops)
        assert result > 0
