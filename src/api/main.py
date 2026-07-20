from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from src.config import settings
from src.api.routes import router
from src.core.gpu_utils import get_device_info

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="MLOps Platform for LTX-Video 2.3 execution on AWS ECS with G5 GPU nodes.",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Enable CORS for web integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Router
app.include_router(router, prefix=settings.API_PREFIX)

@app.get("/", tags=["Health"])
async def root():
    return {
        "status": "online",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "docs": "/docs"
    }

@app.get("/health", tags=["Health"])
async def health():
    hw = get_device_info()
    return {
        "status": "healthy",
        "cuda_available": hw["cuda_available"],
        "device_name": hw["device_name"],
        "vram_gb": hw["vram_total_gb"]
    }
