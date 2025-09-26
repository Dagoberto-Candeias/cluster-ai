"""
Testes de performance para o sistema Cluster AI
"""
import pytest
import time
import asyncio
import psutil
import os
from unittest.mock import patch, MagicMock
import threading
import concurrent.futures

class TestAPIPerformance:
    """Testes de performance da API"""

    @pytest.mark.performance
    def test_api_response_time(self):
        """Testa tempo de resposta da API"""
        from web_dashboard.backend.main_fixed import app
        from fastapi.testclient import TestClient

        client = TestClient(app)

        # Testar endpoint de saúde
        start_time = time.time()
        response = client.get("/health")
        end_time = time.time()

        response_time = end_time - start_time
        assert response.status_code == 200
        assert response_time < 0.1  # Deve responder em menos de 100ms

    @pytest.mark.performance
    def test_auth_performance(self):
        """Testa performance do sistema de autenticação"""
        from web_dashboard.backend.main_fixed import app, create_access_token
        from fastapi.testclient import TestClient

        client = TestClient(app)

        # Testar criação de token
        data = {"sub": "testuser", "scopes": ["read"]}

        start_time = time.time()
        for _ in range(100):  # Criar 100 tokens
            token = create_access_token(data=data)
        end_time = time.time()

        total_time = end_time - start_time
        avg_time = total_time / 100
        assert avg_time < 0.01  # Menos de 10ms por token

    @pytest.mark.performance
    def test_workers_endpoint_performance(self):
        """Testa performance do endpoint de workers"""
        from web_dashboard.backend.main_fixed import app
        from fastapi.testclient import TestClient

        client = TestClient(app)

        # Simular autenticação
        token = "fake_token_for_testing"

        # Testar GET /workers com cache
        start_time = time.time()
        for _ in range(50):
            with patch('web_dashboard.backend.main_fixed.get_current_user') as mock_user:
                mock_user.return_value = MagicMock(username="admin")
                response = client.get("/workers", headers={"Authorization": f"Bearer {token}"})
        end_time = time.time()

        total_time = end_time - start_time
        avg_time = total_time / 50
        assert avg_time < 0.05  # Menos de 50ms por requisição

class TestSystemPerformance:
    """Testes de performance do sistema"""

    @pytest.mark.performance
    def test_memory_usage_baseline(self):
        """Testa uso de memória baseline"""
        process = psutil.Process()
        memory_before = process.memory_info().rss / 1024 / 1024  # MB

        # Fazer algumas operações
        for _ in range(1000):
            _ = list(range(100))

        memory_after = process.memory_info().rss / 1024 / 1024  # MB
        memory_delta = memory_after - memory_before

        assert memory_delta < 50  # Menos de 50MB de aumento

    @pytest.mark.performance
    def test_cpu_usage_during_operations(self):
        """Testa uso de CPU durante operações"""
        cpu_before = psutil.cpu_percent(interval=1)

        # Simular operações CPU-intensivas
        def cpu_intensive_task():
            for _ in range(100000):
                _ = _ ** 2

        threads = []
        for _ in range(4):  # 4 threads
            t = threading.Thread(target=cpu_intensive_task)
            threads.append(t)
            t.start()

        for t in threads:
            t.join()

        cpu_after = psutil.cpu_percent(interval=1)

        # CPU deve aumentar, mas não deve ser excessivo
        assert cpu_after > cpu_before
        assert cpu_after < 95  # Menos de 95% uso

class TestConcurrentPerformance:
    """Testes de performance concorrente"""

    @pytest.mark.performance
    @pytest.mark.asyncio
    async def test_concurrent_api_calls(self):
        """Testa chamadas API concorrentes"""
        from web_dashboard.backend.main_fixed import app
        from fastapi.testclient import TestClient
        import asyncio

        client = TestClient(app)

        async def make_request(request_id):
            with patch('web_dashboard.backend.main_fixed.get_current_user') as mock_user:
                mock_user.return_value = MagicMock(username="admin")
                start_time = time.time()
                response = client.get("/workers", headers={"Authorization": "Bearer fake_token"})
                end_time = time.time()
                return end_time - start_time

        # Fazer 20 requisições concorrentes
        tasks = [make_request(i) for i in range(20)]
        response_times = await asyncio.gather(*tasks)

        avg_response_time = sum(response_times) / len(response_times)
        max_response_time = max(response_times)

        assert avg_response_time < 0.1  # Média < 100ms
        assert max_response_time < 0.5  # Máximo < 500ms

    @pytest.mark.performance
    def test_thread_pool_performance(self):
        """Testa performance do pool de threads"""
        def worker_task(task_id):
            time.sleep(0.01)  # Simular trabalho
            return f"Task {task_id} completed"

        start_time = time.time()

        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(worker_task, i) for i in range(100)]
            results = [future.result() for future in concurrent.futures.as_completed(futures)]

        end_time = time.time()
        total_time = end_time - start_time

        assert len(results) == 100
        assert total_time < 2.0  # Deve completar em menos de 2 segundos

class TestCachePerformance:
    """Testes de performance do sistema de cache"""

    @pytest.mark.performance
    def test_cache_hit_performance(self):
        """Testa performance de cache hit"""
        from web_dashboard.backend.main_fixed import cache_manager

        # Simular cache hit
        cache_manager.set("test_key", "test_value", ttl=300)

        start_time = time.time()
        for _ in range(1000):
            value = cache_manager.get("test_key")
            assert value == "test_value"
        end_time = time.time()

        total_time = end_time - start_time
        avg_time = total_time / 1000

        assert avg_time < 0.001  # Menos de 1ms por acesso ao cache

    @pytest.mark.performance
    def test_cache_miss_performance(self):
        """Testa performance de cache miss"""
        from web_dashboard.backend.main_fixed import cache_manager

        start_time = time.time()
        for _ in range(1000):
            value = cache_manager.get("nonexistent_key")
            assert value is None
        end_time = time.time()

        total_time = end_time - start_time
        avg_time = total_time / 1000

        assert avg_time < 0.001  # Menos de 1ms mesmo para miss

class TestDatabasePerformance:
    """Testes de performance do banco de dados"""

    @pytest.mark.performance
    def test_database_connection_pool(self):
        """Testa pool de conexões do banco"""
        from web_dashboard.backend.main_fixed import SessionLocal

        start_time = time.time()

        # Criar múltiplas conexões
        sessions = []
        for _ in range(50):
            db = SessionLocal()
            sessions.append(db)

        # Fechar conexões
        for db in sessions:
            db.close()

        end_time = time.time()
        total_time = end_time - start_time

        assert total_time < 1.0  # Menos de 1 segundo para 50 conexões

class TestResourceOptimization:
    """Testes de otimização de recursos"""

    @pytest.mark.performance
    def test_memory_efficient_processing(self):
        """Testa processamento eficiente de memória"""
        # Simular processamento de dados grandes
        data = list(range(1000000))  # 1M elementos

        start_time = time.time()
        start_memory = psutil.Process().memory_info().rss / 1024 / 1024

        # Processar dados em chunks
        chunk_size = 10000
        results = []
        for i in range(0, len(data), chunk_size):
            chunk = data[i:i + chunk_size]
            processed_chunk = [x * 2 for x in chunk]
            results.extend(processed_chunk)
            del chunk, processed_chunk  # Liberar memória

        end_time = time.time()
        end_memory = psutil.Process().memory_info().rss / 1024 / 1024

        memory_delta = end_memory - start_memory
        processing_time = end_time - start_time

        assert len(results) == 1000000
        assert memory_delta < 100  # Menos de 100MB adicional
        assert processing_time < 5.0  # Menos de 5 segundos

    @pytest.mark.performance
    def test_gzip_compression_performance(self):
        """Testa performance da compressão GZip"""
        from web_dashboard.backend.main_fixed import app
        from fastapi.testclient import TestClient

        client = TestClient(app)

        # Criar resposta grande
        large_data = {"data": ["item"] * 10000}

        start_time = time.time()
        response = client.post("/settings", json=large_data,
                              headers={"Authorization": "Bearer fake_token"})
        end_time = time.time()

        response_time = end_time - start_time

        # Verificar se compressão está funcionando (resposta deve ser rápida)
        assert response_time < 0.5  # Menos de 500ms mesmo com dados grandes

if __name__ == '__main__':
    pytest.main([__file__, "-m", "performance"])
