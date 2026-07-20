import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, FileResponse
from src.config import settings
from src.api.routes import router
from src.core.gpu_utils import get_device_info

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Plataforma MLOps para inferencia de LTX-Video 2.3 en AWS ECS con nodos GPU G5.",
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

STATIC_HTML_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static", "index.html")

@app.get("/", response_class=HTMLResponse, tags=["Web UI"])
async def root():
    """
    Serves the Graphical Web UI for VideoForge.
    """
    if os.path.exists(STATIC_HTML_PATH):
        return FileResponse(STATIC_HTML_PATH)
    return HTMLResponse(content="<h1>VideoForge API Active</h1><p>Web UI index.html not found.</p>")

@app.get("/health", tags=["Health"])
async def health():
    hw = get_device_info()
    return {
        "status": "healthy",
        "cuda_available": hw["cuda_available"],
        "device_name": hw["device_name"],
        "vram_gb": hw["vram_total_gb"]
    }
