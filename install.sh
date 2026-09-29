```bash
#!/usr/bin/env bash

set -e

# ============================================================
# llama.cpp Vulkan Installer
# Ubuntu 24.04 / LXD Container
#
# Install:
#   - System dependencies
#   - Vulkan SDK 1.4.363.0
#   - glslc
#   - Python virtual environment
#   - Hugging Face Hub CLI
#   - llama.cpp
#   - llama.cpp Vulkan build
#
# DOES NOT DOWNLOAD ANY AI MODEL
# ============================================================

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

VULKAN_VERSION="1.4.363.0"

VULKAN_SDK_DIR="/opt/${VULKAN_VERSION}"
VULKAN_SDK_ARCHIVE="/opt/vulkan-sdk.tar.gz"

VENV_DIR="/opt/venv"
LLAMA_DIR="/opt/llama.cpp"
MODEL_DIR="/models"

LLAMA_REPO="https://github.com/ggml-org/llama.cpp.git"

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Installer harus dijalankan sebagai root."
    echo ""
    echo "Gunakan:"
    echo "  sudo ./install.sh"
    exit 1
fi

echo ""
echo "============================================================"
echo " llama.cpp + Vulkan Installer"
echo "============================================================"
echo ""
echo "Vulkan SDK : ${VULKAN_VERSION}"
echo "llama.cpp  : ${LLAMA_DIR}"
echo "Python venv: ${VENV_DIR}"
echo "Models     : ${MODEL_DIR}"
echo ""

# ------------------------------------------------------------
# 1. System information
# ------------------------------------------------------------

echo "============================================================"
echo "[1/9] System information"
echo "============================================================"

echo "OS:"
grep PRETTY_NAME /etc/os-release || true

echo ""
echo "Kernel:"
uname -r

echo ""
echo "Architecture:"
uname -m

# ------------------------------------------------------------
# 2. Install dependencies
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "[2/9] Installing system dependencies"
echo "============================================================"

apt update

apt install -y \
    git \
    cmake \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    libvulkan-dev \
    vulkan-tools \
    wget \
    curl \
    pkg-config \
    ca-certificates \
    tar

echo ""
echo "[OK] System dependencies installed."

# ------------------------------------------------------------
# 3. Check GPU passthrough
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "[3/9] Checking GPU / Vulkan device"
echo "============================================================"

if [ -e /dev/kfd ]; then
    echo "[OK] /dev/kfd detected"
else
    echo "[WARNING] /dev/kfd tidak ditemukan."
    echo "Pastikan GPU AMD sudah dipassthrough ke container."
fi

if [ -d /dev/dri ]; then
    echo ""
    echo "[OK] /dev/dri detected:"
    ls -lah /dev/dri
else
    echo "[WARNING] /dev/dri tidak ditemukan."
fi

echo ""

if command -v vulkaninfo >/dev/null 2>&1; then

    echo "[INFO] Vulkan devices:"

    vulkaninfo --summary 2>/dev/null \
        | grep -E "GPU|deviceName" \
        || true

else

    echo "[WARNING] vulkaninfo belum dapat dijalankan."

fi

# ------------------------------------------------------------
# 4. Install Vulkan SDK
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "[4/9] Installing Vulkan SDK ${VULKAN_VERSION}"
echo "============================================================"

if [ -d "${VULKAN_SDK_DIR}" ]; then

    echo "[INFO] Vulkan SDK sudah ada:"
    echo "${VULKAN_SDK_DIR}"

else

    echo "[INFO] Downloading Vulkan SDK..."

    cd /opt

    rm -f "${VULKAN_SDK_ARCHIVE}"

    wget \
        -O "${VULKAN_SDK_ARCHIVE}" \
        "https://sdk.lunarg.com/sdk/download/${VULKAN_VERSION}/linux/vulkan-sdk.tar.gz"

    echo ""
    echo "[INFO] Extracting Vulkan SDK..."

    tar -xvf "${VULKAN_SDK_ARCHIVE}"

fi

# ------------------------------------------------------------
# 5. Activate Vulkan SDK
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "[5/9] Activating Vulkan SDK environment"
echo "============================================================"

if [ ! -f "${VULKAN_SDK_DIR}/setup-env.sh" ]; then

    echo "[ERROR] setup-env.sh tidak ditemukan."

    echo ""
    echo "Isi /opt:"
    ls -lah /opt

    exit 1

fi

cd "${VULKAN_SDK_DIR}"

source setup-env.sh

echo ""
echo "VULKAN_SDK:"
echo "${VULKAN_SDK:-NOT_SET}"

echo ""
echo "glslc:"

if command -v glslc >/dev/null 2>&1; then

    which glslc

    echo ""
    glslc --version

else

    echo ""
    echo "[ERROR] glslc tidak ditemukan setelah Vulkan SDK diaktifkan."
    exit 1

fi

# ------------------------------------------------------------
# 6. Python virtual environment
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "[6/9] Creating Python virtual environment"
echo "============================================================"

if [ -d "${VENV_DIR}" ]; then

    echo "[INFO] Virtual environment sudah ada:"
    echo "${VENV_DIR}"

else

    python3 -m venv "${VENV_DIR}"

fi

source "${VENV_DIR}/bin/activate"

python -m pip install --upgrade pip

echo ""
echo "[INFO] Installing Hugging Face Hub..."

python -m pip install huggingface_hub

echo ""
echo "[OK] Python environment ready."

echo ""
echo "Python:"
which python

echo ""
echo "HF:"
hf --version || true

# ------------------------------------------------------------
# 7. Clone llama.cpp
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "[7/9] Installing llama.cpp"
echo "============================================================"

if [ -d "${LLAMA_DIR}/.git" ]; then

    echo "[INFO] llama.cpp sudah tersedia."

    cd "${LLAMA_DIR}"

    echo "[INFO] Updating llama.cpp..."

    git pull

else

    echo "[INFO] Cloning llama.cpp..."

    rm -rf "${LLAMA_DIR}"

    git clone \
        "${LLAMA_REPO}" \
        "${LLAMA_DIR}"

fi

echo ""
echo "[OK] llama.cpp source:"
echo "${LLAMA_DIR}"

# ------------------------------------------------------------
# 8. Build llama.cpp with Vulkan
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "[8/9] Building llama.cpp with Vulkan"
echo "============================================================"

cd "${LLAMA_DIR}"

rm -rf build

echo ""
echo "[INFO] CMake configuration..."

cmake \
    -S . \
    -B build \
    -DGGML_VULKAN=ON \
    -DCMAKE_BUILD_TYPE=Release

echo ""
echo "[OK] CMake configuration completed."

echo ""
echo "[INFO] Building llama.cpp..."

cmake \
    --build build \
    --config Release \
    -j"$(nproc)"

echo ""
echo "[OK] llama.cpp build completed."

# ------------------------------------------------------------
# 9. Prepare model directories
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "[9/9] Preparing model directories"
echo "============================================================"

mkdir -p "${MODEL_DIR}"

mkdir -p "${MODEL_DIR}/qwen36-35b"
mkdir -p "${MODEL_DIR}/qwen32b"
mkdir -p "${MODEL_DIR}/gptoss20b"
mkdir -p "${MODEL_DIR}/gemma4"

echo "[OK] Model directories created."

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo " Verification"
echo "============================================================"

BIN_DIR="${LLAMA_DIR}/build/bin"

echo ""
echo "Vulkan SDK:"
echo "${VULKAN_SDK}"

echo ""
echo "glslc:"
which glslc

echo ""
echo "llama.cpp binaries:"
echo ""

if [ -x "${BIN_DIR}/llama-cli" ]; then
    echo "[OK] llama-cli"
else
    echo "[ERROR] llama-cli tidak ditemukan."
fi

if [ -x "${BIN_DIR}/llama-server" ]; then
    echo "[OK] llama-server"
else
    echo "[ERROR] llama-server tidak ditemukan."
fi

if [ -x "${BIN_DIR}/llama-bench" ]; then
    echo "[OK] llama-bench"
else
    echo "[ERROR] llama-bench tidak ditemukan."
fi

echo ""
echo "Binary directory:"
echo "${BIN_DIR}"

echo ""
echo "============================================================"
echo " INSTALLATION COMPLETE"
echo "============================================================"

echo ""
echo "Vulkan SDK:"
echo "  ${VULKAN_SDK_DIR}"

echo ""
echo "Python venv:"
echo "  ${VENV_DIR}"

echo ""
echo "llama.cpp:"
echo "  ${LLAMA_DIR}"

echo ""
echo "Models:"
echo "  ${MODEL_DIR}"

echo ""
echo "Untuk mengaktifkan Python environment:"
echo ""
echo "  source ${VENV_DIR}/bin/activate"

echo ""
echo "Untuk mengaktifkan Vulkan SDK pada shell baru:"
echo ""
echo "  source ${VULKAN_SDK_DIR}/setup-env.sh"

echo ""
echo "llama-cli:"
echo ""
echo "  ${BIN_DIR}/llama-cli"

echo ""
echo "llama-server:"
echo ""
echo "  ${BIN_DIR}/llama-server"

echo ""
echo "llama-bench:"
echo ""
echo "  ${BIN_DIR}/llama-bench"

echo ""
echo "============================================================"
echo " NOTE"
echo "============================================================"
echo ""
echo "AI MODEL TIDAK DIDOWNLOAD."
echo ""
echo "Installer hanya menyiapkan:"
echo "  - Vulkan SDK"
echo "  - glslc"
echo "  - Python venv"
echo "  - HuggingFace Hub"
echo "  - llama.cpp"
echo "  - llama.cpp Vulkan build"
echo "  - /models directory"
echo ""
echo "============================================================"
```

### Perubahan penting dari versi sebelumnya

Sekarang bagian yang menyebabkan error kamu:

```text
Could NOT find Vulkan (missing: glslc)
```

ditangani **sebelum CMake dijalankan**.

Urutannya sekarang:

```text
apt install
     ↓
/dev/kfd & /dev/dri check
     ↓
Download Vulkan SDK 1.4.363.0
     ↓
/opt/1.4.363.0/setup-env.sh
     ↓
which glslc
     ↓
glslc --version
     ↓
Python venv
     ↓
clone llama.cpp
     ↓
cmake -DGGML_VULKAN=ON
     ↓
build
```

Dan **tidak ada satupun `hf download <model>`**, sehingga model AI tidak akan ikut terdownload.

### Untuk memasukkannya ke GitHub

Di repository:

```bash
cd ~/llama.cpp-vulkan
nano install.sh
```

hapus isi lama → paste script di atas → simpan.

Kemudian:

```bash
chmod +x install.sh
git add install.sh
git commit -m "Update Vulkan 1.4.363.0 installer"
git push
```

Lalu di container baru:

```bash
git clone https://github.com/djoelGemah/llama.cpp-vulkan.git
cd llama.cpp-vulkan
chmod +x install.sh
./install.sh
```

**Satu catatan:** script ini sengaja menggunakan URL SDK versi **1.4.363.0**, sesuai versi yang kamu tetapkan. Jadi kalau LunarG mengubah URL distribusi untuk versi tersebut, bagian download adalah satu-satunya bagian yang mungkin perlu disesuaikan.
