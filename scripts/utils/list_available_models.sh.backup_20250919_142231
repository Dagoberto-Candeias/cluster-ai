#!/bin/bash
# Script para listar todos os modelos disponíveis no Ollama
# Mostra informações detalhadas sobre cada modelo

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Funções auxiliares
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }
section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Verificar se Ollama está instalado
check_ollama() {
    if ! command -v ollama &> /dev/null; then
        error "Ollama não está instalado!"
        echo "Instale o Ollama primeiro:"
        echo "curl -fsSL https://ollama.com/install.sh | sh"
        exit 1
    fi
}

# Verificar se Ollama está rodando
check_ollama_running() {
    if ! pgrep -f "ollama serve" &> /dev/null && ! systemctl is-active --quiet ollama 2>/dev/null; then
        warn "Ollama não está rodando. Iniciando..."
        if command -v ollama &> /dev/null; then
            nohup ollama serve > /dev/null 2>&1 &
            sleep 3
            success "Ollama iniciado"
        fi
    fi
}

# Obter lista de modelos disponíveis da API
get_available_models() {
    log "Consultando modelos disponíveis na biblioteca Ollama..."

    # Tentar obter lista da API
    if curl -s "http://localhost:11434/api/tags" &> /dev/null; then
        # API está disponível
        local models_json=$(curl -s "http://localhost:11434/api/tags")
        echo "$models_json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    models = data.get('models', [])
    for model in models:
        name = model.get('name', 'Unknown')
        size = model.get('size', 0)
        size_gb = size / (1024**3) if size > 0 else 0
        print(f'{name}|{size_gb:.1f}GB')
except:
    print('Erro ao processar resposta da API')
"
    else
        warn "API do Ollama não está acessível. Usando lista conhecida..."
        return 1
    fi
}

# Lista conhecida de modelos populares (fallback)
# Formato: "nome|tamanho|categoria|descrição|casos_de_uso|comando_instalacao"
KNOWN_MODELS=(
    # === MODELOS GERAIS (LLM) ===
    "llama2:7b|3.8GB|🟡 LLM GERAL|Meta Llama 2 7B|Chat, geração de conteúdo|ollama pull llama2:7b"
    "llama2:13b|7.4GB|🔴 LLM GERAL|Meta Llama 2 13B|Conteúdo avançado, pesquisa|ollama pull llama2:13b"
    "llama2:70b|40.0GB|🔴 COLOSSAL|Meta Llama 2 70B|Máxima qualidade, aplicações críticas|ollama pull llama2:70b"
    "llama3:8b|4.7GB|🟡 LLM GERAL|Meta Llama 3|Assistente, aulas, autoatendimento|ollama pull llama3:8b"
    "llama3.1:8b|4.7GB|🟡 LLM GERAL|Meta Llama 3.1|Chatbots, análise de texto|ollama pull llama3.1:8b"
    "llama3.3:70b|40.0GB|🔴 PESADO|Meta Llama 3.3|Alta performance, pesquisa|ollama pull llama3.3:70b"
    "mixtral:8x7b|26.0GB|🔴 PESADO|Mixture of Experts|Chat rápido, suporte em tempo real|ollama pull mixtral:8x7b"
    "mistral:7b|4.1GB|🟡 LLM GERAL|Mistral AI|Lógico, leve e eficiente|ollama pull mistral:7b"
    "mistral-nemo:instruct|7.4GB|🟡 LLM INSTRUCT|Mistral Nemo|Perguntas/respostas, seguir instruções|ollama pull mistral-nemo:instruct"
    "gemma:2b|1.5GB|🟢 LEVE|Google Gemma 2B|Conteúdo leve e raciocínio|ollama pull gemma:2b"
    "gemma:7b|4.1GB|🟡 LLM GERAL|Google Gemma 7B|Conversação, análise|ollama pull gemma:7b"
    "granite3.2:8b|4.7GB|🟡 LLM GERAL|IBM Granite|Aplicações corporativas|ollama pull granite3.2:8b"
    "phi3:3.8b|2.2GB|🟢 LEVE|Microsoft Phi-3|Modelos leves, rápidos|ollama pull phi3:3.8b"
    "phi3:14b|8.0GB|🟡 MÉDIO|Microsoft Phi-3|Análise avançada, processamento|ollama pull phi3:14b"
    "qwen2:7b|4.4GB|🟡 MÉDIO|Alibaba Qwen2|Conversação avançada, análise|ollama pull qwen2:7b"
    "qwen2:72b|42.0GB|🔴 PESADO|Alibaba Qwen2|Pesquisa, aplicações enterprise|ollama pull qwen2:72b"
    "falcon:7b|3.8GB|🟡 LLM GERAL|TII Falcon|Pesquisa, respostas técnicas|ollama pull falcon:7b"
    "falcon:40b|23.0GB|🔴 PESADO|TII Falcon|Análise técnica avançada|ollama pull falcon:40b"
    "opt:30b|18.0GB|🔴 PESADO|Meta OPT|Alternativa ao GPT para estudo|ollama pull opt:30b"
    "bloom|100.0GB|🔴 COLOSSAL|BigScience BLOOM|Texto em vários idiomas|ollama pull bloom"

    # === MODELOS DE CODIFICAÇÃO ===
    "codellama:7b|3.8GB|🟡 CODIFICAÇÃO|Meta CodeLlama|Geração e explicação de código|ollama pull codellama:7b"
    "codellama:13b|7.4GB|🟡 CODIFICAÇÃO|Meta CodeLlama|Código complexo, arquitetura|ollama pull codellama:13b"
    "codellama:34b|20.0GB|🔴 CODIFICAÇÃO|Meta CodeLlama|Projetos enterprise|ollama pull codellama:34b"
    "codegemma:7b|4.1GB|🟡 CODIFICAÇÃO|Google CodeGemma|Geração e explicação de código|ollama pull codegemma:7b"
    "qwen2.5-coder:14b|8.0GB|🟡 CODIFICAÇÃO|Alibaba Qwen2.5|Programação multi-linguagem|ollama pull qwen2.5-coder:14b"
    "deepseek-coder:6.7b|3.8GB|🟡 CODIFICAÇÃO|DeepSeek Coder|Depuração e geração de código|ollama pull deepseek-coder:6.7b"
    "deepseek-coder:33b|19.0GB|🔴 CODIFICAÇÃO|DeepSeek Coder|Projetos complexos|ollama pull deepseek-coder:33b"
    "starcoder2:3b|1.7GB|🟡 CODIFICAÇÃO|BigCode StarCoder2|Programação geral|ollama pull starcoder2:3b"
    "starcoder2:7b|3.5GB|🟡 CODIFICAÇÃO|BigCode StarCoder2|Código complexo|ollama pull starcoder2:7b"
    "starcoder2:15b|8.0GB|🟡 CODIFICAÇÃO|BigCode StarCoder2|Projetos grandes|ollama pull starcoder2:15b"

    # === MODELOS MULTIMODAIS ===
    "llava:7b|4.6GB|🟡 MULTIMODAL|LLaVA 1.6|Perguntas sobre imagens|ollama pull llava:7b"
    "llava:13b|8.2GB|🟡 MULTIMODAL|LLaVA 1.6|Análise visual avançada|ollama pull llava:13b"
    "llava:34b|20.0GB|🔴 MULTIMODAL|LLaVA 1.6|Processamento visual complexo|ollama pull llava:34b"
    "bakllava:7b|4.6GB|🟡 MULTIMODAL|BakLLaVA|Melhor qualidade visual|ollama pull bakllava:7b"
    "moondream:1.8b|0.9GB|🟢 LEVE|Moondream|Descrição de imagens rápida|ollama pull moondream:1.8b"

    # === MODELOS DE EMBEDDINGS ===
    "nomic-embed-text|0.2GB|🟢 EMBEDDINGS|Nomic|Busca semântica simples|ollama pull nomic-embed-text"
    "mxbai-embed-large|0.7GB|🟢 EMBEDDINGS|MixedBread|Documentos grandes/complexos|ollama pull mxbai-embed-large"
    "bge-m3|0.6GB|🟢 EMBEDDINGS|BGE-M3|Multilíngue (ótimo PT/EN)|ollama pull bge-m3"
    "snowflake-arctic-embed:335m|0.2GB|🟢 EMBEDDINGS|Snowflake|Busca rápida, aplicações leves|ollama pull snowflake-arctic-embed:335m"
    "all-minilm:22m|0.02GB|🟢 EMBEDDINGS|MiniLM|Dispositivos móveis, edge|ollama pull all-minilm:22m"

    # === MODELOS DE CONVERSAÇÃO ESPECIALIZADOS ===
    "command-r-plus|35.0GB|🔴 RAG|Command-R+|Autoatendimento com documentos|ollama pull command-r-plus"
    "neural-chat:7b|4.1GB|🟡 CONVERSAÇÃO|Intel Neural Chat|Assistente amigável|ollama pull neural-chat:7b"
    "dolphin-phi:2.7b|1.6GB|🟢 LEVE|Dolphin Phi|Roleplay, criatividade sem censura|ollama pull dolphin-phi:2.7b"
    "dolphin-mistral:7b|4.1GB|🟡 CONVERSAÇÃO|Dolphin Mistral|Diálogo criativo, histórias|ollama pull dolphin-mistral:7b"
    "deephermes3:8b|4.7GB|🟡 CONVERSAÇÃO|DeepHermes 3|Diálogo criativo, histórias|ollama pull deephermes3:8b"
    "zephyr:7b|3.8GB|🟡 INSTRUCT|Zephyr|Seguir instruções com precisão|ollama pull zephyr:7b"
    "wizardlm:13b|7.4GB|🟡 INSTRUCT|WizardLM|Perguntas e raciocínio lógico|ollama pull wizardlm:13b"
    "openchat:7b|4.1GB|🟡 CONVERSAÇÃO|OpenChat|Chat criativo, respostas naturais|ollama pull openchat:7b"

    # === MODELOS DE CONTEXTO LONGO ===
    "yarn-mistral:7b|4.1GB|🟡 LONGO CONTEXTO|YARN Mistral|Documentos longos, análise extensa|ollama pull yarn-mistral:7b"
    "yarn-llama2:7b|3.8GB|🟡 LONGO CONTEXTO|YARN Llama2|Processamento de texto longo|ollama pull yarn-llama2:7b"

    # === MODELOS CLÁSSICOS/LEGADOS ===
    "bert|0.4GB|🟢 NLP CLÁSSICO|Google BERT|Classificação, análise de sentimentos|ollama pull bert"
    "flan-t5:base|0.2GB|🟢 INSTRUCT|FLAN-T5|Perguntas e respostas diretas|ollama pull flan-t5:base"
    "dolly-v2:3b|1.8GB|🟢 LEVE|Dolly 2.0|Perguntas/respostas simples|ollama pull dolly-v2:3b"
    "stablelm:3b|1.8GB|🟢 LEVE|StableLM|Alternativa leve e aberta|ollama pull stablelm:3b"
    "mpt:7b|3.8GB|🟡 LLM GERAL|MosaicML MPT|Ajustável para vários usos|ollama pull mpt:7b"
    "firefunction-v2:70b|40.0GB|🔴 FERRAMENTAS|FireFunction|Execução de funções|ollama pull firefunction-v2:70b"
)

# Mostrar modelos disponíveis
show_available_models() {
    section "📚 MODELOS DISPONÍVEIS NO OLLAMA"

    # Tentar obter da API primeiro
    if get_available_models; then
        log "Modelos obtidos da API do Ollama"
    else
        # Fallback para lista conhecida
        section "📋 CATÁLOGO COMPLETO DE MODELOS OLLAMA"

        # Cabeçalho da tabela
        printf "${CYAN}%-25s %-8s %-15s %-35s %-45s${NC}\n" "MODELO" "TAMANHO" "CATEGORIA" "DESCRIÇÃO" "USO IDEAL"
        echo "-----------------------------------------------------------------------------------------------------------------------------"

        for model_info in "${KNOWN_MODELS[@]}"; do
            IFS='|' read -r name size category desc usage install_cmd <<< "$model_info"

            # Verificar se já está instalado
            if ollama list 2>/dev/null | grep -q "^$name"; then
                printf "${GREEN}%-25s %-8s %-15s %-35s %-45s${NC}\n" "$name ✓" "$size" "$category" "$desc" "$usage"
            else
                printf "${YELLOW}%-25s %-8s %-15s %-35s %-45s${NC}\n" "$name" "$size" "$category" "$desc" "$usage"
            fi
        done

        echo ""
        info "💡 LEGENDA:"
        echo "  🟢 LEVE: Modelos pequenos, ideais para testes e dispositivos limitados"
        echo "  🟡 MÉDIO: Modelos balanceados, boa relação performance/tamanho"
        echo "  🔴 PESADO: Modelos grandes, máxima qualidade mas exigem mais recursos"
        echo "  🔴 COLOSSAL: Modelos enormes, para servidores dedicados"
        echo ""
        info "📦 Para instalar qualquer modelo: copie o comando da coluna 'DESCRIÇÃO'"
        info "✅ Modelos marcados com ✓ já estão instalados no sistema"
    fi
}

# Mostrar categorias de modelos
show_model_categories() {
    section "🏷️ CATEGORIAS DE MODELOS"

    echo -e "${CYAN}1. MODELOS DE CONVERSAÇÃO GERAL${NC}"
    echo "   - llama3.1:8b, llama3.2:3b, mistral:7b, phi3:3.8b"
    echo "   - Recomendados para chatbots e assistentes virtuais"
    echo ""

    echo -e "${CYAN}2. MODELOS PARA PROGRAMAÇÃO${NC}"
    echo "   - codellama:7b/13b, deepseek-coder, starcoder2"
    echo "   - Especializados em geração e análise de código"
    echo ""

    echo -e "${CYAN}3. MODELOS MULTIMODAIS${NC}"
    echo "   - llava:7b/13b, bakllava"
    echo "   - Capazes de analisar imagens e texto simultaneamente"
    echo ""

    echo -e "${CYAN}4. MODELOS DE EMBEDDINGS${NC}"
    echo "   - nomic-embed-text, mxbai-embed-large, all-minilm"
    echo "   - Para busca semântica e similaridade de texto"
    echo ""

    echo -e "${CYAN}5. MODELOS LEVES${NC}"
    echo "   - llama3.2:1b, gemma2:2b, qwen2:0.5b"
    echo "   - Para dispositivos com recursos limitados"
    echo ""

    echo -e "${CYAN}6. MODELOS PESADOS${NC}"
    echo "   - llama3.1:70b, mixtral:8x7b, qwen2:72b"
    echo "   - Máxima qualidade (requer hardware potente)"
    echo ""

    echo -e "${CYAN}7. MODELOS ESPECIALIZADOS${NC}"
    echo "   - portuguese-llm (português), neural-chat, dolphin"
    echo "   - Fine-tuned para tarefas específicas"
}

# Mostrar requisitos de hardware
show_hardware_requirements() {
    section "💻 REQUISITOS DE HARDWARE"

    echo -e "${YELLOW}MODELOS LEVES (1-2GB):${NC}"
    echo "   - RAM: 4GB mínimo, 8GB recomendado"
    echo "   - Armazenamento: 2-5GB livres"
    echo "   - Exemplo: llama3.2:1b, gemma2:2b"
    echo ""

    echo -e "${YELLOW}MODELOS MÉDIOS (3-8GB):${NC}"
    echo "   - RAM: 8GB mínimo, 16GB recomendado"
    echo "   - Armazenamento: 5-15GB livres"
    echo "   - GPU: 4GB VRAM (opcional, acelera processamento)"
    echo "   - Exemplo: llama3.1:8b, mistral:7b, codellama:7b"
    echo ""

    echo -e "${YELLOW}MODELOS GRANDES (13-27GB):${NC}"
    echo "   - RAM: 16GB mínimo, 32GB recomendado"
    echo "   - Armazenamento: 15-30GB livres"
    echo "   - GPU: 8GB+ VRAM recomendada"
    echo "   - Exemplo: llama3.1:70b, mixtral:8x7b, codellama:13b"
    echo ""

    echo -e "${YELLOW}MODELOS COLOSSAIS (40GB+):${NC}"
    echo "   - RAM: 64GB+ recomendado"
    echo "   - Armazenamento: 50GB+ livres"
    echo "   - GPU: 24GB+ VRAM recomendada"
    echo "   - Exemplo: llama3.1:405b, mixtral:8x22b"
    echo ""

    echo -e "${GREEN}💡 DICAS:${NC}"
    echo "   - Modelos maiores = melhor qualidade, mas mais lentos"
    echo "   - GPU acelera significativamente o processamento"
    echo "   - Considere usar modelos quantizados para economia de recursos"
}

# Menu interativo
interactive_menu() {
    while true; do
        section "🔍 MENU - DESCOBRIR MODELOS OLLAMA"

        echo "1. 📋 Listar todos os modelos disponíveis"
        echo "2. 🏷️ Ver categorias de modelos"
        echo "3. 💻 Ver requisitos de hardware"
        echo "4. 🔍 Procurar modelo específico"
        echo "5. 📊 Ver modelos instalados"
        echo "6. 🚀 Instalar modelo recomendado"
        echo "7. 📦 Ver comandos de instalação"
        echo "0. ❌ Sair"
        echo ""

        read -p "Escolha uma opção: " choice

        case $choice in
            1)
                show_available_models
                ;;
            2)
                show_model_categories
                ;;
            3)
                show_hardware_requirements
                ;;
            4)
                read -p "Digite o nome do modelo para procurar: " search_term
                log "Procurando por: $search_term"
                echo "${KNOWN_MODELS[@]}" | tr ' ' '\n' | grep -i "$search_term" | head -10
                ;;
            5)
                section "📦 MODELOS INSTALADOS"
                if command -v ollama &> /dev/null; then
                    ollama list
                else
                    error "Ollama não está instalado"
                fi
                ;;
            6)
                section "🚀 INSTALAÇÃO RÁPIDA"
                echo "Modelos recomendados para começar:"
                echo "1. llama3.1:8b (equilibrado) - ollama pull llama3.1:8b"
                echo "2. mistral:7b (rápido) - ollama pull mistral:7b"
                echo "3. codellama:7b (programação) - ollama pull codellama:7b"
                echo "4. llava:7b (multimodal) - ollama pull llava:7b"
                echo "5. nomic-embed-text (embeddings) - ollama pull nomic-embed-text"
                echo ""
                read -p "Digite o número do modelo ou nome personalizado: " model_choice

                case $model_choice in
                    1) model="llama3.1:8b" ; cmd="ollama pull llama3.1:8b" ;;
                    2) model="mistral:7b" ; cmd="ollama pull mistral:7b" ;;
                    3) model="codellama:7b" ; cmd="ollama pull codellama:7b" ;;
                    4) model="llava:7b" ; cmd="ollama pull llava:7b" ;;
                    5) model="nomic-embed-text" ; cmd="ollama pull nomic-embed-text" ;;
                    *) model="$model_choice" ; cmd="ollama pull $model_choice" ;;
                esac

                if [ -n "$model" ]; then
                    log "Executando: $cmd"
                    $cmd
                fi
                ;;
            7)
                section "📦 COMANDOS DE INSTALAÇÃO"
                echo "Lista completa de comandos para instalar modelos:"
                echo ""

                # Mostrar apenas os comandos de instalação
                for model_info in "${KNOWN_MODELS[@]}"; do
                    IFS='|' read -r name size category desc usage install_cmd <<< "$model_info"

                    # Verificar se já está instalado
                    if ollama list 2>/dev/null | grep -q "^$name"; then
                        printf "${GREEN}%-30s ✅ INSTALADO${NC}\n" "$install_cmd"
                    else
                        printf "${YELLOW}%-30s 📦 DISPONÍVEL${NC}\n" "$install_cmd"
                    fi
                done

                echo ""
                info "💡 Copie e execute qualquer comando acima para instalar o modelo desejado"
                ;;
            0)
                log "Saindo..."
                break
                ;;
            *)
                warn "Opção inválida"
                ;;
        esac

        echo ""
        read -p "Pressione Enter para continuar..."
    done
}

# Função principal
main() {
    echo -e "${BLUE}🔍 DESCOBRINDO MODELOS DISPONÍVEIS NO OLLAMA${NC}"
    echo "========================================"

    check_ollama
    check_ollama_running

    # Verificar se foi chamado com argumentos
    if [ $# -eq 0 ]; then
        interactive_menu
    else
        case "$1" in
            "list")
                show_available_models
                ;;
            "categories")
                show_model_categories
                ;;
            "hardware")
                show_hardware_requirements
                ;;
            "installed")
                section "📦 MODELOS INSTALADOS"
                ollama list
                ;;
            *)
                error "Uso: $0 [list|categories|hardware|installed]"
                echo "Ou execute sem argumentos para menu interativo"
                ;;
        esac
    fi
}

# Executar
main "$@"
