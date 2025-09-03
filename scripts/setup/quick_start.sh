#!/bin/bash

# Quick Start Script para Cluster AI
# Configuração ultra-rápida em um comando

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    🚀 CLUSTER AI 🚀                          ║"
echo "║                 Configuração Ultra-Rápida                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se estamos no diretório correto
if [ ! -f "auto_setup.sh" ]; then
    echo -e "${RED}❌ Erro: Execute este script dentro do diretório cluster-ai${NC}"
    echo -e "${YELLOW}💡 Dica: cd ~/cluster-ai && ./quick_start.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Diretório correto detectado${NC}"
echo ""

# Menu de opções
echo -e "${BLUE}Escolha o tipo de configuração:${NC}"
echo "1) 🚀 Configuração AUTOMÁTICA (recomendado)"
echo "2) 🖥️  Configurar como SERVIDOR"
echo "3) 🔧 Configurar como WORKER"
echo "4) 📚 Ver documentação"
echo "5) ❌ Sair"
echo ""

read -p "Digite sua opção (1-5): " choice

case $choice in
    1)
        echo -e "${GREEN}🚀 Iniciando configuração automática...${NC}"
        ./auto_setup.sh
        ;;
    2)
        echo -e "${GREEN}🖥️  Configurando como servidor...${NC}"
        echo "NODE_ROLE=server" > cluster.conf
        ./auto_setup.sh
        ;;
    3)
        echo -e "${GREEN}🔧 Configurando como worker...${NC}"
        echo "NODE_ROLE=worker" > cluster.conf
        ./auto_setup.sh
        ;;
    4)
        echo -e "${BLUE}📚 Abrindo documentação...${NC}"
        if command -v xdg-open &> /dev/null; then
            xdg-open docs/guides/cluster_setup_guide.md
        elif command -v open &> /dev/null; then
            open docs/guides/cluster_setup_guide.md
        else
            echo -e "${YELLOW}📖 Leia a documentação em: docs/guides/cluster_setup_guide.md${NC}"
        fi
        ;;
    5)
        echo -e "${YELLOW}👋 Até logo!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opção inválida!${NC}"
        exit 1
        ;;
esac
