# Script de instalação que aponta para seu repositório
#!/bin/bash
REPO_URL="https://github.com/seu-usuario/cluster-ai"
SCRIPTS_URL="$REPO_URL/raw/main/scripts"

echo "Instalando Cluster AI from $REPO_URL"

# Baixar e executar script principal
curl -fsSL $SCRIPTS_URL/install_cluster_ai.sh | bash