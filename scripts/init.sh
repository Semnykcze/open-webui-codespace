#!/bin/bash
set -e

# Install Python deps
cd /webui
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Install Node.js deps
cd frontend
npm install
cd ..

echo "✅ Open WebUI & llama.cpp are ready. Use /start.sh to launch."
