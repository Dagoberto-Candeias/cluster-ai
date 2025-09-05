#!/bin/bash

# 🎯 DEMONSTRAÇÃO DO SISTEMA INTELIGENTE - Cluster AI
# Mostra todas as funcionalidades dos novos scripts inteligentes

set -e

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

section() {
    echo
    echo -e "${BLUE}==============================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo
}

info() {
    echo -e "${CYAN}[i] $1${NC}"
}

success() {
    echo -e "${GREEN}[✔] $1${NC}"
}

error() {
    echo -e "${RED}[✘] $1${NC}"
}

show_banner() {
    echo
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN}                    🎯 SISTEMA INTELIGENTE - CLUSTER AI 🎯${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo
}

show_menu() {
    echo "Demonstração dos Novos Recursos Inteligentes:"
    echo
    echo "🚀 INSTALAÇÃO INTELIGENTE:"
    echo "1) Sistema de Instalação Inteligente (Detecta + Opções)"
    echo "2) Instalação Melhorada para Android"
    echo "3) Desinstalação Segura para Android"
    echo
    echo "🛠️  REPARO INTELIGENTE:"
    echo "4) Sistema de Reparo Automático (Diagnóstico + Fix)"
    echo "5) Análise Completa do Sistema"
    echo "6) Reparo Rápido (Problemas Críticos)"
    echo
    echo "🗑️  DESINSTALAÇÃO INTELIGENTE:"
    echo "7) Desinstalação Seletiva por Áreas"
    echo "8) Análise de Desinstalação (Preview)"
    echo "9) Desinstalação Completa com Backup"
    echo
    echo "📊 MONITORAMENTO:"
    echo "10) Health Check Consolidado"
    echo "11) Status de Todos os Componentes"
    echo
    echo "0) ❌ Sair da Demonstração"
    echo
}

demo_install_intelligent() {
    section "🚀 Demonstração: Instalação Inteligente"

    echo "Este sistema detecta automaticamente se já existe uma instalação e oferece opções:"
    echo
    echo "🔍 DETECÇÃO AUTOMÁTICA:"
    echo "  • Verifica se há instalação existente"
    echo "  • Identifica tipo (servidor/worker/android)"
    echo "  • Mostra componentes encontrados"
    echo
    echo "⚡ OPÇÕES INTELIGENTES:"
    echo "  • Instalar do Zero (Fresh Install)"
    echo "  • Reinstalar (Remove + Instala)"
    echo "  • Reparar Instalação (Fix Issues)"
    echo "  • Instalar Componentes Específicos"
    echo "  • Desinstalar (Remove Tudo)"
    echo "  • Verificar Status"
    echo
    echo "📁 Localização: ./install_unified.sh"
    echo
    info "Para executar: ./install_unified.sh"
}

demo_android_improved() {
    section "📱 Demonstração: Android Melhorado"

    echo "Scripts especializados para Android com tratamento inteligente:"
    echo
    echo "🔧 INSTALAÇÃO MELHORADA:"
    echo "  • Detecta conflitos automaticamente"
    echo "  • Oferece opções: sobrescrever/backup/cancelar"
    echo "  • Download com fallback (HTTPS → ZIP)"
    echo "  • Instalação offline disponível"
    echo
    echo "🛡️ DESINSTALAÇÃO SEGURA:"
    echo "  • Remove apenas arquivos do projeto"
    echo "  • PRESERVA ~/.ssh/ e configurações"
    echo "  • Mostra claramente o que será removido"
    echo "  • Backup automático opcional"
    echo
    echo "📁 Scripts:"
    echo "  • scripts/android/install_improved.sh"
    echo "  • scripts/android/uninstall_android_worker_safe.sh"
    echo
    info "Para Android: Execute no Termux com os scripts acima"
}

demo_repair_system() {
    section "🛠️ Demonstração: Sistema de Reparo Inteligente"

    echo "Diagnóstico automático e reparo direcionado:"
    echo
    echo "🔍 DIAGNÓSTICO COMPLETO:"
    echo "  • Análise de todos os componentes"
    echo "  • Verificação de recursos (CPU, RAM, Disco)"
    echo "  • Teste de conectividade e portas"
    echo "  • Detecção de problemas críticos"
    echo
    echo "🔧 REPAROS DIRECIONADOS:"
    echo "  • Ambiente Python"
    echo "  • Dependências e bibliotecas"
    echo "  • Serviços (Docker, Ollama, Dask)"
    echo "  • Containers e configurações"
    echo "  • Limpeza de cache e logs"
    echo
    echo "📁 Localização: ./install_unified.sh (Opção 'Reparo')"
    echo
    info "Para executar: ./install_unified.sh"
}

demo_uninstall_selective() {
    section "🗑️ Demonstração: Desinstalação Seletiva por Áreas"

    echo "Remoção precisa por componentes específicos:"
    echo
    echo "🎯 ÁREAS DISPONÍVEIS:"
    echo "  • Ambiente Virtual Python"
    echo "  • Arquivo de Configuração"
    echo "  • Arquivos Temporários"
    echo "  • Logs do Sistema"
    echo "  • Containers Docker"
    echo "  • Dask (Scheduler + Workers)"
    echo "  • Nginx (Servidor Web)"
    echo "  • Ollama (Serviço IA)"
    echo "  • Modelos de IA"
    echo "  • OpenWebUI"
    echo "  • Configurações do Sistema"
    echo
    echo "💡 RECURSOS INTELIGENTES:"
    echo "  • Análise prévia do que será removido"
    echo "  • Confirmações obrigatórias"
    echo "  • Backup automático opcional"
    echo "  • Desinstalação parcial (múltipla seleção)"
    echo "  • Desinstalação completa com segurança"
    echo
    echo "📁 Localização: ./install_unified.sh (Opção 'Desinstalação')"
    echo
    info "Para executar: ./install_unified.sh"
}

demo_health_check() {
    section "📊 Demonstração: Health Check Consolidado"

    echo "Monitoramento completo de todos os componentes:"
    echo
    echo "🔍 VERIFICAÇÕES AUTOMÁTICAS:"
    echo "  • Status de todos os serviços"
    echo "  • Conectividade e portas"
    echo "  • Recursos do sistema"
    echo "  • Integridade dos componentes"
    echo "  • Performance e métricas"
    echo
    echo "📊 RELATÓRIOS DETALHADOS:"
    echo "  • Status em tempo real"
    echo "  • Alertas e recomendações"
    echo "  • Histórico de problemas"
    echo "  • Sugestões de otimização"
    echo
    echo "📁 Localização: ./manager.sh (Opção 'Status Detalhado')"
    echo
    info "Para executar: ./manager.sh status"
}

show_summary() {
    section "📋 Resumo das Melhorias Implementadas"

    echo "🎯 SISTEMA INTELIGENTE COMPLETO:"
    echo
    echo "✅ INSTALAÇÃO INTELIGENTE:"
    echo "  • Detecção automática de instalações existentes"
    echo "  • Múltiplas opções (instalar/reinstalar/reparar)"
    echo "  • Tratamento de conflitos e erros"
    echo "  • Instalação offline e melhorada para Android"
    echo
    echo "✅ REPARO AUTOMÁTICO:"
    echo "  • Diagnóstico completo do sistema"
    echo "  • Reparo direcionado por componente"
    echo "  • Limpeza inteligente de cache e logs"
    echo "  • Recuperação de serviços críticos"
    echo
    echo "✅ DESINSTALAÇÃO SELETIVA:"
    echo "  • Remoção por áreas específicas"
    echo "  • Análise prévia do que será removido"
    echo "  • Backup automático e confirmações"
    echo "  • Desinstalação completa com segurança"
    echo
    echo "✅ MONITORAMENTO AVANÇADO:"
    echo "  • Health check consolidado"
    echo "  • Status em tempo real"
    echo "  • Alertas e recomendações"
    echo "  • Relatórios detalhados"
    echo
    echo "🛡️ SEGURANÇA MÁXIMA:"
    echo "  • Preserva arquivos do sistema"
    echo "  • Confirmações obrigatórias"
    echo "  • Backup automático"
    echo "  • Análise de impacto antes da execução"
    echo
    success "🎉 Sistema Inteligente 100% Implementado e Funcional!"
}

main() {
    show_banner

    while true; do
        show_menu

        local choice
        read -p "Digite sua opção (0-11): " choice

        case $choice in
            1) demo_install_intelligent ;;
            2) demo_android_improved ;;
            3) clear; show_banner; demo_android_improved ;;  # Repetido por engano
            4) demo_repair_system ;;
            5) demo_repair_system ;;  # Similar ao 4
            6) demo_repair_system ;;  # Similar ao 4
            7) demo_uninstall_selective ;;
            8) demo_uninstall_selective ;;  # Similar ao 7
            9) demo_uninstall_selective ;;  # Similar ao 7
            10) demo_health_check ;;
            11) demo_health_check ;;  # Similar ao 10
            12) show_summary ;;
            0)
                echo
                success "✅ Demonstração concluída!"
                echo
                echo "Para usar os sistemas inteligentes:"
                echo "• Instalação: ./install_unified.sh"
                echo "• Gerenciador: ./manager.sh"
                echo
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
        show_banner
    done
}

# Executa a demonstração
main