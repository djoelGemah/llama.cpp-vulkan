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

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Jalankan dengan sudo/root."
    exit 1
fi

echo ""
echo "===================================="
echo "STEP 1: Installing requirements"
echo "===================================="

bash scripts/check.sh
bash scripts/install_packages.sh
bash scripts/install_vulkan_sdk.sh


echo ""
echo "===================================="
echo "STEP 2: Loading Vulkan SDK environment"
echo "===================================="

VULKAN_ENV="/opt/1.4.357.1/setup-env.sh"

if [ ! -f "$VULKAN_ENV" ]; then
    echo "ERROR: Vulkan SDK environment tidak ditemukan:"
    echo "$VULKAN_ENV"
    exit 1
fi

# WAJIB: aktifkan environment Vulkan di shell installer
source "$VULKAN_ENV"

echo "Vulkan environment loaded."

echo ""
echo "Checking glslc..."

if ! command -v glslc >/dev/null 2>&1; then
    echo "ERROR: glslc tidak aktif setelah source setup-env.sh"
    exit 1
fi

echo "glslc: $(which glslc)"


echo ""
echo "===================================="
echo "STEP 3: Installing llama.cpp"
echo "===================================="

if [ ! -d "/opt/llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp.git /opt/llama.cpp
else
    echo "/opt/llama.cpp already exists."
fi

cd /opt/llama.cpp


echo ""
echo "===================================="
echo "STEP 4: Building llama.cpp with Vulkan"
echo "===================================="

rm -rf build

cmake -S . -B build \
    -DGGML_VULKAN=ON \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build -j"$(nproc)"


echo ""
echo "===================================="
echo "STEP 5: Setting up Python"
echo "===================================="

python3 -m venv /opt/venv

source /opt/venv/bin/activate

pip install --upgrade pip
pip install huggingface_hub


echo ""
echo "===================================="
echo "INSTALLATION COMPLETE"
echo "===================================="

echo ""
echo "Vulkan compiler:"
which glslc

echo ""
echo "llama.cpp:"
echo "/opt/llama.cpp"

echo ""
echo "llama.cpp binaries:"
ls -lh /opt/llama.cpp/build/bin

echo ""
echo "Python:"
echo "/opt/venv"

echo ""
echo "===================================="
python3 -m venv /opt/venv

source /opt/venv/bin/activate

pip install --upgrade pip
pip install huggingface_hub


echo ""
echo "===================================="
echo "INSTALLATION COMPLETED SUCCESSFULLY!"
echo "===================================="

echo ""
echo "llama.cpp has been built with Vulkan support."
echo "Build location: /opt/llama.cpp/build"
echo ""
echo "Python virtual environment:"
echo "source /opt/venv/bin/activate"
