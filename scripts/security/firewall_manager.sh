#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Firewall Manager Script
# Gerenciador de firewall do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável pelo gerenciamento do firewall do Cluster AI.
#   Configura regras de segurança, gerencia portas, implementa
#   proteção contra ataques e fornece monitoramento de tráfego.
#   Suporta UFW, iptables e firewalld.
#
# Uso:
#   ./scripts/security/firewall_manager.sh [opções]
#
# Dependências:
#   - bash
#   - ufw (recomendado)
#   - iptables
#   - firewalld (alternativo)
#   - netstat (para verificação)
#
# Changelog:
#   v1.0.0 - 2024-12-19: Criação inicial com funcionalidades completas
#
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
FIREWALL_LOG="$LOG_DIR/firewall_manager.log"

# Configurações
DEFAULT_FIREWALL="ufw"
LOG_BLOCKED_ATTEMPTS="true"
RATE_LIMIT_CONNECTIONS="10"
RATE_LIMIT_WINDOW="60"
GEO_BLOCK_ENABLED="false"
ALLOWED_COUNTRIES=("BR" "US" "CA" "GB" "DE" "FR")

# Arrays para controle
ACTIVE_RULES=()
BLOCKED_IPS=()
FIREWALL_EVENTS=()

# Funções utilitárias
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar dependências
check_dependencies() {
    log_info "Verificando dependências do gerenciador de firewall..."

    local missing_deps=()
    local required_commands=(
        "ufw"
        "iptables"
        "netstat"
        "ss"
        "ip"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências necessárias e tente novamente"
        return 1
    fi

    log_success "Dependências verificadas"
    return 0
}

# Função para detectar firewall ativo
detect_firewall() {
    if sudo ufw status | grep -q "Status: active"; then
        echo "ufw"
    elif sudo systemctl is-active --quiet firewalld; then
        echo "firewalld"
    elif sudo iptables -L | grep -q "Chain INPUT"; then
        echo "iptables"
    else
        echo "none"
    fi
}

# Função para configurar UFW
configure_ufw() {
    log_info "Configurando UFW..."

    # Resetar UFW
    sudo ufw --force reset

    # Configurar políticas padrão
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Permitir portas essenciais do Cluster AI
    local cluster_ports=(
        "22/tcp"      # SSH
        "80/tcp"      # HTTP
        "443/tcp"     # HTTPS
        "8786/tcp"    # Dask Scheduler
        "8787/tcp"    # Dask Dashboard
        "11434/tcp"   # Ollama API
        "3000/tcp"    # OpenWebUI
        "9090/tcp"    # Prometheus
        "3001/tcp"    # Grafana
        "5601/tcp"    # Kibana
    )

    for port in "${cluster_ports[@]}"; do
        sudo ufw allow "$port"
        ACTIVE_RULES+=("ufw: $port")
    done

    # Configurar rate limiting para SSH
    sudo ufw limit ssh

    # Habilitar logging
    sudo ufw logging on

    # Habilitar UFW
    sudo ufw --force enable

    log_success "UFW configurado com sucesso"
}

# Função para configurar iptables
configure_iptables() {
    log_info "Configurando iptables..."

    # Limpar regras existentes
    sudo iptables -F
    sudo iptables -X
    sudo iptables -t nat -F
    sudo iptables -t nat -X
    sudo iptables -t mangle -F
    sudo iptables -t mangle -X

    # Políticas padrão
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT

    # Permitir loopback
    sudo iptables -A INPUT -i lo -j ACCEPT

    # Permitir conexões estabelecidas
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Portas do Cluster AI
    local cluster_ports=(
        "22"    # SSH
        "80"    # HTTP
        "443"   # HTTPS
        "8786"  # Dask Scheduler
        "8787"  # Dask Dashboard
        "11434" # Ollama API
        "3000"  # OpenWebUI
        "9090"  # Prometheus
        "3001"  # Grafana
        "5601"  # Kibana
    )

    for port in "${cluster_ports[@]}"; do
        sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
        ACTIVE_RULES+=("iptables: tcp/$port")
    done

    # Rate limiting para SSH
    sudo iptables -A INPUT -p tcp --dport 22 -m limit --limit "$RATE_LIMIT_CONNECTIONS"/minute --limit-burst 5 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 22 -j DROP

    # Logging de pacotes bloqueados
    sudo iptables -A INPUT -j LOG --log-prefix "FIREWALL_BLOCKED: " --log-level 4

    # Salvar regras
    sudo iptables-save > /etc/iptables/rules.v4

    log_success "iptables configurado com sucesso"
}

# Função para bloquear IP
block_ip() {
    local ip="$1"
    local reason="${2:-manual block}"

    log_info "Bloqueando IP $ip: $reason"

    local firewall=$(detect_firewall)

    case "$firewall" in
        "ufw")
            sudo ufw deny from "$ip"
            ;;
        "iptables")
            sudo iptables -I INPUT -s "$ip" -j DROP
            ;;
        "firewalld")
            sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$ip' reject"
            sudo firewall-cmd --reload
            ;;
    esac

    BLOCKED_IPS+=("$ip:$reason")
    log_success "IP $ip bloqueado"
}

# Função para desbloquear IP
unblock_ip() {
    local ip="$1"

    log_info "Desbloqueando IP $ip"

    local firewall=$(detect_firewall)

    case "$firewall" in
        "ufw")
            sudo ufw delete deny from "$ip"
            ;;
        "iptables")
            sudo iptables -D INPUT -s "$ip" -j DROP
            ;;
        "firewalld")
            sudo firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$ip' reject"
            sudo firewall-cmd --reload
            ;;
    esac

    # Remover da lista de IPs bloqueados
    BLOCKED_IPS=("${BLOCKED_IPS[@]/$ip:*}")

    log_success "IP $ip desbloqueado"
}

# Função para configurar proteção contra ataques
configure_attack_protection() {
    log_info "Configurando proteção contra ataques..."

    local firewall=$(detect_firewall)

    case "$firewall" in
        "ufw")
            # Rate limiting para serviços críticos
            sudo ufw limit ssh
            sudo ufw limit 80/tcp
            sudo ufw limit 443/tcp
            ;;
        "iptables")
            # Rate limiting para SSH
            sudo iptables -A INPUT -p tcp --dport 22 -m limit --limit "$RATE_LIMIT_CONNECTIONS"/minute --limit-burst 5 -j ACCEPT
            sudo iptables -A INPUT -p tcp --dport 22 -j DROP

            # Rate limiting para HTTP/HTTPS
            sudo iptables -A INPUT -p tcp --dport 80 -m limit --limit 100/minute --limit-burst 20 -j ACCEPT
            sudo iptables -A INPUT -p tcp --dport 80 -j DROP
            sudo iptables -A INPUT -p tcp --dport 443 -m limit --limit 100/minute --limit-burst 20 -j ACCEPT
            sudo iptables -A INPUT -p tcp --dport 443 -j DROP
            ;;
    esac

    log_success "Proteção contra ataques configurada"
}

# Função para monitorar tentativas de conexão
monitor_connection_attempts() {
    log_info "Monitorando tentativas de conexão..."

    local failed_attempts=$(sudo journalctl -u ssh --since "1 hour ago" | grep "Failed password" | wc -l)
    local blocked_count=$(sudo ufw status | grep "DENY" | wc -l 2>/dev/null || echo "0")

    if [ "$failed_attempts" -gt 10 ]; then
        log_warning "Muitas tentativas de login falharam: $failed_attempts"
        FIREWALL_EVENTS+=("High failed login attempts: $failed_attempts")
    fi

    if [ "$blocked_count" -gt 0 ]; then
        log_info "IPs bloqueados atualmente: $blocked_count"
    fi
}

# Função para gerar relatório de firewall
generate_firewall_report() {
    local report_file="$LOG_DIR/firewall_report_$(date +%Y%m%d_%H%M%S).log"

    cat > "$report_file" << EOF
=== Relatório de Firewall - Cluster AI ===
Data: $(date -Iseconds)
Firewall Ativo: $(detect_firewall)

1. Regras Ativas:
$(printf '  - %s\n' "${ACTIVE_RULES[@]}")

2. IPs Bloqueados:
$(printf '  - %s\n' "${BLOCKED_IPS[@]}")

3. Eventos de Segurança:
$(printf '  - %s\n' "${FIREWALL_EVENTS[@]}")

4. Estatísticas:
  - Regras ativas: ${#ACTIVE_RULES[@]}
  - IPs bloqueados: ${#BLOCKED_IPS[@]}
  - Eventos registrados: ${#FIREWALL_EVENTS[@]}

5. Configurações:
  - Rate limiting: $RATE_LIMIT_CONNECTIONS conexões por $RATE_LIMIT_WINDOW segundos
  - Logging de tentativas bloqueadas: $LOG_BLOCKED_ATTEMPTS
  - Bloqueio geográfico: $GEO_BLOCK_ENABLED

=== Fim do Relatório ===
EOF

    log_success "Relatório de firewall gerado: $report_file"
    echo "$report_file"
}

# Função para listar regras ativas
list_active_rules() {
    log_info "Listando regras ativas do firewall..."

    local firewall=$(detect_firewall)

    echo "=== Regras Ativas do Firewall ($firewall) ==="

    case "$firewall" in
        "ufw")
            sudo ufw status numbered
            ;;
        "iptables")
            sudo iptables -L -n --line-numbers
            ;;
        "firewalld")
            sudo firewall-cmd --list-all
            ;;
        "none")
            echo "Nenhum firewall ativo detectado"
            ;;
    esac
}

# Função para listar IPs bloqueados
list_blocked_ips() {
    log_info "Listando IPs bloqueados..."

    if [ ${#BLOCKED_IPS[@]} -eq 0 ]; then
        echo "Nenhum IP bloqueado"
        return 0
    fi

    echo "=== IPs Bloqueados ==="
    for blocked in "${BLOCKED_IPS[@]}"; do
        echo "  - $blocked"
    done
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"
    touch "$FIREWALL_LOG"

    local action="${1:-help}"

    case "$action" in
        "configure")
            check_dependencies || exit 1
            configure_ufw
            configure_attack_protection
            ;;
        "configure-iptables")
            check_dependencies || exit 1
            configure_iptables
            configure_attack_protection
            ;;
        "block")
            check_dependencies || exit 1
            block_ip "${2:-}" "${3:-manual block}"
            ;;
        "unblock")
            check_dependencies || exit 1
            unblock_ip "${2:-}"
            ;;
        "monitor")
            check_dependencies || exit 1
            monitor_connection_attempts
            ;;
        "report")
            check_dependencies || exit 1
            generate_firewall_report
            ;;
        "list-rules")
            list_active_rules
            ;;
        "list-blocked")
            list_blocked_ips
            ;;
        "status")
            local firewall=$(detect_firewall)
            echo "Firewall ativo: $firewall"
            if [ "$firewall" != "none" ]; then
                echo "Status: $(sudo ufw status | head -1 2>/dev/null || echo 'Active')"
            fi
            ;;
        "help"|*)
            echo "Cluster AI - Firewall Manager Script"
            echo ""
            echo "Uso: $0 <ação> [parâmetros]"
            echo ""
            echo "Ações:"
            echo "  configure              - Configurar UFW (recomendado)"
            echo "  configure-iptables     - Configurar iptables"
            echo "  block <ip> [reason]    - Bloquear IP específico"
            echo "  unblock <ip>           - Desbloquear IP"
            echo "  monitor                - Monitorar tentativas de conexão"
            echo "  report                 - Gerar relatório de firewall"
            echo "  list-rules             - Listar regras ativas"
            echo "  list-blocked           - Listar IPs bloqueados"
            echo "  status                 - Verificar status do firewall"
            echo "  help                   - Mostra esta mensagem"
            echo ""
            echo "Configurações:"
            echo "  - Rate limiting: $RATE_LIMIT_CONNECTIONS conexões por $RATE_LIMIT_WINDOW segundos"
            echo "  - Logging de tentativas bloqueadas: $LOG_BLOCKED_ATTEMPTS"
            echo "  - Bloqueio geográfico: $GEO_BLOCK_ENABLED"
            echo ""
            echo "Exemplos:"
            echo "  $0 configure"
            echo "  $0 block 192.168.1.100 \"Suspected attack\""
            echo "  $0 monitor"
            echo "  $0 report"
            ;;
    esac
}

# Executar função principal
main "$@"
