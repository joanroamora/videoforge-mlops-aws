import torch
import logging

logger = logging.getLogger("videoforge.hardware")

def get_device_info() -> dict:
    """
    Detects available hardware (NVIDIA GPU / CUDA) on AWS ECS G5 nodes.
    Returns details about CUDA device availability, GPU model, and VRAM.
    """
    cuda_available = torch.cuda.is_available()
    device_name = "CPU"
    device_count = 0
    vram_total_gb = 0.0

    if cuda_available:
        device_count = torch.cuda.device_count()
        device_name = torch.cuda.get_device_name(0)
        vram_bytes = torch.cuda.get_device_properties(0).total_memory
        vram_total_gb = round(vram_bytes / (1024 ** 3), 2)
        logger.info(f"GPU Detected: {device_name} | VRAM: {vram_total_gb} GB | Devices: {device_count}")
    else:
        logger.warning("No CUDA GPU detected! Falling back to CPU mode.")

    return {
        "cuda_available": cuda_available,
        "device_count": device_count,
        "device_name": device_name,
        "vram_total_gb": vram_total_gb,
        "recommended_dtype": "float16" if cuda_available else "float32"
    }

def get_torch_device() -> torch.device:
    """
    Returns torch.device object for PyTorch model execution.
    """
    if torch.cuda.is_available():
        return torch.device("cuda:0")
    return torch.device("cpu")
