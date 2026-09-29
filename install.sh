#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/qwen-vulkan"
LLAMA_DIR="$INSTALL_DIR/llama.cpp"
VENV_DIR="$INSTALL_DIR/venv"

# 1. Dependencies
sudo apt update
sudo apt install -y \
    git \
    cmake \
    build-essential \
    python3 \
    python3-venv \
    python3-pip \
    pkg-config \
    libvulkan-dev \
    vulkan-tools

# 2. Virtual environment
python3 -m venv "$VENV_DIR"

source "$VENV_DIR/bin/activate"

python -m pip install --upgrade pip

# 3. Clone llama.cpp
if [ ! -d "$LLAMA_DIR" ]; then
    git clone https://github.com/ggml-org/llama.cpp.git "$LLAMA_DIR"
fi

# 4. Build directory
cd "$LLAMA_DIR"

rm -rf build
mkdir -p build
cd build

# 5. Configure Vulkan
cmake .. \
    -DGGML_VULKAN=ON \
    -DCMAKE_BUILD_TYPE=Release

# 6. Build
cmake --build . --config Release -j"$(nproc)"

echo "======================================"
echo " llama.cpp Vulkan build selesai"
echo "======================================"

echo "Binary:"
find "$LLAMA_DIR/build/bin" -maxdepth 1 -type f -executable -print
