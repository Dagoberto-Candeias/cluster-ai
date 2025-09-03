# README FINAL — Deploy Open WebUI + Ollama (TLS) — Instruções completas

Este README consolida os passos para empacotar e transferir os artefatos ao servidor e executar o deploy.

Arquivos principais no pacote local:
- docker-compose-tls.yml
- nginx-tls.conf
- docker-compose.yml (sem TLS, opcional)
- issue-certs-robust.sh
- issue-certs.sh (versão simples)
- Parte1_... md/pdf ... Parte4_... md/pdf
- README_deploy_TLS.md

## 1) Preparar pacote para upload
Organize os arquivos em uma pasta (ex.: `deploy_package/`):
```bash
mkdir -p deploy_package
cp docker-compose-tls.yml nginx-tls.conf issue-certs-robust.sh README_deploy_TLS.md deploy_package/
cp Parte1_Guia_Introducao_venv.md Parte1_Guia_Introducao_venv.pdf deploy_package/ || true
cp Parte2_Conda_Dependencias_IDEs_Scripts.md Parte2_Conda_Dependencias_IDEs_Scripts.pdf deploy_package/ || true
cp Parte3_Ollama_OpenWebUI_Modelos_Exemplos.md Parte3_Ollama_OpenWebUI_Modelos_Exemplos.pdf deploy_package/ || true
cp Parte4_VSCode_Continue_Fluxos_Checklist_Troubleshooting_Anexos.md Parte4_VSCode_Continue_Fluxos_Checklist_Troubleshooting_Anexos.pdf deploy_package/ || true
```

## 2) Transferir para servidor via SCP (exemplos)
Substitua `user@server` e `/opt/deploy` conforme sua infra:
```bash
# copiar pacote
scp -r deploy_package user@server:/opt/

# ou, sem criar pacote local
scp docker-compose-tls.yml nginx-tls.conf issue-certs-robust.sh README_deploy_TLS.md user@server:/opt/deploy/
```

## 3) Acessar servidor e preparar ambiente
```bash
ssh user@server
sudo apt update && sudo apt install -y docker.io docker-compose
# criar usuário dedicado (opcional, recomendado)
sudo useradd -m -s /bin/bash webui && sudo usermod -aG docker webui
sudo mkdir -p /opt/deploy && sudo chown webui:webui /opt/deploy
# mover os arquivos para /opt/deploy (se necessário)
```

## 4) Rodar Ollama (no host)
> Ollama é recomendado rodar no host (não container) — instale e execute:
```bash
# Baixe e instale Ollama conforme instruções oficiais: https://ollama.com/download
# Inicie Ollama (exemplo)
ollama serve --port 11434 &
# confirme
ollama list
```

## 5) Executar compose e emitir certificado (exemplo)
```bash
cd /opt/deploy
# ajustar nginx conf
sed -i 's/SERVER_NAME_PLACEHOLDER/minhadomain.com/g' nginx-tls.conf
# iniciar serviços (open-webui + nginx)
docker compose -f docker-compose-tls.yml up -d open-webui nginx
# emitir certificado (robusto)
./issue-certs-robust.sh minhadomain.com seu@email.com
# verificar logs
tail -n 200 logs/issue-certs.log
# recarregar nginx (se necessário)
docker compose -f docker-compose-tls.yml exec nginx nginx -s reload
```

## 6) Dicas de firewall e permissões
- Abra portas 80 e 443: `sudo ufw allow 80,443/tcp`
- Se usar AWS/GCP/Azure, abra portas nos Security Groups/Firewall rules
- Garanta que o diretório `letsencrypt/` seja persistido e com permissão adequada:
```bash
sudo chown -R 1000:1000 /opt/deploy/letsencrypt || true
```

## 7) Rotina de renovação (cron)
Adicionar crontab para renovar automaticamente e recarregar nginx:
```bash
# editar crontab do usuário que pode executar docker compose
crontab -e
# adicionar linha (exemplo diário às 2:30):
30 2 * * * cd /opt/deploy && docker compose run --rm certbot renew --webroot -w /var/www/certbot && docker compose -f docker-compose-tls.yml exec nginx nginx -s reload >> /opt/deploy/letsencrypt/renew.log 2>&1
```

## 8) Rollback & troubleshooting rápidos
- Se algo falhar, pare os containers e confira logs:
```bash
docker compose -f docker-compose-tls.yml ps
docker compose -f docker-compose-tls.yml logs nginx
docker compose -f docker-compose-tls.yml logs open-webui
```
- Para forçar re-emissão do certificado:
```bash
./issue-certs-robust.sh minhadomain.com email@domain.com --force
```

---
# End of README final
