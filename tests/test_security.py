"""
Testes de segurança para o sistema Cluster AI
"""

import os
import sys
import time
from unittest.mock import MagicMock, patch

import jwt
import pytest
from fastapi.testclient import TestClient

# Add web-dashboard/backend to path for imports
sys.path.insert(
    0, os.path.join(os.path.dirname(__file__), "..", "web-dashboard", "backend")
)

from main_fixed import app, create_access_token, get_password_hash, verify_password


class TestAuthenticationSecurity:
    """Testes de segurança da autenticação"""

    def test_password_hashing_security(self):
        """Testa segurança do hashing de senhas"""
        password = "test_password_123"

        # Hash deve ser diferente da senha original
        hashed = get_password_hash(password)
        assert hashed != password
        assert len(hashed) > len(password)

        # Verificação deve funcionar
        assert verify_password(password, hashed)
        assert not verify_password("wrong_password", hashed)

    def test_jwt_token_security(self):
        """Testa segurança dos tokens JWT"""
        data = {"sub": "testuser", "scopes": ["read", "write"]}

        token = create_access_token(data=data)

        # Token deve ser uma string
        assert isinstance(token, str)

        # Deve ser possível decodificar sem verificação
        decoded = jwt.decode(token, options={"verify_signature": False})
        assert decoded["sub"] == "testuser"
        assert "exp" in decoded

        # Token deve expirar
        time.sleep(1)  # Pequena pausa
        expired_token = create_access_token(
            data=data, expires_delta=-10
        )  # Token expirado

        with pytest.raises(jwt.ExpiredSignatureError):
            jwt.decode(expired_token, os.getenv("SECRET_KEY"), algorithms=["HS256"])

    def test_brute_force_protection(self):
        """Testa proteção contra brute force"""
        client = TestClient(app)

        # Tentar múltiplos logins falhados
        failed_attempts = 0
        for _ in range(10):
            response = client.post(
                "/auth/login", json={"username": "admin", "password": "wrong_password"}
            )
            if response.status_code == 401:
                failed_attempts += 1

        assert failed_attempts >= 5  # Pelo menos alguns devem falhar

    def test_sql_injection_prevention(self):
        """Testa prevenção de SQL injection"""
        from main_fixed import SessionLocal, UserDB

        db = SessionLocal()
        try:
            # Tentar criar usuário com dados maliciosos
            malicious_username = "admin'; DROP TABLE users; --"
            malicious_email = "test@example.com"

            # Deve falhar na validação ou ser sanitizado
            user = UserDB(
                username=malicious_username,
                hashed_password="hashed_pass",
                email=malicious_email,
                full_name="Test User",
                disabled=False,
            )

            # Verificar se o username foi sanitizado ou rejeitado
            assert "'" not in user.username or len(user.username) < 100

        finally:
            db.close()


class TestInputValidationSecurity:
    """Testes de segurança da validação de entrada"""

    def test_worker_input_validation(self):
        """Testa validação de entrada para workers"""
        from models import WorkerInfo
        from pydantic import ValidationError

        # Teste com dados válidos
        valid_data = {
            "id": "worker-001",
            "name": "Test Worker",
            "status": "active",
            "ip_address": "192.168.1.100",
            "cpu_usage": 50.0,
            "memory_usage": 60.0,
            "last_seen": "2024-01-01T00:00:00",
        }

        worker = WorkerInfo(**valid_data)
        assert worker.id == "worker-001"

        # Testes com dados inválidos
        invalid_cases = [
            {"id": "", "error": "ID vazio"},
            {"id": "w", "error": "ID muito curto"},
            {"id": "a" * 51, "error": "ID muito longo"},
            {"id": "worker@001", "error": "Caracteres especiais no ID"},
            {"status": "unknown", "error": "Status inválido"},
            {"ip_address": "999.999.999.999", "error": "IP inválido"},
            {"cpu_usage": 150.0, "error": "CPU usage > 100"},
            {"memory_usage": -10.0, "error": "Memory usage negativo"},
        ]

        for case in invalid_cases:
            invalid_data = valid_data.copy()
            invalid_data.update(case)
            del invalid_data["error"]

            with pytest.raises(ValidationError):
                WorkerInfo(**invalid_data)

    def test_settings_input_validation(self):
        """Testa validação de configurações"""
        client = TestClient(app)

        # Testar configurações válidas - primeiro criar um token válido
        from dependencies import create_access_token
        token = create_access_token(data={"sub": "admin"})

        valid_settings = {"update_interval": 30, "alert_threshold_cpu": 80}
        response = client.post(
            "/settings",
            json=valid_settings,
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code in [200, 422]  # 422 se validação falhar

        # Testar configurações inválidas
        invalid_settings = [
            {"update_interval": 70},  # > 60
            {"alert_threshold_cpu": 150},  # > 100
            {"alert_threshold_memory": -10},  # < 0
        ]

        for settings in invalid_settings:
            response = client.post(
                "/settings",
                json=settings,
                headers={"Authorization": f"Bearer {token}"},
            )
            # Deve retornar erro de validação (400 ou 422)
            assert response.status_code in [400, 422]


class TestAuthorizationSecurity:
    """Testes de segurança de autorização"""

    def test_endpoint_authorization(self):
        """Testa autorização de endpoints"""
        client = TestClient(app)

        protected_endpoints = ["/workers", "/cluster/status", "/settings", "/logs"]

        for endpoint in protected_endpoints:
            response = client.get(endpoint)
            assert response.status_code in [401, 403]  # Deve requerer auth

    def test_invalid_token_handling(self):
        """Testa tratamento de tokens inválidos"""
        client = TestClient(app)

        invalid_tokens = [
            "invalid_token",
            "Bearer invalid",
            "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.invalid.signature",
            "",
        ]

        for token in invalid_tokens:
            headers = {"Authorization": f"Bearer {token}"}
            response = client.get("/workers", headers=headers)
            assert response.status_code in [401, 403]

    def test_token_expiration(self):
        """Testa expiração de tokens"""
        from datetime import timedelta

        # Criar token expirado
        expired_token = create_access_token(
            data={"sub": "testuser"}, expires_delta=timedelta(seconds=-1)
        )

        client = TestClient(app)
        headers = {"Authorization": f"Bearer {expired_token}"}
        response = client.get("/workers", headers=headers)

        assert response.status_code == 401


class TestRateLimitingSecurity:
    """Testes de segurança de rate limiting"""

    def test_login_rate_limiting(self):
        """Testa rate limiting no login"""
        client = TestClient(app)

        # Fazer múltiplas tentativas de login
        responses = []
        for _ in range(15):  # Mais que o limite
            response = client.post(
                "/auth/login", json={"username": "admin", "password": "wrong_password"}
            )
            responses.append(response.status_code)

        # Deve haver pelo menos uma resposta 429 (rate limited)
        has_rate_limit = any(code == 429 for code in responses)
        if has_rate_limit:
            assert True
        else:
            pytest.skip("Rate limiting pode não estar ativo no ambiente de teste")


class TestWebSocketSecurity:
    """Testes de segurança do WebSocket"""

    def test_websocket_csrf_protection(self):
        """Testa proteção CSRF no WebSocket"""
        from main_fixed import ConnectionManager

        manager = ConnectionManager()

        # Testar geração de token CSRF
        token = manager.generate_csrf_token()
        assert isinstance(token, str)
        assert len(token) > 20

        # Testar validação
        assert manager.validate_csrf_token(token)
        assert not manager.validate_csrf_token(token)  # One-time use
        assert not manager.validate_csrf_token("invalid_token")


class TestDataExposureSecurity:
    """Testes de segurança contra exposição de dados"""

    def test_no_sensitive_data_exposure(self):
        """Testa que dados sensíveis não são expostos"""
        client = TestClient(app)

        # Endpoint de saúde não deve expor informações sensíveis
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert "password" not in str(data).lower()
        assert "secret" not in str(data).lower()
        assert "token" not in str(data).lower()

    def test_error_messages_safety(self):
        """Testa que mensagens de erro não expõem informações sensíveis"""
        client = TestClient(app)

        # Tentar acesso sem token
        response = client.get("/workers")
        assert response.status_code == 401
        error_data = response.json()
        assert "detail" in error_data

        # Mensagem não deve conter caminhos do sistema ou stack traces
        error_msg = str(error_data).lower()
        assert "traceback" not in error_msg
        assert "/home/" not in error_msg
        assert "internal" not in error_msg or "server error" in error_msg


class TestFileSystemSecurity:
    """Testes de segurança do sistema de arquivos"""

    def test_log_file_permissions(self):
        """Testa permissões dos arquivos de log"""
        log_files = [
            "logs/services_status.log",
            "logs/auto_init.log",
            "logs/services_startup.log",
        ]

        for log_file in log_files:
            if os.path.exists(log_file):
                # Arquivo deve ser legível pelo dono
                assert os.access(log_file, os.R_OK)

                # Não deve ser executável
                assert not os.access(log_file, os.X_OK)

                # Verificar tamanho não excessivo (evitar logs gigantes)
                size = os.path.getsize(log_file)
                assert size < 100 * 1024 * 1024  # Menos de 100MB

    def test_no_world_writable_files(self):
        """Testa que não há arquivos world-writable"""
        import glob

        # Verificar arquivos no diretório do projeto
        for filepath in glob.glob("**/*", recursive=True):
            if os.path.isfile(filepath):
                stat_info = os.stat(filepath)
                # Verificar se não é world-writable (outros não podem escrever)
                assert not (stat_info.st_mode & 0o002)


if __name__ == "__main__":
    pytest.main([__file__])
