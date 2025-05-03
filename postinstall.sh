#!/bin/bash

set -e

# === CONFIG ===
PYTHON_VERSION=3.11.9
PYTHON_PREFIX=/usr/local/python/$PYTHON_VERSION
PYTHON_BIN=$PYTHON_PREFIX/bin/python3.11
NUM_CORES=$(nproc)
ROOT_DIR="$(pwd)"
MODEL_DIR="$ROOT_DIR/models"
MODEL_URL="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
MODEL_NAME="tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
WEBUI_DIR="$ROOT_DIR/open-webui"

log() {
  STEP_NUM=$1
  TEXT=$2
  echo -e "\033[1;34m[customChat Codespaces - ${STEP_NUM}/7]\033[0m $TEXT"
}

getPath() {
  echo "Bude nainstalovano do : $ROOT_DIR"
}

# === SYSTEM CHECK ===
FREE_SPACE_GB=$(df -BG --output=avail "$ROOT_DIR" | tail -1 | tr -dc '0-9')
REQUIRED_SPACE_GB=4

echo ""
echo "⚠️  Instalace zabere přibližně ${REQUIRED_SPACE_GB} GB místa (Python, model, WebUI)."
echo "📦 Dostupné místo: ${FREE_SPACE_GB} GB v $(pwd)"
echo ""

if [ "$FREE_SPACE_GB" -lt "$REQUIRED_SPACE_GB" ]; then
  echo "❌ Nedostatek místa: potřebuješ alespoň ${REQUIRED_SPACE_GB} GB."
  exit 1
fi

read -p "❓ Chceš pokračovat? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "❌ Instalace zrušena uživatelem."
  exit 0
fi

# 1. Instalace Pythonu
if [ -f "$PYTHON_BIN" ]; then
  log 1 "Python $PYTHON_VERSION je již nainstalovaný."
else
  log 1 "Instaluji Python $PYTHON_VERSION..."
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
  log 1 "✅ Python $PYTHON_VERSION nainstalován."
fi

# 2. PATH a pip
if ! grep -q "$PYTHON_PREFIX/bin" ~/.bashrc; then
  echo "export PATH=$PYTHON_PREFIX/bin:\$PATH" >> ~/.bashrc
  log 2 "✅ Python $PYTHON_VERSION přidán do PATH"
fi

export PATH=$PYTHON_PREFIX/bin:$PATH

log 2 "Použitý Python: $($PYTHON_BIN --version)"
$PYTHON_BIN -m pip install --upgrade pip

if [ ! -x "$PYTHON_BIN" ]; then
  error_exit "Python nebyl správně nainstalován nebo není na $PYTHON_BIN"
fi

# 3. llama-cpp-python
log 3 "Instaluji llama-cpp-python..."
$PYTHON_BIN -m pip install llama-cpp-python

# 4. Stáhnutí modelu
log 4 "Stahuji TinyLlama model (~400MB)..."
mkdir -p "$MODEL_DIR"
curl -L "$MODEL_URL" -o "$MODEL_DIR/$MODEL_NAME"
log 4 "✅ Model uložen do $MODEL_DIR/$MODEL_NAME"

# 5. Spuštění LLM serveru
log 5 "Spouštím llama-cpp-python server..."
nohup $PYTHON_BIN -m llama_cpp.server \
  --model "$MODEL_DIR/$MODEL_NAME" \
  --host 0.0.0.0 \
  --port 8000 > "$ROOT_DIR/llama-server.log" 2>&1 &

log 5 "✅ LLM server běží na http://localhost:8000/v1"

# 6. Instalace a konfigurace Open WebUI
log 6 "Instaluji Open WebUI..."
mkdir -p "$WEBUI_DIR"
cd "$WEBUI_DIR"
$PYTHON_BIN -m pip install open-webui

cat > .env <<EOF
LLM_PROVIDER=llamacpp
LLM_API_BASE_URL=http://localhost:8000/v1
EOF

log 6 "✅ .env vytvořen v $WEBUI_DIR/.env"

# 7. Spuštění Open WebUI
log 7 "Spouštím Open WebUI..."
nohup $PYTHON_BIN -m open_webui.serve > "$ROOT_DIR/webui-server.log" 2>&1 &

log 7 "✅ Open WebUI běží na http://localhost:8080"
echo "[customChat Codespaces - 7/7] Přístup: otevři přesměrovaný port 8080 v Codespaces nebo použij VSCode port forwarding."
