# FaceFusion Docker Image for Vast.ai

Custom Docker image for running [FaceFusion](https://github.com/facefusion/facefusion) on [Vast.ai](https://vast.ai) cloud GPU platform with CUDA 13.0.2 and TensorRT support.

**Research Edition**: This image has NSFW detection disabled for educational and research purposes.

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
11. [AWS S3 Integration](#aws-s3-integration)
12. [Service Management](#service-management)
13. [Building](#building)
14. [Research Mode Notes](#research-mode-notes)
15. [Troubleshooting](#troubleshooting)
16. [License](#license)

---

## Features

- **Base Image**: NVIDIA CUDA 13.0.2 runtime on Ubuntu 24.04
- **Package Manager**: [uv](https://github.com/astral-sh/uv) - Fast Python package installer (sourced from distroless image)
- **AWS CLI**: Pre-installed AWS CLI v2 for S3 and other AWS service integrations
- **AWS Mountpoint S3**: Pre-installed for mounting S3 buckets as local filesystems
- **FaceFusion**: Latest master branch with virtual environment
- **TensorRT**: NVIDIA TensorRT 10.12.0.36 for optimized inference
- **CUDA Acceleration**: onnxruntime-gpu for GPU-accelerated processing
- **SSH Access**: Full SSH support compatible with Vast.ai WebUI and CLI
- **Research Mode**: NSFW detection disabled for educational purposes

### Pre-installed System Packages

- git-all (Git with all components)
- curl, wget (network tools)
- vim, nano (editors)
- ca-certificates (SSL certificates)
- ffmpeg (media processing)
- rsync, rclone (file synchronization)
- openssh-server/client (SSH access)
- htop (system monitoring)
- supervisor (process management)

### Pre-installed Python Packages

In the FaceFusion virtual environment:
- PyTorch with CUDA support
- torchvision, torchaudio
- TensorRT 10.12.0.36
- onnxruntime-gpu 1.23.2
- All FaceFusion requirements

---

## Quick Start

The fastest way to get started is through the Vast.ai WebUI:

1. Go to [cloud.vast.ai](https://cloud.vast.ai)
2. Click **"Create"** or **"Templates"**
3. Search for GPUs with your requirements
4. Use the image `ghcr.io/mlshdev/facefusion-cuda130:latest`
5. Set the on-start command to `/opt/entrypoint.sh`
6. Configure port mapping: `-p 7860:17860`
7. Click **"Rent"** to launch your instance

> **Note**: If you forked this repository and built your own image, replace `mlshdev` with your GitHub username.

---

## Setup via Vast.ai WebUI

This section provides step-by-step instructions for setting up FaceFusion using the Vast.ai web interface.

### Step 1: Navigate to Instance Creation

1. Log in to [cloud.vast.ai](https://cloud.vast.ai)
2. Click **"Create"** in the main navigation
3. Browse available GPU offers or use filters to find suitable machines

### Step 2: Configure Template Settings

Click the **"Edit Image & Config"** button to customize your instance:

#### Image & Docker Settings

| Field | Value | Description |
|-------|-------|-------------|
| **Image Path/Tag** | `ghcr.io/mlshdev/facefusion-cuda130:latest` | The Docker image to use. If you built your own image, replace `mlshdev` with your GitHub username. |
| **Docker Options** | `-p 7860:17860 -p 22:22` | Port mappings for FaceFusion web interface (external:internal) and SSH. |
| **Launch Mode** | `Run interactive shell server, SSH` | Recommended for SSH access with entrypoint execution. |
| **On-start Script** | `/opt/entrypoint.sh` | The entrypoint script that initializes the container. |

#### Environment Variables

Add these environment variables in the **"Environment Variables"** section:

| Variable | Example Value | Required | Description |
|----------|---------------|----------|-------------|
| `FACEFUSION_ARGS` | `--server-name 0.0.0.0 --server-port 17860` | No | Command line arguments for FaceFusion. Default is shown. |
| `WORKSPACE` | `/workspace` | No | Base workspace directory. Default: `/workspace` |
| `PROVISIONING_SCRIPT` | `https://raw.githubusercontent.com/user/repo/main/setup.sh` | No | URL to a shell script for automatic model/extension setup |

#### Disk Configuration

| Field | Recommended Value | Description |
|-------|-------------------|-------------|
| **Disk Space** | `50-100 GB` | Minimum disk space. AI models can be large (2-20GB each), so allocate accordingly. |

### Step 3: Optional - Create Persistent Volume

For persistent storage that survives instance deletion:

1. Enable **"Create Volume"** toggle
2. Set **Volume Size**: `100-200 GB` (depending on model storage needs)
3. Set **Mount Path**: `/workspace`

> **Note**: See [Workspace Volume Configuration](#workspace-volume-configuration) for detailed guidance on when to use volumes.

### Step 4: Select GPU and Launch

1. Choose a GPU offer that meets your requirements:
   - **Basic face swapping**: 8-12 GB VRAM minimum
   - **High-quality processing**: 16-24 GB VRAM recommended
   - **Batch processing**: 24-48 GB+ VRAM recommended
2. Click **"Rent"** to launch your instance
3. Wait for the instance to start (watch the status indicator)
4. Click **"Open"** or use SSH to connect

### Step 5: Access FaceFusion

Once your instance is running:

1. Find the mapped port for 7860 in your instance details
2. Open `http://<PUBLIC_IP>:<MAPPED_PORT>` in your browser
3. The FaceFusion web interface should load

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
  --image ghcr.io/mlshdev/facefusion-cuda130:latest \
  --env '-p 7860:17860 -p 22:22' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 50 \
  --ssh \
  --direct
```

> **Note**: If you built your own image, replace `mlshdev` with your GitHub username.

### Full Configuration with All Options

```bash
vastai create instance <OFFER_ID> \
  --image ghcr.io/mlshdev/facefusion-cuda130:latest \
  --env '-p 7860:17860 -p 22:22 \
         -e FACEFUSION_ARGS="--server-name 0.0.0.0 --server-port 17860" \
         -e WORKSPACE=/workspace \
         -e PROVISIONING_SCRIPT=https://raw.githubusercontent.com/user/repo/main/setup.sh' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 100 \
  --ssh \
  --direct \
  --label "FaceFusion-Research"
```

### Advanced Configuration (Full Portal Support)

For full vast.ai Instance Portal integration with Jupyter, Tensorboard, and Syncthing:

```bash
vastai create instance <OFFER_ID> \
  --image ghcr.io/mlshdev/facefusion-cuda130:latest \
  --env '-p 1111:1111 -p 6006:6006 -p 8080:8080 -p 8384:8384 -p 7860:17860 \
         -e OPEN_BUTTON_PORT=7860 \
         -e OPEN_BUTTON_TOKEN=1 \
         -e JUPYTER_DIR=/ \
         -e DATA_DIRECTORY=/workspace/ \
         -e PORTAL_CONFIG="localhost:7860:17860:/:FaceFusion|localhost:8080:18080:/:Jupyter|localhost:8080:8080:/terminals/1:Jupyter Terminal|localhost:8384:18384:/:Syncthing|localhost:6006:16006:/:Tensorboard"' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 100 \
  --jupyter \
  --ssh \
  --direct
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
| Saving processed media | ❌ No | ✅ Yes |
| Large model collections | ❌ No | ✅ Yes |
| Long-term projects | ❌ No | ✅ Yes |
| Throwaway/temporary work | ✅ Yes | ❌ No |

### Benefits of Persistent Volumes

1. **Data Persistence**: Data survives instance deletion. Models and outputs are preserved.
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
| Basic face swapping | 50-100 GB |
| Extended model collection | 100-200 GB |
| Video processing | 200+ GB |

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

You can forward FaceFusion to your local machine for direct access:

```bash
# Forward FaceFusion to localhost:7860
ssh -p <REMAPPED_PORT> -L 7860:localhost:17860 root@<PUBLIC_IP>

# Then access FaceFusion at http://localhost:7860
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WORKSPACE` | `/workspace` | Base workspace directory for FaceFusion and data |
| `FACEFUSION_DIR` | `/workspace/facefusion` | FaceFusion installation directory |
| `FACEFUSION_ARGS` | `--server-name 0.0.0.0 --server-port 17860` | Command line arguments passed to FaceFusion |
| `PROVISIONING_SCRIPT` | (none) | URL to a shell script for automatic setup on first boot |

### FACEFUSION_ARGS Options

Common arguments you can use:

| Argument | Description |
|----------|-------------|
| `--server-port PORT` | Port for FaceFusion web server (internal). Default: `17860` |
| `--server-name IP` | IP address to listen on. Default: `0.0.0.0` |
| `--open-browser` | Open browser on startup (omit this flag for server use) |
| `--execution-providers cuda` | Use CUDA for GPU acceleration |
| `--execution-providers tensorrt` | Use TensorRT for optimized inference |
| `--execution-thread-count N` | Number of execution threads |
| `--execution-queue-count N` | Number of execution queues |

---

## Ports Reference

### Internal vs External Ports

| Service | Default Internal Port | Description |
|---------|----------------------|-------------|
| FaceFusion | 17860 | FaceFusion web interface (configurable via `FACEFUSION_ARGS`) |
| SSH | 22 | SSH access |

### Port Mapping in Docker

FaceFusion listens on port **17860** by default. When configuring your instance, map your desired external port to 17860:

```bash
# Map external port 7860 to FaceFusion's internal port 17860
-p 7860:17860

# SSH port (Vast.ai will remap this to a random external port)
-p 22:22
```

### Accessing FaceFusion

1. **Via Vast.ai Dashboard**: Click **"Open"** on your instance or access the remapped port shown in the instance details
2. **Via Direct IP**: `http://PUBLIC_IP:PORT` (where PORT is your mapped external port)
3. **Via SSH Tunnel**: Forward port 17860 locally for direct access

---

## Dynamic Provisioning

Use provisioning scripts to automatically set up models and configurations on first boot.

### How It Works

1. Set `PROVISIONING_SCRIPT` environment variable to a URL pointing to your shell script
2. On first boot, the entrypoint downloads and executes the script
3. A marker file (`/.provisioning_complete`) prevents re-running on subsequent boots

> **Security Note**: Always use HTTPS URLs for provisioning scripts and only point to URLs you control and trust. The container will display a warning if a non-HTTPS URL is used.

### Example Provisioning Script

```bash
#!/bin/bash
# provisioning.sh - Example setup script for FaceFusion

set -eo pipefail

FACEFUSION_DIR="${FACEFUSION_DIR:-/workspace/facefusion}"

# Activate the FaceFusion virtual environment
cd "$FACEFUSION_DIR"
source .venv/bin/activate

# Download additional models if needed
# (FaceFusion downloads models on first use, but you can pre-download)

# Configure AWS credentials for S3 access (if using Mountpoint S3)
# aws configure set aws_access_key_id YOUR_ACCESS_KEY
# aws configure set aws_secret_access_key YOUR_SECRET_KEY

echo "Provisioning complete!"
```

### Setting Provisioning Script

**WebUI**: Add to Environment Variables:
```
PROVISIONING_SCRIPT=https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/provisioning.sh
```

**CLI**:
```bash
vastai create instance <OFFER_ID> \
  --image ghcr.io/mlshdev/facefusion-cuda130:latest \
  --env '-p 7860:17860 -p 22:22 -e PROVISIONING_SCRIPT=https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/setup.sh' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 100
```

---

## Directory Structure

```
/workspace/
└── facefusion/
    ├── .venv/              # Python virtual environment
    ├── .assets/
    │   └── models/         # Downloaded AI models
    ├── facefusion/         # FaceFusion source code
    │   ├── content_analyser.py  # Modified for research mode
    │   ├── core.py              # Modified for research mode
    │   └── ...
    ├── facefusion.py       # Main entry point
    ├── facefusion.ini      # Configuration file
    └── ...

/opt/
├── entrypoint.sh           # Container entrypoint script
├── start-facefusion.sh     # FaceFusion startup script
├── propagate-ssh-keys.sh   # SSH key propagation script
└── aws-cli/                # AWS CLI installation
```

---

## AWS S3 Integration

This image includes AWS CLI v2 and AWS Mountpoint S3 for seamless S3 bucket integration.

### AWS CLI

The AWS CLI v2 is pre-installed and available in PATH:

```bash
# Configure AWS credentials
aws configure

# List S3 buckets
aws s3 ls

# Sync data to/from S3
aws s3 sync /workspace/output s3://my-bucket/output
```

### AWS Mountpoint S3

Mountpoint S3 allows you to mount S3 buckets as local filesystems:

```bash
# Mount an S3 bucket (read-only by default)
mkdir -p /mnt/s3-bucket
mount-s3 my-bucket-name /mnt/s3-bucket

# Mount with write access
mount-s3 my-bucket-name /mnt/s3-bucket --allow-delete --allow-overwrite

# Unmount
fusermount -u /mnt/s3-bucket
```

**Note**: Ensure your AWS credentials are configured before mounting. You can use environment variables, IAM roles, or the AWS credentials file.

---

## Service Management

Services are managed by [Supervisor](https://supervisord.readthedocs.io/):

### Common Commands

```bash
# Check all service statuses
supervisorctl status

# Restart FaceFusion (useful after configuration changes)
supervisorctl restart facefusion

# Stop FaceFusion
supervisorctl stop facefusion

# Start FaceFusion
supervisorctl start facefusion

# View live logs
supervisorctl tail -f facefusion

# View recent log output
supervisorctl tail facefusion
```

### Service Configuration Files

- Supervisor config: `/etc/supervisor/supervisord.conf`
- FaceFusion service: `/etc/supervisor/conf.d/facefusion.conf`
- SSHD service: `/etc/supervisor/conf.d/sshd.conf`

---

## Building

### Building Locally

```bash
cd facefusion
docker build -t facefusion-cuda130:local .
```

### Building with GitHub Actions

The image is automatically built and pushed to GitHub Container Registry and DockerHub when the workflow is manually triggered.

Required GitHub secrets:
- `DOCKERHUB_USERNAME`: DockerHub username
- `DOCKERHUB_TOKEN`: DockerHub access token

To trigger a build:
1. Go to the repository's **Actions** tab
2. Select **"Build and Push FaceFusion Image"** workflow
3. Click **"Run workflow"**

---

## Research Mode Notes

This image is configured for **research and educational purposes** with the following modifications:

### NSFW Detection Disabled

The content analysis (NSFW detection) functionality has been disabled to allow researchers to study face manipulation techniques without restrictions. This is achieved through:

1. **`content_analyser.py`**: The `detect_nsfw()` function always returns `False`
2. **`content_analyser.py`**: The `pre_check()` function skips model downloads
3. **`core.py`**: The hash verification for `content_analyser.py` is bypassed

### Ethical Considerations

When using this image:
- **Respect privacy**: Do not use face manipulation technology on individuals without their explicit consent
- **Avoid misinformation**: Do not create deepfakes or manipulated media intended to deceive
- **Follow laws**: Ensure compliance with local regulations regarding synthetic media
- **Research responsibly**: Use this tool for legitimate research and educational purposes only

### Re-enabling NSFW Detection

If you need to restore NSFW detection:

1. Reset the FaceFusion repository to the original state:
   ```bash
   cd /workspace/facefusion
   git checkout -- facefusion/content_analyser.py facefusion/core.py
   ```

2. Restart FaceFusion:
   ```bash
   supervisorctl restart facefusion
   ```

---

## Troubleshooting

### FaceFusion Not Starting

1. Check supervisor logs: `supervisorctl tail -f facefusion`
2. Verify FaceFusion directory exists: `ls -la /workspace/facefusion`
3. Check if provisioning is still running: `ls /.provisioning`

### Out of VRAM

1. Use lower resolution or smaller batch sizes
2. Try different execution providers in `FACEFUSION_ARGS`
3. Close other GPU-intensive applications

### Cannot Connect to Web Interface

1. Verify FaceFusion is running: `supervisorctl status facefusion`
2. Check port mapping in your Vast.ai instance configuration
3. Try SSH port forwarding as an alternative

### Models Not Loading

1. Check if models are downloading: `supervisorctl tail -f facefusion`
2. Verify disk space: `df -h`
3. Restart FaceFusion after errors: `supervisorctl restart facefusion`

### AWS Mountpoint S3 Issues

1. Verify AWS credentials: `aws sts get-caller-identity`
2. Check libfuse2t64 is installed: `dpkg -l | grep fuse`
3. Ensure bucket exists and is accessible: `aws s3 ls s3://bucket-name`

---

## Useful Links

- [FaceFusion GitHub](https://github.com/facefusion/facefusion)
- [FaceFusion Documentation](https://docs.facefusion.io)
- [Vast.ai Documentation](https://docs.vast.ai)
- [Vast.ai CLI Commands](https://docs.vast.ai/cli/commands)
- [Vast.ai SSH Guide](https://docs.vast.ai/documentation/instances/connect/ssh)
- [Vast.ai Storage & Volumes](https://docs.vast.ai/documentation/instances/storage/types)
- [AWS Mountpoint S3](https://github.com/awslabs/mountpoint-s3)
- [uv Package Manager](https://github.com/astral-sh/uv)

---

## License

See [LICENSE.md](../LICENSE.md) for details.

FaceFusion is licensed under the [Open-RAIL-A-S License](https://github.com/facefusion/facefusion/blob/master/LICENSE.md).
