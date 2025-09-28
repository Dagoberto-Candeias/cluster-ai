# Deploy: Open WebUI + Ollama (with automatic Let's Encrypt TLS)

Este README descreve passo-a-passo como subir **Open WebUI** (frontend), **NGINX** (reverse proxy + TLS) e usar **certbot** para obter certificados Let's Encrypt automaticamente. O Ollama deve estar rodando **no host** (não em container) escutando `:11434` (padrão).

> **Observação:** você precisa de um domínio público (ex.: `example.com`) apontando para o IP público do servidor onde fará o deploy. Let's Encrypt só emite para domínios públicos válidos.

---

## Arquivos gerados
- `docker-compose.yml`  (compose com services: open-webui, nginx, certbot)
- `nginx.conf`          (config NGINX com ACME challenge)
- `letsencrypt/`        (volume onde os certificados serão armazenados)
- `html/`               (webroot usado para desafios ACME)

---

## Pré-requisitos
1. **Ollama** instalado no host e rodando (ex.: `ollama serve --port 11434 &`).
2. **Docker Engine** e **Docker Compose** instalados no servidor.
3. Porta **80** e **443** abertas no firewall para o IP do servidor.
4. Um domínio válido apontando para este servidor.

---

## Passo a passo

### 1) Ajuste `nginx.conf`
Edite `nginx.conf` e substitua `SERVER_NAME_PLACEHOLDER` pelo seu domínio (ex.: `minhadomain.com`).

Por exemplo, no Linux:
```bash
sed -i 's/SERVER_NAME_PLACEHOLDER/minhadomain.com/g' nginx.conf
```

### 2) Crie diretórios persistentes
```bash
mkdir -p ./letsencrypt ./html
chmod 755 ./html
```

### 3) (Opcional) criar .env para facilitar
Crie um `.env` com as variáveis abaixo (não é usado automaticamente pelo compose, mas útil para seus scripts):
```
DOMAIN=minhadomain.com
EMAIL=seu@email.com
```

### 4) Inicie os containers (abrange Open WebUI + NGINX)
> **Certbot não emite o certificado automaticamente** nesta configuração — será usado para renovação. Para emitir o primeiro certificado, siga o passo 5.
```bash
docker compose up -d
```

Verifique logs:
```bash
docker compose logs -f nginx
docker compose logs -f open-webui
```

### 5) Obter o certificado inicial com Certbot (execução manual)
Execute o comando `certbot certonly` usando o container `certbot` para criar o certificado usando o webroot (`/var/www/certbot`):
```bash
docker compose run --rm certbot certonly --webroot -w /var/www/certbot -d minhadomain.com --email seu@email.com --agree-tos --no-eff-email
```

Se o comando for bem-sucedido, os certificados serão gravados em `./letsencrypt/live/minhadomain.com/`.

### 6) Reiniciar / recarregar o NGINX
Após emitir os certificados, recarregue o nginx para que passe a usar os arquivos TLS:
```bash
docker compose exec nginx nginx -s reload
# ou reinicie o serviço
docker compose restart nginx
```

### 7) Testar acesso HTTPS
Abra no navegador: `https://minhadomain.com` — você deve ser redirecionado ao Open WebUI com certificado válido.

---

## Renovação automática
Let's Encrypt certificados expiram em 90 dias. Para renovar, a forma simples é agendar um cron job que rode:

```bash
# Exemplo de entrada de cron (rodar diário às 2:30)
30 2 * * * cd /caminho/para/projeto && docker compose run --rm certbot renew --webroot -w /var/www/certbot && docker compose exec nginx nginx -s reload >> ./letsencrypt/renew.log 2>&1
```

Isso chama `certbot renew` que renovará certificados se necessário. Após renovação, recarrega o nginx.

---

## Firewall e segurança (dicas rápidas)
- Abra portas TCP **80** e **443** (ex.: `ufw allow 80,443/tcp`).
- Não exponha a API do Ollama publicamente sem autenticação. Se precisar expor `/ollama/`, proteja com IP allowlist ou autenticação adicional.
- Mantenha backups dos diretórios `letsencrypt/` (contêm chaves privadas).

---

## Nota sobre host.docker.internal (Linux)
- Em sistemas macOS/Windows `host.docker.internal` funciona nativamente.
- Em Linux, versões recentes do Docker suportam `host-gateway` via `extra_hosts` (usado no `docker-compose.yml`). Se não funcionar, substitua `host.docker.internal` pelo IP do host (ex.: `192.168.1.10`) na variável `OLLAMA_API_URL` do serviço `open-webui` no `docker-compose.yml`.

---

## Problemas comuns e soluções rápidas
- **Certbot retorna 403/404 no challenge**: verifique se `nginx` está servindo o `/var/www/certbot` e que o arquivo criado em `./html/.well-known/acme-challenge/...` é acessível publicamente.
- **Timeout ao conectar em Ollama**: verifique se Ollama está ouvindo na porta 11434 e se o host/porta estão corretos a partir do container (use `docker compose exec open-webui wget -qO- http://host.docker.internal:11434` para testar).
- **Erros de permissão ao gravar em ./letsencrypt**: ajuste permissões/ownership para o usuário Docker (ex.: `chown -R 1000:1000 ./letsencrypt` se necessário).

---

## Próximos passos opcionais
- Automatizar o emit inicial com um pequeno script que para/arranca nginx conforme necessário.
- Adicionar proteção básica (HTTP auth) ao painel do Open WebUI.
- Colocar NGINX atrás de um WAF ou Cloudflare (em modo proxy) para proteção adicional.

---

Se quiser, eu posso:
- Gerar um script `issue-certs.sh` que faz os passos 1–6 automaticamente (com checks e validações).  
- Incluir `certbot` com modo automático inicial no `docker-compose` (com cuidado — requer nginx temporariamente ativo e mapeado).  
- Adicionar instruções para criar usuário Linux dedicado para rodar o compose e configurar volumes com permissões corretas.
