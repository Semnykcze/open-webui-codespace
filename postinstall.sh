#!/bin/bash

set -e


# Load configuration from config.ini
source <(grep -v '^#' config.ini | sed 's/\$(\(.*\))/$(\1)/g')


log() {
  STEP_NUM=$1
  TEXT=$2
  echo -e "\033[1;34m[customChat Codespaces - ${STEP_NUM}/7]\033[0m $TEXT"
}

getPath() {
  echo "Bude nainstalovano do : $ROOT_DIR"
}

# Prompt user to choose installation type
read -p "❓ Chceš instalovat na Codespaces nebo lokálně? [ 1 - codespaces | 2 - local]: " INSTALL_TYPE
if [[ "$INSTALL_TYPE" == "1" ]]; then
  log 0 "Instalace na Codespaces vybrána. $(getPath)"
elif [[ "$INSTALL_TYPE" == "2" ]]; then
  log 0 "Lokální instalace vybrána."
else
  echo "❌ Neplatná volba. Prosím spusť skript znovu a vyber správnou možnost."
  exit 1
fi

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
BUILD_REQUIRED_SPACE_GB=2
DOWNLOAD_REQUIRED_SPACE_GB=1

read -p "❓ Chceš Python sestavit ze zdrojového kódu nebo stáhnout a nainstalovat? [ 1 - build | 2 - download]: " PYTHON_INSTALL_METHOD
if [[ "$PYTHON_INSTALL_METHOD" == "1" ]]; then
  if [ "$FREE_SPACE_GB" -lt "$BUILD_REQUIRED_SPACE_GB" ]; then
    echo "❌ Nedostatek místa: potřebuješ alespoň ${BUILD_REQUIRED_SPACE_GB} GB pro sestavení Pythonu."
    exit 1
  fi
  if [ -f "$PYTHON_BIN" ]; then
    log 1 "Python $PYTHON_VERSION je již nainstalovaný."
  else
    log 1 "Sestavuji Python $PYTHON_VERSION..."
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
    log 1 "✅ Python $PYTHON_VERSION sestaven a nainstalován."
  fi
elif [[ "$PYTHON_INSTALL_METHOD" == "2" ]]; then
  if [ "$FREE_SPACE_GB" -lt "$DOWNLOAD_REQUIRED_SPACE_GB" ]; then
    echo "❌ Nedostatek místa: potřebuješ alespoň ${DOWNLOAD_REQUIRED_SPACE_GB} GB pro stažení Pythonu."
    exit 1
  fi
  log 1 "Stahuji a instaluji Python $PYTHON_VERSION..."
  sudo apt update
  sudo apt install -y python3 python3-pip
  log 1 "✅ Python $PYTHON_VERSION stažen a nainstalován."
else
  echo "❌ Neplatná volba. Prosím spusť skript znovu a vyber správnou možnost."
  exit 1
fi

# 2. PATH a pip
if ! grep -q "$PYTHON_PREFIX/bin" ~/.bashrc; then
  echo "export PATH=$PYTHON_PREFIX/bin:\$PATH" >> ~/.bashrc
  log 2 "✅ Python $PYTHON_VERSION přidán do PATH"
fi

export PATH=$PYTHON_PREFIX/bin:$PATH

if [ ! -x "$PYTHON_BIN" ]; then
  echo "❌ Python nebyl nalezen na $PYTHON_BIN. Zkontrolujte konfiguraci v config.ini."
  exit 1
fi

log 2 "Použitý Python: $($PYTHON_BIN --version)"
$PYTHON_BIN -m pip install --upgrade pip

# 3. llama-cpp-python
log 3 "Instaluji llama-cpp-python..."
LLAMA_CPP_DIR="$ROOT_DIR/llama-cpp-python"
mkdir -p "$LLAMA_CPP_DIR"
cd "$LLAMA_CPP_DIR"
$PYTHON_BIN -m pip install llama-cpp-python --target="$LLAMA_CPP_DIR"

# Add llama-cpp-python to PATH
if ! grep -q "$LLAMA_CPP_DIR" ~/.bashrc; then
  echo "export PATH=$LLAMA_CPP_DIR:\$PATH" >> ~/.bashrc
  log 3 "✅ llama-cpp-python přidán do PATH."
fi

export PATH=$LLAMA_CPP_DIR:$PATH
log 3 "✅ llama-cpp-python nainstalován do $LLAMA_CPP_DIR."

# 4. Stáhnutí modelu
log 4 "Stahuji TinyLlama model (~400MB)..."
mkdir -p "$MODEL_DIR"
curl -L "$MODEL_URL" -o "$MODEL_DIR/$MODEL_NAME"
log 4 "✅ Model uložen do $MODEL_DIR/$MODEL_NAME"

# 5. Spuštění LLM serveru
log 5 "Kontroluji, zda jsou všechny potřebné moduly nainstalovány..."
REQUIRED_MODULES=("uvicorn" "llama-cpp-python")
MISSING_MODULES=()

for MODULE in "${REQUIRED_MODULES[@]}"; do
  if ! $PYTHON_BIN -m pip show "$MODULE" > /dev/null 2>&1; then
    MISSING_MODULES+=("$MODULE")
  fi
done

if [ ${#MISSING_MODULES[@]} -ne 0 ]; then
  log 5 "Chybí následující moduly: ${MISSING_MODULES[*]}"
  log 5 "Instaluji chybějící moduly..."
  for MODULE in "${MISSING_MODULES[@]}"; do
    $PYTHON_BIN -m pip install "$MODULE"
  done
  log 5 "✅ Všechny potřebné moduly byly nainstalovány."
fi

log 5 "Spouštím llama-cpp-python server..."
nohup $PYTHON_BIN -m llama_cpp.server \
  --model "$MODEL_DIR/$MODEL_NAME" \
  --host 0.0.0.0 \
  --port 8000 > "$ROOT_DIR/llama-server.log" 2>&1 &

log 5 "✅ LLM server běží na http://localhost:8000/v1"

# 6. Instalace a konfigurace Open WebUI
log 6 "Instaluji Open WebUI..."
WEBUI_DIR="$ROOT_DIR/open-webui"
mkdir -p "$WEBUI_DIR"
cd "$WEBUI_DIR"
$PYTHON_BIN -m pip install open-webui

# Kontrola, zda je balíček již nainstalován
if ! $PYTHON_BIN -m pip show open-webui > /dev/null 2>&1; then
  log 6 "Instaluji Open WebUI do $WEBUI_DIR..."
  $PYTHON_BIN -m pip install open-webui --target="$WEBUI_DIR"
else
  log 6 "✅ Open WebUI je již nainstalován v $WEBUI_DIR."
fi

# Přidání složky do PYTHONPATH
export PYTHONPATH="$WEBUI_DIR:$PYTHONPATH"

# Kontrola, zda modul open_webui.serve existuje
if ! $PYTHON_BIN -c "import open_webui.serve" > /dev/null 2>&1; then
  log 6 "❌ Modul open_webui.serve nebyl nalezen. Opětovná instalace Open WebUI do $WEBUI_DIR..."
  $PYTHON_BIN -m pip install --force-reinstall open-webui --target="$WEBUI_DIR"
  log 6 "✅ Open WebUI byl znovu nainstalován do $WEBUI_DIR."
fi

cat > .env <<EOF
LLM_PROVIDER=llamacpp
LLM_API_BASE_URL=http://localhost:8000/v1
EOF

log 6 "✅ .env vytvořen v $WEBUI_DIR/.env"
log 6 "✅ Open WebUI nainstalován do $WEBUI_DIR."

# 7. Spuštění Open WebUI
log 7 "Spouštím Open WebUI..."
nohup $PYTHON_BIN -m open_webui.serve > "$ROOT_DIR/webui-server.log" 2>&1 &

log 7 "✅ Open WebUI běží na http://localhost:8080"
echo "[customChat Codespaces - 7/7] Přístup: otevři přesměrovaný port 8080 v Codespaces nebo použij VSCode port forwarding."
