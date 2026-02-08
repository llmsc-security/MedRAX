# Multi-stage build for MedRAX
# -------------------------------------------------
#  Builder stage – compile and install Python deps
# -------------------------------------------------
FROM python:3.12-slim-bookworm AS builder

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /build

# Install build-time system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        pkg-config \
        ca-certificates \
        libssl-dev \
        libffi-dev \
        libgl1-mesa-glx \
        libglib2.0-0 \
        wget && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip and create virtual environment
RUN python -m pip install --upgrade pip setuptools wheel && \
    python -m venv /opt/venv

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV PIP_NO_CACHE_DIR=1

# Install Python packages
COPY pyproject.toml .
RUN pip install --default-timeout=300 --no-cache-dir .

# -------------------------------------------------
#  Runtime stage – lightweight image with app code
# -------------------------------------------------
FROM python:3.12-slim-bookworm

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /medrax

# Install runtime system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        libgomp1 \
        wget \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy the pre-built virtual environment
COPY --from=builder /opt/venv /opt/venv

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}" \
    PYTHONPATH="/medrax" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Create non-root user
RUN groupadd -r appuser && \
    useradd -r -g appuser -d /medrax -s /bin/bash appuser && \
    chown -R appuser:appuser /medrax

USER appuser

# Copy application code
COPY --chown=appuser:appuser . .

# Expose Gradio default port
EXPOSE 8585

# Default command - start the Gradio app
CMD ["python", "main.py"]
