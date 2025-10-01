# 📚 Índice da Documentação - Cluster AI

## 🎯 Visão Geral

**Sistema Universal de IA Distribuída**

Esta documentação cobre todos os aspectos do **Cluster AI**, uma plataforma completa para **gerenciamento e orquestração de modelos de inteligência artificial em cluster distribuído**.

## 🚫 ESCOPO DO PROJETO

**IMPORTANTE:** Este projeto **NÃO** contém nenhuma funcionalidade relacionada a:
- Mineração de criptomoedas
- Blockchain ou criptografia financeira
- Qualquer tipo de atividade financeira ou monetária

O projeto é dedicado exclusivamente ao processamento distribuído de inteligência artificial, utilizando tecnologias como:
- Ollama para execução de modelos de IA
- Dask para computação distribuída
- OpenWebUI para interfaces de chat
- Docker para containerização
- Monitoramento e métricas com Prometheus/Grafana

## 📖 Manuais Completos

### 1. [Instalação](manuals/INSTALACAO.md)
Guia detalhado de instalação passo a passo para todas as distribuições Linux.

### 2. [Ollama e Modelos](manuals/OLLAMA.md)
Manual completo dos modelos de IA, configuração e uso avançado.

### 3. [OpenWebUI](manuals/OPENWEBUI.md)
Configuração e uso da interface web (em desenvolvimento).

### 4. [Backup e Recuperação](manuals/BACKUP.md)
Sistema completo de backup e recuperação de desastres.

## ⚡ Guias Rápidos

### 1. [Quick Start](guides/QUICK_START.md)
Comece em 5 minutos - instalação rápida e uso básico.

### 2. [Troubleshooting](guides/TROUBLESHOOTING.md)
Solução de problemas comuns e procedimentos de emergência.

### 3. [Otimização](guides/OPTIMIZATION.md)
Técnicas avançadas de otimização de performance.

### 4. [Gerenciamento de Recursos](guides/RESOURCE_MANAGEMENT.md)
Sistema de memória auto-expansível e monitoramento.

## 🚀 Deploy e Produção

### 1. Backend API

O backend é implementado em FastAPI e roda na porta 8000. Ele fornece endpoints REST para autenticação, monitoramento, controle de workers, alertas e métricas. Para rodar localmente:

```bash
uvicorn web-dashboard.backend.main_fixed:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Frontend Web Dashboard

O frontend é uma aplicação React construída com Vite, rodando na porta 5173 em desenvolvimento e 3000 em produção. Para evitar problemas de CORS, o Vite está configurado para proxyar chamadas API para o backend na porta 8000.

### 3. Configuração do Proxy no Vite

No arquivo `vite.config.js`, configure o proxy para redirecionar chamadas `/api` e WebSocket para o backend:

```js
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true,
    proxy: {
      '/api': 'http://localhost:8000',
      '/ws': {
        target: 'ws://localhost:8000',
        ws: true,
      },
    },
  },
})
```

### 4. Autenticação

O sistema usa autenticação JWT via endpoint `/auth/login` no backend. O frontend deve enviar o token JWT em chamadas subsequentes para acessar recursos protegidos.

### 5. Scripts de Inicialização

- `scripts/auto_init_project.sh`: Inicializa todos os serviços essenciais.
- `scripts/auto_start_services.sh`: Inicializa serviços individualmente:
  - Dashboard Model Registry (porta 5000)
  - Web Dashboard Frontend (porta 3000)
  - Backend API (porta 8000)

## 💡 Exemplos

### 1. [Básicos](../examples/basic/)
Exemplos introdutórios e uso simples.

### 2. [Avançados](../examples/advanced/)
Exemplos complexos e integrações avançadas.

### 3. [Integração](../examples/integration/)
Integração com outros sistemas e APIs.

## 🔧 Scripts e Ferramentas

### 1. [Instalação](../scripts/installation/)
Scripts de instalação e configuração.

### 2. [Utils](../scripts/utils/)
Utilitários e ferramentas auxiliares.

### 3. [Validação](../scripts/validation/)
Scripts de teste e validação.

### 4. [Otimização](../scripts/optimization/)
Otimização de performance e recursos.

## 📊 Estrutura do Projeto

Consulte [ESTRUTURA_PROJETO.md](../ESTRUTURA_PROJETO.md) para detalhes completos da organização de arquivos.

## 🎯 Como Usar Esta Documentação

1. **Iniciantes**: Comece pelo [Quick Start](guides/QUICK_START.md)
2. **Instalação**: Siga o [Manual de Instalação](manuals/INSTALACAO.md)
3. **Problemas**: Consulte [Troubleshooting](guides/TROUBLESHOOTING.md)
4. **Avançado**: Explore [Otimização](guides/OPTIMIZATION.md)

## 📞 Suporte

- **Documentação**: Este índice e manuais
- **Comunidade**: Issues e discussões no GitHub
- **Emergência**: Procedimentos em [Troubleshooting](guides/TROUBLESHOOTING.md)

---

*Última atualização: $(date +%Y-%m-%d)*
