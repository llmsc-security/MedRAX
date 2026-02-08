# Multi-stage build for MedRAX
# Optimized for production deployment with minimal image size
# =============================================================================

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

# Copy only dependency files first (better layer caching)
COPY pyproject.toml .

# Install Python packages
# Note: The transformers git dependency may take some time
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

# Create non-root user first
RUN groupadd -r appuser && \
    useradd -r -g appuser -d /medrax -s /bin/bash appuser

# Create necessary directories with proper permissions
RUN mkdir -p /medrax/temp /medrax/logs /medrax/assets \
             /model-weights \
             /cache/huggingface \
             /cache/torchxrayvision \
             /cache/.cache && \
    chown -R appuser:appuser /medrax /model-weights /cache

# Switch to non-root user
USER appuser

# Copy application code (excluding files in .dockerignore)
COPY --chown=appuser:appuser . .

# Expose Gradio default port (will be mapped to 11180 on host)
EXPOSE 8585

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8585/ || exit 1

# Use entrypoint script for better startup control
COPY --chown=appuser:appuser entrypoint.sh /medrax/entrypoint.sh
RUN chmod +x /medrax/entrypoint.sh

ENTRYPOINT ["/medrax/entrypoint.sh"]
CMD ["web"]

