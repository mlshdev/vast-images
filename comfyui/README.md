# ComfyUI Docker Image for Vast.ai

Custom Docker image for running ComfyUI on [Vast.ai](https://vast.ai) cloud GPU platform with CUDA 13.0.2 support.

## Features

- **Base Image**: NVIDIA CUDA 13.0.2 with cuDNN runtime on Ubuntu 24.04
- **Package Manager**: [uv](https://github.com/astral-sh/uv) - Fast Python package installer
- **AWS CLI**: Pre-installed for S3 and other AWS service integrations
- **ComfyUI**: Latest master branch with virtual environment
- **ComfyUI-Manager**: Pre-configured to use `uv` instead of pip
- **TensorRT**: NVIDIA TensorRT for optimized inference
- **ComfyUI_TensorRT**: TensorRT custom node for ComfyUI
- **SSH Access**: Full SSH support compatible with Vast.ai WebUI and CLI

## Pre-installed Packages

### System Packages
- vim, wget, curl
- rclone (cloud storage sync)
- ca-certificates
- git-all
- ffmpeg
- openssh-server/client

### Python Packages (System-wide)
- PyTorch (nightly with CUDA 13.0 support)
- torchvision, torchaudio
- TensorRT

### ComfyUI Virtual Environment
- All ComfyUI requirements
- ComfyUI-Manager requirements
- ComfyUI_TensorRT requirements

## Usage with Vast.ai

### Basic Instance Creation

```bash
vastai create instance <OFFER_ID> \
  --image ghcr.io/<your-username>/comfyui-cuda130:latest \
  --env '-p 8188:8188 -p 22:22 -e COMFYUI_ARGS="--disable-auto-launch --port 18188 --enable-cors-header"' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 50 \
  --ssh \
  --direct
```

### Full Configuration Example

```bash
vastai create instance <OFFER_ID> \
  --image ghcr.io/<your-username>/comfyui-cuda130:latest \
  --env '-p 1111:1111 -p 8080:8080 -p 8188:8188 -p 22:22 \
         -e COMFYUI_ARGS="--disable-auto-launch --port 18188 --enable-cors-header" \
         -e DATA_DIRECTORY=/workspace/ \
         -e PROVISIONING_SCRIPT=https://example.com/provision.sh' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 50 \
  --create-volume <VOLUME_ASK_ID> \
  --volume-size 200 \
  --mount-path '/workspace' \
  --ssh \
  --direct
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WORKSPACE` | `/workspace` | ComfyUI workspace directory |
| `COMFYUI_DIR` | `/workspace/ComfyUI` | ComfyUI installation directory |
| `COMFYUI_ARGS` | `--disable-auto-launch --enable-cors-header --port 18188` | ComfyUI startup arguments |
| `PROVISIONING_SCRIPT` | (none) | URL to auto-setup script |

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 18188 | ComfyUI (internal) | ComfyUI web interface (internal) |
| 8188 | ComfyUI (external) | ComfyUI web interface (mapped) |
| 22 | SSH | SSH access |

## Directory Structure

```
/workspace/
└── ComfyUI/
    ├── .venv/              # Python virtual environment
    ├── models/
    │   ├── checkpoints/    # Main model files
    │   ├── ckpt -> checkpoints  # Symlink for Jupyter compatibility
    │   ├── loras/          # LoRA files
    │   ├── vae/            # VAE models
    │   ├── controlnet/     # ControlNet models
    │   └── ...
    ├── custom_nodes/
    │   ├── ComfyUI-Manager/    # Node and model manager
    │   └── ComfyUI_TensorRT/   # TensorRT acceleration
    └── user/default/ComfyUI-Manager/
        └── config.ini      # Manager configuration (pip_mode = uv)
```

## Building Locally

```bash
cd comfyui
docker build -t comfyui-cuda130:local .
```

## Building with GitHub Actions

The image is automatically built and pushed to GitHub Container Registry and DockerHub when changes are pushed to the `comfyui/` directory.

Required secrets:
- `DOCKERHUB_USERNAME`: DockerHub username
- `DOCKERHUB_TOKEN`: DockerHub access token

## SSH Access

SSH is pre-configured for Vast.ai compatibility:
- Root login enabled with public key authentication
- Password authentication disabled
- User account (`user`) created with sudo access
- SSH keys automatically propagated from root to user account

## Service Management

Services are managed by Supervisor:

```bash
# Check service status
supervisorctl status

# Restart ComfyUI
supervisorctl restart comfyui

# View logs
supervisorctl tail -f comfyui
```

## License

See [LICENSE.md](../LICENSE.md) for details.
