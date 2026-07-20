from fastapi import APIRouter, BackgroundTasks, HTTPException, status
from src.api.schemas import GenerateRequest, GenerateResponse, JobStatusResponse
from src.api.queue import job_manager
from src.core.gpu_utils import get_device_info

router = APIRouter()

@router.post("/generate", response_model=GenerateResponse, status_code=status.HTTP_202_ACCEPTED)
async def generate_video(request: GenerateRequest, background_tasks: BackgroundTasks):
    """
    Queue an LTX-Video v2.3 video generation job.
    - **image_file**: S3 URI of reference image
    - **prompt**: Text description of desired video animation
    """
    job_id = job_manager.create_job(request)
    
    # Trigger non-blocking background queue processing
    background_tasks.add_task(job_manager.process_job_background, job_id)
    
    return GenerateResponse(
        job_id=job_id,
        message="Video generation job queued and submitted to worker queue"
    )

@router.get("/jobs/{job_id}", response_model=JobStatusResponse)
async def get_job_status(job_id: str):
    """
    Retrieve status and result of a video generation job.
    """
    job = job_manager.get_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail=f"Job '{job_id}' not found")
    return job

@router.get("/hardware")
async def get_hardware_info():
    """
    Returns GPU hardware details (VRAM, CUDA availability, GPU device name).
    """
    return get_device_info()
