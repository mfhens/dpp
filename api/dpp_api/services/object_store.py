# object_store.py
from __future__ import annotations

import io
import os
import typing as t
import hashlib
from datetime import timedelta, datetime

import boto3
from botocore.client import Config


_MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "http://localhost:9000")
_MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minio")
_MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minio12345")
_MINIO_REGION = os.getenv("MINIO_REGION", "us-east-1")
_MINIO_SECURE = os.getenv("MINIO_SECURE", "0") in ("1", "true", "TRUE", "yes")
_PRESIGN_TTL_SECONDS = int(os.getenv("OBJECT_URL_TTL", "604800"))  # 7 days default


def _s3():
    return boto3.client(
        "s3",
        endpoint_url=_MINIO_ENDPOINT,
        aws_access_key_id=_MINIO_ACCESS_KEY,
        aws_secret_access_key=_MINIO_SECRET_KEY,
        region_name=_MINIO_REGION,
        config=Config(signature_version="s3v4"),
        use_ssl=_MINIO_SECURE,
        verify=_MINIO_SECURE,
    )


def _as_bytes(body: t.Union[bytes, bytearray, io.BufferedIOBase, io.IOBase, t.Iterable[bytes]]) -> bytes:
    if isinstance(body, (bytes, bytearray)):
        return bytes(body)
    if hasattr(body, "read"):
        return body.read()  # type: ignore[attr-defined]
    # Fallback: assume iterable of bytes
    buf = bytearray()
    for chunk in body:  # type: ignore[assignment]
        buf.extend(chunk)
    return bytes(buf)


def put_object(*, bucket: str, key: str, body: t.Union[bytes, bytearray, io.BufferedIOBase, io.IOBase, t.Iterable[bytes]]) -> str:
    """
    Upload to S3-compatible store (MinIO). Returns a presigned GET URL.
    Creates the bucket if it does not exist.
    """
    s3 = _s3()

    # Ensure bucket exists
    try:
        s3.head_bucket(Bucket=bucket)
    except Exception:
        s3.create_bucket(Bucket=bucket)

    data = _as_bytes(body)
    # basic ETag integrity
    etag = hashlib.md5(data).hexdigest()  # nosec - for ETag only

    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=data,
        ContentLength=len(data),
        Metadata={"etag": etag},
    )

    url = s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": bucket, "Key": key},
        ExpiresIn=_PRESIGN_TTL_SECONDS,
    )
    return url

