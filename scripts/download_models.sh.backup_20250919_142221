#!/bin/bash
# Script to download AI/ML models in background for Cluster AI

MODELS_DIR="models"
LOG_FILE="logs/model_download.log"

mkdir -p "$MODELS_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# List of model URLs to download
MODEL_URLS=(
    "https://example.com/models/model1.bin"
    "https://example.com/models/model2.bin"
    "https://example.com/models/model3.bin"
)

echo "Starting model downloads in background..." | tee -a "$LOG_FILE"

for url in "${MODEL_URLS[@]}"; do
    filename=$(basename "$url")
    if [ -f "$MODELS_DIR/$filename" ]; then
        echo "Model $filename already exists, skipping." | tee -a "$LOG_FILE"
    else
        echo "Downloading $filename..." | tee -a "$LOG_FILE"
        curl -L "$url" -o "$MODELS_DIR/$filename" &
    fi
done

wait

echo "Model downloads completed." | tee -a "$LOG_FILE"
