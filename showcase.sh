#!/bin/bash
#
# 🎯 SCRIPT DE SHOWCASE UNIFICADO - CLUSTER AI
# Ponto de entrada único para demonstrar todas as funcionalidades do sistema.
#

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# =============================================================================
# FUNÇÕES DE DEMONSTRAÇÃO - INSTALAÇÃO E MANUTENÇÃO
# =============================================================================

demo_install_intelligent() {
    section "🚀 Demonstração: Instalação Inteligente e Unificada"
    echo "O script 'install_unified.sh' é o cérebro da instalação, oferecendo:"
    echo
    echo "  🔍 Detecção automática de instalações existentes."
    echo "  🎛️  Menu contextual com opções de Instalar, Reinstalar, Reparar e Desinstalar."
    echo "  📦 Instalação modular de componentes (Docker, Python, Ollama, etc.)."
    echo "  🛡️  Operações seguras com backups e confirmações."
    echo
    info "Para executar: ./install_unified.sh"
}

demo_android_improved() {
    section "📱 Demonstração: Suporte Avançado para Android (Termux)"
    echo "Scripts especializados para transformar dispositivos Android em workers:"
    echo
    echo "  🔧 Instalação segura que preserva dados do usuário (~/.ssh)."
    echo "  🔄 Detecção de conflitos e opções de sobrescrita ou backup."
    echo "  🔌 Suporte para instalação offline."
    echo
    info "Scripts: scripts/android/install_improved.sh e uninstall_android_worker_safe.sh"
}

demo_repair_system() {
    section "🛠️ Demonstração: Sistema de Reparo Inteligente"
    echo "Diagnóstico automático e reparo direcionado através do instalador:"
    echo
    echo "  🔍 Análise completa de todos os componentes do sistema."
    echo "  🔧 Reparo seletivo de: Ambiente Python, Docker, Serviços, etc."
    echo "  🧹 Limpeza inteligente de cache e logs corrompidos."
    echo
    info "Para executar: ./install_unified.sh (Opção 'Reparo')"
}

demo_uninstall_selective() {
    section "🗑️ Demonstração: Desinstalação Seletiva e Segura"
    echo "Remoção precisa de componentes específicos, com total controle:"
    echo
    echo "  🎯 Remoção por áreas: Ambiente Virtual, Modelos de IA, Containers, etc."
    echo "  📝 Análise de impacto antes da execução (preview do que será removido)."
    echo "  💾 Backup automático opcional antes da remoção."
    echo
    info "Para executar: ./install_unified.sh (Opção 'Desinstalação')"
}

# =============================================================================
# FUNÇÕES DE DEMONSTRAÇÃO - GERENCIAMENTO E OPERAÇÃO
# =============================================================================

demo_auto_discovery() {
    section "🔍 Demonstração: Descoberta Automática de Workers na Rede"
    echo "O sistema pode descobrir e configurar workers automaticamente na rede local:"
    echo
    echo "  📡 Varredura automática da rede para encontrar hosts ativos."
    echo "  🤖 Verificação se os hosts são workers do Cluster AI (via portas e SSH)."
    echo "  ⚡ Configuração automática na lista de nós, sem intervenção manual."
    echo
    info "Para executar: ./scripts/management/network_discovery.sh auto"
}

demo_health_check() {
    section "📊 Demonstração: Health Check e Status Detalhado"
    echo "Monitoramento completo de todos os componentes através do gerenciador:"
    echo
    echo "  🌡️  Verificação de status de todos os serviços (Dask, Ollama, Docker)."
    echo "  💻 Análise de recursos do sistema (CPU, RAM, Disco)."
    echo "  🔌 Teste de conectividade e portas abertas."
    echo
    info "Para executar: ./manager.sh status"
}

demo_todo_consolidation() {
    section "🧹 Demonstração: Consolidação Inteligente de TODOs"
    echo "Uma ferramenta de manutenção para organizar tarefas de desenvolvimento:"
    echo
    echo "  🔄 Análise de todos os arquivos TODO e consolidação em um 'TODO_MASTER.md'."
    echo "  📊 Identificação e remoção de duplicatas."
    echo "  💾 Backup automático dos arquivos originais antes de qualquer mudança."
    echo
    info "Para executar: ./scripts/maintenance/consolidate_todos.sh"
}

demo_project_organization() {
    section "📁 Demonstração: Organização Inteligente do Projeto"
    echo "Ferramenta para manter a estrutura do projeto limpa e otimizada:"
    echo
    echo "  🚚 Move documentação interna e logs para uma área 'server_only'."
    echo "  🗑️  Limpa arquivos temporários e de cache."
    echo "  📊 Gera relatórios sobre a estrutura do projeto."
    echo
    info "Para executar: ./scripts/maintenance/organize_project.sh"
}

# =============================================================================
# MENUS INTERATIVOS
# =============================================================================

show_main_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║           🎯 SHOWCASE UNIFICADO - CLUSTER AI 🎯              ║
║                                                              ║
║      Explore todas as funcionalidades inteligentes do        ║
║      nosso sistema de forma organizada e interativa.         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

run_install_menu() {
    while true; do
        show_main_banner
        subsection "Menu: Instalação e Manutenção"
        echo "1) 🚀 Instalação Inteligente"
        echo "2) 📱 Suporte para Android (Termux)"
        echo "3) 🛠️  Sistema de Reparo"
        echo "4) 🗑️  Desinstalação Seletiva"
        echo "0) ↩️  Voltar ao Menu Principal"
        echo
        read -p "Sua opção: " choice

        case $choice in
            1) demo_install_intelligent ;;
            2) demo_android_improved ;;
            3) demo_repair_system ;;
            4) demo_uninstall_selective ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

run_management_menu() {
    while true; do
        show_main_banner
        subsection "Menu: Gerenciamento e Operação"
        echo "1) 🔍 Descoberta Automática de Workers"
        echo "2) 📊 Health Check e Status Detalhado"
        echo "3) 🧹 Consolidação de TODOs"
        echo "4) 📁 Organização do Projeto"
        echo "0) ↩️  Voltar ao Menu Principal"
        echo
        read -p "Sua opção: " choice

        case $choice in
            1) demo_auto_discovery ;;
            2) demo_health_check ;;
            3) demo_todo_consolidation ;;
            4) demo_project_organization ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

show_summary() {
    section "🎉 Resumo dos Benefícios e Integração"
    echo -e "${GREEN}✅ AUTOMAÇÃO E INTELIGÊNCIA:${NC}"
    echo "  • Instalação e reparo que se adaptam ao contexto."
    echo "  • Descoberta de rede que elimina configuração manual."
    echo "  • Ferramentas de manutenção que organizam o projeto automaticamente."
    echo
    echo -e "${GREEN}✅ CONTROLE E SEGURANÇA:${NC}"
    echo "  • Operações críticas sempre pedem confirmação."
    echo "  • Análise de impacto antes de desinstalar ou modificar arquivos."
    echo "  • Backups automáticos para garantir a recuperação de dados."
    echo
    echo -e "${GREEN}✅ EXPERIÊNCIA UNIFICADA:${NC}"
    echo "  • Um instalador central ('install_unified.sh') para tudo."
    echo "  • Um gerenciador central ('manager.sh') para operar o cluster."
    echo "  • Scripts modulares e bem documentados em 'scripts/'."
    echo
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    while true; do
        show_main_banner
        subsection "Menu Principal do Showcase"
        echo "1) ⚙️  Demonstração de Instalação e Manutenção"
        echo "2) 🚀 Demonstração de Gerenciamento e Operação"
        echo "3) 🎉 Resumo dos Benefícios e Integração"
        echo "0) ❌ Sair do Showcase"
        echo
        read -p "Sua opção: " choice

        case $choice in
            1) run_install_menu ;;
            2) run_management_menu ;;
            3) show_summary ;;
            0)
                echo
                success "Obrigado por explorar o Cluster AI!"
                exit 0
                ;;
            *) error "Opção inválida." ;;
        esac

        if [[ "$choice" != "0" ]]; then
            read -p "Pressione Enter para voltar ao menu principal..."
        fi
    done
}

main "$@"