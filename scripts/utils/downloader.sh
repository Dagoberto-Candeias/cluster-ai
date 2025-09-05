#!/bin/bash
#
# downloader.sh - Um script simples para baixar um arquivo.

set -euo pipefail

# Carrega funções comuns se existirem no contexto
if [[ -f "${PROJECT_ROOT}/scripts/lib/common.sh" ]]; then
    source "${PROJECT_ROOT}/scripts/lib/common.sh"
else
    # Fallback simples se common.sh não for encontrado
    info() { echo "[INFO] $1"; }
    error() { echo "[ERROR] $1" >&2; }
fi

download_file() {
    if [ "$#" -ne 2 ]; then
        error "Uso: download_file <URL> <arquivo_de_saida>"
        return 1
    fi

    local url="$1"
    local output_file="$2"

    info "Baixando '$url' para '$output_file'..."

    # -f: Falha silenciosamente em erros de servidor.
    # -L: Segue redirecionamentos.
    # -s: Modo silencioso.
    # -o: Arquivo de saída.
    if curl -fLs -o "$output_file" "$url"; then
        info "Download concluído com sucesso."
    else
        error "Falha no download de '$url'."
        # Limpa o arquivo parcial em caso de falha
        rm -f "$output_file"
        return 1
    fi
}

download_file "$@"