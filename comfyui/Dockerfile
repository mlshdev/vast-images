# Multi-stage Dockerfile for ComfyUI with CUDA 13.0.2
# Builds custom Docker image for vast.ai cloud platform
# Features: CUDA + TensorRT acceleration, Instance Portal with Cloudflare tunnels

# Stage 1: Get uv from distroless image
FROM ghcr.io/astral-sh/uv:latest AS uv-source

# Stage 2: Build AWS CLI
FROM python:3.12-slim AS aws-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install --install-dir /opt/aws-cli --bin-dir /opt/aws-cli/bin

# Stage 3: Main build
FROM docker.io/nvidia/cuda:13.0.2-cudnn-runtime-ubuntu24.04 AS main

# Maintainer details
LABEL org.opencontainers.image.source="https://github.com/mlshdev/vast-images"
LABEL org.opencontainers.image.description="ComfyUI image with CUDA 13.0.2, Instance Portal, Cloudflare tunnels for Vast.ai"
LABEL maintainer="mlshdev"

# Environment configuration
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV NVIDIA_DRIVER_CAPABILITIES=all

# Workspace configuration for vast.ai
ENV DATA_DIRECTORY=/workspace
ENV WORKSPACE=/workspace

# UV configuration - removed UV_SYSTEM_PYTHON since we use venv
ENV UV_NO_CACHE=1
ENV UV_LINK_MODE=copy

# ComfyUI configuration
ENV COMFYUI_DIR=/workspace/ComfyUI
ENV COMFYUI_ARGS="--disable-auto-launch --enable-cors-header --port 18188"

# Instance Portal configuration for vast.ai
# This enables the Instance Portal with Cloudflare tunnel integration
ENV TUNNEL_MANAGER="http://localhost:11112"
ENV CLOUDFLARE_METRICS="localhost:11113"

# Default PORTAL_CONFIG for ComfyUI - configure applications for Instance Portal
# Format: hostname:external_port:internal_port:path:name
# external_port != internal_port means Caddy will act as reverse proxy
ENV PORTAL_CONFIG="localhost:1111:11111:/:Instance Portal|localhost:8188:18188:/:ComfyUI"

# Copy uv binary from distroless image
COPY --from=uv-source /uv /usr/local/bin/uv

# Copy AWS CLI from builder stage
COPY --from=aws-builder /opt/aws-cli /opt/aws-cli
RUN ln -s /opt/aws-cli/bin/aws /usr/local/bin/aws \
    && ln -s /opt/aws-cli/bin/aws_completer /usr/local/bin/aws_completer

# Install required apt packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    wget \
    curl \
    rclone \
    ca-certificates \
    git-all \
    ffmpeg \
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
    rsync \
    zip \
    unzip \
    # Required for portal-aio (Instance Portal)
    jq \
    openssl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create symlinks for python
RUN ln -sf /usr/bin/python3.12 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.12 /usr/bin/python

# Create workspace directory (ComfyUI directory will be created by git clone)
RUN mkdir -p /workspace

# Clone ComfyUI (master branch)
RUN cd /workspace && \
    git clone https://github.com/Comfy-Org/ComfyUI.git && \
    cd ComfyUI && \
    git checkout master

# Create ComfyUI venv and install PyTorch with CUDA 13.0 nightly
RUN cd /workspace/ComfyUI && \
    uv venv .venv --python 3.12 && \
    . .venv/bin/activate && \
    uv pip install --compile-bytecode \
        --pre torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/nightly/cu130 && \
    deactivate

# Install TensorRT (with pre-built native libraries) into the venv
# The tensorrt package from pypi.nvidia.com includes libnvinfer.so and other TensorRT native libraries
# Set UV_HTTP_TIMEOUT to 300s (5 minutes) for large NVIDIA package downloads
RUN cd /workspace/ComfyUI && \
    . .venv/bin/activate && \
    UV_HTTP_TIMEOUT=300 uv pip install --compile-bytecode \
        tensorrt tensorrt-bindings tensorrt-libs \
        --extra-index-url https://pypi.nvidia.com && \
    deactivate

# Install ComfyUI requirements into the venv
RUN cd /workspace/ComfyUI && \
    . .venv/bin/activate && \
    uv pip install --compile-bytecode -r requirements.txt && \
    deactivate

# Install ComfyUI-Manager and configure it to use uv
RUN cd /workspace/ComfyUI/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git && \
    cd ComfyUI-Manager && \
    . /workspace/ComfyUI/.venv/bin/activate && \
    uv pip install --compile-bytecode -r requirements.txt && \
    deactivate

# Configure ComfyUI-Manager to use uv instead of pip
RUN mkdir -p /workspace/ComfyUI/user/default/ComfyUI-Manager && \
    echo '[default]' > /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'security_level = normal' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'default_ui = none' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'component_policy = workflow' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'double_click_policy = copy-all' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'badge_mode = none' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'git_exe = ' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'channel_url = https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'share_option = all' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'bypass_ssl = False' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'model_download_by_agent = False' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'file_logging = True' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'default_page_url = ' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'downgrade_blacklist = ' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'skip_migration = ' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini && \
    echo 'pip_mode = uv' >> /workspace/ComfyUI/user/default/ComfyUI-Manager/config.ini

# Install ComfyUI_TensorRT custom node
RUN cd /workspace/ComfyUI/custom_nodes && \
    git clone https://github.com/comfyanonymous/ComfyUI_TensorRT.git && \
    cd ComfyUI_TensorRT && \
    . /workspace/ComfyUI/.venv/bin/activate && \
    if [ -f requirements.txt ]; then uv pip install --compile-bytecode -r requirements.txt; fi && \
    deactivate

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

# Download Caddy binary for reverse proxy
RUN curl -fsSL -o /tmp/caddy.tar.gz \
        "https://github.com/caddyserver/caddy/releases/download/v2.9.1/caddy_2.9.1_linux_amd64.tar.gz" && \
    tar -xzf /tmp/caddy.tar.gz -C /opt/portal-aio/caddy_manager caddy && \
    chmod +x /opt/portal-aio/caddy_manager/caddy && \
    rm -f /tmp/caddy.tar.gz

# Copy supervisor configuration
COPY comfyui/supervisord.conf /etc/supervisor/supervisord.conf
COPY comfyui/conf.d/ /etc/supervisor/conf.d/

# Copy scripts
COPY comfyui/scripts/entrypoint.sh /opt/entrypoint.sh
COPY comfyui/scripts/start-comfyui.sh /opt/start-comfyui.sh
COPY comfyui/scripts/propagate-ssh-keys.sh /opt/propagate-ssh-keys.sh

RUN chmod +x /opt/entrypoint.sh /opt/start-comfyui.sh /opt/propagate-ssh-keys.sh

# Create symlink to models directory to avoid Jupyter display bug
RUN cd /workspace/ComfyUI/models && \
    ln -s checkpoints ckpt

# Expose ports
# 1111 - Instance Portal
# 8080 - Jupyter (optional)
# 8188 - ComfyUI external port
# 18188 - ComfyUI internal port
# 22 - SSH
EXPOSE 1111 8080 8188 18188 22

# Set working directory
WORKDIR /workspace

# Entrypoint
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD []
