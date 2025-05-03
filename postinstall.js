#!/bin/bash

set -e

# === CONFIG ===
PYTHON_VERSION=3.11.9
PYTHON_PREFIX=/usr/local/python/$PYTHON_VERSION
PYTHON_BIN=$PYTHON_PREFIX/bin/python3.11
NUM_CORES=$(nproc)

echo "🔧 [1/7] Instalace Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
echo "✅ Ollama nainstalována."

echo "🔧 [2/7] Nastavení OLLAMA_FORCE_CPU=true..."
export OLLAMA_FORCE_CPU=true

if ! grep -q "OLLAMA_FORCE_CPU=true" ~/.bashrc; then
  echo "export OLLAMA_FORCE_CPU=true" >> ~/.bashrc
  echo "✅ Přidáno do ~/.bashrc"
fi

# Kontrola existence Pythonu
if [ -f "$PYTHON_BIN" ]; then
  echo "✅ [3/7] Python $PYTHON_VERSION je již nainstalovaný."
else
  echo "🔧 [3/7] Instalace Python $PYTHON_VERSION..."
  sudo apt update
  sudo apt install -y build-essential libssl-dev zlib1g-dev libncurses5-dev \
    libsqlite3-dev libreadline-dev libbz2-dev libffi-dev curl liblzma-dev tk-dev wget

  cd /tmp
  wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
  tar -xzf Python-$PYTHON_VERSION.tgz
  cd Python-$PYTHON_VERSION

  ./configure --prefix=$PYTHON_PREFIX --enable-optimizations --with-ensurepip=install
  make -j$NUM_CORES
  sudo make install
fi

# Přidání do PATH
if ! grep -q "$PYTHON_PREFIX/bin" ~/.bashrc; then
  echo "export PATH=$PYTHON_PREFIX/bin:\$PATH" >> ~/.bashrc
  echo "✅ Python $PYTHON_VERSION přidán do PATH"
fi

export PATH=$PYTHON_PREFIX/bin:$PATH

echo "🐍 Použitý Python:"
$PYTHON_BIN --version

echo "📦 [4/7] Instalace uv Runtime Manageru..."
curl -Ls https://astral.sh/uv/install.sh | bash

if [ -f "$HOME/.cargo/bin/uv" ]; then
  if ! grep -q "export PATH=\$HOME/.cargo/bin:\$PATH" ~/.bashrc; then
    echo "export PATH=\$HOME/.cargo/bin:\$PATH" >> ~/.bashrc
    echo "✅ Přidáno uv do PATH v ~/.bashrc"
  fi
fi

echo "📥 [5/7] Instalace Open WebUI (pokud Python $PYTHON_VERSION existuje)..."
if [ -x "$PYTHON_BIN" ]; then
  $PYTHON_BIN -m pip install --upgrade pip
  $PYTHON_BIN -m pip install open-webui
  echo "✅ open-webui nainstalováno pro Python $PYTHON_VERSION"
else
  echo "❌ Python $PYTHON_VERSION není dostupný – přeskočeno pip install open-webui"
fi

echo "🔧 [6/7] Aktivace změn..."
source ~/.bashrc || echo "ℹ️ Spusť 'source ~/.bashrc' ručně, pokud je potřeba"

echo "🚀 [7/7] Hotovo! Můžeš spustit Open WebUI následovně:"
echo ""
echo "Once uv is installed, running Open WebUI is a breeze."
echo "Use the command below, ensuring to set the DATA_DIR environment variable to avoid data loss."
echo ""
echo "macOS/Linux:"
echo "  DATA_DIR=\$HOME/.open-webui uvx --python 3.11 open-webui@latest serve"
echo ""
echo "📁 Ujisti se, že adresář ~/.open-webui existuje a má správná práva."
echo ""
echo "🎉 Můžeš také spustit Ollama s CPU: ollama run mistral"
