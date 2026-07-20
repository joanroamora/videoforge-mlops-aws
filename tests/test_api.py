from fastapi.testclient import TestClient
from src.api.main import app

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "cuda_available" in data

def test_generate_endpoint_validation():
    # Test valid generation request
    payload = {
        "image_file": "s3://videoforge-inputs/sample.jpg",
        "prompt": "Cyberpunk video animation test"
    }
    response = client.post("/api/v1/generate", json=payload)
    assert response.status_code == 202
    data = response.json()
    assert "job_id" in data
    assert data["status"] == "pending"

def test_job_status_endpoint():
    # Queue a job
    payload = {
        "image_file": "s3://videoforge-inputs/sample2.jpg",
        "prompt": "Abstract particle wave animation"
    }
    res = client.post("/api/v1/generate", json=payload)
    job_id = res.json()["job_id"]

    # Check status
    status_res = client.get(f"/api/v1/jobs/{job_id}")
    assert status_res.status_code == 200
    status_data = status_res.json()
    assert status_data["job_id"] == job_id
    assert status_data["status"] in ["pending", "processing", "completed"]
