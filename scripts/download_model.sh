#!/bin/bash

set -e

echo ""
echo "===================================="
echo "Downloading Qwen3.6..."
echo "===================================="

source /opt/venv/bin/activate

mkdir -p /models/qwen36-35b

hf download \
unsloth/Qwen3.6-35B-A3B-MTP-GGUF \
Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf \
--local-dir /models/qwen36-35b

echo "Model downloaded."
