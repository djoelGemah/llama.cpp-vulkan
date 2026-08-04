#!/bin/bash

set -e

echo ""
echo "===================================="
echo "Creating Python Virtual Environment..."
echo "===================================="

python3 -m venv /opt/venv

source /opt/venv/bin/activate

pip install --upgrade pip

pip install huggingface_hub

echo "Python environment ready."
