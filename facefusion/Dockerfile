# Multi-stage Dockerfile for FaceFusion with CUDA 12.9.1
# Builds custom Docker image for vast.ai cloud platform
# Features: CUDA + TensorRT acceleration, Instance Portal with Cloudflare tunnels, NSFW detection disabled for research
# OCI compliant - compatible with Docker, Podman, and Buildah

# Stage 1: Get uv from distroless image
FROM ghcr.io/astral-sh/uv:latest AS uv-source

# Stage 2: Build AWS CLI
FROM docker.io/library/python:3.12-slim AS aws-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install --install-dir /opt/aws-cli --bin-dir /opt/aws-cli/bin

# Stage 3: Main build
FROM docker.io/nvidia/cuda:12.9.1-cudnn-runtime-ubuntu24.04 AS main

# OCI-compliant labels for container metadata
LABEL org.opencontainers.image.title="FaceFusion"
LABEL org.opencontainers.image.description="FaceFusion image with CUDA 12.9.1, TensorRT, Instance Portal, Cloudflare tunnels for Vast.ai"
LABEL org.opencontainers.image.source="https://github.com/mlshdev/vast-images"
LABEL org.opencontainers.image.url="https://github.com/mlshdev/vast-images"
LABEL org.opencontainers.image.authors="mlshdev"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.vendor="mlshdev"

# Environment configuration
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV NVIDIA_DRIVER_CAPABILITIES=all

# Workspace configuration for vast.ai
ENV DATA_DIRECTORY=/workspace
ENV WORKSPACE=/workspace

# UV configuration
ENV UV_NO_CACHE=1
ENV UV_LINK_MODE=copy

# FaceFusion configuration using Gradio environment variables
# These are the recommended way to configure Gradio-based applications
ENV FACEFUSION_DIR=/workspace/facefusion
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=17860

# FaceFusion CLI arguments (for execution provider and other settings)
# Note: Server settings are configured via GRADIO_* environment variables above
ENV FACEFUSION_ARGS="--execution-providers cuda"

# Instance Portal configuration for vast.ai
# This enables the Instance Portal with Cloudflare tunnel integration
ENV TUNNEL_MANAGER="http://localhost:11112"
ENV CLOUDFLARE_METRICS="localhost:11113"

# Default PORTAL_CONFIG for FaceFusion - configure applications for Instance Portal
# Format: hostname:external_port:internal_port:path:name
# external_port != internal_port means Caddy will act as reverse proxy
ENV PORTAL_CONFIG="localhost:1111:11111:/:Instance Portal|localhost:7860:17860:/:FaceFusion"

# Copy uv binary from distroless image
COPY --from=uv-source /uv /usr/local/bin/uv

# Copy AWS CLI from builder stage
COPY --from=aws-builder /opt/aws-cli /opt/aws-cli
RUN ln -s /opt/aws-cli/bin/aws /usr/local/bin/aws \
    && ln -s /opt/aws-cli/bin/aws_completer /usr/local/bin/aws_completer

# Install required apt packages with cache mount for faster rebuilds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    # Required packages from specification
    git-all \
    curl \
    wget \
    vim \
    ca-certificates \
    ffmpeg \
    rsync \
    rclone \
    # Additional packages for vast.ai compatibility
    openssh-server \
    openssh-client \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    supervisor \
    sudo \
    htop \
    nano \
    zip \
    unzip \
    # Required for AWS Mountpoint S3
    libfuse2t64 \
    fuse3 \
    # Required for portal-aio (Instance Portal)
    jq \
    openssl

# Create symlinks for python
RUN ln -sf /usr/bin/python3.12 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.12 /usr/bin/python

# Install AWS Mountpoint S3
RUN wget -O /tmp/mount-s3.deb https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.deb \
    && dpkg -i /tmp/mount-s3.deb || apt-get install -f -y \
    && rm -f /tmp/mount-s3.deb

# Create workspace directory
RUN mkdir -p /workspace

# Clone FaceFusion
RUN cd /workspace && \
    git clone https://github.com/facefusion/facefusion.git && \
    cd facefusion && \
    git checkout master

# Apply NSFW detection bypass patches for research purposes
# Modify content_analyser.py: make detect_nsfw always return False and pre_check return True
# Modify core.py: remove hash verification for content_analyser
RUN cd /workspace/facefusion && \
    # Add research mode header to content_analyser.py
    sed -i '1i # RESEARCH MODE: NSFW detection disabled for educational purposes' facefusion/content_analyser.py && \
    # Modify detect_nsfw function to always return False
    sed -i 's/def detect_nsfw(vision_frame : VisionFrame) -> bool:/def detect_nsfw(vision_frame : VisionFrame) -> bool:\n\t# RESEARCH MODE: Always return False to skip NSFW detection\n\treturn False\n\t# Original code below (disabled):/' facefusion/content_analyser.py && \
    # Modify pre_check function in content_analyser.py to skip model downloads
    sed -i 's/return conditional_download_hashes(model_hash_set) and conditional_download_sources(model_source_set)/# RESEARCH MODE: Skip NSFW model downloads\n\treturn True/' facefusion/content_analyser.py && \
    # Modify core.py to skip hash verification
    sed -i "s/return all(module.pre_check() for module in common_modules) and content_analyser_hash == 'b14e7b92'/# RESEARCH MODE: Skip hash check for modified content_analyser\n\treturn all(module.pre_check() for module in common_modules)/" facefusion/core.py

# Create FaceFusion venv and install all Python dependencies in a single layer
# This optimizes layer caching and reduces build time
# Set UV_HTTP_TIMEOUT to 300s (5 minutes) for large NVIDIA package downloads
RUN --mount=type=cache,target=/root/.cache/uv \
    cd /workspace/facefusion && \
    uv venv .venv --python 3.12 && \
    . .venv/bin/activate && \
    # Install PyTorch with CUDA 12.9 nightly
    UV_HTTP_TIMEOUT=300 uv pip install --compile-bytecode \
        --pre torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/nightly/cu129 && \
    # Install TensorRT (CUDA 12 variant with pre-built native libraries)
    # The tensorrt-cu12 package includes libnvinfer.so.10 for onnxruntime-gpu TensorRT execution provider
    UV_HTTP_TIMEOUT=300 uv pip install --compile-bytecode \
        tensorrt-cu12 tensorrt-cu12-bindings tensorrt-cu12-libs \
        --extra-index-url https://pypi.nvidia.com && \
    # Install onnxruntime-gpu for CUDA acceleration
    UV_HTTP_TIMEOUT=300 uv pip install --compile-bytecode \
        onnxruntime-gpu==1.23.2 && \
    # Install FaceFusion requirements (excluding onnxruntime since we install GPU version)
    uv pip install --compile-bytecode \
        gradio-rangeslider==0.0.8 \
        gradio==5.44.1 \
        numpy==2.2.6 \
        onnx==1.19.1 \
        opencv-python==4.12.0.88 \
        psutil==7.1.3 \
        tqdm==4.67.1 \
        scipy==1.16.3 && \
    deactivate

# Copy custom facefusion.ini configuration file
# This sets default models to use pre-downloaded models in the Docker image
COPY facefusion/facefusion.ini /workspace/facefusion/facefusion.ini

# Create models directory for pre-downloaded models
RUN mkdir -p /workspace/facefusion/.assets/models

# Pre-download FaceFusion models to avoid downloading after container starts
# These models are configured as defaults in facefusion.ini
#
# Face Detector: yoloface_8n (default for yolo_face detector)
RUN curl -fSL -o /workspace/facefusion/.assets/models/yoloface_8n.hash \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.hash" && \
    curl -fSL -o /workspace/facefusion/.assets/models/yoloface_8n.onnx \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx"

# Face Landmarker: 2dfan4 and fan_68_5 (required for landmark detection)
RUN curl -fSL -o /workspace/facefusion/.assets/models/2dfan4.hash \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/2dfan4.hash" && \
    curl -fSL -o /workspace/facefusion/.assets/models/2dfan4.onnx \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/2dfan4.onnx" && \
    curl -fSL -o /workspace/facefusion/.assets/models/fan_68_5.hash \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/fan_68_5.hash" && \
    curl -fSL -o /workspace/facefusion/.assets/models/fan_68_5.onnx \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/fan_68_5.onnx"

# Face Recognizer: arcface_w600k_r50 (required for face swapping)
RUN curl -fSL -o /workspace/facefusion/.assets/models/arcface_w600k_r50.hash \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/arcface_w600k_r50.hash" && \
    curl -fSL -o /workspace/facefusion/.assets/models/arcface_w600k_r50.onnx \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/arcface_w600k_r50.onnx"

# Face Masker: xseg_1 (occlusion model) and bisenet_resnet_34 (parser model)
# Note: Different model versions are used as specified by FaceFusion's face_masker.py
# - xseg_1 is from models-3.1.0
# - bisenet_resnet_34 is from models-3.0.0
RUN curl -fSL -o /workspace/facefusion/.assets/models/xseg_1.hash \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.1.0/xseg_1.hash" && \
    curl -fSL -o /workspace/facefusion/.assets/models/xseg_1.onnx \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.1.0/xseg_1.onnx" && \
    curl -fSL -o /workspace/facefusion/.assets/models/bisenet_resnet_34.hash \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/bisenet_resnet_34.hash" && \
    curl -fSL -o /workspace/facefusion/.assets/models/bisenet_resnet_34.onnx \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/bisenet_resnet_34.onnx"

# Face Swapper: hyperswap_1c_256 (high-quality face swap model)
RUN curl -fSL -o /workspace/facefusion/.assets/models/hyperswap_1c_256.hash \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.3.0/hyperswap_1c_256.hash" && \
    curl -fSL -o /workspace/facefusion/.assets/models/hyperswap_1c_256.onnx \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.3.0/hyperswap_1c_256.onnx"

# Face Enhancer: gpen_bfr_2048 (high-resolution face enhancement)
RUN curl -fSL -o /workspace/facefusion/.assets/models/gpen_bfr_2048.hash \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/gpen_bfr_2048.hash" && \
    curl -fSL -o /workspace/facefusion/.assets/models/gpen_bfr_2048.onnx \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/gpen_bfr_2048.onnx"

# Frame Enhancer: real_esrgan_x8_fp16 (8x upscaling with FP16 for GPU efficiency)
RUN curl -fSL -o /workspace/facefusion/.assets/models/real_esrgan_x8_fp16.hash \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/real_esrgan_x8_fp16.hash" && \
    curl -fSL -o /workspace/facefusion/.assets/models/real_esrgan_x8_fp16.onnx \
        "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/real_esrgan_x8_fp16.onnx"

# Setup SSH server for vast.ai compatibility
RUN mkdir -p /var/run/sshd /root/.ssh && \
    chmod 700 /root/.ssh && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config

# Create non-root user for vast.ai compatibility
RUN useradd -ms /bin/bash user -u 1001 -g 0 && \
    echo "user ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user && \
    mkdir -p /home/user/.ssh && \
    chmod 700 /home/user/.ssh && \
    chown -R user:root /home/user/.ssh

# Create supervisor directories
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d /var/log/portal

# Copy portal-aio components for Instance Portal and Cloudflare tunnel integration
COPY portal-aio /opt/portal-aio

# Create portal-aio venv and install dependencies
RUN python3 -m venv /opt/portal-aio/venv && \
    /opt/portal-aio/venv/bin/pip install --upgrade pip && \
    /opt/portal-aio/venv/bin/pip install -r /opt/portal-aio/requirements.txt

# Download cloudflared binary for Cloudflare Quick Tunnels
RUN curl -fsSL -o /opt/portal-aio/tunnel_manager/cloudflared \
        "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" && \
    chmod +x /opt/portal-aio/tunnel_manager/cloudflared

# Download latest Caddy binary for reverse proxy
# Uses GitHub API to get the latest release version dynamically
RUN CADDY_VERSION=$(curl -s https://api.github.com/repos/caddyserver/caddy/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/') && \
    curl -fsSL -o /tmp/caddy.tar.gz \
        "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz" && \
    tar -xzf /tmp/caddy.tar.gz -C /opt/portal-aio/caddy_manager caddy && \
    chmod +x /opt/portal-aio/caddy_manager/caddy && \
    rm -f /tmp/caddy.tar.gz

# Copy supervisor configuration
COPY facefusion/supervisord.conf /etc/supervisor/supervisord.conf
COPY facefusion/conf.d/ /etc/supervisor/conf.d/

# Copy scripts
COPY facefusion/scripts/entrypoint.sh /opt/entrypoint.sh
COPY facefusion/scripts/start-facefusion.sh /opt/start-facefusion.sh
COPY facefusion/scripts/propagate-ssh-keys.sh /opt/propagate-ssh-keys.sh

RUN chmod +x /opt/entrypoint.sh /opt/start-facefusion.sh /opt/propagate-ssh-keys.sh

# Expose ports
# 1111 - Instance Portal (proxied by Caddy)
# 7860 - FaceFusion WebUI (Gradio)
# 22 - SSH
EXPOSE 1111 7860 22

# Set working directory
WORKDIR /workspace

# Entrypoint
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD []
