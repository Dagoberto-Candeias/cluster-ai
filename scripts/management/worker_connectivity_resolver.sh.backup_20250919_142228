#!/bin/bash
# Script para resolver problemas de conectividade dos workers do Cluster AI
# Integra descoberta automática, diagnóstico e resolução de problemas

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"
MANAGEMENT_DIR="${PROJECT_ROOT}/scripts/management"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# Funções auxiliares locais (fallback)
if ! command -v info >/dev/null 2>&1; then
    info() {
        echo "[INFO] $1"
    }
fi

if ! command -v warn >/dev/null 2>&1; then
    warn() {
        echo "[WARN] $1"
    }
fi

if ! command -v error >/dev/null 2>&1; then
    error() {
        echo "[ERROR] $1"
    }
fi

if ! command -v success >/dev/null 2>&1; then
    success() {
        echo "[SUCCESS] $1"
    }
fi

if ! command -v progress >/dev/null 2>&1; then
    progress() {
        echo "[...] $1"
    }
fi

if ! command -v section >/dev/null 2>&1; then
    section() {
        echo
        echo "=============================="
        echo " $1"
        echo "=============================="
    }
fi

if ! command -v subsection >/dev/null 2>&1; then
    subsection() {
        echo
        echo "--- $1 ---"
    }
fi

# --- Constantes ---
NODES_LIST_FILE="$HOME/.cluster_config/nodes_list.conf"
CLUSTER_PORTS=(22 8786 8787 11434 3000)  # SSH, Dask, Ollama, OpenWebUI
DIAGNOSTIC_LOG="${PROJECT_ROOT}/logs/worker_connectivity_diagnostic.log"

# --- Funções de Diagnóstico ---

# Diagnóstico completo de conectividade
diagnostic_worker_connectivity() {
    local worker_name="$1"
    local worker_ip="$2"
    local worker_user="$3"
    local worker_port="$4"

    section "🔍 Diagnóstico de Conectividade: $worker_name"

    local issues_found=()
    local recommendations=()

    # 1. Teste de ping
    progress "1/5 - Testando conectividade básica (ping)..."
    if ping -c 3 -W 2 "$worker_ip" >/dev/null 2>&1; then
        success "  ✅ Ping bem-sucedido para $worker_ip"
    else
        warn "  ❌ Ping falhou para $worker_ip"
        issues_found+=("ping_failed")
        recommendations+=("Verificar se o worker está ligado e conectado à mesma rede")
    fi

    # 2. Verificar entrada ARP
    progress "2/5 - Verificando tabela ARP..."
    local arp_entry
    arp_entry=$(arp -n "$worker_ip" 2>/dev/null | grep "$worker_ip" || echo "")

    if [ -n "$arp_entry" ]; then
        local mac_address
        mac_address=$(echo "$arp_entry" | awk '{print $3}')
        if [ "$mac_address" != "(incomplete)" ]; then
            success "  ✅ Entrada ARP encontrada: $mac_address"
        else
            warn "  ❌ Entrada ARP incompleta"
            issues_found+=("arp_incomplete")
            recommendations+=("Possível problema de resolução MAC - verificar switches/routers")
        fi
    else
        warn "  ❌ Nenhuma entrada ARP encontrada"
        issues_found+=("no_arp_entry")
        recommendations+=("Worker não está na mesma rede ou não está respondendo a ARP")
    fi

    # 3. Teste de portas
    progress "3/5 - Verificando portas do cluster..."
    local open_ports=()
    for port in "${CLUSTER_PORTS[@]}"; do
        if timeout 3 bash -c "echo >/dev/tcp/$worker_ip/$port" 2>/dev/null; then
            case $port in
                22) open_ports+=("SSH") ;;
                8786) open_ports+=("Dask-Scheduler") ;;
                8787) open_ports+=("Dask-Dashboard") ;;
                11434) open_ports+=("Ollama") ;;
                3000) open_ports+=("OpenWebUI") ;;
            esac
        fi
    done

    if [ ${#open_ports[@]} -gt 0 ]; then
        success "  ✅ Portas abertas encontradas: ${open_ports[*]}"
    else
        warn "  ❌ Nenhuma porta do cluster aberta"
        issues_found+=("no_cluster_ports")
        recommendations+=("Worker pode não ter serviços do cluster rodando")
    fi

    # 4. Teste SSH
    progress "4/5 - Testando conectividade SSH..."
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$worker_port" "$worker_user@$worker_ip" "echo 'SSH OK'" 2>/dev/null; then
        success "  ✅ SSH acessível com chave"
    else
        warn "  ❌ SSH não acessível"
        issues_found+=("ssh_failed")
        recommendations+=("Configurar chave SSH ou verificar credenciais")
    fi

    # 5. Verificar hostname
    progress "5/5 - Verificando resolução de hostname..."
    local resolved_hostname
    resolved_hostname=$(getent hosts "$worker_ip" | awk '{print $2}' | head -1 || echo "")

    if [ -n "$resolved_hostname" ]; then
        success "  ✅ Hostname resolvido: $resolved_hostname"
    else
        info "  ℹ️  Hostname não resolvido (usando IP)"
    fi

    # Resumo do diagnóstico
    section "📊 Resumo do Diagnóstico: $worker_name"

    if [ ${#issues_found[@]} -eq 0 ]; then
        success "✅ Worker $worker_name está totalmente acessível!"
        return 0
    else
        warn "⚠️  Problemas encontrados: ${#issues_found[@]}"
        for issue in "${issues_found[@]}"; do
            echo "  - $issue"
        done

        echo
        info "💡 Recomendações para resolver:"
        for rec in "${recommendations[@]}"; do
            echo "  - $rec"
        done

        return 1
    fi
}

# --- Funções de Resolução ---

# Tentar resolver problemas automaticamente
auto_resolve_connectivity_issues() {
    local worker_name="$1"
    local worker_ip="$2"
    local worker_user="$3"
    local worker_port="$4"

    section "🔧 Tentando Resolver Problemas Automaticamente: $worker_name"

    local fixes_applied=()

    # 1. Tentar descobrir IP correto se o atual não funcionar
    progress "1/4 - Verificando se IP está correto..."
    if ! ping -c 1 -W 2 "$worker_ip" >/dev/null 2>&1; then
        info "  🔍 Procurando IP alternativo para $worker_name..."

        # Reutilizar a função de descoberta de rede, que é mais completa
        local discovered_info
        # A função discover_workers_network retorna "hostname:ip:port"
        discovered_info=$(discover_workers_network | grep "^${worker_name}:")

        if [ -n "$discovered_info" ]; then
            local new_ip
            new_ip=$(echo "$discovered_info" | head -1 | cut -d':' -f2)

            if [ -n "$new_ip" ] && [ "$new_ip" != "$worker_ip" ]; then
                warn "  📝 IP atual ($worker_ip) para '$worker_name' parece incorreto."
                success "  💡 IP alternativo encontrado via descoberta de rede: $new_ip"
                info "  🔄 Para corrigir, use a opção '5) Atualizar configuração de worker' no menu ou execute:"
                info "     ./scripts/management/worker_connectivity_resolver.sh update"
                # Apenas sugere, não aplica automaticamente para evitar erros.
                fixes_applied+=("suggested_ip_update:$new_ip")
            fi
        fi
    fi

    # 2. Verificar e atualizar chave SSH no known_hosts
    progress "2/4 - Verificando chave SSH..."
    if ! ssh-keyscan -H "$worker_ip" >> ~/.ssh/known_hosts 2>/dev/null; then
        info "  ℹ️  Chave SSH adicionada ao known_hosts"
    fi

    # 3. Tentar configurar SSH se possível
    progress "3/4 - Verificando configuração SSH..."
    if ! ssh -o BatchMode=yes -o ConnectTimeout=3 "$worker_user@$worker_ip" "echo 'test'" 2>/dev/null; then
        info "  🔑 SSH requer configuração manual"
        info "  💡 Execute: ./scripts/setup_ssh_workers.sh"
        fixes_applied+=("ssh_config_needed")
    fi

    # 4. Verificar se worker tem projeto cluster-ai
    progress "4/4 - Verificando instalação do Cluster AI..."
    if ssh -o BatchMode=yes -o ConnectTimeout=3 "$worker_user@$worker_ip" "test -d ~/Projetos/cluster-ai" 2>/dev/null; then
        success "  ✅ Projeto Cluster AI encontrado"
    else
        warn "  ❌ Projeto Cluster AI não encontrado"
        info "  💡 Execute no worker: git clone <repo> ~/Projetos/cluster-ai"
        fixes_applied+=("cluster_ai_missing")
    fi

    # Resumo das correções aplicadas
    if [ ${#fixes_applied[@]} -gt 0 ]; then
        section "📋 Correções Aplicadas/Sugeridas: $worker_name"
        for fix in "${fixes_applied[@]}"; do
            echo "  - $fix"
        done
    else
        success "✅ Nenhuma correção adicional necessária"
    fi
}

# --- Funções de Descoberta ---

# Descobrir workers na rede usando múltiplas técnicas
discover_workers_network() {
    section "🔍 Descobrindo Workers na Rede"

    local discovered_workers=()

    # 1. Escanear rede local com nmap
    progress "1/3 - Escaneando rede local..."
    if command_exists nmap; then
        local network_range
        network_range=$(ip route | grep default | awk '{print $3}' | cut -d'.' -f1-3).0/24

        info "  📡 Escaneando rede: $network_range"

        local scan_results
        scan_results=$(nmap -sn "$network_range" 2>/dev/null | grep "Nmap scan" | awk '{print $5}' | while read -r ip; do
            # Verificar se tem portas SSH abertas
            if timeout 3 bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null; then
                local hostname
                hostname=$(getent hosts "$ip" | awk '{print $2}' | head -1 || echo "unknown-$ip")
                echo "$hostname:$ip:22"
            fi
        done)

        discovered_workers+=($scan_results)
    else
        warn "  ⚠️  nmap não encontrado - pulando escaneamento de rede"
    fi

    # 2. Verificar tabela ARP
    progress "2/3 - Verificando tabela ARP..."
    local arp_workers
    if command_exists arp; then
        arp_workers=$(arp -a | grep -v incomplete | while read -r line; do
            local ip hostname
            ip=$(echo "$line" | awk '{print $2}' | tr -d '()')
            hostname=$(echo "$line" | awk '{print $1}')

            # Verificar se tem SSH
            if timeout 3 bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null; then
                echo "$hostname:$ip:22"
            fi
        done)
    else
        info "  ℹ️  arp não disponível, usando ip neigh"
        arp_workers=$(ip neigh | grep -v FAILED | while read -r line; do
            local ip hostname
            ip=$(echo "$line" | awk '{print $1}')
            hostname=$(echo "$line" | awk '{print $5}')

            # Verificar se tem SSH
            if timeout 3 bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null; then
                echo "$hostname:$ip:22"
            fi
        done)
    fi

    discovered_workers+=($arp_workers)

    # 3. Buscar via mDNS/avahi
    progress "3/3 - Buscando via mDNS..."
    if command_exists avahi-browse; then
        local mdns_workers
        mdns_workers=$(timeout 10 avahi-browse -t -r _ssh._tcp 2>/dev/null | grep "=;" | while read -r line; do
            local hostname ip port
            hostname=$(echo "$line" | awk -F';' '{print $7}')
            ip=$(echo "$line" | awk -F';' '{print $8}')
            port=$(echo "$line" | awk -F';' '{print $9}')

            if [ -n "$hostname" ] && [ -n "$ip" ]; then
                echo "$hostname:$ip:$port"
            fi
        done)

        discovered_workers+=($mdns_workers)
    else
        info "  ℹ️  avahi-browse não disponível - pulando mDNS"
    fi

    # Remover duplicatas e mostrar resultados
    local unique_workers
    unique_workers=$(printf '%s\n' "${discovered_workers[@]}" | sort | uniq)

    if [ -n "$unique_workers" ]; then
        success "✅ Workers descobertos na rede:"
        echo "$unique_workers" | while IFS=':' read -r hostname ip port; do
            echo "  - $hostname ($ip:$port)"
        done
        echo "$unique_workers"
    else
        warn "⚠️  Nenhum worker descoberto na rede"
        echo ""
    fi
}

# --- Funções de Configuração ---

# Atualizar configuração do worker
update_worker_config() {
    local worker_name="$1"
    local new_ip="$2"
    local new_user="${3:-$USER}"
    local new_port="${4:-22}"

    section "📝 Atualizando Configuração do Worker: $worker_name"

    # Criar backup
    if [ -f "$NODES_LIST_FILE" ]; then
        cp "$NODES_LIST_FILE" "${NODES_LIST_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Verificar se worker já existe
    if grep -q "^$worker_name " "$NODES_LIST_FILE" 2>/dev/null; then
        # Atualizar entrada existente
        sed -i "s|^$worker_name .*|$worker_name $new_ip $new_user $new_port active|" "$NODES_LIST_FILE"
        success "✅ Configuração atualizada para $worker_name"
    else
        # Adicionar nova entrada
        echo "$worker_name $new_ip $new_user $new_port active" >> "$NODES_LIST_FILE"
        success "✅ Worker $worker_name adicionado à configuração"
    fi

    # Sincronizar a mudança para o cluster.conf
    bash "${PROJECT_ROOT}/scripts/utils/sync_config.sh"
}

# --- Função Principal ---

# Resolver conectividade de todos os workers
resolve_all_workers_connectivity() {
    section "🚀 Resolução Completa de Conectividade dos Workers"

    if [ ! -f "$NODES_LIST_FILE" ]; then
        error "Arquivo de configuração dos workers não encontrado: $NODES_LIST_FILE"
        info "Execute primeiro: ./manager.sh configure"
        return 1
    fi

    local total_workers=0
    local healthy_workers=0
    local fixed_workers=0

    while IFS= read -r line; do
        [[ $line =~ ^# ]] && continue
        [[ -z $line ]] && continue

        ((total_workers++))

        local worker_name worker_ip worker_user worker_port status
        read -r worker_name worker_ip worker_user worker_port status <<< "$line"

        # Usar valores padrão se não especificados
        worker_user=${worker_user:-$USER}
        worker_port=${worker_port:-22}
        status=${status:-inactive}

        subsection "Processando Worker $total_workers: $worker_name"

        # Diagnóstico
        if diagnostic_worker_connectivity "$worker_name" "$worker_ip" "$worker_user" "$worker_port"; then
            ((healthy_workers++))
            success "✅ Worker $worker_name está saudável"
        else
            # Tentar resolver automaticamente
            auto_resolve_connectivity_issues "$worker_name" "$worker_ip" "$worker_user" "$worker_port"
            ((fixed_workers++))
        fi

        echo
    done < "$NODES_LIST_FILE"

    # Resumo final
    section "📊 Relatório Final de Resolução"
    success "Total de workers processados: $total_workers"
    success "Workers saudáveis: $healthy_workers"
    success "Workers com correções aplicadas: $fixed_workers"

    if [ $fixed_workers -gt 0 ]; then
        echo
        info "💡 Próximos passos recomendados:"
        echo "  1. Execute: ./scripts/setup_ssh_workers.sh"
        echo "  2. Execute: ./test_workers_fixed.sh"
        echo "  3. Execute: ./manager.sh status"
    fi
}

# Menu principal
show_menu() {
    subsection "Menu de Resolução de Conectividade"

    echo "Escolha uma operação:"
    echo
    echo "🔍 DIAGNÓSTICO:"
    echo "1) 🔍 Diagnosticar conectividade de worker específico"
    echo "2) 📊 Diagnosticar todos os workers"
    echo
    echo "🔧 RESOLUÇÃO:"
    echo "3) 🔧 Resolver problemas automaticamente"
    echo "4) 🔍 Descobrir workers na rede"
    echo "5) 📝 Atualizar configuração de worker"
    echo
    echo "⚙️  UTILITÁRIOS:"
    echo "6) 📋 Listar workers configurados"
    echo "7) 📊 Gerar relatório completo"
    echo
    echo "0) ❌ Voltar"
    echo
}

# Função principal
main() {
    # Criar diretório de logs
    mkdir -p "${PROJECT_ROOT}/logs"

    # Processar argumentos da linha de comando
    case "${1:-}" in
        diagnose)
            if [ -z "${2:-}" ]; then
                error "Especifique o nome do worker: $0 diagnose <worker_name>"
                exit 1
            fi
            # Buscar worker na configuração
            local worker_info
            worker_info=$(grep "^${2} " "$NODES_LIST_FILE" 2>/dev/null || echo "")
            if [ -n "$worker_info" ]; then
                local worker_name worker_ip worker_user worker_port status
                read -r worker_name worker_ip worker_user worker_port status <<< "$worker_info"
                diagnostic_worker_connectivity "$worker_name" "$worker_ip" "${worker_user:-$USER}" "${worker_port:-22}"
            else
                error "Worker $2 não encontrado na configuração"
            fi
            exit 0
            ;;
        auto-resolve)
            resolve_all_workers_connectivity
            exit 0
            ;;
        discover)
            discover_workers_network
            exit 0
            ;;
    esac

    # Menu interativo
    while true; do
        section "🔗 Resolvedor de Conectividade - Cluster AI"
        show_menu

        local choice
        read -p "Digite sua opção (0-7): " choice

        case $choice in
            1)
                read -p "Digite o nome do worker: " worker_name
                if [ -n "$worker_name" ]; then
                    main diagnose "$worker_name"
                fi
                ;;
            2)
                # Diagnosticar todos os workers
                if [ -f "$NODES_LIST_FILE" ]; then
                    while IFS= read -r line; do
                        [[ $line =~ ^# ]] && continue
                        [[ -z $line ]] && continue

                        local worker_name worker_ip worker_user worker_port status
                        read -r worker_name worker_ip worker_user worker_port status <<< "$line"
                        diagnostic_worker_connectivity "$worker_name" "$worker_ip" "${worker_user:-$USER}" "${worker_port:-22}"
                        echo
                    done < "$NODES_LIST_FILE"
                else
                    error "Arquivo de configuração não encontrado"
                fi
                ;;
            3)
                resolve_all_workers_connectivity
                ;;
            4)
                discover_workers_network
                ;;
            5)
                read -p "Nome do worker: " worker_name
                read -p "Novo IP: " new_ip
                read -p "Usuário SSH (padrão: $USER): " new_user
                new_user=${new_user:-$USER}
                read -p "Porta SSH (padrão: 22): " new_port
                new_port=${new_port:-22}

                if [ -n "$worker_name" ] && [ -n "$new_ip" ]; then
                    update_worker_config "$worker_name" "$new_ip" "$new_user" "$new_port"
                fi
                ;;
            6)
                if [ -f "$NODES_LIST_FILE" ]; then
                    section "📋 Workers Configurados"
                    cat "$NODES_LIST_FILE"
                else
                    error "Arquivo de configuração não encontrado"
                fi
                ;;
            7)
                section "📊 Relatório Completo de Conectividade"
                echo "Data/Hora: $(date)"
                echo "Arquivo de configuração: $NODES_LIST_FILE"
                echo
                main auto-resolve
                ;;
            0)
                info "Voltando ao menu principal"
                exit 0
                ;;
            *)
                error "Opção inválida. Tente novamente."
                sleep 2
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
        clear
    done
}

# Executar função principal
main "$@"
