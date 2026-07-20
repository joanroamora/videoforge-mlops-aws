from typing import Optional
from pydantic import BaseModel, Field
from enum import Enum
import uuid
from datetime import datetime

class JobStatusEnum(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"

class GenerateRequest(BaseModel):
    image_file: str = Field(..., description="S3 URL o ruta de la imagen de referencia")
    prompt: str = Field(..., description="Prompt descriptivo para la animación de video")
    num_frames: Optional[int] = Field(default=121, description="Número de cuadros (121 para ~5s a 24fps)")
    fps: Optional[int] = Field(default=24, description="Fotogramas por segundo (24 fps estándar cinematográfico)")
    guidance_scale: Optional[float] = Field(default=3.0, description="Fidelidad al texto prompt (Escala CFG)")
    num_inference_steps: Optional[int] = Field(default=30, description="Pasos de inferencia de difusion (Calidad vs Velocidad)")
    motion_scale: Optional[float] = Field(default=1.0, description="Intensidad de movimiento (0.5 Suave, 1.0 Balanceado, 2.0 Dinámico)")
    seed: Optional[int] = Field(default=-1, description="Semilla aleatoria (-1 para aleatorio, o número específico para reproducir)")

class GenerateResponse(BaseModel):
    job_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    status: JobStatusEnum = JobStatusEnum.PENDING
    message: str = "Video generation job queued successfully"
    created_at: str = Field(default_factory=lambda: datetime.utcnow().isoformat())

class JobStatusResponse(BaseModel):
    job_id: str
    status: JobStatusEnum
    prompt: str
    image_file: str
    video_url: Optional[str] = None
    error: Optional[str] = None
    created_at: str
    completed_at: Optional[str] = None
