# Manifesto dos Scripts Consolidados - Cluster AI

## Scripts Ativos e Funcionais

### Core Scripts
- `manager.sh` - Gerenciador principal do cluster
- `scripts/utils/common_functions.sh` - Biblioteca de funções comuns consolidada

### Worker Setup Scripts
- `scripts/android/setup_android_worker.sh` - Configuração automática de worker Android
- `scripts/installation/setup_generic_worker.sh` - Configuração automática de worker Linux/Unix

### Management Scripts
- `scripts/management/worker_registration.sh` - Processa registro automático de workers
- `scripts/management/network_discovery.sh` - Descoberta automática de nós na rede

### Maintenance Scripts
- `scripts/maintenance/backup_manager.sh` - Gerenciamento de backups
- `scripts/maintenance/consolidate_scripts.sh` - Este script de consolidação

## Scripts Removidos (Redundantes)

### Android Worker Scripts (Removidos)
Estes scripts foram consolidados em `setup_android_worker.sh`:
- advanced_worker.sh
- install_improved.sh
- install_manual.sh
- install_offline.sh
- install_worker.sh
- quick_install.sh
- setup_android_worker_robust.sh
- setup_android_worker_simple.sh
- setup_github_auth.sh
- setup_github_ssh.sh
- test_android_worker.sh
- uninstall_android_worker_safe.sh
- uninstall_android_worker.sh

### Backup Location
Scripts removidos foram backupados em:
`backups/script_cleanup_YYYYMMDD_HHMMSS/`

## Funcionalidades Consolidadas

### Sistema Plug-and-Play
- ✅ Descoberta automática de workers na rede
- ✅ Registro automático no servidor
- ✅ Suporte a Android (Termux) e Linux/Unix
- ✅ Gerenciamento integrado via manager.sh

### Segurança
- ✅ Geração automática de chaves SSH
- ✅ Validação de dados de registro
- ✅ Armazenamento seguro de chaves públicas

### Monitoramento
- ✅ Verificação automática de status
- ✅ Logs detalhados de operações
- ✅ Interface unificada no manager.sh

## Como Usar

### Para Workers Android
```bash
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash
```

### Para Workers Linux/Unix
```bash
wget https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/installation/setup_generic_worker.sh
chmod +x setup_generic_worker.sh
./setup_generic_worker.sh
```

### Gerenciamento via Manager
```bash
./manager.sh
# Escolher: 15) ⚙️ Configurar Workers (Remoto/Android)
```

## Manutenção

Para manter a organização:
1. Novos scripts devem ser adicionados em diretórios apropriados
2. Scripts redundantes devem ser identificados e consolidados
3. Este manifesto deve ser atualizado após mudanças significativas

---
Gerado automaticamente em: $(date)
