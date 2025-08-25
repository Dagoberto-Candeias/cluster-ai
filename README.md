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

- **✅ Memória Auxiliar Auto-Expansível**: Utiliza SSD como swap dinâmico
- **✅ Otimização Automática**: Ajusta configurações baseadas no hardware
- **✅ Monitoramento Contínuo**: Previne travamentos e falta de memória
- **✅ Verificação Pré-Instalação**: Garante recursos mínimos antes de instalar

### Recursos do Sistema
- **Swap Dinâmico**: Expande/contrai automaticamente baseado no uso
- **Limites de Memória**: Configura automaticamente limites por processo
- **Otimização Ollama**: Ajusta camadas GPU e modelos baseado na RAM
- **Medidas Emergenciais**: Libera memória e reduz carga automaticamente

Consulte [Guia de Gerenciamento de Recursos](docs/guides/RESOURCE_MANAGEMENT.md) para detalhes completos.
