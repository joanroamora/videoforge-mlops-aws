from src.core.gpu_utils import get_device_info, get_torch_device

def test_gpu_info_format():
    info = get_device_info()
    assert isinstance(info, dict)
    assert "cuda_available" in info
    assert "device_name" in info
    assert "vram_total_gb" in info

def test_torch_device_retrieval():
    device = get_torch_device()
    assert device.type in ["cuda", "cpu"]
