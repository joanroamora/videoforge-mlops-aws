import os
import sys
import logging
import boto3
from pathlib import Path
from src.config import settings

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("videoforge.s3_downloader")

def download_weights_from_s3():
    """
    Downloads LTX-Video v2.3 model weights from S3 to local cache directory if not already cached.
    """
    cache_dir = Path(settings.MODEL_CACHE_DIR)
    cache_dir.mkdir(parents=True, exist_ok=True)

    # Check if directory already contains weights files
    existing_files = list(cache_dir.glob("*"))
    if existing_files:
        logger.info(f"Model weights already present in {cache_dir} ({len(existing_files)} files found). Skipping S3 download.")
        return

    bucket_name = settings.S3_BUCKET
    s3_prefix = settings.S3_WEIGHTS_KEY

    # Parse s3:// URI if provided
    if settings.S3_WEIGHTS_URI.startswith("s3://"):
        uri_parts = settings.S3_WEIGHTS_URI[5:].split("/", 1)
        bucket_name = uri_parts[0]
        s3_prefix = uri_parts[1] if len(uri_parts) > 1 else ""

    logger.info(f"Initiating LTX-Video v2.3 weights download from s3://{bucket_name}/{s3_prefix} to {cache_dir}...")

    try:
        s3_client = boto3.client("s3", region_name=settings.AWS_REGION)
        paginator = s3_client.get_paginator("list_objects_v2")
        
        download_count = 0
        for page in paginator.paginate(Bucket=bucket_name, Prefix=s3_prefix):
            if "Contents" not in page:
                continue

            for obj in page["Contents"]:
                key = obj["Key"]
                if key.endswith("/"):
                    continue  # Skip folder objects
                
                # Compute relative destination path
                rel_path = os.path.relpath(key, s3_prefix)
                dest_path = cache_dir / rel_path
                dest_path.parent.mkdir(parents=True, exist_ok=True)

                logger.info(f"Downloading s3://{bucket_name}/{key} -> {dest_path}")
                s3_client.download_file(bucket_name, key, str(dest_path))
                download_count += 1

        if download_count == 0:
            logger.warning(f"No files were found at s3://{bucket_name}/{s3_prefix}. Ensuring fallback structure.")
        else:
            logger.info(f"Successfully downloaded {download_count} model files for LTX-Video v2.3.")

    except Exception as e:
        logger.warning(f"S3 download encountered an issue or credentials missing: {str(e)}")
        logger.info("Container will proceed with on-demand HuggingFace / S3 loading or local cache.")

if __name__ == "__main__":
    download_weights_from_s3()
