# 🧪 Suíte de Testes - Cluster AI

Esta é uma suíte completa de testes para o projeto **Cluster AI**, projetada para garantir qualidade, confiabilidade e manutenibilidade do código.

## 📋 Visão Geral

A suíte de testes está organizada em diferentes tipos de testes:

- **Unitários**: Testam funções individuais
- **Integração**: Testam interação entre componentes
- **End-to-End**: Testam fluxos completos
- **Performance**: Testam desempenho e recursos
- **Segurança**: Testam vulnerabilidades e permissões
- **Bash**: Testam scripts shell

## 🚀 Executando os Testes

### Método 1: Executor Principal (Recomendado)

Use o script principal para executar todos os testes:

```bash
# Executar todos os testes
python tests/run_all_tests.py

# Executar apenas testes unitários
python tests/run_all_tests.py --unit

# Executar apenas testes de integração
python tests/run_all_tests.py --integration

# Executar apenas testes end-to-end
python tests/run_all_tests.py --e2e

# Executar apenas testes de performance
python tests/run_all_tests.py --performance

# Executar apenas testes de segurança
python tests/run_all_tests.py --security

# Executar apenas testes Bash
python tests/run_all_tests.py --bash

# Executar apenas linting
python tests/run_all_tests.py --lint

# Opções adicionais
python tests/run_all_tests.py --fail-fast    # Parar no primeiro erro
python tests/run_all_tests.py --parallel     # Executar em paralelo
python tests/run_all_tests.py --no-lint      # Pular linting
python tests/run_all_tests.py --no-coverage  # Pular análise de cobertura
```

### Método 2: pytest Direto

Para execução mais granular com pytest:

```bash
# Todos os testes
pytest

# Testes unitários específicos
pytest tests/unit/test_demo_cluster.py -v

# Testes de integração
pytest tests/integration/ -v

# Com cobertura
pytest --cov=. --cov-report=html

# Testes específicos por marcador
pytest -m unit
pytest -m integration
pytest -m e2e
pytest -m performance
pytest -m security
```

### Método 3: Scripts Bash

Para testes de scripts Bash (requer BATS):

```bash
# Instalar BATS
sudo apt-get install bats

# Executar testes Bash
bats tests/bash/
```

## 📁 Estrutura dos Testes

```
tests/
├── conftest.py              # Configurações globais
├── pytest.ini              # Configurações do pytest
├── test_requirements.txt   # Dependências de teste
├── run_all_tests.py        # Executor principal
├── README.md               # Esta documentação
│
├── unit/                   # Testes unitários
│   ├── test_demo_cluster.py
│   └── ...
│
├── integration/            # Testes de integração
│   ├── test_dask_integration.py
│   └── ...
│
├── e2e/                    # Testes end-to-end
│   └── ...
│
├── performance/            # Testes de performance
│   └── ...
│
├── security/               # Testes de segurança
│   └── ...
│
├── bash/                   # Testes de scripts Bash
│   └── ...
│
├── fixtures/               # Dados de teste
│   └── ...
│
└── reports/                # Relatórios gerados
    ├── coverage/
    ├── unit_tests.html
    ├── integration_tests.html
    └── ...
```

## 🛠️ Configuração do Ambiente

### Dependências Python

Instale as dependências de teste:

```bash
pip install -r tests/test_requirements.txt
```

### Dependências do Sistema

Para Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3-dev \
    bats  # Para testes Bash
```

### Variáveis de Ambiente

Configure variáveis de ambiente para testes:

```bash
export CLUSTER_AI_TEST_MODE=1
export CLUSTER_AI_CONFIG_DIR=/tmp/test_config
export CLUSTER_AI_LOG_DIR=/tmp/test_logs
```

## 📊 Relatórios e Cobertura

### Relatórios HTML

Os testes geram relatórios HTML automaticamente:

- `tests/reports/unit_tests.html` - Relatório de testes unitários
- `tests/reports/integration_tests.html` - Relatório de testes de integração
- `tests/reports/coverage/index.html` - Relatório de cobertura

### Cobertura de Código

A cobertura mínima requerida é de **80%**. Para verificar:

```bash
pytest --cov=. --cov-report=term-missing --cov-fail-under=80
```

### Relatório de Performance

Para testes de performance:

```bash
pytest tests/performance/ --benchmark-only --benchmark-json=benchmark.json
```

## 🔧 Desenvolvimento de Testes

### Estrutura Básica de um Teste

```python
import pytest
from unittest.mock import MagicMock, patch

class TestMinhaClasse:
    """Testes para MinhaClasse"""

    def test_metodo_basico(self):
        """Testa funcionalidade básica"""
        # Arrange
        obj = MinhaClasse()

        # Act
        result = obj.metodo()

        # Assert
        assert result == esperado

    @patch('modulo.funcao_externa')
    def test_metodo_com_mock(self, mock_funcao):
        """Testa método com dependência externa mockada"""
        # Arrange
        mock_funcao.return_value = "mocked_result"
        obj = MinhaClasse()

        # Act
        result = obj.metodo_que_usa_externa()

        # Assert
        assert result == "mocked_result"
        mock_funcao.assert_called_once()

    @pytest.mark.parametrize("input,expected", [
        (1, 2),
        (2, 4),
        (3, 6),
    ])
    def test_metodo_parametrizado(self, input, expected):
        """Testa método com múltiplos parâmetros"""
        assert MinhaClasse.metodo_estatico(input) == expected
```

### Fixtures Personalizadas

Use fixtures para compartilhar configuração:

```python
@pytest.fixture
def meu_fixture():
    """Fixture personalizado"""
    # Setup
    resource = criar_recurso()

    yield resource

    # Teardown
    resource.cleanup()

def test_usa_fixture(meu_fixture):
    """Teste que usa fixture"""
    assert meu_fixture.esta_pronto()
```

### Mocks e Stubs

Para dependências externas:

```python
@patch('requests.get')
def test_api_call(mock_get):
    """Testa chamada de API"""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"data": "test"}
    mock_get.return_value = mock_response

    result = minha_funcao_que_faz_request()

    assert result["data"] == "test"
```

## 🏷️ Marcadores de Teste

### Marcadores Disponíveis

- `@pytest.mark.unit` - Testes unitários
- `@pytest.mark.integration` - Testes de integração
- `@pytest.mark.e2e` - Testes end-to-end
- `@pytest.mark.performance` - Testes de performance
- `@pytest.mark.security` - Testes de segurança
- `@pytest.mark.slow` - Testes que demoram mais
- `@pytest.mark.skip_ci` - Pular em CI/CD

### Usando Marcadores

```python
@pytest.mark.unit
def test_rapido():
    """Teste unitário rápido"""
    pass

@pytest.mark.slow
def test_lento():
    """Teste que demora muito"""
    time.sleep(10)

@pytest.mark.skip_ci
def test_apenas_local():
    """Teste que não roda no CI"""
    pass
```

## 🔒 Testes de Segurança

### Executando Testes de Segurança

```bash
# Com Bandit
bandit -r . -f json -o security_report.json

# Com Safety
safety check --output json
```

### Tipos de Testes de Segurança

- Validação de permissões de arquivo
- Verificação de configurações seguras
- Testes de injeção
- Validação de entrada/saída

## 📈 Testes de Performance

### Benchmarks

```python
import pytest_benchmark

def test_performance(benchmark):
    """Teste de performance com benchmark"""
    result = benchmark(minha_funcao_custosa, arg1, arg2)
    assert result is not None
```

### Profiling

```python
import cProfile
import pstats

def test_with_profiling():
    """Teste com profiling"""
    profiler = cProfile.Profile()
    profiler.enable()

    # Código a ser perfilado
    minha_funcao()

    profiler.disable()
    stats = pstats.Stats(profiler).sort_stats('cumulative')
    stats.print_stats()
```

## 🐛 Debugging de Testes

### Executando Testes em Debug

```bash
# Parar no primeiro erro
pytest --pdb

# Modo verbose
pytest -v -s

# Executar teste específico
pytest tests/unit/test_demo_cluster.py::TestFibonacciTask::test_fibonacci_base_cases -v -s
```

### Logs de Debug

```python
import logging

def test_com_logs(caplog):
    """Teste que captura logs"""
    caplog.set_level(logging.DEBUG)

    minha_funcao_que_loga()

    assert "mensagem esperada" in caplog.text
```

## 📋 CI/CD Integration

### GitHub Actions

Os testes são executados automaticamente via GitHub Actions:

- **Push/PR**: Executa todos os testes
- **Schedule**: Testes diários de regressão
- **Release**: Testes completos antes do deploy

### Configuração Local de CI

Para simular CI localmente:

```bash
# Executar como no CI
python tests/run_all_tests.py --fail-fast --parallel

# Com variáveis de ambiente do CI
CI=true python tests/run_all_tests.py
```

## 🎯 Melhores Práticas

### Princípios Gerais

1. **Teste uma coisa por vez** - Cada teste deve validar um comportamento específico
2. **Nome descritivo** - O nome do teste deve explicar o que está sendo testado
3. **Independência** - Testes não devem depender uns dos outros
4. **Rapidez** - Testes devem ser rápidos para executar frequentemente
5. **Confiabilidade** - Testes devem passar consistentemente

### Estrutura de Teste

```python
def test_descricao_clara_do_que_esta_sendo_testado():
    # Given - Contexto/Setup
    setup_dados = criar_dados_de_teste()

    # When - Ação
    resultado = funcao_sob_teste(setup_dados)

    # Then - Verificação
    assert resultado == esperado
    assert condicao_adicional
```

### Cobertura de Cenários

- **Caminho feliz** - Funcionamento normal
- **Casos extremos** - Valores limites, vazios, nulos
- **Cenários de erro** - Exceções, falhas, timeouts
- **Edge cases** - Condições especiais

## 📞 Suporte e Contribuição

### Relatando Problemas

Para reportar problemas nos testes:

1. Verifique se o problema já foi reportado
2. Crie um issue detalhado com:
   - Descrição do problema
   - Passos para reproduzir
   - Logs de erro
   - Ambiente (OS, Python version, etc.)

### Contribuindo

Para contribuir com novos testes:

1. Siga a estrutura existente
2. Adicione testes para nova funcionalidade
3. Mantenha cobertura > 80%
4. Execute todos os testes antes do PR

## 📚 Recursos Adicionais

- [Pytest Documentation](https://docs.pytest.org/)
- [Testing Python Applications](https://testandcode.com/)
- [Python Testing with pytest](https://pragprog.com/titles/bopytest/python-testing-with-pytest/)
- [BATS Testing Framework](https://bats-core.readthedocs.io/)

---

## 🎉 Conclusão

Esta suíte de testes garante que o **Cluster AI** mantenha altos padrões de qualidade e confiabilidade. Execute os testes regularmente e contribua com novos testes para manter a saúde do projeto!
