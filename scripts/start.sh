#!/bin/bash

# Start llama.cpp server
/llama.cpp/server -m /llama.cpp/models/ggml-tinyllama.gguf --port 8000 &

# Start backend
cd /webui
source .venv/bin/activate
uvicorn app:app --host 0.0.0.0 --port 8080 &

# Start frontend
cd frontend
npm run dev -- --host 0.0.0.0 --port 3000
