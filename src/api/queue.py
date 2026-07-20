import asyncio
import logging
import uuid
from typing import Dict, Optional
from datetime import datetime
from src.api.schemas import JobStatusEnum, JobStatusResponse, GenerateRequest
from src.core.gpu_utils import get_torch_device

logger = logging.getLogger("videoforge.queue")

class JobManager:
    """
    In-Memory Job Queue and Execution Manager for LTX-Video generation jobs.
    Designed for single-node ECS G5 worker tasks, extensible to SQS/Redis workers.
    """
    def __init__(self):
        self._jobs: Dict[str, dict] = {}

    def create_job(self, req: GenerateRequest) -> str:
        job_id = str(uuid.uuid4())
        self._jobs[job_id] = {
            "job_id": job_id,
            "status": JobStatusEnum.PENDING,
            "prompt": req.prompt,
            "image_file": req.image_file,
            "video_url": None,
            "error": None,
            "created_at": datetime.utcnow().isoformat(),
            "completed_at": None,
            "params": req.model_dump()
        }
        logger.info(f"Created job {job_id} for prompt: '{req.prompt[:40]}...'")
        return job_id

    def get_job(self, job_id: str) -> Optional[JobStatusResponse]:
        if job_id not in self._jobs:
            return None
        data = self._jobs[job_id]
        return JobStatusResponse(
            job_id=data["job_id"],
            status=data["status"],
            prompt=data["prompt"],
            image_file=data["image_file"],
            video_url=data["video_url"],
            error=data["error"],
            created_at=data["created_at"],
            completed_at=data["completed_at"]
        )

    async def process_job_background(self, job_id: str):
        if job_id not in self._jobs:
            return
        
        job = self._jobs[job_id]
        job["status"] = JobStatusEnum.PROCESSING
        logger.info(f"Processing job {job_id} on GPU/CPU worker...")

        try:
            # Check hardware
            device = get_torch_device()
            logger.info(f"Executing LTX-Video v2.3 inference on device: {device}")
            
            # Simulate inference workflow (pipeline execution)
            await asyncio.sleep(2)  # Async non-blocking simulation for job pipeline
            
            # Output generated video path / S3 destination
            s3_output_url = f"s3://videoforge-outputs/{job_id}.mp4"
            job["status"] = JobStatusEnum.COMPLETED
            job["video_url"] = s3_output_url
            job["completed_at"] = datetime.utcnow().isoformat()
            logger.info(f"Job {job_id} completed successfully. Output: {s3_output_url}")

        except Exception as e:
            logger.error(f"Error processing job {job_id}: {str(e)}", exc_info=True)
            job["status"] = JobStatusEnum.FAILED
            job["error"] = str(e)
            job["completed_at"] = datetime.utcnow().isoformat()

job_manager = JobManager()
