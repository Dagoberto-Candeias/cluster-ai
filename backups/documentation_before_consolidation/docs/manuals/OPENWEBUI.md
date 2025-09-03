# 📖 Manual do OpenWebUI - Interface Web para Ollama

## 🎯 Visão Geral

O OpenWebUI é uma interface web de código aberto projetada para interagir com modelos de linguagem executados localmente através do Ollama. Esta interface oferece uma experiência de usuário moderna e intuitiva para trabalhar com modelos de IA.

## 🚀 Instalação e Configuração

### Instalação Automática
O OpenWebUI é instalado automaticamente quando você configura uma máquina como **Servidor Principal** ou **Estação de Trabalho** usando o script de instalação do Cluster AI.

```bash
./install_cluster.sh --role server
```

### Instalação Manual
```bash
# Usando Docker (recomendado)
docker run -d --name open-webui \
  -p 8080:8080 \
  -v open-webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main

# Ou usando Docker Compose
docker-compose -f configs/docker/compose-basic.yml up -d
```

## ⚙️ Configuração

### Variáveis de Ambiente
| Variável | Descrição | Valor Padrão |
|----------|-----------|-------------|
| `OLLAMA_BASE_URL` | URL da API do Ollama | `http://localhost:11434` |
| `WEBUI_PORT` | Porta do OpenWebUI | `8080` |
| `DATA_DIR` | Diretório de dados | `/app/data` |

### Configuração com TLS (Produção)
Para configuração segura em produção, use o arquivo `docker-compose-tls.yml`:

```bash
cd configs/docker
docker-compose -f compose-tls.yml up -d
```

## 🌐 Acesso e Uso

### Primeiro Acesso
1. Abra seu navegador e acesse: `http://localhost:8080`
2. Crie uma conta de administrador
3. Configure as preferências iniciais

### Funcionalidades Principais

#### 💬 Chat com Modelos
- Interface de chat intuitiva
- Suporte a múltiplos modelos
- Histórico de conversas
- Exportação de conversas

#### ⚙️ Gerenciamento de Modelos
- Lista de modelos disponíveis
- Download de novos modelos
- Configuração de parâmetros

#### 👥 Gerenciamento de Usuários
- Sistema de autenticação
- Controle de permissões
- Logs de atividade

## 🔧 Configuração Avançada

### Integração com Ollama
Certifique-se de que o Ollama está configurado para aceitar conexões externas:

```bash
# Configurar Ollama para escutar em todas as interfaces
export OLLAMA_HOST=0.0.0.0
ollama serve
```

### Configuração de Proxy Reverso (Nginx)
Exemplo de configuração Nginx:

```nginx
server {
    listen 80;
    server_name seu-dominio.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Configuração com TLS
Use o script de certificados Let's Encrypt:

```bash
./configs/tls/issue-certs-robust.sh seu-dominio.com seu-email@exemplo.com
```

## 🛠️ Solução de Problemas

### Problemas Comuns

#### ❌ OpenWebUI não consegue conectar ao Ollama
**Solução:**
```bash
# Verificar se Ollama está rodando
curl http://localhost:11434/api/tags

# Configurar Ollama para aceitar conexões externas
export OLLAMA_HOST=0.0.0.0
sudo systemctl restart ollama
```

#### ❌ Erro de permissão no Docker
**Solução:**
```bash
# Verificar permissões do volume
sudo chown -R 1000:1000 /var/lib/docker/volumes/open-webui
```

#### ❌ Porta já em uso
**Solução:**
```bash
# Verificar processos usando a porta
sudo lsof -i :8080

# Matar processo conflitante ou mudar porta
docker run -p 8081:8080 ... 
```

### Logs e Diagnóstico

#### Verificar Logs do Container
```bash
docker logs open-webui
docker logs openwebui-nginx
```

#### Verificar Saúde dos Serviços
```bash
# Verificar se OpenWebUI está respondendo
curl http://localhost:8080/api/health

# Verificar conexão com Ollama
curl http://localhost:11434/api/tags
```

## 🔒 Segurança

### Melhores Práticas de Segurança

1. **Use HTTPS em produção**
2. **Configure firewall adequadamente**
3. **Mantenha software atualizado**
4. **Use autenticação forte**
5. **Monitore logs regularmente**

### Configuração de Firewall
```bash
# Permitir apenas portas necessárias
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 8080/tcp  # OpenWebUI
sudo ufw allow 11434/tcp # Ollama
sudo ufw enable
```

## 📊 Monitoramento e Manutenção

### Backup de Dados
```bash
# Fazer backup dos dados do OpenWebUI
tar -czf openwebui-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/docker/volumes/open-webui
```

### Atualização
```bash
# Parar containers
docker-compose down

# Pull da imagem mais recente
docker pull ghcr.io/open-webui/open-webui:main

# Reiniciar containers
docker-compose up -d
```

### Limpeza de Dados
```bash
# Limpar conversas antigas (via interface web)
# Ou manualmente via banco de dados
```

## 🎯 Exemplos de Uso

### Uso Básico
1. Acesse `http://localhost:8080`
2. Selecione um modelo (ex: llama3)
3. Comece a conversar!

### Uso Avançado com API
```python
import requests

# Enviar mensagem para o OpenWebUI
response = requests.post(
    'http://localhost:8080/api/chat',
    json={
        'model': 'llama3',
        'messages': [{'role': 'user', 'content': 'Olá!'}]
    }
)
```

### Integração com Outras Ferramentas
```bash
# Usar curl para interagir com a API
curl -X POST http://localhost:8080/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3", "messages": [{"role": "user", "content": "Explique AI"}]}'
```

## 📈 Otimização de Performance

### Configuração para Alta Demanda
```yaml
# docker-compose.yml otimizado
services:
  open-webui:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2'
    environment:
      - WORKER_COUNT=4
      - MAX_REQUEST_SIZE=100MB
```

### Monitoramento de Performance
```bash
# Verificar uso de recursos
docker stats open-webui

# Monitorar logs em tempo real
docker logs -f open-webui
```

## 🤝 Suporte e Comunidade

### Recursos Úteis
- **[Documentação Oficial](https://docs.openwebui.com/)**
- **[GitHub Repository](https://github.com/open-webui/open-webui)**
- **[Discord Community](https://discord.gg/openwebui)**

### Reportar Problemas
1. Verifique logs primeiro
2. Consulte a documentação
3. Procure issues existentes no GitHub
4. Crie novo issue com informações detalhadas

## 📝 Changelog

### Versão 1.0
- ✅ Instalação básica funcionando
- ✅ Integração com Ollama
- ✅ Interface web moderna
- ✅ Sistema de autenticação

### Próximas Versões
- [ ] Suporte a múltiplos usuários avançado
- [ ] Plugins e extensões
- [ ] API mais robusta
- [ ] Melhorias de performance

---

**💡 Dica**: Para começar rapidamente, execute o script de instalação do Cluster AI que configura automaticamente o OpenWebUI junto com todos os outros componentes necessários.

**📞 Suporte**: Em caso de problemas, consulte a documentação oficial ou abra uma issue no GitHub do projeto.
