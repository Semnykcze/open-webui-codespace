#!/bin/bash

set -e

echo "🔧 Instalace Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

echo "✅ Ollama nainstalováno."

# Dočasně nastavíme proměnnou v tomto shellu
export OLLAMA_FORCE_CPU=true
echo "✅ OLLAMA_FORCE_CPU=true aktivováno pro tuto relaci."

# Přidání do .bashrc, aby se nastavila automaticky při každém spuštění shellu
if ! grep -q "OLLAMA_FORCE_CPU=true" ~/.bashrc; then
  echo "export OLLAMA_FORCE_CPU=true" >> ~/.bashrc
  echo "✅ Přidáno do ~/.bashrc (trvalé nastavení)"
fi

echo "🎉 Hotovo! Můžeš spustit např.:  ollama run llama3"
