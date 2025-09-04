#!/bin/bash
# Utilitários de Progresso e Retry para Scripts do Cluster AI

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

# Cores para barras de progresso
PROGRESS_COLOR='\033[0;32m'
PROGRESS_BG='\033[0;42m'
PROGRESS_RESET='\033[0m'

# ==================== FUNÇÕES DE BARRA DE PROGRESSO ====================

# Função para mostrar barra de progresso simples
show_progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"
    local label="${4:-Progress}"

    # Calcular porcentagem
    local percentage=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))

    # Construir barra
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar="${bar}█"
    done
    for ((i=0; i<empty; i++)); do
        bar="${bar}░"
    done

    # Mostrar progresso
    printf "\r${PROGRESS_COLOR}%s: [${PROGRESS_BG}%s${PROGRESS_RESET}${PROGRESS_COLOR}%s${PROGRESS_RESET}] %d%% (%d/%d)" \
           "$label" "$bar" "" "$percentage" "$current" "$total"
}

# Função para finalizar barra de progresso
finish_progress_bar() {
    echo ""  # Nova linha após completar
}

# Função para mostrar spinner de carregamento
show_spinner() {
    local pid="$1"
    local message="${2:-Processando}"
    local spin_chars="/-\|"

    while kill -0 "$pid" 2>/dev/null; do
        for ((i=0; i<${#spin_chars}; i++)); do
            printf "\r${PROGRESS_COLOR}%s... %s${PROGRESS_RESET}" "$message" "${spin_chars:i:1}"
            sleep 0.1
        done
    done

    printf "\r${PROGRESS_COLOR}%s... Concluído!${PROGRESS_RESET}\n" "$message"
}

# ==================== FUNÇÕES DE RETRY ====================

# Função para executar comando com retry
retry_command() {
    local max_attempts="${1:-3}"
    local delay="${2:-2}"
    local command="$3"
    local description="${4:-comando}"

    local attempt=1
    local exit_code=1

    while [ $attempt -le $max_attempts ]; do
        log "INFO" "Tentativa $attempt/$max_attempts: $description"

        if eval "$command"; then
            success "$description executado com sucesso na tentativa $attempt"
            return 0
        else
            exit_code=$?
            if [ $attempt -lt $max_attempts ]; then
                warn "Tentativa $attempt falhou. Tentando novamente em $delay segundos..."
                sleep "$delay"
                # Aumentar delay exponencialmente
                delay=$(( delay * 2 ))
            fi
        fi

        ((attempt++))
    done

    error "Todas as $max_attempts tentativas falharam para: $description"
    return $exit_code
}

# Função para retry com backoff exponencial
retry_with_backoff() {
    local max_attempts="${1:-5}"
    local base_delay="${2:-1}"
    local max_delay="${3:-60}"
    local command="$4"
    local description="${5:-comando}"

    local attempt=1
    local delay="$base_delay"

    while [ $attempt -le $max_attempts ]; do
        log "INFO" "Tentativa $attempt/$max_attempts: $description (delay: ${delay}s)"

        if eval "$command"; then
            success "$description executado com sucesso na tentativa $attempt"
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                warn "Tentativa $attempt falhou. Próxima tentativa em ${delay}s..."
                sleep "$delay"

                # Calcular próximo delay (backoff exponencial com jitter)
                delay=$(( delay * 2 ))
                if [ $delay -gt $max_delay ]; then
                    delay=$max_delay
                fi

                # Adicionar jitter (±25%)
                local jitter=$(( delay / 4 ))
                local random_jitter=$(( RANDOM % (jitter * 2) - jitter ))
                delay=$(( delay + random_jitter ))
                if [ $delay -lt 1 ]; then
                    delay=1
                fi
            fi
        fi

        ((attempt++))
    done

    error "Todas as $max_attempts tentativas falharam para: $description"
    return 1
}

# Função para retry específico para operações de rede
retry_network_operation() {
    local url="$1"
    local max_attempts="${2:-3}"
    local timeout="${3:-10}"
    local description="${4:-conexão}"

    retry_with_backoff "$max_attempts" 2 30 \
        "curl -f --max-time $timeout '$url' >/dev/null 2>&1" \
        "$description com $url"
}

# ==================== FUNÇÕES DE PROGRESSO PARA OPERAÇÕES COMUNS ====================

# Função para instalar pacotes com progresso
install_packages_with_progress() {
    local packages=("$@")
    local total=${#packages[@]}
    local current=0

    section "Instalando Pacotes do Sistema"

    for package in "${packages[@]}"; do
        ((current++))
        show_progress_bar "$current" "$total" 40 "Instalando pacotes"

        if ! install_package_with_fallback "$package"; then
            warn "Falha ao instalar: $package"
        fi
    done

    finish_progress_bar
    success "Instalação de pacotes concluída"
}

# Função para download com progresso e retry
download_with_progress() {
    local url="$1"
    local output="$2"
    local description="${3:-download}"

    log "Baixando: $description"

    # Executar download em background para mostrar spinner
    (
        curl -L -o "$output" "$url" 2>/dev/null
    ) &
    local pid=$!

    show_spinner "$pid" "Baixando $description"

    wait "$pid"
    local exit_code=$?

    if [ $exit_code -eq 0 ] && [ -f "$output" ]; then
        success "$description baixado com sucesso"
        return 0
    else
        error "Falha no download: $description"
        return 1
    fi
}

# Função para executar comando longo com progresso
run_long_command() {
    local command="$1"
    local description="$2"
    local timeout="${3:-300}"  # 5 minutos por padrão

    log "Executando: $description"

    # Executar comando em background
    (
        eval "$command"
    ) &
    local pid=$!

    # Monitorar progresso
    local start_time=$(date +%s)
    local elapsed=0

    while kill -0 "$pid" 2>/dev/null; do
        elapsed=$(( $(date +%s) - start_time ))

        if [ $elapsed -ge $timeout ]; then
            warn "Timeout atingido ($timeout segundos) para: $description"
            kill "$pid" 2>/dev/null || true
            return 1
        fi

        printf "\r${PROGRESS_COLOR}%s... (%ds)${PROGRESS_RESET}" "$description" "$elapsed"
        sleep 1
    done

    echo ""  # Nova linha

    wait "$pid"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        success "$description concluído em ${elapsed}s"
        return 0
    else
        error "$description falhou após ${elapsed}s"
        return $exit_code
    fi
}

# ==================== FUNÇÕES DE VALIDAÇÃO COM PROGRESSO ====================

# Função para validar lista de itens com progresso
validate_items_with_progress() {
    local items=("$@")
    local total=${#items[@]}
    local current=0
    local valid=0
    local invalid=0

    section "Validando Itens"

    for item in "${items[@]}"; do
        ((current++))
        show_progress_bar "$current" "$total" 40 "Validando"

        if validate_item "$item"; then
            ((valid++))
        else
            ((invalid++))
        fi
    done

    finish_progress_bar

    log "Validação concluída: $valid válidos, $invalid inválidos"

    if [ $invalid -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Função placeholder para validação de item (deve ser sobrescrita)
validate_item() {
    local item="$1"
    # Implementação específica deve ser fornecida pelo script que usar esta função
    return 0
}

# ==================== FUNÇÕES DE RELATÓRIO ====================

# Função para gerar relatório de progresso
generate_progress_report() {
    local report_file="$1"
    local start_time="$2"
    local end_time="$3"
    local operations="$4"

    local duration=$(( end_time - start_time ))

    cat > "$report_file" << EOF
RELATÓRIO DE PROGRESSO - CLUSTER AI
=====================================

Data/Hora de Início: $(date -d "@$start_time")
Data/Hora de Fim: $(date -d "@$end_time")
Duração Total: ${duration}s

OPERAÇÕES REALIZADAS:
$operations

RESUMO:
- Tempo total: ${duration}s
- Status: $(if [ $? -eq 0 ]; then echo "SUCESSO"; else echo "FALHA"; fi)

=====================================
EOF

    success "Relatório de progresso salvo em: $report_file"
}

# ==================== FUNÇÃO DE INICIALIZAÇÃO ====================

# Função para inicializar sistema de progresso
init_progress_system() {
    # Verificar se estamos em um terminal interativo
    if [ -t 1 ]; then
        # Terminal interativo - usar cores e barras de progresso
        export PROGRESS_ENABLED=true
    else
        # Não interativo (log file, pipe, etc.) - desabilitar elementos visuais
        export PROGRESS_ENABLED=false
    fi

    log "Sistema de progresso inicializado (Interativo: $PROGRESS_ENABLED)"
}

# ==================== EXEMPLO DE USO ====================

# Exemplo de função que demonstra o uso do sistema
demo_progress_system() {
    section "Demonstração do Sistema de Progresso"

    # Inicializar sistema
    init_progress_system

    # Exemplo 1: Barra de progresso simples
    subsection "Exemplo 1: Barra de Progresso"
    for i in {1..10}; do
        show_progress_bar "$i" 10 30 "Processando"
        sleep 0.2
    done
    finish_progress_bar

    # Exemplo 2: Spinner
    subsection "Exemplo 2: Spinner"
    (
        sleep 3
        echo "Comando simulado concluído"
    ) &
    local demo_pid=$!
    show_spinner "$demo_pid" "Executando comando de demonstração"

    # Exemplo 3: Retry
    subsection "Exemplo 3: Sistema de Retry"
    retry_command 3 1 "echo 'Comando de teste'" "comando de teste"

    success "Demonstração concluída!"
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    case "${1:-demo}" in
        demo)
            demo_progress_system
            ;;
        init)
            init_progress_system
            ;;
        *)
            echo "Uso: $0 [demo|init]"
            echo "  demo - Executa demonstração do sistema"
            echo "  init - Inicializa sistema de progresso"
            ;;
    esac
}

# Executar apenas se chamado diretamente
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
