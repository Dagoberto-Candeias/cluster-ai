#!/bin/bash
# ~/.bashrc - Sistema Avançado de Gerenciamento de Projetos Python

# ======================================================================
# CONFIGURAÇÕES BÁSICAS
# ======================================================================

[ -z "$PS1" ] && return

# Configurações de histórico
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize
shopt -s globstar
shopt -s dotglob

# ======================================================================
# VERIFICAÇÃO DE AMBIENTE AO ABRIR O TERMINAL
# ======================================================================

handle_existing_venv() {
    if [ -n "$VIRTUAL_ENV" ]; then
        local venv_name=$(basename "$VIRTUAL_ENV")
        local project_path=$(dirname "$VIRTUAL_ENV")
        local rel_path="${project_path#$HOME/}"

        echo -e "\n\033[1;33m⚠️  AMBIENTE VIRTUAL DETECTADO!\033[0m"
        echo -e "Projeto: \033[1;34m$rel_path\033[0m"
        echo -e "Ambiente: \033[1;35m$venv_name\033[0m"
        echo -e "\n\033[1;36mO que deseja fazer?\033[0m"
        echo "1) Manter ambiente ativo (continuar trabalhando)"
        echo "2) Desativar ambiente (mantém terminal aberto)"
        echo "3) Fechar este terminal"
        echo "4) Navegar para o diretório do projeto"
        echo "5) Abrir projeto no VSCode"

        read -p $'\n\033[1;36mDigite sua escolha: \033[0m' choice

        case $choice in
            1)
                echo -e "\033[1;32m✅ Ambiente mantido. Continue trabalhando.\033[0m"
                ;;
            2)
                deactivate
                echo -e "\033[1;32m✅ Ambiente desativado. Terminal pronto para outros comandos.\033[0m"
                ;;
            3)
                echo -e "\033[1;31m🚫 Terminal sendo fechado...\033[0m"
                sleep 1
                exit 0
                ;;
            4)
                cd "$project_path"
                echo -e "\033[1;32m📂 Diretório alterado para: $rel_path\033[0m"
                ;;
            5)
                if command -v code &>/dev/null; then
                    cd "$project_path"
                    code .
                    echo -e "\033[1;36m</> VS Code iniciado!\033[0m"
                else
                    echo -e "\033[1;31m❌ VS Code não encontrado!\033[0m"
                fi
                ;;
            *)
                echo -e "\033[1;33m⚠️  Opção inválida. Mantendo ambiente.\033[0m"
                ;;
        esac
    fi
}

# Executa a verificação imediatamente
handle_existing_venv

# ======================================================================
# PROMPT INFORMATIVO
# ======================================================================

parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

set_prompt() {
    local venv_info=""
    if [ -n "$VIRTUAL_ENV" ]; then
        venv_info="\[\033[1;35m\][$(basename "$VIRTUAL_ENV")]\[\033[0m\] "
    fi

    PS1="${venv_info}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[00m\]\$ "
}
PROMPT_COMMAND=set_prompt

# ======================================================================
# SISTEMA DE GERENCIAMENTO DE PROJETOS HIERÁRQUICO
# ======================================================================

PROJECTS_DIR="${PYTHON_PROJECTS_DIR:-$HOME/Projetos}"
declare -a PROJECT_PATHS
CURRENT_MENU="main"
CURRENT_PATH=""

# Função para sanitizar números
sanitize_number() {
    echo "$1" | tr -cd '[:digit:]'
}

# Encontrar todos os projetos
find_projects() {
    PROJECT_PATHS=()

    while IFS= read -r -d $'\0' path; do
        PROJECT_PATHS+=("$path")
    done < <(find "$PROJECTS_DIR" -type d \( -name venv -o -name .venv -o -name env -o -name .env \) \
             -exec dirname {} \; -print0 2>/dev/null | sort -z)
}

# Detecção melhorada de ambientes virtuais
activate_project() {
    local project_path="$1"
    local venv_path=""

    # Verifica se já tem ambiente ativo
    if [ -n "$VIRTUAL_ENV" ]; then
        read -p $'\033[1;33m⚠️  Já existe um ambiente ativo. Deseja desativá-lo? (s/n) \033[0m' -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            deactivate
            echo -e "\033[1;32m✅ Ambiente anterior desativado.\033[0m"
        fi
    fi

    # Busca por ambientes
    local common_locations=("venv" ".venv" "env" ".env" "virtualenv")
    for name in "${common_locations[@]}"; do
        if [ -f "$project_path/$name/bin/activate" ]; then
            venv_path="$project_path/$name"
            break
        fi
    done

    if [ -z "$venv_path" ]; then
        venv_path=$(find "$project_path" -type f -path "*/bin/activate" -print -quit 2>/dev/null | xargs dirname 2>/dev/null | xargs dirname 2>/dev/null)
        venv_path=$(echo "$venv_path" | tr -d '[:space:]')
    fi

    if [ -n "$venv_path" ] && [ -f "$venv_path/bin/activate" ]; then
        source "$venv_path/bin/activate"
        cd "$project_path"

        local rel_path="${project_path#$PROJECTS_DIR/}"
        echo -e "\033[1;32m✅ Projeto ativado: $rel_path\033[0m"
        echo -e "\033[1;33mAmbiente detectado: $(basename "$venv_path")\033[0m"
        echo -e "\033[1;36mPython: $(python --version 2>&1)\033[0m"
        return 0
    else
        echo -e "\033[1;31m❌ Ambiente virtual não encontrado!\033[0m"
        return 1
    fi
}

# Registro de aliases com prevenção de colisões
register_venv_aliases() {
    # Remove aliases antigos
    for alias_name in $(alias | grep -Eo 'venv_[^=]+'); do
        unalias "$alias_name" 2>/dev/null
    done

    # Cria novos aliases
    while IFS= read -r -d $'\0' venv_activate; do
        local venv_path=$(dirname "$venv_activate")
        local project_path=$(dirname "$venv_path")
        local project_name="${project_path#$PROJECTS_DIR/}"

        # Gera nome seguro para alias
        local safe_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr -sc '[:alnum:]' '_')
        local alias_name="venv_${safe_name%_}"

        # Verifica se o alias já existe
        if ! alias "$alias_name" &>/dev/null; then
            alias "$alias_name"="source \"$venv_activate\" && cd \"$project_path\" && \
                echo -e \"\033[1;32m✅ Projeto ativado: $project_name\033[0m\""
        fi
    done < <(find "$PROJECTS_DIR" -type f -path "*/bin/activate" -print0 2>/dev/null)
}

# Navegação hierárquica melhorada
browse_directory() {
    local target_dir="${1:-$PROJECTS_DIR}"
    CURRENT_PATH="$target_dir"

    while true; do
        clear
        local options=()
        local paths=()
        local types=()

        # Opção para voltar
        if [ "$target_dir" != "$PROJECTS_DIR" ]; then
            options+=(".. (voltar)")
            paths+=("$(dirname "$target_dir")")
            types+=("dir")
        fi

        # Lista diretórios
        while IFS= read -r -d $'\0' dir; do
            options+=("$(basename "$dir")/")
            paths+=("$dir")
            types+=("dir")
        done < <(find "$target_dir" -maxdepth 1 -mindepth 1 -type d -not -name '.*' -print0 2>/dev/null | sort -z)

        # Lista projetos nesta pasta
        while IFS= read -r -d $'\0' venv_path; do
            local project_path=$(dirname "$venv_path")
            options+=("▶ $(basename "$project_path")")
            paths+=("$project_path")
            types+=("project")
        done < <(find "$target_dir" -maxdepth 2 -mindepth 1 -type d \( -name venv -o -name .venv -o -name env -o -name .env \) -print0 2>/dev/null | sort -z)

        # Exibe menu
        echo -e "\033[1;34m=== BROWSE: ${target_dir#$PROJECTS_DIR/} ===\033[0m"
        echo -e "0) Voltar ao menu principal"

        for i in "${!options[@]}"; do
            echo "$(($i+1))) ${options[$i]}"
        done

        echo -e "\n\033[1;36mDigite o número da opção ou 'q' para sair:\033[0m"
        read -e choice_raw

        # Sanitiza a entrada
        local choice=$(sanitize_number "$choice_raw")

        if [[ "$choice_raw" == "q" ]]; then
            return
        elif [[ -z "$choice" ]]; then
            echo -e "\033[1;31m❌ Opção inválida!\033[0m"
            sleep 1
        elif [ "$choice" -eq 0 ]; then
            return
        elif [ "$choice" -le ${#options[@]} ]; then
            local idx=$(($choice-1))
            local selected_path="${paths[$idx]}"

            if [ "${types[$idx]}" == "dir" ]; then
                browse_directory "$selected_path"
                return
            else
                project_actions "$selected_path"
                return
            fi
        else
            echo -e "\033[1;31m❌ Opção inválida!\033[0m"
            sleep 1
        fi
    done
}

# Ações de projeto com validação
project_actions() {
    local project_path="$1"
    local project_name="${project_path#$PROJECTS_DIR/}"

    while true; do
        clear
        echo -e "\033[1;34m=== PROJETO: $project_name ===\033[0m"
        echo "1) Ativar projeto"
        echo "2) Abrir Spyder"
        echo "3) Abrir VS Code"
        echo "4) Abrir Jupyter"
        echo "5) Abrir PyCharm"
        echo "6) Criar link 'venv'"
        echo "7) Instalar pacotes básicos"
        echo "8) Verificar dependências"
        echo "9) Voltar"
        echo "0) Sair do menu"

        read -p $'\n\033[1;36mDigite o número da opção:\033[0m' choice_raw

        # Sanitiza a entrada
        local choice=$(sanitize_number "$choice_raw")

        case $choice in
            1) activate_project "$project_path" ;;
            2)
                if activate_project "$project_path"; then
                    command -v spyder &>/dev/null || pip install -q spyder
                    spyder . >/dev/null 2>&1 &
                    echo -e "\033[1;36m🖥️  Spyder iniciado!\033[0m"
                fi
                ;;
            3)
                if activate_project "$project_path"; then
                    if command -v code &>/dev/null; then
                        code .
                        echo -e "\033[1;36m</> VS Code iniciado!\033[0m"
                    else
                        echo -e "\033[1;31m❌ VS Code não encontrado!\033[0m"
                    fi
                fi
                ;;
            4)
                if activate_project "$project_path"; then
                    command -v jupyter &>/dev/null || pip install -q jupyter
                    jupyter notebook . >/dev/null 2>&1 &
                    echo -e "\033[1;36m📓 Jupyter iniciado!\033[0m"
                fi
                ;;
            5)
                if activate_project "$project_path"; then
                    if command -v pycharm &>/dev/null; then
                        pycharm . >/dev/null 2>&1 &
                        echo -e "\033[1;36m🐍 PyCharm iniciado!\033[0m"
                    else
                        echo -e "\033[1;31m❌ PyCharm não encontrado!\033[0m"
                    fi
                fi
                ;;
            6) create_venv_link "$project_path" ;;
            7) install_base_packages ;;
            8) check_dependencies ;;
            9) return ;;
            0) exit 0 ;;
            *) echo -e "\033[1;31m❌ Opção inválida!\033[0m" ;;
        esac

        read -n 1 -s -r -p $'\n\033[1;33mPressione qualquer tecla para continuar...\033[0m'
    done
}

# Função para criar link de venv
create_venv_link() {
    local project_path="$1"
    local env_options=()
    local env_paths=()

    echo -e "\n\033[1;34m=== CRIAR LINK PARA VENV ===\033[0m"
    echo "Projeto: $project_path"

    # Busca ambientes virtuais
    while IFS= read -r -d $'\0' env; do
        if [ -f "$env/bin/activate" ]; then
            env_options+=("$(basename "$env")")
            env_paths+=("$env")
        fi
    done < <(find "$project_path" -maxdepth 2 -type d -name "*venv*" -print0 2>/dev/null)

    if [ ${#env_options[@]} -eq 0 ]; then
        echo -e "\033[1;31m❌ Nenhum ambiente virtual encontrado!\033[0m"
        return 1
    fi

    # Mostra opções
    for i in "${!env_options[@]}"; do
        echo "$(($i+1))) ${env_options[$i]}"
    done

    read -p $'\n\033[1;36mSelecione o ambiente para vincular:\033[0m' choice_raw

    # Sanitiza a entrada
    local choice=$(sanitize_number "$choice_raw")

    if [ "$choice" -ge 1 ] && [ "$choice" -le ${#env_options[@]} ]; then
        local idx=$(($choice-1))
        local selected_env="${env_paths[$idx]}"
        local link_path="$project_path/venv"

        if [ -e "$link_path" ]; then
            read -p $'\033[1;33m⚠️  Link já existe. Sobrescrever? (s/n) \033[0m' -n 1 -r
            echo
            [[ $REPLY =~ ^[Ss]$ ]] || return
            rm -rf "$link_path"
        fi

        ln -s "$selected_env" "$link_path"
        echo -e "\033[1;32m✅ Link criado: venv → $(basename "$selected_env")\033[0m"
        sleep 1
    else
        echo -e "\033[1;31m❌ Seleção inválida!\033[0m"
        sleep 1
    fi
}

# Funções adicionais de gerenciamento
install_base_packages() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo -e "\033[1;34mInstalando pacotes básicos...\033[0m"
        pip install -U pip wheel setuptools
        pip install ipython pandas numpy matplotlib seaborn jupyterlab scikit-learn black flake8
        echo -e "\033[1;32m✅ Pacotes básicos instalados!\033[0m"
    else
        echo -e "\033[1;31m❌ Nenhum ambiente ativo!\033[0m"
    fi
}

check_dependencies() {
    if [ -n "$VIRTUAL_ENV" ]; then
        if [ -f "requirements.txt" ]; then
            echo -e "\033[1;34mVerificando dependências...\033[0m"
            pip install -r requirements.txt
            echo -e "\033[1;32m✅ Dependências instaladas!\033[0m"
        else
            echo -e "\033[1;33m⚠️  requirements.txt não encontrado!\033[0m"
        fi
    else
        echo -e "\033[1;31m❌ Nenhum ambiente ativo!\033[0m"
    fi
}

# ======================================================================
# MENU PRINCIPAL
# ======================================================================

main_menu() {
    while true; do
        clear
        echo -e "\033[1;34m=== MENU PRINCIPAL ===\033[0m"
        echo -e "Diretório atual: \033[0;34m$(pwd)\033[0m"

        if [ -n "$VIRTUAL_ENV" ]; then
            echo -e "Ambiente ativo: \033[0;31m$(basename "$VIRTUAL_ENV")\033[0m"
            echo -e "Projeto: \033[0;35m${VIRTUAL_ENV%/*}\033[0m"
        else
            echo -e "Ambiente ativo: \033[0;33mNenhum\033[0m"
        fi

        echo -e "\n\033[1;36mOPÇÕES:\033[0m"
        echo "1) Navegar pela estrutura de projetos"
        echo "2) Listar todos os projetos"
        echo "3) Criar novo projeto"
        echo "4) Recarregar lista de projetos"
        echo "5) Desativar ambiente atual"
        echo "6) Mostrar aliases de ambientes"
        echo "7) Configurações"
        echo "0) Sair"

        read -p $'\n\033[1;36mDigite o número da opção:\033[0m' choice_raw

        # Sanitiza a entrada
        local choice=$(sanitize_number "$choice_raw")

        case $choice in
            1) browse_directory "$PROJECTS_DIR" ;;
            2) list_all_projects ;;
            3) create_project ;;
            4) refresh_projects ;;
            5) deactivate_env ;;
            6) show_venv_aliases ;;
            7) config_menu ;;
            0) exit 0 ;;
            *) echo -e "\033[1;31m❌ Opção inválida!\033[0m"; sleep 1 ;;
        esac
    done
}

# Funções auxiliares do menu
list_all_projects() {
    clear
    echo -e "\033[1;34m=== TODOS OS PROJETOS (${#PROJECT_PATHS[@]}) ===\033[0m"

    if [ ${#PROJECT_PATHS[@]} -eq 0 ]; then
        echo -e "\033[1;33mNenhum projeto encontrado!\033[0m"
    else
        for i in "${!PROJECT_PATHS[@]}"; do
            local rel_path="${PROJECT_PATHS[$i]#$PROJECTS_DIR/}"
            echo -e "$(($i+1))) $rel_path"
        done
    fi

    read -n 1 -s -r -p $'\n\033[1;36mPressione qualquer tecla para voltar...\033[0m'
}

create_project() {
    read -p "Nome do projeto (caminho relativo): " project_path
    if [ -z "$project_path" ]; then
        echo -e "\033[1;31m❌ Nome não pode ser vazio!\033[0m"
        return 1
    fi

    local full_path="$PROJECTS_DIR/$project_path"

    if [ -d "$full_path" ]; then
        echo -e "\033[1;33m⚠️  Diretório já existe!\033[0m"
        return 1
    fi

    mkdir -p "$full_path"
    cd "$full_path" || return 1

    python3 -m venv venv
    source venv/bin/activate

    # Configuração inicial do projeto
    touch README.md requirements.txt .gitignore
    cat > .gitignore <<EOL
# Environments
venv/
.env/
.venv/
env/

# Python cache
__pycache__/
*.pyc
*.pyo
*.pyd

# Jupyter
.ipynb_checkpoints/
EOL

    mkdir -p src data docs notebooks tests
    touch src/__init__.py

    echo -e "\033[1;32m🚀 Projeto criado: $project_path\033[0m"
    refresh_projects
    sleep 2
}

refresh_projects() {
    find_projects
    register_venv_aliases
    echo -e "\033[1;32m✅ Projetos e ambientes recarregados!\033[0m"
    sleep 1
}

deactivate_env() {
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate
        echo -e "\033[1;32m✅ Ambiente desativado!\033[0m"
    else
        echo -e "\033[1;33m⚠️  Nenhum ambiente ativo!\033[0m"
    fi
    sleep 1
}

show_venv_aliases() {
    clear
    echo -e "\033[1;34m=== ALIASES DE AMBIENTES VIRTUAIS ===\033[0m"

    local aliases_found=0
    while IFS= read -r line; do
        local alias_name=$(awk -F'=' '{print $1}' <<< "$line")
        local alias_cmd=$(awk -F"'" '{print $2}' <<< "$line")
        local project_path=$(dirname "$(dirname "$alias_cmd")")

        echo -e "\033[1;36m$alias_name\033[0m → ${project_path#$PROJECTS_DIR/}"
        aliases_found=1
    done < <(alias | grep 'venv_')

    if [ "$aliases_found" -eq 0 ]; then
        echo -e "\033[1;33mNenhum alias encontrado!\033[0m"
    fi

    echo -e "\n\033[1;32mPara ativar: \033[1;36mvenv_Nome_Do_Projeto\033[0m"
    read -n 1 -s -r -p $'\n\033[1;36mPressione qualquer tecla para voltar...\033[0m'
}

config_menu() {
    while true; do
        clear
        echo -e "\033[1;34m=== CONFIGURAÇÕES ===\033[0m"
        echo "1) Alterar diretório de projetos"
        echo "2) Definir versão padrão do Python"
        echo "3) Configurar editor padrão"
        echo "9) Voltar"

        read -p $'\n\033[1;36mDigite o número da opção:\033[0m' choice_raw

        # Sanitiza a entrada
        local choice=$(sanitize_number "$choice_raw")

        case $choice in
            1)
                read -p "Novo diretório de projetos: " new_dir
                if [ -d "$new_dir" ]; then
                    PROJECTS_DIR="$new_dir"
                    refresh_projects
                    echo -e "\033[1;32m✅ Diretório atualizado!\033[0m"
                else
                    echo -e "\033[1;31m❌ Diretório inválido!\033[0m"
                fi
                ;;
            9) return ;;
            *) echo -e "\033[1;31m❌ Opção inválida!\033[0m" ;;
        esac
        sleep 1
    done
}

# ======================================================================
# ALIASES E UTILITÁRIOS
# ======================================================================

# Navegação
alias ll='ls -alFh --group-directories-first'
alias la='ls -Ah'
alias l='ls -CFh'
alias proj='cd "$PROJECTS_DIR"'

# Gerenciamento de projetos
alias pmenu='main_menu'
alias refresh='refresh_projects'
alias pnew='create_project'
alias pfind='find_projects && list_all_projects'

# Python
alias python='python3'
alias py='python3'
alias pip='pip3'
export PYTHONWARNINGS="ignore"
export PYTHONSTARTUP="$HOME/.pythonrc"
export QT_QPA_PLATFORM=xcb

# Inicialização do sistema
initialize_project_system() {
    mkdir -p "$PROJECTS_DIR"
    refresh_projects

    # Mensagem inicial condicional
    if [ -z "$VIRTUAL_ENV" ]; then
        echo -e "\n\033[1;32mSISTEMA DE GERENCIAMENTO DE PROJETOS\033[0m"
        echo -e "Diretório de projetos: \033[1;34m$PROJECTS_DIR\033[0m"
        echo -e "Projetos encontrados: \033[1;35m${#PROJECT_PATHS[@]}\033[0m"
        echo -e "\nComandos disponíveis:"
        echo -e "  \033[1;36mpmenu\033[0m    - Menu interativo"
        echo -e "  \033[1;36mrefresh\033[0m  - Recarregar projetos"
        echo -e "  \033[1;36mproj\033[0m     - Ir para pasta de projetos"

        # Lista alguns aliases
        local alias_count=$(alias | grep -c 'venv_')
        if [ "$alias_count" -gt 0 ]; then
            echo -e "\n\033[1;33mAliases de ambientes disponíveis:\033[0m"
            alias | grep 'venv_' | head -n 3 | cut -d'=' -f1
            if [ "$alias_count" -gt 3 ]; then
                echo -e "\033[1;36m... e mais $((alias_count - 3)) ambientes\033[0m"
            fi
        fi
    fi
}

# Inicializa o sistema
initialize_project_system

PATH=~/.console-ninja/.bin:$PATH
# >>> Configuração Cluster Dask/MPI >>>
if [ -f ~/cluster_env/bin/activate ]; then
    source ~/cluster_env/bin/activate
    echo "[INFO] Ambiente cluster_env ativado automaticamente."
fi
# <<< Configuração Cluster Dask/MPI <<<
