FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
  git curl build-essential python3 python3-venv python3-pip \
  nodejs npm ffmpeg libopenblas-dev libsndfile1 cmake

# Install llama.cpp
RUN git clone https://github.com/ggerganov/llama.cpp /llama.cpp && \
  cd /llama.cpp && make server

# Install Open WebUI
RUN git clone https://github.com/open-webui/open-webui /webui

WORKDIR /webui
