# založeno na oficiálním Python obrazu
FROM python:3.10-slim

# systémové závislosti (např. git, curl)
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# nastavení pracovního adresáře
WORKDIR /workspace

# nainstaluj text-generation-webui (nebo jiný UI)
RUN git clone https://github.com/oobabooga/text-generation-webui.git /workspace/webui

# nainstaluj Python závislosti
WORKDIR /workspace/webui
RUN pip install --upgrade pip && pip install -r requirements.txt