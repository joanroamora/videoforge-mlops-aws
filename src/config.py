import os
from pydantic import BaseModel

class Settings(BaseModel):
    PROJECT_NAME: str = "VideoForge LTX-Video Platform"
    VERSION: str = "2.3.0"
    API_PREFIX: str = "/api/v1"
    
    # Storage & Model Weights
    MODEL_CACHE_DIR: str = os.getenv("MODEL_CACHE_DIR", "/app/models/ltx-video-v2.3")
    S3_BUCKET: str = os.getenv("S3_BUCKET", "videoforge-model-weights")
    S3_WEIGHTS_KEY: str = os.getenv("S3_WEIGHTS_KEY", "ltx-video/v2.3/")
    S3_WEIGHTS_URI: str = os.getenv("S3_WEIGHTS_URI", "")
    AWS_REGION: str = os.getenv("AWS_REGION", "us-east-1")
    
    # GPU / Hardware
    FORCE_CPU: bool = os.getenv("FORCE_CPU", "false").lower() == "true"
    DEFAULT_TORCH_DTYPE: str = os.getenv("TORCH_DTYPE", "float16")
    
    # Server
    PORT: int = int(os.getenv("PORT", "8000"))

settings = Settings()
