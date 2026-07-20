#!/bin/bash
set -e

echo "[VideoForge] Starting VideoForge LTX-Video 2.3 Container Service..."

# 1. Hardware Check
echo "[VideoForge] Checking hardware resources..."
python3 -c "import torch; print(f'PyTorch CUDA Available: {torch.cuda.is_available()}'); print(f'GPU Count: {torch.cuda.device_count()}'); print(f'GPU Device: {torch.cuda.get_device_name(0)}' if torch.cuda.is_available() else 'NO GPU DETECTED!')"

# 2. S3 Weights Initialization
echo "[VideoForge] Initializing LTX-Video v2.3 model weights from S3..."
python3 -m src.core.s3_downloader

# 3. Start FastAPI Server
echo "[VideoForge] Launching FastAPI application on port ${PORT:-8000}..."
exec uvicorn src.api.main:app --host 0.0.0.0 --port "${PORT:-8000}" --workers 1
