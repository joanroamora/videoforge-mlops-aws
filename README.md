# VideoForge - Plataforma de Generación de Video con IA (LTX-Video v2.3)

![AWS ECS](https://img.shields.io/badge/AWS-ECS_G5_GPU-orange?logo=amazon-aws)
![CUDA](https://img.shields.io/badge/NVIDIA-CUDA_12.1-green?logo=nvidia)
![PyTorch](https://img.shields.io/badge/PyTorch-2.3.1-EE4C2C?logo=pytorch)
![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688?logo=fastapi)

VideoForge es una infraestructura MLOps lista para producción optimizada exclusivamente para la ejecución en paralelo del modelo de difusión de video **LTX-Video (versión 2.3)** sobre instancias de GPU en **AWS ECS (instancias G5)**.

---

## 📁 Estructura MLOps del Proyecto

```
videoForge/
├── docker/
│   ├── Dockerfile             # Dockerfile Multi-stage (NVIDIA CUDA 12.1 + Python Venv)
│   └── entrypoint.sh          # Script de inicio (descarga de pesos desde S3 + Uvicorn)
├── infrastructure/
│   └── README.md              # Documentación de arquitectura AWS ECS, S3 & G5 Nodes
├── src/
│   ├── api/
│   │   ├── main.py            # Inicialización FastAPI, middlewares y rutas
│   │   ├── routes.py          # Endpoints: POST /generate, GET /jobs/{id}, GET /hardware
│   │   ├── schemas.py         # Modelos Pydantic de entrada/salida
│   │   └── queue.py           # Gestor de cola y tareas en segundo plano
│   ├── core/
│   │   ├── config.py          # Configuración global por variables de entorno
│   │   ├── gpu_utils.py       # Detección y verificación de hardware NVIDIA GPU
│   │   └── s3_downloader.py   # Descarga de pesos de modelo desde S3 al arrancar
│   └── models/
│       └── ltx_video.py       # Pipeline de inferencia PyTorch / Diffusers para LTX-Video
├── tests/
│   ├── test_api.py            # Pruebas unitarias de la API FastAPI
│   └── test_gpu.py            # Pruebas de utilidades de hardware
├── workflows/
│   └── ci.yml                 # Pipeline CI/CD GitHub Actions
├── .gitignore
├── requirements.txt           # Dependencias de Python optimizadas (CUDA 12.1, PyTorch, Diffusers, xFormers)
└── README.md
```

---

## 🚀 Inicio Rápido con Docker

### 1. Construir la Imagen Docker Multi-stage
```bash
docker build -f docker/Dockerfile -t videoforge-ltx:latest .
```

### 2. Ejecutar el Contenedor con Soporte GPU (NVIDIA Container Toolkit)
```bash
docker run --gpus all -p 8000:8000 \
  -e S3_BUCKET="tu-bucket-pesos-s3" \
  -e S3_WEIGHTS_KEY="ltx-video/v2.3/" \
  -e AWS_REGION="us-east-1" \
  videoforge-ltx:latest
```

---

## 📡 API Core

La documentación interactiva OpenAPI (Swagger) está disponible en: `http://localhost:8000/docs`

### Crear Trabajo de Generación de Video
`POST /api/v1/generate`

**Request:**
```json
{
  "image_file": "s3://videoforge-inputs/character.png",
  "prompt": "Futuristic cyberpunk animation with glowing neon lights and high motion",
  "num_frames": 121,
  "fps": 24
}
```

**Response (HTTP 202 Accepted):**
```json
{
  "job_id": "c9b14f4e-3401-447a-8f92-5b91b8d23b9d",
  "status": "pending",
  "message": "Video generation job queued and submitted to worker queue",
  "created_at": "2026-07-20T13:06:00Z"
}
```

### Consultar Estado del Trabajo
`GET /api/v1/jobs/c9b14f4e-3401-447a-8f92-5b91b8d23b9d`

**Response:**
```json
{
  "job_id": "c9b14f4e-3401-447a-8f92-5b91b8d23b9d",
  "status": "completed",
  "prompt": "Futuristic cyberpunk animation with glowing neon lights and high motion",
  "image_file": "s3://videoforge-inputs/character.png",
  "video_url": "s3://videoforge-outputs/c9b14f4e-3401-447a-8f92-5b91b8d23b9d.mp4",
  "error": null,
  "created_at": "2026-07-20T13:06:00Z",
  "completed_at": "2026-07-20T13:06:05Z"
}
```
