# ComfyUI Docker Image for Vast.ai

Custom Docker image for running ComfyUI on [Vast.ai](https://vast.ai) cloud GPU platform with CUDA 13.0.2 support.

## Table of Contents

1. [Features](#features)
2. [Quick Start](#quick-start)
3. [Setup via Vast.ai WebUI](#setup-via-vastai-webui)
4. [Setup via vast-cli](#setup-via-vast-cli)
5. [Workspace Volume Configuration](#workspace-volume-configuration)
6. [SSH Access & Port Remapping](#ssh-access--port-remapping)
7. [Environment Variables](#environment-variables)
8. [Ports Reference](#ports-reference)
9. [Dynamic Provisioning](#dynamic-provisioning)
10. [Directory Structure](#directory-structure)
11. [Service Management](#service-management)
12. [Building](#building)
13. [License](#license)

---

## Features

- **Base Image**: NVIDIA CUDA 13.0.2 with cuDNN runtime on Ubuntu 24.04
- **Package Manager**: [uv](https://github.com/astral-sh/uv) - Fast Python package installer
- **AWS CLI**: Pre-installed for S3 and other AWS service integrations
- **ComfyUI**: Latest master branch with virtual environment
- **ComfyUI-Manager**: Pre-configured to use `uv` instead of pip
- **TensorRT**: NVIDIA TensorRT for optimized inference
- **ComfyUI_TensorRT**: TensorRT custom node for ComfyUI
- **SSH Access**: Full SSH support compatible with Vast.ai WebUI and CLI

### Pre-installed Packages

#### System Packages
- vim, wget, curl, nano, htop
- rclone (cloud storage sync)
- ca-certificates
- git-all
- ffmpeg
- openssh-server/client
- rsync, zip, unzip

#### Python Packages
- PyTorch (nightly with CUDA 13.0 support)
- torchvision, torchaudio
- TensorRT

#### ComfyUI Virtual Environment
- All ComfyUI requirements
- ComfyUI-Manager requirements
- ComfyUI_TensorRT requirements

---

## Quick Start

The fastest way to get started is through the Vast.ai WebUI:

1. Go to [cloud.vast.ai](https://cloud.vast.ai)
2. Click **"Create"** or **"Templates"**
3. Search for GPUs with your requirements
4. Use the image `ghcr.io/mlshdev/comfyui-cuda130:latest`
5. Set the on-start command to `/opt/entrypoint.sh`
6. Click **"Rent"** to launch your instance

> **Note**: If you forked this repository and built your own image, replace `mlshdev` with your GitHub username.

---

## Setup via Vast.ai WebUI

This section provides step-by-step instructions for setting up ComfyUI using the Vast.ai web interface.

### Step 1: Navigate to Instance Creation

1. Log in to [cloud.vast.ai](https://cloud.vast.ai)
2. Click **"Create"** in the main navigation
3. Browse available GPU offers or use filters to find suitable machines

### Step 2: Configure Template Settings

Click the **"Edit Image & Config"** button to customize your instance:

#### Image & Docker Settings

| Field | Value | Description |
|-------|-------|-------------|
| **Image Path/Tag** | `ghcr.io/mlshdev/comfyui-cuda130:latest` | The Docker image to use. If you built your own image, replace `mlshdev` with your GitHub username. |
| **Docker Options** | `-p 8188:18188 -p 22:22` | Port mappings for ComfyUI web interface (external:internal) and SSH. |
| **Launch Mode** | `Run interactive shell server, SSH` | Recommended for SSH access with entrypoint execution. |
| **On-start Script** | `/opt/entrypoint.sh` | The entrypoint script that initializes the container. |

#### Environment Variables

Add these environment variables in the **"Environment Variables"** section:

| Variable | Example Value | Required | Description |
|----------|---------------|----------|-------------|
| `COMFYUI_ARGS` | `--disable-auto-launch --port 18188 --enable-cors-header` | No | Command line arguments for ComfyUI. Default is shown. |
| `WORKSPACE` | `/workspace` | No | Base workspace directory. Default: `/workspace` |
| `PROVISIONING_SCRIPT` | `https://raw.githubusercontent.com/user/repo/main/setup.sh` | No | URL to a shell script for automatic model/extension setup |

#### Disk Configuration

| Field | Recommended Value | Description |
|-------|-------------------|-------------|
| **Disk Space** | `50-100 GB` | Minimum disk space. AI models can be large (2-20GB each), so allocate accordingly. For SDXL/FLUX workflows, use 100GB+. |

### Step 3: Optional - Create Persistent Volume

For persistent storage that survives instance deletion:

1. Enable **"Create Volume"** toggle
2. Set **Volume Size**: `100-500 GB` (depending on model storage needs)
3. Set **Mount Path**: `/workspace`

> **Note**: See [Workspace Volume Configuration](#workspace-volume-configuration) for detailed guidance on when to use volumes.

### Step 4: Select GPU and Launch

1. Choose a GPU offer that meets your requirements:
   - **SD 1.5/SDXL**: 8-12 GB VRAM minimum
   - **FLUX.1**: 16-24 GB VRAM recommended
   - **Video Generation**: 24-48 GB+ VRAM recommended
2. Click **"Rent"** to launch your instance
3. Wait for the instance to start (watch the status indicator)
4. Click **"Open"** or use SSH to connect

---

## Setup via vast-cli

The vast-cli provides programmatic control over instance creation. This section covers all available options.

### Prerequisites

Install the vast-cli:

```bash
pip install vastai
```

Set your API key (get it from [vast.ai/account](https://vast.ai/account)):

```bash
vastai set api-key YOUR_API_KEY
```

### Finding Available Offers

Search for suitable GPU instances:

```bash
# List all offers with at least 16GB VRAM, sorted by price
vastai search offers 'gpu_ram >= 16 reliability > 0.95' -o 'dph+'

# Find RTX 4090 instances
vastai search offers 'gpu_name=RTX_4090' -o 'dph+'

# Find instances with specific CUDA compute capability
vastai search offers 'compute_cap >= 8.0 gpu_ram >= 24'
```

Note the `ID` column from the search results - this is your `<OFFER_ID>`.

### Basic Instance Creation

```bash
vastai create instance <OFFER_ID> \
  --image ghcr.io/mlshdev/comfyui-cuda130:latest \
  --env '-p 8188:18188 -p 22:22' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 50 \
  --ssh \
  --direct
```

> **Note**: If you built your own image, replace `mlshdev` with your GitHub username.

### Full Configuration with All Options

```bash
vastai create instance <OFFER_ID> \
  --image ghcr.io/mlshdev/comfyui-cuda130:latest \
  --env '-p 8188:18188 -p 22:22 \
         -e COMFYUI_ARGS="--disable-auto-launch --port 18188 --enable-cors-header" \
         -e WORKSPACE=/workspace \
         -e PROVISIONING_SCRIPT=https://raw.githubusercontent.com/user/repo/main/setup.sh' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 100 \
  --ssh \
  --direct \
  --label "ComfyUI-Production"
```

### Command Line Options Reference

| Option | Type | Description |
|--------|------|-------------|
| `<OFFER_ID>` | integer | **Required**. The ID of the machine offer from `search offers` |
| `--image` | string | **Required**. Docker image path with optional tag |
| `--env` | string | Docker environment variables and port mappings. Format: `-p HOST:CONTAINER -e VAR=value` |
| `--onstart-cmd` | string | Command to run when instance starts. Use `/opt/entrypoint.sh` for this image |
| `--disk` | integer | Local disk space in GB |
| `--ssh` | flag | Enable SSH access |
| `--direct` | flag | Use direct network connection (recommended for SSH) |
| `--label` | string | Human-readable name for the instance |
| `--jupyter` | flag | Enable Jupyter notebook |
| `--jupyter-dir` | string | Directory for Jupyter to use |
| `--jupyter-lab` | flag | Use JupyterLab instead of classic notebook |

### Creating Instance with Persistent Volume

To use a persistent volume for data that survives instance deletion:

```bash
# First, find available volume offers on the same machine
vastai search offers 'gpu_ram >= 16' -o 'dph+'

# Create instance with new volume
vastai create instance <OFFER_ID> \
  --image ghcr.io/mlshdev/comfyui-cuda130:latest \
  --env '-p 8188:18188 -p 22:22 \
         -e COMFYUI_ARGS="--disable-auto-launch --port 18188 --enable-cors-header"' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 50
```

> **Note**: Volume creation through CLI may require additional steps. See Vast.ai documentation for the latest volume management commands.

### Connecting to Your Instance

After creating an instance, get connection details:

```bash
# List your instances
vastai show instances

# Get SSH connection command
vastai ssh-url <INSTANCE_ID>
```

---

## Workspace Volume Configuration

### Should You Create a Separate /workspace Volume?

**Short Answer**: Yes, for most production and long-term use cases.

### When to Use a Persistent Volume

| Scenario | Use Container Storage | Use Persistent Volume |
|----------|----------------------|----------------------|
| Quick experiments or testing | ✅ Yes | ❌ No |
| Training and saving models | ❌ No | ✅ Yes |
| Large model collections | ❌ No | ✅ Yes |
| Long-term projects | ❌ No | ✅ Yes |
| Throwaway/temporary work | ✅ Yes | ❌ No |

### Benefits of Persistent Volumes

1. **Data Persistence**: Data survives instance deletion. Models, custom nodes, and outputs are preserved.
2. **Reusability**: Volumes can be reattached to new instances on the same physical machine.
3. **Isolation**: Separates important data from the container's filesystem.
4. **Cost Efficiency**: Avoid re-downloading large models when recreating instances.

### Limitations to Consider

1. **Machine-Specific**: Volumes are tied to the physical machine where created. Cannot transfer between hosts.
2. **Fixed Size**: Volume size cannot be changed after creation. Plan accordingly.
3. **Separate Billing**: Volume storage is billed independently, even when not attached to an instance.

### Recommended Volume Sizes

| Use Case | Recommended Size |
|----------|-----------------|
| Basic SD 1.5/SDXL workflows | 50-100 GB |
| FLUX models + LoRAs | 100-200 GB |
| Video generation (Wan 2.x, Mochi, LTX-Video) | 200-500 GB |
| Large model collection | 500+ GB |

### Setting Up with Volume (WebUI)

1. When creating an instance, enable **"Create Volume"**
2. Set **Volume Size** based on your needs
3. Set **Mount Path** to `/workspace`
4. The container will automatically use this volume for ComfyUI data

### Setting Up with Volume (CLI)

```bash
# The volume mount path should match the WORKSPACE environment variable
vastai create instance <OFFER_ID> \
  --image ghcr.io/mlshdev/comfyui-cuda130:latest \
  --env '-p 8188:18188 -p 22:22 -e WORKSPACE=/workspace' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 50
```

---

## SSH Access & Port Remapping

### SSH Port Remapping Compatibility

**Yes, this Docker image is fully compatible with Vast.ai's SSH port remapping.**

### How Vast.ai SSH Port Remapping Works

Vast.ai hosts run multiple containers on shared public IP addresses. Since all containers cannot use port 22 simultaneously, Vast.ai automatically remaps the internal SSH port (22) to a randomly assigned external port.

**Example:**
- Container exposes: Port 22 (SSH)
- Vast.ai maps to: `PUBLIC_IP:23456` → Container port 22
- You connect using: `ssh -p 23456 root@PUBLIC_IP`

### Why This Image Is Compatible

1. **Standard SSH Configuration**: The image uses standard OpenSSH server configuration on port 22 inside the container.
2. **SSH Keys Propagation**: The entrypoint script automatically propagates SSH keys from Vast.ai to both root and user accounts.
3. **Environment Export**: SSH sessions inherit all container environment variables via `/etc/environment`.

### Finding Your SSH Connection Details

#### Via WebUI:
1. Click the **"SSH"** button on your instance card
2. Copy the provided SSH command with the remapped port

#### Via CLI:
```bash
# Get SSH URL for your instance
vastai ssh-url <INSTANCE_ID>

# Or list instances to see connection info
vastai show instances
```

### SSH Connection Examples

```bash
# Basic connection (use port from Vast.ai dashboard)
ssh -p <REMAPPED_PORT> root@<PUBLIC_IP>

# With your SSH key explicitly specified
ssh -i ~/.ssh/your_key -p <REMAPPED_PORT> root@<PUBLIC_IP>

# Connect as non-root user
ssh -p <REMAPPED_PORT> user@<PUBLIC_IP>
```

### SSH Port Forwarding for Local Access

You can forward ComfyUI to your local machine for direct access without authentication:

```bash
# Forward ComfyUI to localhost:8188
ssh -p <REMAPPED_PORT> -L 8188:localhost:18188 root@<PUBLIC_IP>

# Then access ComfyUI at http://localhost:8188
```

### Troubleshooting SSH

| Issue | Solution |
|-------|----------|
| Connection refused | Wait for instance to fully start (check status indicator) |
| Permission denied | Ensure your SSH public key is added to Vast.ai account settings |
| Host key verification failed | Remove old host key: `ssh-keygen -R "[PUBLIC_IP]:PORT"` |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WORKSPACE` | `/workspace` | Base workspace directory for ComfyUI and data |
| `COMFYUI_DIR` | `/workspace/ComfyUI` | ComfyUI installation directory |
| `COMFYUI_ARGS` | `--disable-auto-launch --enable-cors-header --port 18188` | Command line arguments passed to ComfyUI |
| `PROVISIONING_SCRIPT` | (none) | URL to a shell script for automatic setup on first boot |
| `DATA_DIRECTORY` | `/workspace` | Alternative data directory path |

### COMFYUI_ARGS Options

Common arguments you can use:

| Argument | Description |
|----------|-------------|
| `--port PORT` | Port for ComfyUI web server (internal). Default: `18188` |
| `--listen IP` | IP address to listen on. Default: `0.0.0.0` |
| `--enable-cors-header` | Enable CORS headers for API access |
| `--disable-auto-launch` | Don't open browser on startup (required for server use) |
| `--cuda-device N` | Specify which GPU to use (for multi-GPU systems) |
| `--preview-method TYPE` | Preview method: `auto`, `latent2rgb`, `taesd` |
| `--lowvram` | Enable low VRAM mode for cards with limited memory |
| `--cpu` | Run on CPU only (for testing) |

---

## Ports Reference

### Internal vs External Ports

| Service | Default Internal Port | Description |
|---------|----------------------|-------------|
| ComfyUI | 18188 | ComfyUI web interface (configurable via `COMFYUI_ARGS`) |
| SSH | 22 | SSH access |

### Port Mapping in Docker

ComfyUI listens on port **18188** by default. When configuring your instance, map your desired external port to 18188:

```bash
# Map external port 8188 to ComfyUI's internal port 18188
-p 8188:18188

# SSH port (Vast.ai will remap this to a random external port)
-p 22:22
```

**Alternative**: You can change the port ComfyUI listens on via the `COMFYUI_ARGS` environment variable:

```bash
# Have ComfyUI listen on port 8188 directly
-e COMFYUI_ARGS="--disable-auto-launch --port 8188 --enable-cors-header"
```

### Accessing ComfyUI

1. **Via Vast.ai Dashboard**: Click **"Open"** on your instance or access the remapped port shown in the instance details
2. **Via Direct IP**: `http://PUBLIC_IP:PORT` (where PORT is your mapped external port, may be remapped by Vast.ai)
3. **Via SSH Tunnel**: Forward port 18188 (or your configured port) locally for direct access

---

## Dynamic Provisioning

Use provisioning scripts to automatically set up models, custom nodes, and configurations on first boot.

### How It Works

1. Set `PROVISIONING_SCRIPT` environment variable to a URL pointing to your shell script
2. On first boot, the entrypoint downloads and executes the script
3. A marker file (`/.provisioning_complete`) prevents re-running on subsequent boots

### Example Provisioning Script

```bash
#!/bin/bash
# provisioning.sh - Example setup script for ComfyUI

set -eo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/workspace/ComfyUI}"

# Activate the ComfyUI virtual environment
cd "$COMFYUI_DIR"
source .venv/bin/activate

# Download a checkpoint model
echo "Downloading SDXL model..."
wget -O models/checkpoints/sd_xl_base_1.0.safetensors \
  "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"

# Install additional custom nodes
cd custom_nodes
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
cd ComfyUI-VideoHelperSuite
pip install -r requirements.txt

echo "Provisioning complete!"
```

### Setting Provisioning Script

**WebUI**: Add to Environment Variables:
```
PROVISIONING_SCRIPT=https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/provisioning.sh
```

> **Tip**: Create a GitHub Gist with your provisioning script and use the raw URL. This makes it easy to update your script without rebuilding the image.

**CLI**:
```bash
vastai create instance <OFFER_ID> \
  --image ghcr.io/mlshdev/comfyui-cuda130:latest \
  --env '-p 8188:18188 -p 22:22 -e PROVISIONING_SCRIPT=https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/setup.sh' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 100
```

---

## Directory Structure

```
/workspace/
└── ComfyUI/
    ├── .venv/              # Python virtual environment
    ├── models/
    │   ├── checkpoints/    # Main model files (.safetensors, .ckpt)
    │   ├── ckpt -> checkpoints  # Symlink for Jupyter compatibility
    │   ├── loras/          # LoRA files
    │   ├── vae/            # VAE models
    │   ├── controlnet/     # ControlNet models
    │   ├── clip/           # CLIP models
    │   ├── embeddings/     # Textual embeddings
    │   ├── upscale_models/ # Upscaling models (ESRGAN, etc.)
    │   └── ...
    ├── custom_nodes/
    │   ├── ComfyUI-Manager/    # Node and model manager
    │   └── ComfyUI_TensorRT/   # TensorRT acceleration
    ├── output/             # Generated images output
    ├── input/              # Input images for workflows
    └── user/default/ComfyUI-Manager/
        └── config.ini      # Manager configuration (pip_mode = uv)
```

---

## Service Management

Services are managed by [Supervisor](https://supervisord.readthedocs.io/):

### Common Commands

```bash
# Check all service statuses
supervisorctl status

# Restart ComfyUI (useful after installing custom nodes)
supervisorctl restart comfyui

# Stop ComfyUI
supervisorctl stop comfyui

# Start ComfyUI
supervisorctl start comfyui

# View live logs
supervisorctl tail -f comfyui

# View recent log output
supervisorctl tail comfyui
```

### Service Configuration Files

- Supervisor config: `/etc/supervisor/supervisord.conf`
- ComfyUI service: `/etc/supervisor/conf.d/comfyui.conf`
- SSHD service: `/etc/supervisor/conf.d/sshd.conf`

---

## Building

### Building Locally

```bash
cd comfyui
docker build -t comfyui-cuda130:local .
```

### Building with GitHub Actions

The image is automatically built and pushed to GitHub Container Registry and DockerHub when changes are pushed to the `comfyui/` directory.

Required GitHub secrets:
- `DOCKERHUB_USERNAME`: DockerHub username
- `DOCKERHUB_TOKEN`: DockerHub access token

---

## Troubleshooting

### ComfyUI Not Starting

1. Check supervisor logs: `supervisorctl tail -f comfyui`
2. Verify ComfyUI directory exists: `ls -la /workspace/ComfyUI`
3. Check if provisioning is still running: `ls /.provisioning`

### Out of VRAM

1. Try low VRAM mode: Set `COMFYUI_ARGS="--lowvram --disable-auto-launch --port 18188 --enable-cors-header"`
2. Use smaller models or enable model offloading in ComfyUI-Manager settings

### Cannot Connect to Web Interface

1. Verify ComfyUI is running: `supervisorctl status comfyui`
2. Check port mapping in your Vast.ai instance configuration
3. Try SSH port forwarding as an alternative

### Models Not Loading

1. Verify model files are in correct directories under `/workspace/ComfyUI/models/`
2. Check file permissions: `ls -la /workspace/ComfyUI/models/checkpoints/`
3. Restart ComfyUI after adding new models: `supervisorctl restart comfyui`

---

## Useful Links

- [ComfyUI GitHub](https://github.com/Comfy-Org/ComfyUI)
- [ComfyUI-Manager](https://github.com/Comfy-Org/ComfyUI-Manager)
- [Vast.ai Documentation](https://docs.vast.ai)
- [Vast.ai CLI Commands](https://docs.vast.ai/cli/commands)
- [Vast.ai SSH Guide](https://docs.vast.ai/documentation/instances/connect/ssh)
- [Vast.ai Storage & Volumes](https://docs.vast.ai/documentation/instances/storage/types)

---

## License

See [LICENSE.md](../LICENSE.md) for details.
