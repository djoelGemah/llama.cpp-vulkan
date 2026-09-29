#!/usr/bin/env bash

set -e

echo "=========================================="
echo " llama.cpp Vulkan Installer"
echo " Ubuntu 24.04"
echo "=========================================="

# =========================================================
# 1. Install dependencies
# =========================================================

echo ""
echo "[1/5] Installing dependencies..."

apt update

apt install -y \
    git cmake build-essential \
    python3 python3-pip python3-venv \
    libvulkan-dev vulkan-tools \
    glslang-tools wget

# =========================================================
# 2. Install Vulkan SDK
# =========================================================

echo ""
echo "[2/5] Installing Vulkan SDK..."

cd /opt

wget https://sdk.lunarg.com/sdk/download/latest/linux/vulkan-sdk.tar.gz

tar -xvf vulkan-sdk.tar.gz

echo ""
echo "Available Vulkan SDK directories:"
ls -d /opt/1.* 2>/dev/null || true

# Gunakan versi yang ditentukan deployment guide
VULKAN_VERSION="1.4.363.0"

cd "/opt/${VULKAN_VERSION}"

echo ""
echo "Activating Vulkan SDK..."

source setup-env.sh

echo ""
echo "Validating glslc..."

which glslc

glslc --version

# =========================================================
# 3. Create Python virtual environment
# =========================================================

echo ""
echo "[3/5] Creating Python virtual environment..."

python3 -m venv /opt/venv

source /opt/venv/bin/activate

pip install --upgrade pip

pip install huggingface_hub

# =========================================================
# 4. Clone llama.cpp
# =========================================================

echo ""
echo "[4/5] Cloning llama.cpp..."

git clone https://github.com/ggerganov/llama.cpp /opt/llama.cpp

cd /opt/llama.cpp

rm -rf build

# =========================================================
# 5. Build llama.cpp with Vulkan
# =========================================================

echo ""
echo "[5/5] Building llama.cpp with Vulkan..."

cmake -S . \
    -B build \
    -DGGML_VULKAN=ON \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build -j"$(nproc)"

# =========================================================
# Finished
# =========================================================

echo ""
echo "=========================================="
echo " Installation completed successfully!"
echo "=========================================="

echo ""
echo "llama.cpp:"
echo "  /opt/llama.cpp"

echo ""
echo "Python venv:"
echo "  /opt/venv"

echo ""
echo "Vulkan SDK:"
echo "  /opt/${VULKAN_VERSION}"

echo ""
echo "llama-cli:"
echo "  /opt/llama.cpp/build/bin/llama-cli"

echo ""
echo "llama-server:"
echo "  /opt/llama.cpp/build/bin/llama-server"

echo ""
echo "Vulkan:"
which glslc

echo ""
echo "No AI model was downloaded."
