#!/bin/bash
# Script para instalar RStudio no Cluster AI
# Autor: Cluster AI Team
# Data: $(date +%Y-%m-%d)

set -e

echo "=== Instalador RStudio para Cluster AI ==="

# Detectar distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    echo "Não foi possível detectar o sistema operacional."
    exit 1
fi

echo "Sistema detectado: $OS $VERSION_ID"

# Instalar R se não estiver instalado
install_r() {
    echo "Verificando instalação do R..."
    if ! command -v R >/dev/null 2>&1; then
        echo "Instalando R..."
        case $OS in
            ubuntu|debian)
                sudo apt update
                sudo apt install -y r-base r-base-dev
                ;;
            manjaro)
                sudo pacman -S --noconfirm r
                ;;
            centos|rhel|fedora)
                sudo yum install -y R R-devel
                ;;
            *)
                echo "Sistema não suportado para instalação automática do R."
                echo "Instale o R manualmente e execute este script novamente."
                exit 1
                ;;
        esac
    else
        echo "R já está instalado."
    fi
}

# Instalar RStudio
install_rstudio() {
    echo "Instalando RStudio..."

    case $OS in
        ubuntu|debian)
            # Baixar e instalar versão mais recente
            RSTUDIO_DEB_URL="https://download1.rstudio.org/electron/jammy/amd64/rstudio-2025.05.1-513-amd64.deb"
            RSTUDIO_DEB_FILE="/tmp/rstudio-2025.05.1-513-amd64.deb"

            echo "Baixando RStudio versão 2025.05.1+513..."
            wget -O "$RSTUDIO_DEB_FILE" "$RSTUDIO_DEB_URL"

            echo "Instalando RStudio..."
            sudo apt install -y "$RSTUDIO_DEB_FILE"

            # Limpar arquivo temporário
            rm -f "$RSTUDIO_DEB_FILE"
            ;;
        manjaro)
            # Para Manjaro, instalar via AUR ou snap
            if command -v snap >/dev/null 2>&1; then
                sudo snap install rstudio --classic
            else
                echo "Para Manjaro, instale o RStudio via AUR:"
                echo "yay -S rstudio-desktop-bin"
                exit 1
            fi
            ;;
        centos|rhel|fedora)
            # Para CentOS/RHEL/Fedora, baixar RPM
            RSTUDIO_RPM="https://download1.rstudio.org/desktop/centos7/x86_64/rstudio-2023.06.1-524-x86_64.rpm"
            wget -O /tmp/rstudio.rpm $RSTUDIO_RPM
            sudo yum install -y /tmp/rstudio.rpm
            ;;
        *)
            echo "Instalação automática do RStudio não suportada para $OS."
            echo "Baixe e instale manualmente de: https://www.rstudio.com/products/rstudio/download/"
            exit 1
            ;;
    esac
}

# Configurar RStudio para o Cluster AI
configure_rstudio() {
    echo "Configurando RStudio para Cluster AI..."

    # Criar diretório de projetos se não existir
    mkdir -p ~/cluster_projects/r

    # Criar arquivo de configuração R
    cat > ~/.Rprofile << 'EOL'
# Configuração R para Cluster AI
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Carregar bibliotecas essenciais
if (!require("dplyr")) install.packages("dplyr")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("tidyr")) install.packages("tidyr")

# Configurar ambiente
Sys.setenv(LANG = "en_US.UTF-8")

# Função para conectar ao cluster Dask
connect_dask_cluster <- function(scheduler_address = "localhost:8786") {
    if (!require("dask")) {
        install.packages("dask")
    }
    library(dask)
    client <- dask$Client(scheduler_address)
    message("Conectado ao cluster Dask em: ", scheduler_address)
    return(client)
}

message("Ambiente R configurado para Cluster AI")
EOL

    # Criar script de exemplo
    cat > ~/cluster_projects/r/exemplo_cluster.R << 'EOL'
#!/usr/bin/env Rscript
# Exemplo de uso do R com Cluster AI

# Carregar bibliotecas
library(dplyr)
library(ggplot2)

# Conectar ao cluster Dask (se disponível)
# client <- connect_dask_cluster()

# Exemplo de processamento de dados
message("R configurado para trabalhar com Cluster AI!")

# Criar dados de exemplo
dados <- data.frame(
    x = rnorm(1000),
    y = rnorm(1000),
    grupo = sample(c("A", "B", "C"), 1000, replace = TRUE)
)

# Análise básica
summary(dados)

# Visualização
ggplot(dados, aes(x = x, y = y, color = grupo)) +
    geom_point(alpha = 0.6) +
    theme_minimal() +
    labs(title = "Exemplo de visualização com R no Cluster AI")

message("Script executado com sucesso!")
EOL

    # Criar atalho na área de trabalho
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/rstudio-cluster.desktop << 'EOL'
[Desktop Entry]
Version=1.0
Type=Application
Name=RStudio (Cluster AI)
Exec=rstudio
Icon=rstudio
Comment=RStudio IDE for Cluster AI development
Categories=Development;IDE;
Terminal=false
StartupWMClass=rstudio
EOL

    # Configurar permissões
    chmod +x ~/cluster_projects/r/exemplo_cluster.R
}

# Verificar instalação
verify_installation() {
    echo "Verificando instalação..."

    # Verificar R
    if command -v R >/dev/null 2>&1; then
        echo "✅ R instalado: $(R --version | head -1)"
    else
        echo "❌ R não encontrado"
        return 1
    fi

    # Verificar RStudio
    if command -v rstudio >/dev/null 2>&1; then
        echo "✅ RStudio instalado"
    else
        echo "❌ RStudio não encontrado"
        return 1
    fi

    # Verificar bibliotecas R essenciais
    R -e "if (!require('dplyr')) install.packages('dplyr', repos='https://cran.rstudio.com/')" >/dev/null 2>&1
    R -e "if (!require('ggplot2')) install.packages('ggplot2', repos='https://cran.rstudio.com/')" >/dev/null 2>&1

    echo "✅ Bibliotecas R essenciais instaladas"
    return 0
}

# Função principal
main() {
    echo "Iniciando instalação do R e RStudio..."

    # Verificar se está executando como root
    if [[ $EUID -eq 0 ]]; then
        echo "❌ Não execute este script como root"
        exit 1
    fi

    # Instalar R
    install_r

    # Instalar RStudio
    install_rstudio

    # Configurar ambiente
    configure_rstudio

    # Verificar instalação
    if verify_installation; then
        echo ""
        echo "🎉 Instalação concluída com sucesso!"
        echo ""
        echo "Para usar o RStudio:"
        echo "1. Execute: rstudio"
        echo "2. Ou use o atalho criado na área de trabalho"
        echo ""
        echo "Arquivos criados:"
        echo "- ~/.Rprofile (configuração R)"
        echo "- ~/cluster_projects/r/exemplo_cluster.R (script exemplo)"
        echo "- ~/.local/share/applications/rstudio-cluster.desktop (atalho)"
        echo ""
        echo "Para conectar ao cluster Dask do R:"
        echo "client <- connect_dask_cluster('localhost:8786')"
    else
        echo "❌ Houve problemas na instalação"
        exit 1
    fi
}

# Executar função principal
main "$@"
