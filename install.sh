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

echo ""
echo "===================================="
echo "STEP 1: Checking and installing requirements"
echo "===================================="

bash scripts/check.sh
bash scripts/install_packages.sh
bash scripts/install_vulkan_sdk.sh


echo ""
echo "===================================="
echo "STEP 2: Setting up Vulkan environment"
echo "===================================="

source /opt/1.4.357.1/setup-env.sh

cd /opt/llama.cpp

rm -rf build


echo ""
echo "===================================="
echo "STEP 3: Building llama.cpp with Vulkan"
echo "===================================="

cmake -S . -B build -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"


echo ""
echo "===================================="
echo "STEP 4: Setting up Python environment"
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
