#!/bin/bash

set -e

echo "===================================="
echo "AI Local Installer YoelC"
echo "===================================="



if [ "$EUID" -ne 0 ]; then
    echo ""
    echo "ERROR: Installer harus dijalankan sebagai root."
    echo ""
    echo "Gunakan:"
    echo "sudo ./install.sh"
    exit 1
fi


# ============================================================
# CONFIGURATION
# ============================================================

VULKAN_DIR="/opt/1.4.357.1"
VULKAN_ENV="$VULKAN_DIR/setup-env.sh"

LLAMA_DIR="/opt/llama.cpp"
VENV_DIR="/opt/venv"

MODEL_DIR="/models/qwen36"




echo ""
echo "===================================="
echo "Run 1"
echo "===================================="

bash scripts/check.sh
bash scripts/install_packages.sh
bash scripts/install_vulkan_sdk.sh




echo ""
echo "===================================="
echo "Run 2"
echo "===================================="

if [ ! -f "$VULKAN_ENV" ]; then
    echo ""
    echo "ERROR: Vulkan SDK tidak ditemukan."
    echo "File yang dicari:"
    echo "$VULKAN_ENV"
    exit 1
fi

echo "Vulkan SDK ditemukan:"
echo "$VULKAN_DIR"




echo ""
echo "===================================="
echo "Run 3"
echo "===================================="

source "$VULKAN_ENV"

if ! command -v glslc >/dev/null 2>&1; then
    echo ""
    echo "ERROR: glslc tidak ditemukan setelah setup-env.sh dijalankan."
    exit 1
fi

echo "glslc:"
which glslc




echo ""
echo "Creating persistent Vulkan environment..."

cat > /etc/profile.d/qwen-vulkan.sh <<EOF
# Qwen Vulkan environment
if [ -f "$VULKAN_ENV" ]; then
    source "$VULKAN_ENV"
fi
EOF

chmod 644 /etc/profile.d/qwen-vulkan.sh

echo "Persistent environment created:"
echo "/etc/profile.d/qwen-vulkan.sh"




echo ""
echo "===================================="
echo "Run 4"
echo "===================================="

if [ ! -d "$LLAMA_DIR/.git" ]; then

    echo "llama.cpp belum ada."
    echo "Cloning repository..."

    rm -rf "$LLAMA_DIR"

    git clone https://github.com/ggerganov/llama.cpp.git "$LLAMA_DIR"

else

    echo "llama.cpp sudah tersedia:"
    echo "$LLAMA_DIR"

fi




echo ""
echo "===================================="
echo "Run 5"
echo "===================================="

cd "$LLAMA_DIR"

echo "Removing previous build..."
rm -rf build

echo ""
echo "Configuring CMake..."

cmake -S . -B build \
    -DGGML_VULKAN=ON \
    -DCMAKE_BUILD_TYPE=Release

echo ""
echo "Building llama.cpp..."
echo "CPU threads: $(nproc)"

cmake --build build -j"$(nproc)"




echo ""
echo "Checking llama-server..."

if [ ! -x "$LLAMA_DIR/build/bin/llama-server" ]; then
    echo ""
    echo "ERROR: llama-server tidak ditemukan."
    exit 1
fi

echo "llama-server:"
echo "$LLAMA_DIR/build/bin/llama-server"



echo ""
echo "Checking Vulkan backend..."

if [ ! -f "$LLAMA_DIR/build/bin/libggml-vulkan.so" ]; then
    echo ""
    echo "ERROR: libggml-vulkan.so tidak ditemukan."
    exit 1
fi

echo "Vulkan backend:"
echo "$LLAMA_DIR/build/bin/libggml-vulkan.so"



echo ""
echo "===================================="
echo "Run 6"
echo "===================================="

if [ ! -d "$VENV_DIR" ]; then

    echo "Creating Python virtual environment..."

    python3 -m venv "$VENV_DIR"

else

    echo "Python virtual environment already exists."

fi


# ============================================================
# ACTIVATE VENV
# ============================================================

source "$VENV_DIR/bin/activate"

echo ""
echo "Python:"
python --version

echo ""
echo "Upgrading pip..."

python -m pip install --upgrade pip




echo ""
echo "===================================="
echo "Run 7"
echo "===================================="

mkdir -p "$MODEL_DIR"

echo "Model directory:"
echo "$MODEL_DIR"


# ============================================================
# FINAL STATUS
# ============================================================

echo ""
echo "===================================="
echo "INSTALLATION COMPLETED SUCCESSFULLY!"
echo "===================================="

echo ""
echo "Vulkan SDK:"
echo "$VULKAN_DIR"

echo ""
echo "glslc:"
which glslc

echo ""
echo "llama.cpp:"
echo "$LLAMA_DIR"

echo ""
echo "llama-server:"
echo "$LLAMA_DIR/build/bin/llama-server"

echo ""
echo "Python environment:"
echo "$VENV_DIR"

echo ""
echo "Model directory:"
echo "$MODEL_DIR"

echo ""
echo "===================================="
echo "READY FOR MODEL INFERENCE"
echo "===================================="

echo ""
echo "Model harus di-download secara manual"
echo "dan ditempatkan di:"
echo "$MODEL_DIR"

echo ""
echo "Vulkan environment akan otomatis aktif"
echo "pada shell/login berikutnya."

echo ""
echo "Python environment dapat diaktifkan dengan:"
echo "source /opt/venv/bin/activate"

echo ""
echo "Installer berhenti di sini."
echo "llama-cli TIDAK dijalankan secara otomatis."
echo ""
