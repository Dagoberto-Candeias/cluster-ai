"""
Performance tests for Cluster AI

This module contains performance tests to ensure the system
maintains good performance under various conditions.
"""

import os
import time
from pathlib import Path

import psutil
import pytest
import gc

PROJECT_ROOT = Path(__file__).parent.parent.parent


class TestPerformance:
    """Performance test suite"""

    def test_script_execution_time(self):
        """Test that critical scripts execute within acceptable time"""
        import subprocess

        scripts_to_test = [
            ("scripts/auto_init_project.sh", 30),  # 30 seconds max
            ("scripts/health_check.sh", 10),  # 10 seconds max
        ]

        for script, max_time in scripts_to_test:
            script_path = PROJECT_ROOT / script
            if script_path.exists():
                start_time = time.time()
                try:
                    with subprocess.Popen(
                        [str(script_path)],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        text=True,
                    ) as proc:
                        try:
                            stdout, stderr = proc.communicate(timeout=max_time + 5)
                            execution_time = time.time() - start_time

                            assert (
                                execution_time < max_time
                            ), f"Script {script} took {execution_time:.2f}s (max {max_time}s)"
                            assert (
                                proc.returncode == 0
                            ), f"Script {script} failed with return code {proc.returncode}"

                        except subprocess.TimeoutExpired:
                            proc.kill()
                            pytest.fail(f"Script {script} timed out after {max_time}s")
                except FileNotFoundError:
                    pytest.skip(f"Script {script} not found")
            else:
                pytest.skip(f"Script {script} does not exist")

    @pytest.mark.memory
    def test_memory_usage(self):
        """Test memory usage stays within limits"""
        # Coletar garbage múltiplas vezes antes da medição para reduzir flutuações
        for _ in range(3):
            gc.collect()

        # Pequena pausa para estabilizar medições
        time.sleep(0.1)

        process = psutil.Process(os.getpid())
        memory_mb = process.memory_info().rss / 1024 / 1024

        # Limite aumentado para 800MB devido ao carregamento de muitos módulos nos testes
        limit_mb = int(os.getenv("CLUSTER_AI_TEST_MEMORY_LIMIT", "800"))

        # Log da medição para debugging
        print(f"Current memory usage: {memory_mb:.1f}MB (limit: {limit_mb}MB)")

        assert memory_mb < limit_mb, f"Memory usage too high: {memory_mb:.1f}MB (limit {limit_mb}MB)"

        # Limpeza adicional após teste
        gc.collect()

    def test_cpu_usage(self):
        """Test CPU usage during operations"""
        # Get initial CPU usage
        initial_cpu = psutil.cpu_percent(interval=1)

        # Perform some operations
        for i in range(1000):
            _ = i * i

        # Check CPU usage after operations
        final_cpu = psutil.cpu_percent(interval=1)

        # CPU usage should not exceed 80%
        assert final_cpu < 80, f"CPU usage too high: {final_cpu}%"

    def test_file_operations_performance(self):
        """Test file operations performance"""
        test_file = PROJECT_ROOT / "test_performance.tmp"

        # Test write performance
        start_time = time.time()
        data = "test data\n" * 1000
        test_file.write_text(data)
        write_time = time.time() - start_time

        # Test read performance
        start_time = time.time()
        read_data = test_file.read_text()
        read_time = time.time() - start_time

        # Cleanup
        test_file.unlink(missing_ok=True)

        # Assert reasonable performance (less than 1 second each)
        assert write_time < 1.0, f"Write too slow: {write_time:.3f}s"
        assert read_time < 1.0, f"Read too slow: {read_time:.3f}s"
        assert read_data == data, "Data integrity check failed"

    def test_import_performance(self):
        """Test module import performance"""
        modules_to_test = ["os", "sys", "pathlib", "json", "subprocess"]

        for module in modules_to_test:
            start_time = time.time()
            __import__(module)
            import_time = time.time() - start_time

            # Import should be fast (less than 0.1s)
            assert import_time < 0.1, f"Import {module} too slow: {import_time:.3f}s"

    @pytest.mark.slow
    def test_concurrent_operations(self):
        """Test performance under concurrent operations"""
        import threading

        results = []
        errors = []

        def worker_task(task_id):
            try:
                # Simulate some work
                time.sleep(0.1)
                results.append(f"Task {task_id} completed")
            except Exception as e:
                errors.append(f"Task {task_id} failed: {e}")

        # Start multiple threads
        threads = []
        for i in range(10):
            t = threading.Thread(target=worker_task, args=(i,))
            threads.append(t)
            t.start()

        # Wait for all threads
        for t in threads:
            t.join(timeout=5)

        # Check results
        assert len(results) == 10, f"Expected 10 results, got {len(results)}"
        assert len(errors) == 0, f"Errors occurred: {errors}"

    def test_large_data_handling(self):
        """Test handling of large data structures"""
        # Create large list
        large_list = list(range(100000))

        start_time = time.time()
        # Perform operations on large data
        result = sum(large_list)
        operation_time = time.time() - start_time

        expected_sum = 4999950000  # sum of 0 to 99999
        assert result == expected_sum, "Large data operation failed"
        assert (
            operation_time < 1.0
        ), f"Large data operation too slow: {operation_time:.3f}s"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
