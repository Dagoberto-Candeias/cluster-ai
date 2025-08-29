# 🚀 Cluster AI - Ambiente de IA Local e Distribuído

![Cluster AI Banner](https://example.com/banner.png) <!-- Placeholder para um banner futuro -->

O **Cluster AI** é um projeto completo para criar, gerenciar e otimizar um ambiente de desenvolvimento e execução de Inteligência Artificial localmente. Ele integra ferramentas poderosas como **Ollama**, **OpenWebUI** e **Dask** em um sistema coeso, robusto e com capacidades de auto-gerenciamento.

---

## 🎯 Visão Geral

Este projeto resolve o desafio de executar modelos de linguagem grandes (LLMs) e cargas de trabalho de processamento de dados em máquinas locais, mesmo com recursos limitados. Ele automatiza a instalação, configuração, monitoramento e otimização de todo o ecossistema de IA.

## ✨ Principais Funcionalidades

- **Instalação Automatizada:** Scripts unificados para configurar todo o ambiente (Ollama, Docker, Python, Dask).
- **Interface Web Intuitiva:** Integração com **OpenWebUI** para interagir facilmente com os modelos Ollama.
- **Processamento Distribuído:** Cluster **Dask** pré-configurado para processamento de dados em paralelo.
- **Gerenciamento de Recursos:** Sistema de **swap auto-expansível** para evitar travamentos por falta de memória.
- **Monitoramento e Auto-Cura:** Um serviço de monitoramento contínuo que verifica a saúde do sistema (CPU, RAM, Disco) e **reinicia automaticamente serviços críticos** (Ollama, Docker) se falharem.
- **Otimização de Performance:** Scripts para ajustar dinamicamente as configurações do sistema com base no hardware disponível.
- **Verificação de Saúde:** Um script de diagnóstico completo (`health_check.sh`) para validar toda a instalação.
- **Biblioteca de Prompts:** Um guia completo com centenas de prompts otimizados para tarefas de desenvolvimento.

---

## 🚀 Guia de Início Rápido (Quick Start)

Siga estes passos para ter seu Cluster AI funcionando em minutos.

### 1. Clonar o Repositório
```bash
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai
```

### 2. Verificar Requisitos do Sistema
Antes de instalar, execute o verificador de recursos para garantir que seu sistema atende aos requisitos mínimos.
```bash
chmod +x scripts/utils/resource_checker.sh
./scripts/utils/resource_checker.sh full
```

### 3. Executar o Instalador Principal
O instalador principal guiará você pela configuração.
```bash
chmod +x install_cluster.sh
./install_cluster.sh
```

### 4. Configurar o Serviço de Monitoramento
Para garantir a estabilidade do sistema, configure o serviço de monitoramento para iniciar com o sistema.
```bash
chmod +x scripts/deployment/setup_monitor_service.sh
sudo bash scripts/deployment/setup_monitor_service.sh

# Siga as instruções na tela para habilitar e iniciar o serviço:
sudo systemctl daemon-reload
sudo systemctl enable resource-monitor.service
sudo systemctl start resource-monitor.service
```

### 5. Validar a Instalação
Após a instalação, execute o script de verificação de saúde para confirmar que todos os componentes estão funcionando corretamente.
```bash
chmod +x scripts/utils/health_check.sh
./scripts/utils/health_check.sh
```

---

## 📚 Documentação

Para mais detalhes sobre cada componente, consulte a documentação completa.

- **Guia de Gerenciamento de Recursos**
- **Manual do OpenWebUI**
- **Biblioteca de Prompts para Desenvolvedores**

## 🤝 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests.

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.