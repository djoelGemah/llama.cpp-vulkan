#!/bin/bash

set -e

echo "===================================="
echo "Qwen Vulkan Automatic Installer"
echo "===================================="

bash scripts/check.sh

bash scripts/install_packages.sh

bash scripts/install_vulkan_sdk.sh

bash scripts/create_python.sh

bash scripts/build_llama.sh

bash scripts/download_model.sh

bash scripts/finish.sh
