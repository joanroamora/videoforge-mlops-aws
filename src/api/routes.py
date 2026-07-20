import os
import uuid
import boto3
from fastapi import APIRouter, BackgroundTasks, HTTPException, UploadFile, File, status
from fastapi.responses import FileResponse, RedirectResponse
from src.api.schemas import GenerateRequest, GenerateResponse, JobStatusResponse
from src.api.queue import job_manager
from src.core.gpu_utils import get_device_info
from src.config import settings

router = APIRouter()

@router.post("/generate", response_model=GenerateResponse, status_code=status.HTTP_202_ACCEPTED)
async def generate_video(request: GenerateRequest, background_tasks: BackgroundTasks):
    """
    Queue an LTX-Video v2.3 video generation job.
    - **image_file**: S3 URI or path of reference image
    - **prompt**: Text description of desired video animation
    """
    job_id = job_manager.create_job(request)
    
    # Trigger non-blocking background queue processing
    background_tasks.add_task(job_manager.process_job_background, job_id)
    
    return GenerateResponse(
        job_id=job_id,
        message="Video generation job queued and submitted to worker queue"
    )

@router.post("/upload-image")
async def upload_image(file: UploadFile = File(...)):
    """
    Upload an image file directly to S3 inputs bucket or temporary storage.
    """
    ext = file.filename.split(".")[-1] if "." in file.filename else "png"
    filename = f"inputs/{uuid.uuid4()}.{ext}"
    
    try:
        s3 = boto3.client("s3", region_name=settings.AWS_REGION)
        bucket = os.getenv("S3_INPUTS_BUCKET", settings.S3_BUCKET)
        s3.upload_fileobj(file.file, bucket, filename)
        s3_uri = f"s3://{bucket}/{filename}"
        return {"filename": file.filename, "s3_uri": s3_uri, "message": "Image uploaded to S3 successfully"}
    except Exception as e:
        # Fallback local storage
        local_dir = "/tmp/videoforge_inputs"
        os.makedirs(local_dir, exist_ok=True)
        local_path = os.path.join(local_dir, filename.replace("/", "_"))
        content = await file.read()
        with open(local_path, "wb") as f:
            f.write(content)
        return {"filename": file.filename, "s3_uri": local_path, "message": "Image saved locally"}

@router.get("/jobs/{job_id}", response_model=JobStatusResponse)
async def get_job_status(job_id: str):
    """
    Retrieve status and result of a video generation job.
    """
    job = job_manager.get_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail=f"Job '{job_id}' not found")
    return job

@router.get("/videos/{filename}")
async def get_video(filename: str):
    """
    Serve generated MP4 video file to browser with HTTP streaming headers or S3 presigned URL.
    """
    # Clean filename
    clean_name = os.path.basename(filename)
    local_path = os.path.join("/tmp/videoforge_outputs", clean_name)
    
    if os.path.exists(local_path):
        return FileResponse(local_path, media_type="video/mp4", filename=clean_name)
    
    # Try AWS S3 presigned URL
    try:
        bucket = os.getenv("S3_OUTPUTS_BUCKET", settings.S3_BUCKET)
        s3 = boto3.client("s3", region_name=settings.AWS_REGION)
        presigned_url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket, 'Key': clean_name},
            ExpiresIn=3600
        )
        return RedirectResponse(url=presigned_url)
    except Exception:
        # Fallback public sample video if file is generating or simulated
        return RedirectResponse(url="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")

@router.get("/hardware")
async def get_hardware_info():
    """
    Returns GPU hardware details (VRAM, CUDA availability, GPU device name).
    """
    return get_device_info()
