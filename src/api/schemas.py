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
    image_file: str = Field(..., description="S3 URL or URI of the input image (e.g. s3://bucket/image.png)")
    prompt: str = Field(..., description="Text prompt for LTX-Video generation", example="A futuristic cyberpunk vehicle racing through rain")
    num_frames: Optional[int] = Field(default=121, description="Number of video frames to generate")
    fps: Optional[int] = Field(default=24, description="Frames per second")
    guidance_scale: Optional[float] = Field(default=3.0, description="Guidance scale")
    num_inference_steps: Optional[int] = Field(default=30, description="Inference steps")

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
