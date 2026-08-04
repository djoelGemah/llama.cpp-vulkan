#!/bin/bash

set -e

echo ""
echo "===================================="
echo "Installing Vulkan SDK..."
echo "===================================="

cd /opt

wget https://sdk.lunarg.com/sdk/download/latest/linux/vulkan-sdk.tar.gz

tar -xvf vulkan-sdk.tar.gz

echo "Vulkan SDK downloaded."
