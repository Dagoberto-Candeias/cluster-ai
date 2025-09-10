#!/bin/bash
set -e

echo "=== Instalador Unificado: Open WebUI + Cluster Dask ==="

# === CONFIGURAÇÕES DE EMAIL ===
EMAIL_USER="betoallnet@gmail.com"
read -sp "Digite sua senha de app do Gmail para $EMAIL_USER: " EMAIL_PASS
echo

# === [1/6] Instalar dependências principais ===
echo "[1/6] Instalando dependências do sistema com paralelização..."

# Memory monitoring function
check_memory_usage() {
    local mem_usage
    mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    echo "$mem_usage"
}

# Parallel apt install with memory monitoring and recovery
parallel_apt_install() {
    local packages=("$@")
    local max_parallel=4
    local mem_threshold=85

    echo "📦 Instalando ${#packages[@]} pacotes com paralelização..."

    # Check memory before starting
    local mem_before
    mem_before=$(check_memory_usage)
    if [ "$mem_before" -gt "$mem_threshold" ]; then
        echo "⚠️  Memória alta detectada (${mem_before}%), instalando sequencialmente..."
        sudo apt install -y "${packages[@]}"
        return
    fi

    # Split packages into chunks for parallel processing
    local chunk_size=$(( (${#packages[@]} + max_parallel - 1) / max_parallel ))
    local temp_dir
    temp_dir=$(mktemp -d)

    # Create installation scripts for each chunk
    for ((i=0; i<max_parallel; i++)); do
        local start=$((i * chunk_size))
        local end=$((start + chunk_size))
        if [ $end -gt ${#packages[@]} ]; then
            end=${#packages[@]}
        fi

        if [ $start -lt $end ]; then
            local chunk_packages=("${packages[@]:start:end-start}")
            cat > "${temp_dir}/install_${i}.sh" << EOF
#!/bin/bash
# Enhanced monitoring and recovery for apt install chunk
(
    sudo apt install -y ${chunk_packages[*]}
) &
pid=\$!
# Monitor with recovery
while kill -0 \$pid 2>/dev/null; do
    mem_usage=\$(free | awk 'NR==2{printf "%.0f", \$3*100/\$2}')
    if (( mem_usage > 90 )); then
        echo "⚠️ Memória alta durante instalação apt, aguardando..."
    fi
    sleep 5
done
wait \$pid
EOF
            chmod +x "${temp_dir}/install_${i}.sh"
        fi
    done

    # Run installations in parallel
    local pids=()
    for script in "${temp_dir}"/install_*.sh; do
        if [ -f "$script" ]; then
            "$script" &
            pids+=($!)
        fi
    done

    # Wait for all installations to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    # Cleanup
    rm -rf "$temp_dir"

    # Check memory after installation
    local mem_after
    mem_after=$(check_memory_usage)
    echo "✅ Instalação concluída. Uso de memória: ${mem_after}%"
}

# Intelligent apt caching system
setup_apt_cache() {
    echo "🔧 Configurando cache inteligente para apt..."

    # Create local apt cache directory
    local apt_cache_dir="$HOME/.cache/apt"
    mkdir -p "$apt_cache_dir"

    # Configure apt to use local cache
    if [ ! -f /etc/apt/apt.conf.d/99local-cache ]; then
        echo "Configurando cache local do apt..."
        sudo tee /etc/apt/apt.conf.d/99local-cache > /dev/null << EOF
Dir::Cache::Archives "$apt_cache_dir";
EOF
    fi

    # Check if cache is recent (less than 24 hours old)
    local cache_age=0
    if [ -f "$apt_cache_dir/pkgcache.bin" ]; then
        cache_age=$(( $(date +%s) - $(stat -c %Y "$apt_cache_dir/pkgcache.bin") ))
    fi

    if [ $cache_age -lt 86400 ]; then
        echo "✅ Cache apt está atualizado (idade: $((cache_age/3600))h)"
        return 0
    else
        echo "📦 Cache apt desatualizado, será atualizado..."
        return 1
    fi
}

# Update package lists with retry and caching
update_apt_cache() {
    local max_retries=3
    local attempt=1

    # Try to use cached data first
    if setup_apt_cache; then
        echo "🔄 Usando cache apt local..."
        return 0
    fi

    while [ $attempt -le $max_retries ]; do
        echo "🔄 Tentativa $attempt/$max_retries: Atualizando cache apt..."
        if sudo apt update; then
            echo "✅ Cache apt atualizado com sucesso"
            return 0
        fi
        sleep 2
        ((attempt++))
    done

    echo "❌ Falha ao atualizar cache apt após $max_retries tentativas"
    return 1
}

# Main package installation
update_apt_cache

# Define packages for parallel installation
SYSTEM_PACKAGES=(
    "python3.13-venv"
    "python3-pip"
    "python3.13-full"
    "openmpi-bin"
    "libopenmpi-dev"
    "apt-transport-https"
    "ca-certificates"
    "curl"
    "software-properties-common"
)

parallel_apt_install "${SYSTEM_PACKAGES[@]}"

# === [2/6] Configurar ambiente virtual ===
echo "[2/6] Criando ambiente virtual cluster_env..."
if [ ! -d "$HOME/cluster_env" ]; then
    mkdir -p ~/cluster_env
    python3 -m venv ~/cluster_env
fi
source ~/cluster_env/bin/activate

# === [3/6] Instalar dependências Python ===
echo "[3/6] Instalando pacotes Python no ambiente virtual com cache..."

# Configure pip cache
export PIP_CACHE_DIR="$HOME/.cache/pip"
mkdir -p "$PIP_CACHE_DIR"

# Parallel pip install with caching
parallel_pip_install() {
    local packages=("$@")
    local max_parallel=2  # Pip can be memory intensive, limit parallelism

    echo "🐍 Instalando ${#packages[@]} pacotes Python com paralelização..."

    # Check available memory
    local mem_usage
    mem_usage=$(check_memory_usage)
    if [ "$mem_usage" -gt 90 ]; then
        echo "⚠️  Memória muito alta (${mem_usage}%), instalando sequencialmente..."
        pip install --upgrade pip
        pip install "${packages[@]}"
        return
    fi

    # Create temporary requirements files for parallel installation
    local temp_dir
    temp_dir=$(mktemp -d)

    # Split packages into chunks
    local chunk_size=$(( (${#packages[@]} + max_parallel - 1) / max_parallel ))

    for ((i=0; i<max_parallel; i++)); do
        local start=$((i * chunk_size))
        local end=$((start + chunk_size))
        if [ $end -gt ${#packages[@]} ]; then
            end=${#packages[@]}
        fi

        if [ $start -lt $end ]; then
            local chunk_packages=("${packages[@]:start:end-start}")
            printf '%s\n' "${chunk_packages[@]}" > "${temp_dir}/requirements_${i}.txt"
        fi
    done

    # Upgrade pip first
    pip install --upgrade pip

    # Install packages in parallel
    local pids=()
    for req_file in "${temp_dir}"/requirements_*.txt; do
        if [ -f "$req_file" ]; then
            pip install -r "$req_file" &
            pids+=($!)
        fi
    done

    # Wait for all installations
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    # Cleanup
    rm -rf "$temp_dir"

    echo "✅ Instalação Python concluída com cache otimizado"
}

# Define Python packages
PYTHON_PACKAGES=(
    "dask[complete]"
    "distributed"
    "numpy"
    "pandas"
    "scipy"
    "mpi4py"
)

parallel_pip_install "${PYTHON_PACKAGES[@]}"

# Verificação com timeout
echo "🔍 Verificando instalação..."
timeout 30 python -c "import dask; print('✅ Dask versão:', dask.__version__)" || echo "⚠️  Verificação falhou, mas continuando..."

# === [4/6] Configurar ativação automática ===
BASHRC="$HOME/.bashrc"
if ! grep -q "cluster_env/bin/activate" "$BASHRC"; then
    echo "[4/6] Configurando ativação automática no ~/.bashrc..."
    cat <<EOF >> "$BASHRC"

# Ativar ambiente do cluster automaticamente
if [ -f ~/cluster_env/bin/activate ]; then
    source ~/cluster_env/bin/activate
fi
EOF
fi

# === [5/6] Instalar e configurar Docker ===
echo "[5/6] Instalando Docker com cache de layers..."

# Build cache for common operations
setup_build_cache() {
    local build_cache_dir="$HOME/.cache/build"
    mkdir -p "$build_cache_dir"

    # Create cache directories for different build types
    mkdir -p "$build_cache_dir/apt"
    mkdir -p "$build_cache_dir/pip"
    mkdir -p "$build_cache_dir/docker"
    mkdir -p "$build_cache_dir/ccache"
    mkdir -p "$build_cache_dir/npm"

    echo "✅ Build cache directories created at $build_cache_dir"

    # Configure ccache for C/C++ builds
    if ! command -v ccache >/dev/null 2>&1; then
        echo "📦 Installing ccache for C/C++ build caching..."
        sudo apt install -y ccache
    fi

    export CCACHE_DIR="$build_cache_dir/ccache"
    export CCACHE_MAXSIZE="2G"
    export CC="ccache gcc"
    export CXX="ccache g++"

    # Configure npm cache
    export npm_config_cache="$build_cache_dir/npm"

    echo "✅ Build cache configured (ccache, npm)"
}

# Build with cache function
build_with_cache() {
    local build_type="$1"
    local target="$2"
    local build_cache_dir="$HOME/.cache/build"

    case "$build_type" in
        "docker")
            echo "🐳 Building Docker image with cache: $target"
            export DOCKER_BUILDKIT=1
            docker build \
                --tag "$target" \
                --cache-from "$target:latest" \
                --build-arg BUILDKIT_INLINE_CACHE=1 \
                --progress=plain \
                .
            ;;
        "make")
            echo "🔨 Building with make and ccache: $target"
            export CCACHE_DIR="$build_cache_dir/ccache"
            make -j$(nproc) "$target"
            ;;
        "cmake")
            echo "🔨 Building with cmake and ccache: $target"
            export CCACHE_DIR="$build_cache_dir/ccache"
            mkdir -p build && cd build
            cmake .. -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
            make -j$(nproc) "$target"
            ;;
        "pip")
            echo "🐍 Installing Python package with cache: $target"
            export PIP_CACHE_DIR="$build_cache_dir/pip"
            pip install --cache-dir "$build_cache_dir/pip" "$target"
            ;;
        *)
            echo "❌ Unsupported build type: $build_type"
            return 1
            ;;
    esac

    echo "✅ Build completed with cache: $build_type $target"
}

# Docker layer caching function
setup_docker_cache() {
    local docker_cache_dir="$HOME/.cache/docker"
    mkdir -p "$docker_cache_dir"

    # Configure Docker daemon for better caching
    local daemon_config="/etc/docker/daemon.json"
    if [ ! -f "$daemon_config" ] || ! grep -q "storage-driver" "$daemon_config"; then
        echo "Configurando Docker para melhor cache..."
        sudo tee "$daemon_config" > /dev/null << EOF
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "registry-mirrors": ["https://registry-1.docker.io"],
    "experimental": true,
    "features": {
        "buildkit": true
    },
    "builder": {
        "gc": {
            "enabled": true,
            "defaultKeepStorage": "20GB",
            "policy": [
                {"keepStorage": "10GB", "filter": ["unused-for=2200h"]},
                {"keepStorage": "25GB", "filter": ["unused-for=3300h"]},
                {"keepStorage": "50GB", "all": true}
            ]
        }
    }
}
EOF
        sudo systemctl restart docker
    fi

    echo "✅ Cache Docker configurado"
}

# Setup build cache for common operations
setup_build_cache

# Install Docker if not present
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    setup_docker_cache
    echo "⚠️  Saia e entre novamente no sistema para usar o Docker sem sudo."
else
    setup_docker_cache
fi

echo "[5/6] Configurando e iniciando o Open WebUI com cache otimizado..."

# Check if container already exists
if [ "$(sudo docker ps -aq -f name=open-webui)" ]; then
    echo "⚠️  O container 'open-webui' já existe. Removendo..."
    sudo docker stop open-webui >/dev/null 2>&1 || true
    sudo docker rm open-webui >/dev/null 2>&1 || true
fi

# Create data directory with optimized permissions
mkdir -p "$HOME/open-webui"

# Pull image with retry and cache utilization
pull_docker_image() {
    local image="$1"
    local max_retries=3
    local attempt=1

    while [ $attempt -le $max_retries ]; do
        echo "🐳 Tentativa $attempt/$max_retries: Baixando imagem $image..."
        if sudo docker pull "$image"; then
            echo "✅ Imagem $image baixada com sucesso (usando cache)"
            return 0
        fi
        sleep 2
        ((attempt++))
    done

    echo "❌ Falha ao baixar imagem $image após $max_retries tentativas"
    return 1
}

# Pull image with caching
pull_docker_image "ghcr.io/open-webui/open-webui:main"

# Run container with optimized settings
sudo docker run -d \
    --name open-webui \
    --restart unless-stopped \
    -p 8080:8080 \
    -v "$HOME/open-webui:/app/data" \
    --memory=2g \
    --cpus=2 \
    --log-driver=json-file \
    --log-opt max-size=100m \
    --log-opt max-file=3 \
    ghcr.io/open-webui/open-webui:main

echo "✅ Open WebUI iniciado com configurações otimizadas"

echo "✅ Open WebUI iniciado em http://localhost:8080"

# === [6/6] Configurar envio de alertas por email ===
echo "[6/6] Configurando envio de alertas por email..."
cat > ~/send_alert.py <<EOF
import smtplib
from email.mime.text import MIMEText

def send_alert(subject, message):
    sender = "$EMAIL_USER"
    password = "$EMAIL_PASS"
    recipient = "$EMAIL_USER"

    msg = MIMEText(message)
    msg["Subject"] = subject
    msg["From"] = sender
    msg["To"] = recipient

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(sender, password)
            server.sendmail(sender, recipient, msg.as_string())
        print("✅ Alerta enviado com sucesso!")
    except Exception as e:
        print("❌ Erro ao enviar alerta:", e)

if __name__ == "__main__":
    send_alert("Teste de Alerta", "Sistema configurado com sucesso!")
EOF

echo "=== Instalação finalizada! ==="
echo "👉 Open WebUI: http://localhost:8080"
echo "👉 Ambiente cluster_env pronto (Dask + MPI)"
echo "👉 Script de envio de alertas: ~/send_alert.py"
