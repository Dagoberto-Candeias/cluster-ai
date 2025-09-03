#!/bin/bash

# 🗑️ Script Master de Desinstalação - Cluster AI
# Descrição: Desinstala o Cluster AI de diferentes tipos de sistemas

set -e

# --- Carregar Funções Comuns ---
PROJECT_ROOT=$(pwd)
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Menu Principal ---
show_uninstall_menu() {
    section "Desinstalação do Cluster AI"

    echo "Escolha o tipo de desinstalação:"
    echo
    echo "1) 🖥️  Desinstalar do Servidor Principal"
    echo "2) 📱 Desinstalar Worker Android (Termux)"
    echo "3) 💻 Desinstalar Estação de Trabalho"
    echo "4) 🔄 Desinstalar Workers Remotos (SSH)"
    echo "5) 🧹 Limpeza Completa (todos os tipos)"
    echo "6) 📊 Verificar Status de Instalação"
    echo
    echo "0) ❌ Cancelar"
    echo
}

# --- Desinstalar do Servidor ---
uninstall_server() {
    section "Desinstalando do Servidor Principal"

    if [ ! -f "scripts/maintenance/uninstall.sh" ]; then
        error "Script de desinstalação do servidor não encontrado."
        return 1
    fi

    warn "Esta operação removerá todos os artefatos do servidor."
    if confirm_operation "Continuar com a desinstalação do servidor?"; then
        bash scripts/maintenance/uninstall.sh
        success "Desinstalação do servidor concluída."
    else
        warn "Desinstalação do servidor cancelada."
    fi
}

# --- Desinstalar Worker Android ---
uninstall_android() {
    section "Desinstalando Worker Android"

    echo "Para desinstalar o worker Android:"
    echo "1. Abra o Termux no seu dispositivo Android"
    echo "2. Execute o comando abaixo:"
    echo
    echo "   curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/uninstall_android_worker.sh | bash"
    echo
    echo "Ou copie e execute manualmente:"
    echo
    echo "   # Script de desinstalação Android"
    echo "   pkill -f sshd"
    echo "   rm -rf ~/Projetos/cluster-ai"
    echo "   rm -rf ~/.ssh"
    echo "   echo 'Worker Android desinstalado'"
    echo

    if confirm_operation "Você executou a desinstalação no Android?"; then
        success "Worker Android marcado como desinstalado."
    else
        info "Lembre-se de executar a desinstalação no dispositivo Android."
    fi
}

# --- Desinstalar Estação de Trabalho ---
uninstall_workstation() {
    section "Desinstalando Estação de Trabalho"

    if [ ! -f "scripts/maintenance/uninstall_workstation.sh" ]; then
        error "Script de desinstalação da estação de trabalho não encontrado."
        return 1
    fi

    warn "Esta operação removerá a instalação local da estação de trabalho."
    if confirm_operation "Continuar com a desinstalação da estação de trabalho?"; then
        bash scripts/maintenance/uninstall_workstation.sh
        success "Desinstalação da estação de trabalho concluída."
    else
        warn "Desinstalação da estação de trabalho cancelada."
    fi
}

# --- Desinstalar Workers Remotos ---
uninstall_remote_workers() {
    section "Desinstalando Workers Remotos"

    local config_file="$HOME/.cluster_config/nodes_list.conf"

    if [ ! -f "$config_file" ]; then
        warn "Nenhum arquivo de configuração de workers remotos encontrado."
        info "Use o manager.sh para configurar workers remotos primeiro."
        return 1
    fi

    subsection "Workers Configurados"
    if grep -v '^#' "$config_file" | grep -q .; then
        echo "Workers encontrados:"
        awk 'NR>1 && !/^#/ {print NR-1 ") " $1 " - " $2 ":" $4 " (" $3 ")"}' "$config_file"
        echo
    else
        warn "Nenhum worker remoto configurado."
        return 1
    fi

    if confirm_operation "Desinstalar workers remotos?"; then
        log "Executando desinstalação remota..."

        while IFS= read -r line; do
            if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                continue
            fi

            local name ip user port
            read name ip user port <<< "$line"

            log "Desinstalando worker: $name ($ip)"

            # Comando remoto de desinstalação
            local uninstall_cmd="
                pkill -f 'dask-worker' || true
                pkill -f 'ollama' || true
                rm -rf ~/cluster-ai-worker || true
                rm -rf ~/.ollama || true
                echo 'Worker $name desinstalado'
            "

            if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$port" "$user@$ip" "$uninstall_cmd" 2>/dev/null; then
                success "Worker $name desinstalado com sucesso."
                # Remover do arquivo de configuração
                sed -i "/^$name $ip $user $port/d" "$config_file"
            else
                error "Falha ao desinstalar worker $name."
            fi
        done < "$config_file"

        success "Desinstalação de workers remotos concluída."
    else
        warn "Desinstalação de workers remotos cancelada."
    fi
}

# --- Limpeza Completa ---
full_cleanup() {
    section "Limpeza Completa do Cluster AI"

    warn "Esta operação removerá TODAS as instalações do Cluster AI."
    warn "Isso inclui servidor, workers remotos e configurações locais."
    echo

    if confirm_operation "Você tem certeza que deseja fazer uma limpeza completa?"; then
        # Desinstalar servidor
        if [ -f "scripts/maintenance/uninstall.sh" ]; then
            log "Desinstalando servidor..."
            bash scripts/maintenance/uninstall.sh
        fi

        # Desinstalar estação de trabalho
        if [ -f "scripts/maintenance/uninstall_workstation.sh" ]; then
            log "Desinstalando estação de trabalho..."
            bash scripts/maintenance/uninstall_workstation.sh
        fi

        # Desinstalar workers remotos
        uninstall_remote_workers

        # Limpar configurações globais
        log "Limpando configurações globais..."
        rm -rf "$HOME/.cluster_config" 2>/dev/null || true
        rm -rf "$HOME/.ollama/prompts" 2>/dev/null || true

        success "✅ Limpeza completa concluída!"
        echo
        info "Para uma limpeza manual adicional:"
        echo "  - Remova modelos Ollama: rm -rf ~/.ollama"
        echo "  - Limpe Docker: docker system prune -a"
        echo "  - Remova dependências: pip uninstall cluster-ai"
    else
        warn "Limpeza completa cancelada."
    fi
}

# --- Verificar Status ---
check_installation_status() {
    section "Status de Instalação do Cluster AI"

    subsection "Servidor Principal"
    if [ -d ".venv" ] || [ -d "logs" ] || [ -f "cluster.conf" ]; then
        success "Servidor: Instalado"
    else
        warn "Servidor: Não instalado"
    fi

    subsection "Workers Android"
    local android_config="$HOME/.cluster_config/nodes_list.conf"
    if [ -f "$android_config" ] && grep -q "android" "$android_config" 2>/dev/null; then
        success "Workers Android: Configurados"
    else
        warn "Workers Android: Não configurados"
    fi

    subsection "Workers Remotos"
    if [ -f "$android_config" ] && grep -v '^#' "$android_config" | grep -q . 2>/dev/null; then
        local worker_count=$(grep -v '^#' "$android_config" | wc -l)
        success "Workers Remotos: $worker_count configurados"
    else
        warn "Workers Remotos: Nenhum configurado"
    fi

    subsection "Integrações"
    if [ -d "$HOME/.ollama/prompts" ]; then
        success "Ollama: Integrado"
    else
        warn "Ollama: Não integrado"
    fi

    if [ -f "$HOME/.config/cluster-ai/prompts" ]; then
        success "IDEs: Integradas"
    else
        warn "IDEs: Não integradas"
    fi
}

# --- Script Principal ---
main() {
    while true; do
        show_uninstall_menu

        local choice
        read -p "Digite sua opção (0-6): " choice

        case $choice in
            1) uninstall_server ;;
            2) uninstall_android ;;
            3) uninstall_workstation ;;
            4) uninstall_remote_workers ;;
            5) full_cleanup ;;
            6) check_installation_status ;;
            0)
                info "Desinstalação cancelada."
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

# Executa o script principal
main
