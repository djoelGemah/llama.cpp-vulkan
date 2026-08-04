#!/bin/bash

set -e

echo ""
echo "===================================="
echo "Building llama.cpp..."
echo "===================================="

cd /opt

git clone https://github.com/ggerganov/llama.cpp /opt/llama.cpp

cd /opt/llama.cpp

rm -rf build

SDK_DIR=$(find /opt -maxdepth 1 -type d -name "*vulkan*" | head -n1)

source "$SDK_DIR/setup-env.sh"

cmake -S . -B build \
-DGGML_VULKAN=ON \
-DCMAKE_BUILD_TYPE=Release

cmake --build build -j$(nproc)

echo "llama.cpp build completed."
