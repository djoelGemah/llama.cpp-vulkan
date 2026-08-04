#!/bin/bash

set -e

echo ""
echo "===================================="
echo "Launching llama-cli..."
echo "===================================="

SDK_DIR=$(find /opt -maxdepth 1 -type d -name "*vulkan*" | head -n1)

source "$SDK_DIR/setup-env.sh"

cd /opt/llama.cpp

./build/bin/llama-cli \
-m /models/qwen36-35b/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf \
--spec-type draft-mtp \
-fa on \
-c 64000 \
-t 12
