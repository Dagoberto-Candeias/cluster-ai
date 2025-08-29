#!/bin/bash
# Script de Teste para o Instalador Universal em Múltiplas Distribuições

# --- Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_SCRIPT_PATH="$SCRIPT_DIR/../../install_universal.sh"

# Carregar funções comuns para logging e cores
source "$SCRIPT_DIR/../utils/common.sh"

# Verificar se o instalador existe antes de continuar
if [ ! -f "$INSTALLER_SCRIPT_PATH" ]; then
    error "Script do instalador universal não encontrado em: $INSTALLER_SCRIPT_PATH"
    exit 1
fi

# Carregar as funções do instalador para que possamos testá-las
source "$INSTALLER_SCRIPT_PATH"

# --- Mocking Area ---
# Sobrescrevemos os comandos do sistema para que não executem de verdade.
# Em vez disso, eles registram o que teriam feito em um arquivo de log.
COMMAND_LOG="/tmp/installer_test_commands.log"

# Mock para o comando 'sudo' para apenas executar o que vem depois
sudo() {
    "$@"
}

# Mocks para os gerenciadores de pacotes
apt() {
    echo "APT_CALLED: $@" >> "$COMMAND_LOG"
}

pacman() {
    echo "PACMAN_CALLED: $@" >> "$COMMAND_LOG"
}

dnf() {
    echo "DNF_CALLED: $@" >> "$COMMAND_LOG"
}

yum() {
    echo "YUM_CALLED: $@" >> "$COMMAND_LOG"
}

systemctl() {
    echo "SYSTEMCTL_CALLED: $@" >> "$COMMAND_LOG"
}

usermod() {
    echo "USERMOD_CALLED: $@" >> "$COMMAND_LOG"
}

# Mock para a função de detecção de OS. Em vez de ler /etc/os-release,
# ela não fará nada, permitindo que nosso teste defina a variável $OS manualmente.
detect_os() {
    return 0
}

# --- Test Runner ---
TEST_COUNT=0
FAIL_COUNT=0

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

run_test_for_distro() {
    local distro_to_test="$1"
    local update_pattern="$2"
    local install_pattern="$3"

    echo -e "\n${CYAN}--> Testando para a distro '$distro_to_test'...${NC}"

    # Define a variável global $OS que o script do instalador usa
    OS="$distro_to_test"

    # --- Teste de atualização de pacotes ---
    > "$COMMAND_LOG" # Limpa o log
    update_system_packages > /dev/null 2>&1
    assert_contains "Atualização de pacotes" "$update_pattern"

    # --- Teste de instalação de dependências ---
    > "$COMMAND_LOG" # Limpa o log
    install_dependency_packages > /dev/null 2>&1
    assert_contains "Instalação de dependências" "$install_pattern"
    assert_contains "Instalação de dependências" "curl" # Verifica um pacote comum

    # --- Teste de configuração do Docker ---
    > "$COMMAND_LOG" # Limpa o log
    configure_docker > /dev/null 2>&1
    assert_contains "Configuração do Docker" "SYSTEMCTL_CALLED: enable docker"
    assert_contains "Configuração do Docker" "USERMOD_CALLED: -aG docker"
}

# --- Main Execution ---
echo -e "${BLUE}=== INICIANDO TESTE DO INSTALADOR UNIVERSAL (Refatorado) ===${NC}"
echo "Simulando diferentes distribuições Linux para validar a lógica de instalação..."

# Executa os testes para cada distro suportada
run_test_for_distro "ubuntu" "APT_CALLED: update" "APT_CALLED: install -y"
run_test_for_distro "debian" "APT_CALLED: update" "APT_CALLED: install -y"
run_test_for_distro "manjaro" "PACMAN_CALLED: -Syu" "PACMAN_CALLED: -S --noconfirm"
run_test_for_distro "centos" "DNF_CALLED: update -y" "DNF_CALLED: install -y"

# --- Resumo e Limpeza ---
echo -e "\n${BLUE}=== RESULTADO DO TESTE DO INSTALADOR ===${NC}"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}🎉 Todos os $TEST_COUNT testes de distribuição passaram com sucesso!${NC}"
else
    echo -e "${RED}❌ $FAIL_COUNT de $TEST_COUNT testes falharam.${NC}"
fi

rm -f "$COMMAND_LOG"
echo "Limpeza de arquivos de teste concluída."

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi