#!/bin/bash
# Sistema de Gerenciamento de Backup para o Cluster AI
#
# Este script automatiza o backup de componentes críticos, incluindo:
# - Modelos Ollama
# - Dados do OpenWebUI
# - Configurações do Cluster
# - Chaves SSH e outras configurações do usuário

# Carregar funções comuns
COMMON_SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")/../utils/common.sh"
if [ -f "$COMMON_SCRIPT_PATH" ]; then
    # shellcheck source=../utils/common.sh
    source "$COMMON_SCRIPT_PATH"
else
    # Fallback para cores e logs se common.sh não for encontrado
    RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
    error() { echo -e "${RED}[ERROR]${NC} $1"; }
    warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log() { echo -e "${GREEN}[INFO]${NC} $1"; }
    success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
    section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
    confirm_operation() {
        read -p "$1 (s/N): " -n 1 -r; echo
        [[ $REPLY =~ ^[Ss]$ ]]
    }
fi

# --- Configurações ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_BASE_DIR="$PROJECT_ROOT/backups" # Salvar backups dentro da pasta do projeto
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30 # Dias para manter os backups

# --- Componentes para Backup ---
# Adicionar ou remover caminhos conforme necessário
# Usando $PROJECT_ROOT para caminhos relativos ao projeto
COMPONENTS_FULL=(
    "$HOME/.ollama"
    "$HOME/open-webui" # Assumindo que os dados do OpenWebUI estão aqui
    "$PROJECT_ROOT/.cluster_config"
    "$PROJECT_ROOT/scripts" # Scripts de instalação, utils, etc.
    "$PROJECT_ROOT/.venv" # Ambiente virtual
    "$HOME/.msmtprc"
    "$HOME/.gmail_pass.gpg"
    "$HOME/.ssh"
)
COMPONENTS_MODELS=("$HOME/.ollama")
COMPONENTS_CONFIG=(
    "$PROJECT_ROOT/.cluster_config"
    "$PROJECT_ROOT/scripts"
    "$HOME/.msmtprc"
    "$HOME/.gmail_pass.gpg"
    "$HOME/.ssh"
)
COMPONENTS_WEBUI=("$HOME/open-webui")

# --- Funções ---

# Função de ajuda
show_help() {
    echo "Uso: $0 [comando]"
    echo "Gerencia backups para o Cluster AI."
    echo ""
    echo "Comandos:"
    echo "  full      - Realiza um backup completo de todos os componentes."
    echo "  models    - Realiza um backup apenas dos modelos Ollama."
    echo "  config    - Realiza um backup apenas das configurações do cluster."
    echo "  webui     - Realiza um backup apenas dos dados do OpenWebUI."
    echo "  list      - Lista todos os backups existentes."
    echo "  cleanup   - Remove backups mais antigos que $RETENTION_DAYS dias."
    echo "  help      - Mostra esta ajuda."
}

# Função principal de backup
# Argumentos: 1=Nome do arquivo de saída, 2=Array de componentes
do_backup() {
    local backup_name="$1"
    shift
    local components_to_backup=("$@")
    local backup_file="$BACKUP_BASE_DIR/${backup_name}_${TIMESTAMP}.tar.gz"
    local existing_components=()

    log "Iniciando backup: $backup_name"
    log "Arquivo de destino: $backup_file"

    # Verificar quais componentes existem
    for component in "${components_to_backup[@]}"; do
        if [ -e "$component" ]; then
            existing_components+=("$component")
        else
            warn "Componente não encontrado, pulando: $component"
        fi
    done

    if [ ${#existing_components[@]} -eq 0 ]; then
        error "Nenhum componente encontrado para o backup. Operação abortada."
        return 1
    fi

    # Criar diretório de backup se não existir
    mkdir -p "$BACKUP_BASE_DIR"

    # Criar o arquivo de backup
    log "Componentes a serem incluídos: ${existing_components[*]}"
    tar -czf "$backup_file" --absolute-names "${existing_components[@]}"
    
    if [ $? -eq 0 ]; then
        success "Backup '$backup_name' concluído com sucesso!"
        log "Tamanho do backup: $(du -h "$backup_file" | cut -f1)"
    else
        error "Falha ao criar o arquivo de backup. Verifique as permissões e o espaço em disco."
        rm -f "$backup_file" # Remove arquivo parcial em caso de erro
        return 1
    fi
}

# Função para listar backups
list_backups() {
    section "Backups Existentes em $BACKUP_BASE_DIR"
    if [ -d "$BACKUP_BASE_DIR" ] && [ -n "$(ls -A "$BACKUP_BASE_DIR"/*.tar.gz 2>/dev/null)" ]; then
        ls -lh "$BACKUP_BASE_DIR" | awk '{print "  " $9 " (" $5 ") - " $6 " " $7 " " $8}'
    else
        warn "Nenhum backup encontrado."
    fi
}

# Função para limpar backups antigos
cleanup_backups() {
    section "Limpando Backups Antigos (mais de $RETENTION_DAYS dias)"
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        warn "Diretório de backup não existe. Nada a fazer."
        return
    fi

    log "Procurando por backups com mais de $RETENTION_DAYS dias em '$BACKUP_BASE_DIR'..."
    # Armazena os arquivos a serem deletados em um array para um manuseio mais seguro
    mapfile -t files_to_delete < <(find "$BACKUP_BASE_DIR" -name "*.tar.gz" -mtime +"$RETENTION_DAYS")

    if [ ${#files_to_delete[@]} -eq 0 ]; then
        log "Nenhum backup antigo para remover."
        return
    fi

    echo "Os seguintes arquivos serão removidos:"
    printf "  - %s\n" "${files_to_delete[@]}"

    if confirm_operation "Deseja continuar com a remoção destes arquivos?"; then
        # Usar print0 e xargs para segurança com nomes de arquivos que possam ter espaços
        find "$BACKUP_BASE_DIR" -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -print0 | xargs -0 -r rm -f
        success "Backups antigos removidos com sucesso."
    else
        warn "Operação de limpeza cancelada."
    fi
}

# --- Execução ---
main() {
    case "$1" in
        full)
            do_backup "cluster_full" "${COMPONENTS_FULL[@]}"
            ;;
        models)
            do_backup "ollama_models" "${COMPONENTS_MODELS[@]}"
            ;;
        config)
            do_backup "cluster_config" "${COMPONENTS_CONFIG[@]}"
            ;;
        webui)
            do_backup "openwebui_data" "${COMPONENTS_WEBUI[@]}"
            ;;
        list)
            list_backups
            ;;
        cleanup)
            cleanup_backups
            ;;
        help|--help|-h|"")
            show_help
            ;;
        *)
            error "Comando desconhecido: '$1'"
            show_help
            exit 1
            ;;
    esac
}

main "$@"