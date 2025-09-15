#!/bin/bash

PERSONAS_FILE="docs/guides/prompts/openwebui_personas.json"
API_URL="http://localhost:3000/api/v1/personas"

# Ler personas do arquivo JSON
personas_count=$(jq '.personas | length' "$PERSONAS_FILE")
echo "Encontradas $personas_count personas para importar."

for i in $(seq 0 $(($personas_count - 1))); do
    persona_name=$(jq -r ".personas[$i].name" "$PERSONAS_FILE")
    echo "Importando persona: $persona_name"

    # Extrair dados da persona
    persona_data=$(jq ".personas[$i]" "$PERSONAS_FILE")

    # Fazer POST para a API
    response=$(curl -s -w "%{http_code}" -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "$persona_data" 2>/dev/null)

    http_code=$(echo "$response" | tail -c 3)
    echo "HTTP Code: $http_code"

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo "✅ Persona '$persona_name' importada com sucesso."
    else
        echo "❌ Falha ao importar persona '$persona_name'."
    fi
done

echo "Importação concluída."
