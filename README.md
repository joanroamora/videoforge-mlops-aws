# VideoForge 🎬⚡
> **Production-Grade MLOps Platform for Generative Video Synthesis with LTX-Video v2.3 & AWS Cloud Infrastructure**

VideoForge is an end-to-end MLOps platform for orchestrating, serving, and scaling state-of-the-art Generative AI video diffusion models (LTX-Video v2.3) on Amazon Web Services (AWS) using Modular Infrastructure as Code (Terraform), Docker CUDA containers, and FastAPI.

---

## 🌟 What Can You Do With VideoForge?

1. **Image-to-Video & Text-to-Video AI Generation**:
   - Transform static reference images and text prompts into 5-second cinematic MP4 animations at 24 FPS.
2. **Interactive Glassmorphic Web UI**:
   - Access a single-page web app for drag-and-drop image uploads, live hardware cluster status monitoring, real-time progress bars, and HTML5 video playback/download.
3. **Fine-Grained Creative Controls**:
   - Interactively adjust Guidance Scale (CFG 1.0 - 7.0), Inference Steps (15, 30, 50 steps), Motion Scale dynamics (0.5 to 2.0), random seeds, frame counts, and frame rates.
4. **Resilient Dual Hardware Support (GPU & CPU Modes)**:
   - **GPU Production Mode**: Harnesses NVIDIA A10G 24GB VRAM instances (`g5.xlarge`) with PyTorch CUDA 12.1 and xFormers/SDPA attention acceleration.
   - **CPU Demo & Testing Mode**: Seamlessly runs on `c5.xlarge` instances with $0.00 GPU cost overhead and synthetic dynamic fluid fractal animation fallbacks.
5. **Cost-Optimized Cloud Architecture**:
   - Configured with $0.00 idle billing rules: EC2 instances auto-scale to 0 during local Docker builds and scale to 1 only after image push to ECR completes.
6. **1-Click Deployment & Teardown**:
   - Automated `./deploy_aws.sh` script handles Terraform initialization, ECR authentication, container build & push, and ECS rolling deployments.
   - Automated `./destroy_aws.sh` script tears down all 44 AWS resources in 1 click for $0.00 billing safety.

---

## 🏗️ System Architecture & Stack

```
                                +-----------------------------------+
                                |   User Browser (Glassmorphic UI)   |
                                +-----------------+-----------------+
                                                  |
                                                  v
                                +-----------------+-----------------+
                                |  Application Load Balancer (ALB)   |
                                +-----------------+-----------------+
                                                  |
                                                  v
                                +-----------------+-----------------+
                                |     AWS ECS Container Service     |
                                |  (FastAPI + PyTorch CUDA 12.1)    |
                                +--------+-----------------+--------+
                                         |                 |
                   +---------------------+                 +---------------------+
                   v                                                             v
+------------------+------------------+                       +------------------+------------------+
|    Amazon ECR Image Repository      |                       |    Amazon S3 Bucket Storage      |
|     (videoforge-ltx:latest)         |                       | (Weights / Inputs / Outputs)    |
+-------------------------------------+                       +-------------------------------------+
```

- **Frontend**: HTML5, Vanilla CSS3 Glassmorphic Design System, ES6 JavaScript.
- **Backend API**: FastAPI, Uvicorn, Pydantic, Boto3 SDK.
- **AI Core**: PyTorch 2.3+cu121, Diffusers 0.30+, HuggingFace Transformers, FFmpeg.
- **Cloud Infrastructure**: AWS ECS (Elastic Container Service), EC2 (G5/C5), ECR, S3, Application Load Balancer, VPC, Auto Scaling Groups.
- **Infrastructure as Code (IaC)**: Terraform 1.5+ with modular HCL structure.

---

## 📁 Repository Structure

```
videoForge/
├── deploy_aws.sh                  # Automated 1-click AWS build, push & deploy script
├── destroy_aws.sh                 # Automated 1-click AWS infrastructure teardown script
├── requirements.txt               # PyTorch CUDA 12.1 & FastAPI dependencies
├── docker/
│   ├── Dockerfile                 # Multi-stage CUDA 12.1 build context
│   └── entrypoint.sh              # Container startup & model downloader
├── infrastructure/
│   ├── README.md                  # Infrastructure deployment documentation
│   └── terraform/                 # Modular IaC HCL manifests
│       ├── main.tf                # AWS provider constraints & tags
│       ├── variables.tf           # Configurable parameters (use_gpu, instance_type)
│       ├── networking.tf          # VPC, Subnets, ALB, Target Groups, Security Groups
│       ├── compute.tf             # ECS Cluster, Task Def, Auto Scaling Group
│       ├── storage.tf             # ECR repository & S3 buckets with force_destroy
│       ├── iam.tf                 # Task Execution Role & S3 Least-Privilege Policies
│       └── outputs.tf             # ALB DNS, ECR URI, S3 Bucket names
└── src/
    ├── api/
    │   ├── main.py                # FastAPI app entrypoint mounting Web UI
    │   ├── routes.py              # REST API endpoints & Video HTTP streaming
    │   ├── queue.py               # Background worker job manager & video generator
    │   └── schemas.py             # Pydantic data validation models
    ├── core/
    │   └── gpu_utils.py           # PyTorch CUDA / VRAM detection utilities
    ├── models/
    │   └── ltx_video.py           # LTX-Video pipeline wrapper & hyperparameter tuning
    └── static/
        └── index.html             # Glassmorphic Web UI single-page application
```

---

## 🚀 Quickstart Guide

### 1. Prerequisites
- **AWS CLI** configured (`aws configure`) with valid credentials (`us-east-1`).
- **Terraform 1.5+** installed.
- **Docker Desktop** running with WSL2 integration enabled.

### 2. Deploy to AWS Cloud
To deploy the full cloud platform to AWS:

```bash
chmod +x deploy_aws.sh destroy_aws.sh
./deploy_aws.sh
```

Upon script completion, you will receive the live endpoints:
- **Web UI Endpoint**: `http://videoforge-alb-xxxx.us-east-1.elb.amazonaws.com`
- **Swagger Docs**: `http://videoforge-alb-xxxx.us-east-1.elb.amazonaws.com/docs`

### 3. GPU vs. CPU Hardware Selection
To toggle between GPU (`g5.xlarge` NVIDIA A10G) and CPU (`c5.xlarge` cost-saving) modes, update `infrastructure/terraform/variables.tf`:

```hcl
variable "use_gpu" {
  type    = bool
  default = true  # Set to true for GPU or false for CPU demo
}
```

### 4. Teardown & Cost Zeroing ($0.00 USD)
When testing is complete, destroy all cloud resources in 1 click:

```bash
./destroy_aws.sh
```

---

## 📡 REST API Reference

- `GET /`: Serves the interactive Glassmorphic Web UI.
- `POST /api/v1/generate`: Enqueues an LTX-Video generation job.
- `POST /api/v1/upload-image`: Uploads a reference image directly to S3 `videoforge-inputs`.
- `GET /api/v1/jobs/{job_id}`: Polls job status and retrieves output video URLs.
- `GET /api/v1/videos/{filename}`: Streams MP4 videos directly to the browser with S3 presigned HTTP redirect support.
- `GET /api/v1/hardware`: Returns live GPU VRAM, CUDA availability, and device names.

---

## 🛡️ License
Distributed under the MIT License. Built for MLOps engineering excellence.
