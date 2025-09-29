# Guia de Configuração de Workers (SSH)

Este guia descreve como configurar autenticação SSH sem senha para os workers e preparar o `cluster.yaml` para que o `health_check.sh` valide os workers corretamente.

## Pré-requisitos
- Chave SSH local (ed25519 recomendado):
  ```bash
  ls -l ~/.ssh/id_ed25519 || ssh-keygen -t ed25519 -C "cluster-ai" -f ~/.ssh/id_ed25519 -N ""
  eval "$(ssh-agent -s)"; ssh-add ~/.ssh/id_ed25519 || true
  ```
- `yq` v4 e `ssh` instalados no host que executa os scripts.

## Preencher `cluster.yaml`
Use nomes estáveis e preencha pelo menos `host`, `user`, `port` para cada worker:

```yaml
workers:
  pc-dago:
    host: 10.0.0.10
    user: ubuntu
    port: 22
  worker-10-0-0-11:
    host: 10.0.0.11
    user: ubuntu
    port: 22
  worker-10-0-0-12:
    host: 10.0.0.12
    user: ubuntu
    port: 22
  android-worker:
    host: 10.0.0.21
    user: u0_a123
    port: 8022
```

Observações:
- Evite chaves ambíguas (por exemplo, usar apenas `10.0.0.12` como nome). Prefira `worker-10-0-0-12`.
- Para Android (Termux), a porta comum é `8022`.

## Distribuir a chave pública aos workers
Repita para cada worker:
```bash
ssh-copy-id -p <PORT> <USER>@<HOST>
ssh-keyscan -p <PORT> <HOST> >> ~/.ssh/known_hosts
```
Teste rápido:
```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -p <PORT> <USER>@<HOST> 'echo OK'
```

## Diagnóstico automatizado
Use os alvos do Makefile:
- Listar/testar SSH e gerar relatório:
  ```bash
  make health-ssh
  # Gera workers-ssh-report.txt com SUMMARY
  ```
- Health JSON completo (inclui workers):
  ```bash
  make health-json-full SERVICES="azure-cluster-worker azure-cluster-control-plane gcp-cluster-worker aws-cluster-worker"
  ```
- Health JSON padrão (pula workers; útil enquanto configura):
  ```bash
  make health-json
  ```

## Integração CI (GitLab)
- Job agendado (padrão, ignora workers): `scheduled:health_check_json` (gera `health-check.json`).
- Job manual completo (inclui workers): `manual:health_check_full`.

## Troubleshooting
- "Permission denied (publickey)": repasse `ssh-copy-id` e confirme permissões do `~/.ssh` no worker (`chmod 700 ~/.ssh` e `chmod 600 ~/.ssh/authorized_keys`).
- Porta fechada: abra no firewall/SG (ex.: `ufw allow 22/tcp`).
- Usuário incorreto: verifique distro/AMI (ex.: `ubuntu`, `ec2-user`, `debian`).
- Binários ausentes no worker: `top`, `free`, `df` são usados pelo health; instale `procps`, `coreutils`.
