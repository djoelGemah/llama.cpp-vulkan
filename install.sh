# #!/bin/bash

# set -e

# echo "===================================="
# echo "Qwen Vulkan Automatic Installer"
# echo "===================================="

# bash scripts/check.sh

# bash scripts/install_packages.sh

# bash scripts/install_vulkan_sdk.sh

# # bash scripts/create_python.sh

# # bash scripts/build_llama.sh

# # bash scripts/download_model.sh

# # bash scripts/finish.sh


#!/bin/bash

set -e

echo "===================================="
echo "Qwen Vulkan Automatic Installer"
echo "===================================="

# ============================================================
# ROOT CHECK
# ============================================================

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
MODEL_REPO="unsloth/Qwen3.6-35B-A3B-MTP-GGUF"

MODEL_FILE="Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf"
MMPROJ_FILE="mmproj-BF16.gguf"


# ============================================================
# STEP 1
# CHECK & INSTALL BASIC REQUIREMENTS
# ============================================================

echo ""
echo "===================================="
echo "STEP 1: Installing requirements"
echo "===================================="

bash scripts/check.sh
bash scripts/install_packages.sh
bash scripts/install_vulkan_sdk.sh


# ============================================================
# STEP 2
# CHECK VULKAN SDK
# ============================================================

echo ""
echo "===================================="
echo "STEP 2: Checking Vulkan SDK"
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


# ============================================================
# STEP 3
# ACTIVATE VULKAN ENVIRONMENT
# ============================================================

echo ""
echo "===================================="
echo "STEP 3: Activating Vulkan environment"
echo "===================================="

source "$VULKAN_ENV"

if ! command -v glslc >/dev/null 2>&1; then
    echo ""
    echo "ERROR: glslc tidak ditemukan setelah setup-env.sh dijalankan."
    exit 1
fi

echo "glslc:"
which glslc


# ============================================================
# MAKE VULKAN ENVIRONMENT PERSISTENT
# ============================================================

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


# ============================================================
# STEP 4
# INSTALL LLAMA.CPP
# ============================================================

echo ""
echo "===================================="
echo "STEP 4: Installing llama.cpp"
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


# ============================================================
# STEP 5
# BUILD LLAMA.CPP WITH VULKAN
# ============================================================

echo ""
echo "===================================="
echo "STEP 5: Building llama.cpp with Vulkan"
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


# ============================================================
# VERIFY LLAMA SERVER
# ============================================================

echo ""
echo "Checking llama-server..."

if [ ! -x "$LLAMA_DIR/build/bin/llama-server" ]; then
    echo ""
    echo "ERROR: llama-server tidak ditemukan."
    exit 1
fi

echo "llama-server:"
echo "$LLAMA_DIR/build/bin/llama-server"


# ============================================================
# VERIFY VULKAN LIBRARY
# ============================================================

echo ""
echo "Checking Vulkan backend..."

if [ ! -f "$LLAMA_DIR/build/bin/libggml-vulkan.so" ]; then
    echo ""
    echo "ERROR: libggml-vulkan.so tidak ditemukan."
    exit 1
fi

echo "Vulkan backend:"
echo "$LLAMA_DIR/build/bin/libggml-vulkan.so"


# ============================================================
# STEP 6
# PYTHON VIRTUAL ENVIRONMENT
# ============================================================

echo ""
echo "===================================="
echo "STEP 6: Setting up Python environment"
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
echo "Installing Hugging Face Hub..."

python -m pip install --upgrade huggingface_hub


# ============================================================
# VERIFY HF CLI
# ============================================================

echo ""
echo "Checking Hugging Face CLI..."

HF_BIN="$VENV_DIR/bin/hf"

if [ ! -x "$HF_BIN" ]; then
    echo ""
    echo "ERROR: hf CLI tidak ditemukan."
    exit 1
fi

echo "HF CLI:"
echo "$HF_BIN"

echo ""
echo "HF version:"
"$HF_BIN" version || true


# ============================================================
# STEP 7
# PREPARE MODEL DIRECTORY
# ============================================================

echo ""
echo "===================================="
echo "STEP 7: Preparing model directory"
echo "===================================="

mkdir -p "$MODEL_DIR"

echo "Model directory:"
echo "$MODEL_DIR"


# ============================================================
# STEP 8
# DOWNLOAD QWEN3.6 MODEL
# ============================================================

echo ""
echo "===================================="
echo "STEP 8: Downloading Qwen3.6 model"
echo "===================================="

echo ""
echo "Repository:"
echo "$MODEL_REPO"

echo ""
echo "Downloading: $MODEL_FILE"

"$HF_BIN" download \
    "$MODEL_REPO" \
    "$MODEL_FILE" \
    --local-dir "$MODEL_DIR"


# ============================================================
# DOWNLOAD MMPROJ
# ============================================================

echo ""
echo "Downloading: $MMPROJ_FILE"

"$HF_BIN" download \
    "$MODEL_REPO" \
    "$MMPROJ_FILE" \
    --local-dir "$MODEL_DIR"


# ============================================================
# VERIFY MODEL
# ============================================================

echo ""
echo "===================================="
echo "Verifying downloaded model"
echo "===================================="

if [ ! -f "$MODEL_DIR/$MODEL_FILE" ]; then
    echo ""
    echo "ERROR: Model utama tidak ditemukan."
    exit 1
fi

if [ ! -f "$MODEL_DIR/$MMPROJ_FILE" ]; then
    echo ""
    echo "ERROR: mmproj tidak ditemukan."
    exit 1
fi


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
echo "Hugging Face CLI:"
echo "$HF_BIN"

echo ""
echo "Model directory:"
echo "$MODEL_DIR"

echo ""
echo "Downloaded files:"
ls -lh "$MODEL_DIR"

echo ""
echo "===================================="
echo "READY FOR MODEL INFERENCE"
echo "===================================="

echo ""
echo "Model:"
echo "$MODEL_DIR/$MODEL_FILE"

echo ""
echo "mmproj:"
echo "$MODEL_DIR/$MMPROJ_FILE"

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
