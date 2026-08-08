#!/bin/bash

set -e

echo ""
echo "===================================="
echo "Installing Vulkan SDK..."
echo "===================================="

cd /opt

echo "Downloading Vulkan SDK..."

wget https://sdk.lunarg.com/sdk/download/latest/linux/vulkan-sdk.tar.gz

echo "Extracting Vulkan SDK..."

tar -xvf vulkan-sdk.tar.gz

echo "Vulkan SDK downloaded and extracted."

# Detect Vulkan SDK version directory
VULKAN_SDK_DIR=$(find /opt -maxdepth 1 -type d -name "1.*" | sort -V | tail -n 1)

if [ -z "$VULKAN_SDK_DIR" ]; then
    echo "ERROR: Vulkan SDK directory not found."
    exit 1
fi

echo ""
echo "Vulkan SDK directory:"
echo "$VULKAN_SDK_DIR"

# Enter Vulkan SDK directory
cd "$VULKAN_SDK_DIR"

# Check setup-env.sh
if [ ! -f "setup-env.sh" ]; then
    echo "ERROR: setup-env.sh not found."
    exit 1
fi

echo ""
echo "Loading Vulkan SDK environment..."

source setup-env.sh

echo ""
echo "===================================="
echo "Vulkan SDK installed successfully"
echo "===================================="

echo "VULKAN_SDK: $VULKAN_SDK"

echo ""
echo "Vulkan SDK environment loaded."
echo ""
