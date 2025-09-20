#!/bin/bash
# =============================================================================
# Script para baixar modelos do Ollama
# =============================================================================
# Downloads automáticos desabilitados por padrão
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: auto_download_models.sh
# =============================================================================

set -euo pipefail

# Carregar biblioteca comum
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# Configurações
LOG_FILE="${PROJECT_ROOT}/logs/model_downloads.log"
MODELS_DIR="${PROJECT_ROOT}/models"
CRON_SCHEDULE="0 0 * * *"  # Meia-noite diária

# Criar diretórios necessários
mkdir -p "$MODELS_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Função para log detalhado
log_model() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Verificar se downloads automáticos estão habilitados
check_auto_download() {
    if [[ "${AUTO_DOWNLOAD_MODELS:-false}" != "true" ]]; then
        log_model "Downloads automáticos desabilitados (AUTO_DOWNLOAD_MODELS=false)"
        return 1
    fi
    return 0
}

# Verificar conectividade com Ollama
check_ollama() {
    if ! curl -s "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
        log_model "Ollama não está respondendo na porta 11434"
        return 1
    fi
    return 0
}

# Obter lista de modelos instalados
get_installed_models() {
    ollama list 2>/dev/null | awk 'NR>1 {print $1}' | sort || echo ""
}

# Verificar se modelo já está instalado
is_model_installed() {
    local model="$1"
    local installed_models="$2"
    echo "$installed_models" | grep -q "^${model}$"
}

# Instalar modelo com progresso
install_model() {
    local model="$1"
    local description="$2"

    log_model "📥 Iniciando download: $model"
    log_model "   Descrição: $description"

    if ollama pull "$model" >> "$LOG_FILE" 2>&1; then
        success "✅ Modelo $model instalado com sucesso"
        return 0
    else
        error "❌ Falha ao instalar $model"
        return 1
    fi
}

# Lista de modelos essenciais para o Cluster AI
get_essential_models() {
    cat << 'EOF'
llama3:8b:Modelo conversacional balanceado da Meta
mistral:7b:Modelo eficiente da Mistral AI
gemma:2b:Modelo leve do Google
codellama:7b:Especialista em geração de código
phi-3:3.8b:Modelo compacto da Microsoft
qwen2:7b:Modelo versátil da Alibaba
deepseek-coder:6.7b:Modelo otimizado para programação
tinyllama:1.1b:Modelo ultracompacto
EOF
}

# Função principal de download
download_models() {
    log_model "=== INICIANDO DOWNLOAD DE MODELOS ==="
    log_model "Data/Hora: $(date)"
    log_model "Usuário: $(whoami)"

    # Verificar pré-requisitos
    if ! check_ollama; then
        error "Ollama não está disponível. Abortando download."
        return 1
    fi

    if ! check_auto_download; then
        log_model "Downloads automáticos desabilitados. Execute manualmente se necessário."
        return 0
    fi

    # Obter modelos já instalados
    local installed_models
    installed_models=$(get_installed_models)
    local installed_count=$(echo "$installed_models" | wc -l)
    log_model "Modelos já instalados: $installed_count"

    # Contadores
    local total_models=0
    local installed_count=0
    local skipped_count=0
    local failed_count=0

    # Processar modelos essenciais
    log_model "🔍 Verificando modelos essenciais..."
    while IFS=':' read -r model description; do
        # Remover espaços extras
        model=$(echo "$model" | xargs)
        description=$(echo "$description" | xargs)

        if [[ -z "$model" || "$model" == "#"* ]]; then
            continue
        fi

        ((total_models++))

        if is_model_installed "$model" "$installed_models"; then
            log_model "⏭️  Modelo $model já instalado - pulando"
            ((skipped_count++))
        else
            log_model "📥 Novo modelo encontrado: $model"
            if install_model "$model" "$description"; then
                ((installed_count++))
            else
                ((failed_count++))
            fi
        fi
    done < <(get_essential_models)

    # Resumo final
    log_model "=== RESUMO DO DOWNLOAD ==="
    log_model "Total de modelos processados: $total_models"
    log_model "✅ Instalados com sucesso: $installed_count"
    log_model "⏭️  Já estavam instalados: $skipped_count"
    log_model "❌ Falharam: $failed_count"

    if [[ $failed_count -eq 0 ]]; then
        success "🎉 Download de modelos concluído com sucesso!"
    else
        warn "⚠️  Alguns modelos falharam. Verifique o log para detalhes."
    fi

    return $failed_count
}

# Função para configurar cron job
setup_cron() {
    log_model "⚙️  Configurando cron job para downloads automáticos..."

    # Remover cron jobs existentes para este script
    crontab -l 2>/dev/null | grep -v "auto_download_models.sh" | crontab - 2>/dev/null || true

    # Adicionar novo cron job
    (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $PROJECT_ROOT/scripts/ollama/auto_download_models.sh") | crontab -

    if [[ $? -eq 0 ]]; then
        success "✅ Cron job configurado: $CRON_SCHEDULE"
        log_model "O script será executado automaticamente todos os dias à meia-noite"
    else
        error "❌ Falha ao configurar cron job"
        return 1
    fi
}

# Função para verificar status
check_status() {
    log_model "📊 STATUS DOS MODELOS DO OLLAMA"
    log_model "================================="

    if ! check_ollama; then
        error "Ollama não está rodando"
        return 1
    fi

    local models
    models=$(ollama list 2>/dev/null)

    if [[ -z "$models" ]]; then
        warn "Nenhum modelo instalado"
        return 1
    fi

    echo "$models" | while IFS= read -r line; do
        log_model "  $line"
    done

    local count=$(echo "$models" | wc -l)
    log_model "Total: $((count - 1)) modelos instalados"
}

# Processar argumentos
case "${1:-}" in
    "download"|"--download"|"-d")
        download_models
        ;;
    "setup"|"--setup"|"-s")
        setup_cron
        ;;
    "status"|"--status"|"-st")
        check_status
        ;;
    "enable"|"--enable"|"-e")
        log_model "Habilitando downloads automáticos..."
        export AUTO_DOWNLOAD_MODELS=true
        download_models
        ;;
    "help"|"--help"|"-h"|"")
        cat << 'EOF'
📖 Script de Download Automático de Modelos do Ollama

USO:
    ./auto_download_models.sh [COMANDO]

COMANDOS:
    download, -d    Baixar modelos essenciais
    setup, -s       Configurar cron job para downloads automáticos
    status, -st     Verificar status dos modelos instalados
    enable, -e      Habilitar e executar downloads automáticos
    help, -h        Mostrar esta ajuda

CONFIGURAÇÃO:
    - Downloads automáticos são controlados pela variável AUTO_DOWNLOAD_MODELS
    - Por padrão, está desabilitado (AUTO_DOWNLOAD_MODELS=false)
    - Configure AUTO_DOWNLOAD_MODELS=true para habilitar downloads automáticos

EXEMPLO:
    # Habilitar downloads automáticos
    export AUTO_DOWNLOAD_MODELS=true

    # Executar download manual
    ./auto_download_models.sh download

    # Configurar cron job
    ./auto_download_models.sh setup

CRON JOB:
    O script pode ser configurado para executar automaticamente:
    - Horário: Meia-noite diária (0 0 * * *)
    - Local: Configurado automaticamente pelo comando 'setup'

LOG:
    Todos os logs são salvos em: logs/model_downloads.log
EOF
        ;;
    *)
        error "Comando inválido: $1"
        echo "Use 'help' para ver as opções disponíveis"
        exit 1
        ;;
esac
