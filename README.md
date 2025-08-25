# Cluster AI - Sistema de Processamento Distribuído

![GitHub](https://img.shields.io/github/license/Dagoberto-Candeias/cluster-ai)
![GitHub issues](https://img.shields.io/github/issues/Dagoberto-Candeias/cluster-ai)
![GitHub release](https://img.shields.io/github/v/release/Dagoberto-Candeias/cluster-ai)

Sistema completo para implantação de clusters de IA com processamento distribuído usando Dask, Ollama e OpenWebUI.

## 🚀 Instalação Rápida

```bash
# Instalação automática em uma única máquina
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/install_cluster.sh)"
```

## ⚡ Sistema de Gerenciamento de Recursos

O Cluster AI agora inclui um sistema avançado de gerenciamento de recursos que:

- **✅ Memória Auxiliar Auto-Expansível**: Utiliza SSD como swap dinâmico (2G-16G)
- **✅ Otimização Automática**: Ajusta configurações baseadas no hardware disponível
- **✅ Monitoramento Contínuo**: Previne travamentos e falta de memória
- **✅ Verificação Pré-Instalação**: Garante recursos mínimos antes de instalar
- **✅ Suporte a Múltiplas Interfaces**: Wi-Fi + Ethernet simultâneas

### Recursos do Sistema
- **Swap Dinâmico**: Expande/contrai automaticamente baseado no uso de memória
- **Limites de Memória**: Configura automaticamente limites por processo
- **Otimização Ollama**: Ajusta camadas GPU e modelos baseado na RAM disponível
- **Medidas Emergenciais**: Libera memória e reduz carga automaticamente
- **Verificação de Recursos**: Detecta CPU, memória, disco e interfaces de rede

### Scripts de Gerenciamento
- `scripts/utils/resource_checker.sh` - Verificação completa de recursos
- `scripts/utils/memory_manager.sh` - Gerenciamento de memória e swap
- `scripts/utils/resource_optimizer.sh` - Otimização automática
- `scripts/utils/memory_stress_test.sh` - Testes de estresse

Consulte [Guia de Gerenciamento de Recursos](docs/guides/RESOURCE_MANAGEMENT.md) para detalhes completos.

## 📦 Dependências Python

O projeto utiliza um arquivo `requirements.txt` com todas as dependências necessárias:

```bash
pip install -r requirements.txt
```

Principais dependências: Dask, FastAPI, Ollama, psutil, e utilitários de monitoramento.

## 🔧 Estrutura do Projeto

```
cluster-ai/
├── 📁 scripts/           # Scripts de gerenciamento
├── 📁 docs/             # Documentação completa  
├── 📁 configs/          # Configurações do sistema
├── 📁 deployments/      # Configurações de deploy
├── 📁 examples/         # Exemplos de código
├── 📄 requirements.txt  # Dependências Python
└── 📄 .gitignore       # Arquivos ignorados pelo Git
```

Consulte [ESTRUTURA_PROJETO.md](ESTRUTURA_PROJETO.md) para detalhes completos da estrutura.
