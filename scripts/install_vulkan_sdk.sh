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

# echo ""
# echo "Entering Vulkan SDK directory..."
# cd 1.4.357.1

# echo "Loading Vulkan SDK environment..."
# source setup-env.sh

# echo ""
# echo "===================================="
# echo "Vulkan SDK installed successfully"
# echo "===================================="

# echo "VULKAN_SDK: $VULKAN_SDK"
