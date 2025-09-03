#!/bin/bash

echo "=== Limpeza de Configurações Antigas do VS Code ==="

# Backup das configurações atuais
BACKUP_DIR="$HOME/vscode_workspace_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r ~/.config/Code/User/workspaceStorage/ "$BACKUP_DIR/" 2>/dev/null || true
echo "Backup criado em: $BACKUP_DIR"

# Limpar configurações de workspace antigas
echo "Limpando configurações de workspace..."
rm -rf ~/.config/Code/User/workspaceStorage/*

# Verificar e corrigir configurações problemáticas
echo "Verificando configurações problemáticas..."
find ~/.config/Code -name "*.json" -exec grep -l "Desktop\|Windows\|windows" {} \; 2>/dev/null | while read file; do
    echo "Arquivo problemático encontrado: $file"
    # Fazer backup do arquivo
    cp "$file" "$file.backup_$(date +%Y%m%d_%H%M%S)"
    # Remover referências a caminhos do Windows
    sed -i '/Desktop\|Windows\|windows/d' "$file" 2>/dev/null || true
done

# Recriar estrutura básica do workspace
mkdir -p ~/.config/Code/User/workspaceStorage

echo "=== Limpeza concluída! ==="
echo "Reinicie o VS Code para aplicar as mudanças."
echo "Se ainda houver problemas, verifique se há extensões com configurações persistentes."
