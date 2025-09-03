#!/bin/bash
# Script de Teste para o Instalador de Ferramentas de Desenvolvimento

# --- Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
INSTALLER_SCRIPT_PATH="$PROJECT_ROOT/install_universal.sh"

# Carregar funções comuns para logging e cores
source "$SCRIPT_DIR/../utils/common.sh"

# Verificar se o instalador existe
if [ ! -f "$INSTALLER_SCRIPT_PATH" ]; then
    error "Script do instalador universal não encontrado em: $INSTALLER_SCRIPT_PATH"
    exit 1
fi

# Carregar as funções do instalador
source "$INSTALLER_SCRIPT_PATH"

# --- Mocking Area ---
COMMAND_LOG="/tmp/dev_tools_test_commands.log"
MOCK_COMMANDS=() # Array para controlar quais comandos "existem"

# Mock para o comando 'sudo'
sudo() {
    "$@"
}

# Mocks para gerenciadores de pacotes e outros comandos
apt-get() { echo "APT_GET_CALLED: $@" >> "$COMMAND_LOG"; }
pacman() { echo "PACMAN_CALLED: $@" >> "$COMMAND_LOG"; }
dnf() { echo "DNF_CALLED: $@" >> "$COMMAND_LOG"; }
yum() { echo "YUM_CALLED: $@" >> "$COMMAND_LOG"; }
wget() { echo "WGET_CALLED: $@" >> "$COMMAND_LOG"; }
gpg() { echo "GPG_CALLED: $@" >> "$COMMAND_LOG"; }
tee() { echo "TEE_CALLED: $@" >> "$COMMAND_LOG"; }
rpm() { echo "RPM_CALLED: $@" >> "$COMMAND_LOG"; }
pip() { echo "PIP_CALLED: $@" >> "$COMMAND_LOG"; }
bash() { echo "BASH_CALLED: $@" >> "$COMMAND_LOG"; }

# Mock para 'command_exists' para controlar o que está "instalado"
command_exists() {
    local cmd_to_check="$1"
    for cmd in "${MOCK_COMMANDS[@]}"; do
        if [[ "$cmd" == "$cmd_to_check" ]]; then
            return 0
        fi
    done
    return 1
}

# Mock para 'python' para simular a verificação de pacotes
python() {
    if [[ "$1" == "-c" && "$2" == "import spyder" ]]; then
        # A existência de spyder é controlada pela presença de 'spyder-installed' no MOCK_COMMANDS
        if command_exists "spyder-installed"; then
            return 0
        else
            return 1
        fi
    fi
    # Se não for a chamada que queremos mockar, apenas loga
    echo "PYTHON_CALLED: $@" >> "$COMMAND_LOG"
}

# Mock para 'source' e 'deactivate' (são built-ins, então só logamos a tentativa)
source() {
    echo "SOURCE_CALLED: $@" >> "$COMMAND_LOG"
    # Para o teste, precisamos que o ambiente pareça ativado, então retornamos sucesso
    return 0
}
deactivate() {
    echo "DEACTIVATE_CALLED" >> "$COMMAND_LOG"
}

# --- Test Runner ---
TEST_COUNT=0
FAIL_COUNT=0
TEST_AREA="/tmp/cluster_ai_dev_test_area"

# Helper para verificar se o log de comando contém um padrão
assert_contains() {
    local description="$1"
    local pattern="$2"
    ((TEST_COUNT++))
    echo -n "  [TEST $TEST_COUNT] $description: verificando por '$pattern'... "
    if grep -q "$pattern" "$COMMAND_LOG"; then
        echo -e "${GREEN}PASSOU${NC}"
    else
        echo -e "${RED}FALHOU${NC}"
        echo "      Log de comando:"
        cat "$COMMAND_LOG" | sed 's/^/        /'
        ((FAIL_COUNT++))
    fi
}

# Helper para verificar se o log de comando NÃO contém um padrão
assert_not_contains() {
    local description="$1"
    local pattern="$2"
    ((TEST_COUNT++))
    echo -n "  [TEST $TEST_COUNT] $description: verificando que NÃO contém '$pattern'... "
    if ! grep -q "$pattern" "$COMMAND_LOG"; then
        echo -e "${GREEN}PASSOU${NC}"
    else
        echo -e "${RED}FALHOU${NC}"
        echo "      Log de comando:"
        cat "$COMMAND_LOG" | sed 's/^/        /'
        ((FAIL_COUNT++))
    fi
}

setup_test_area() {
    rm -rf "$TEST_AREA"
    mkdir -p "$TEST_AREA/scripts/installation"
    # Redefinir o diretório de trabalho para a área de teste para que os caminhos relativos funcionem
    cd "$TEST_AREA"
}

cleanup_test_area() {
    cd "$PROJECT_ROOT"
    rm -rf "$TEST_AREA"
    rm -f "$COMMAND_LOG"
}

# --- Main Execution ---
echo -e "${BLUE}=== INICIANDO TESTE DO INSTALADOR DE FERRAMENTAS DE DESENVOLVIMENTO ===${NC}"

# --- Testes para VSCode ---
section "Testes para Visual Studio Code"

# Cenário 1: Instalação via script de setup do projeto
subsection "Cenário 1: Usando script de setup 'setup_vscode.sh'"
setup_test_area
touch "scripts/installation/setup_vscode.sh" # Simula a existência do script
> "$COMMAND_LOG" # Limpa o log
MOCK_COMMANDS=() # Nenhum comando pré-instalado
install_vscode > /dev/null 2>&1
assert_contains "VSCode (setup script)" "BASH_CALLED: scripts/installation/setup_vscode.sh"
assert_not_contains "VSCode (setup script)" "APT_GET_CALLED"

# Cenário 2: Instalação via gerenciador de pacotes (script de setup não existe)
subsection "Cenário 2: Usando gerenciador de pacotes"
setup_test_area
> "$COMMAND_LOG"
MOCK_COMMANDS=()
OS="ubuntu" # Simula Ubuntu
install_vscode_from_package_manager > /dev/null 2>&1
assert_contains "VSCode (apt)" "APT_GET_CALLED: install -y code"
assert_contains "VSCode (apt)" "WGET_CALLED"

setup_test_area
> "$COMMAND_LOG"
MOCK_COMMANDS=()
OS="manjaro" # Simula Manjaro
install_vscode_from_package_manager > /dev/null 2>&1
assert_contains "VSCode (pacman)" "PACMAN_CALLED: -S --noconfirm code"

setup_test_area
> "$COMMAND_LOG"
MOCK_COMMANDS=("dnf") # Simula CentOS com dnf
OS="centos"
install_vscode_from_package_manager > /dev/null 2>&1
assert_contains "VSCode (dnf)" "DNF_CALLED: install -y code"
assert_contains "VSCode (dnf)" "RPM_CALLED: --import"

# Cenário 3: VSCode já está instalado
subsection "Cenário 3: VSCode já instalado"
setup_test_area
> "$COMMAND_LOG"
MOCK_COMMANDS=("code") # Simula que 'code' já existe
install_vscode_from_package_manager > /dev/null 2>&1
assert_not_contains "VSCode (já instalado)" "APT_GET_CALLED"
assert_not_contains "VSCode (já instalado)" "PACMAN_CALLED"
assert_not_contains "VSCode (já instalado)" "DNF_CALLED"

# --- Testes para Spyder ---
section "Testes para Spyder IDE"

# Cenário 4: Instalação do Spyder
subsection "Cenário 4: Instalando Spyder"
setup_test_area
mkdir -p "$HOME/cluster_env/bin" # Simula venv
> "$COMMAND_LOG"
MOCK_COMMANDS=() # Spyder não está instalado
install_spyder > /dev/null 2>&1
assert_contains "Spyder (instalação)" "PIP_CALLED: install spyder"
assert_contains "Spyder (instalação)" "SOURCE_CALLED: ~/cluster_env/bin/activate"
assert_contains "Spyder (instalação)" "DEACTIVATE_CALLED"

# Cenário 5: Spyder já instalado
subsection "Cenário 5: Spyder já instalado"
setup_test_area
mkdir -p "$HOME/cluster_env/bin"
> "$COMMAND_LOG"
MOCK_COMMANDS=("spyder-installed") # Simula que 'import spyder' funciona
install_spyder > /dev/null 2>&1
assert_not_contains "Spyder (já instalado)" "PIP_CALLED: install spyder"

# Cenário 6: Ambiente virtual não existe
subsection "Cenário 6: Ambiente virtual não encontrado"
setup_test_area
# Não cria o diretório do venv
> "$COMMAND_LOG"
MOCK_COMMANDS=()
# A função `install_spyder` imprime um erro, então capturamos para o log
install_spyder >> "$COMMAND_LOG" 2>&1
assert_contains "Spyder (sem venv)" "Ambiente virtual '~/cluster_env' não encontrado"
assert_not_contains "Spyder (sem venv)" "PIP_CALLED"

# --- Resumo e Limpeza ---
cleanup_test_area
echo -e "\n${BLUE}=== RESULTADO DO TESTE DO INSTALADOR DE FERRAMENTAS ===${NC}"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}🎉 Todos os $TEST_COUNT testes passaram com sucesso!${NC}"
else
    echo -e "${RED}❌ $FAIL_COUNT de $TEST_COUNT testes falharam.${NC}"
fi

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi