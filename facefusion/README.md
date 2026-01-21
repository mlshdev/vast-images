# FaceFusion Docker Image for Vast.ai

Custom Docker image for running [FaceFusion](https://github.com/facefusion/facefusion) on [Vast.ai](https://vast.ai) cloud GPU platform with CUDA 12.9.1 and TensorRT support.

**Research Edition**: This image has NSFW detection disabled for educational and research purposes.

## Table of Contents

1. [Features](#features)
2. [Quick Start](#quick-start)
3. [Accessing FaceFusion WebUI](#accessing-facefusion-webui)
   - [Method 1: Instance Portal with Cloudflare Tunnels (Recommended)](#method-1-instance-portal-with-cloudflare-tunnels-recommended)
   - [Method 2: Direct IP:PORT Access](#method-2-direct-ipport-access)
   - [Method 3: SSH Port Forwarding](#method-3-ssh-port-forwarding)
   - [Method 4: Gradio Share Mode](#method-4-gradio-share-mode)
4. [Setup via Vast.ai WebUI](#setup-via-vastai-webui)
5. [Setup via vast-cli](#setup-via-vast-cli)
6. [Workspace Volume Configuration](#workspace-volume-configuration)
7. [SSH Access & Port Remapping](#ssh-access--port-remapping)
8. [Environment Variables](#environment-variables)
9. [FaceFusion Run Parameters](#facefusion-run-parameters)
10. [Ports Reference](#ports-reference)
11. [Dynamic Provisioning](#dynamic-provisioning)
12. [Directory Structure](#directory-structure)
13. [AWS S3 Integration](#aws-s3-integration)
14. [Service Management](#service-management)
15. [Building](#building)
16. [Research Mode Notes](#research-mode-notes)
17. [Troubleshooting](#troubleshooting)
18. [Useful Links](#useful-links)
19. [License](#license)

---

## Features

- **Base Image**: NVIDIA CUDA 12.9.1 with cuDNN runtime on Ubuntu 24.04
- **Instance Portal**: Built-in web portal for easy application access and management
- **Cloudflare Tunnels**: Automatic secure HTTPS tunnels for accessing FaceFusion from anywhere
- **Package Manager**: [uv](https://github.com/astral-sh/uv) - Fast Python package installer
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
- cloudflared (Cloudflare tunnel client)
- caddy (reverse proxy server)

### Pre-installed Python Packages

In the FaceFusion virtual environment:
- PyTorch with CUDA 12.9 support
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
4. Use the image `ghcr.io/mlshdev/facefusion:latest`
5. Set the on-start command to `/opt/entrypoint.sh`
6. Configure port mapping: `-p 1111:1111 -p 7860:7860`
7. Click **"Rent"** to launch your instance
8. Click **"Open"** to access the Instance Portal and FaceFusion

> **Note**: If you forked this repository and built your own image, replace `mlshdev` with your GitHub username.

---

## Accessing FaceFusion WebUI

This image provides multiple methods to access the FaceFusion web interface. Choose the method that best fits your needs.

### Method 1: Instance Portal with Cloudflare Tunnels (Recommended)

The Instance Portal automatically creates secure Cloudflare tunnels for all configured ports. This is the **recommended method** as it provides:
- Secure HTTPS access from anywhere
- No firewall configuration needed
- Automatic token-based authentication
- Easy-to-remember URLs (e.g., `https://four-random-words.trycloudflare.com`)

**How to use:**

1. After your instance starts, click the **"Open"** button on your instance card
2. The Instance Portal will load and show available applications
3. Click **"Launch Application"** next to FaceFusion
4. A new tab will open with your FaceFusion web interface

The Instance Portal automatically:
- Creates a Cloudflare tunnel for port 7860 (FaceFusion)
- Appends an authentication token to the URL
- Provides direct links to both tunnel and direct IP access

**Managing Tunnels:**

You can also create additional tunnels for ports you start later:
1. Go to the **"Tunnels"** page in the Instance Portal
2. Enter the local URL (e.g., `http://localhost:8080`)
3. Click **"Create New Tunnel"**

### Method 2: Direct IP:PORT Access

Access FaceFusion directly using the instance's public IP and mapped external port.

**How to use:**

1. Find your mapped port:
   - Click the **"IP Port Info"** button on your instance card
   - Look for the mapping to port 7860 (e.g., `65.130.162.74:33526 -> 7860/tcp`)
2. Open your browser and navigate to: `http://PUBLIC_IP:EXTERNAL_PORT`

**Example:**
```
http://65.130.162.74:33526
```

**Limitations:**
- Requires the port to be opened in your template configuration
- May be blocked by corporate firewalls
- No HTTPS (unless you configure it separately)

### Method 3: SSH Port Forwarding

Forward FaceFusion's port through SSH to access it locally on your machine.

**How to use:**

1. Get your SSH connection details from the Vast.ai dashboard
2. Connect with port forwarding:
   ```bash
   ssh -p <SSH_PORT> -L 7860:localhost:7860 root@<PUBLIC_IP>
   ```
3. Open your browser and navigate to: `http://localhost:7860`

**Example:**
```bash
# Forward FaceFusion to your local machine
ssh -p 23456 -L 7860:localhost:7860 root@65.130.162.74

# Then open http://localhost:7860 in your browser
```

**Benefits:**
- Works through firewalls
- Secure encrypted connection
- Access as if FaceFusion was running locally

### Method 4: Gradio Share Mode

Create a temporary public URL using Gradio's built-in sharing feature.

**How to use:**

1. SSH into your instance
2. Stop the current FaceFusion service:
   ```bash
   supervisorctl stop facefusion
   ```
3. Start FaceFusion with the share flag:
   ```bash
   cd /workspace/facefusion
   source .venv/bin/activate
   python facefusion.py run --share
   ```
4. Gradio will output a public URL like: `https://abcdef123456.gradio.live`
5. Access FaceFusion using this URL from anywhere

**Benefits:**
- Works from anywhere without port configuration
- Temporary URL expires after 72 hours
- Good for sharing access with others temporarily

**Limitations:**
- Requires manual start
- URL changes each time you restart
- Limited to 72 hours

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
| **Image Path/Tag** | `ghcr.io/mlshdev/facefusion:latest` | The Docker image to use. If you built your own image, replace `mlshdev` with your GitHub username. |
| **Docker Options** | `-p 1111:1111 -p 7860:7860` | Port mappings for Instance Portal and FaceFusion web interface. |
| **Launch Mode** | `Run interactive shell server, SSH` | Recommended for SSH access with entrypoint execution. |
| **On-start Script** | `/opt/entrypoint.sh` | The entrypoint script that initializes the container. |

#### Environment Variables

Add these environment variables in the **"Environment Variables"** section:

| Variable | Example Value | Required | Description |
|----------|---------------|----------|-------------|
| `FACEFUSION_ARGS` | `--execution-providers cuda` | No | CLI arguments for FaceFusion. Default: `--execution-providers cuda` |
| `GRADIO_SERVER_PORT` | `7860` | No | Port for FaceFusion web interface. Default: `7860` |
| `WORKSPACE` | `/workspace` | No | Base workspace directory. Default: `/workspace` |
| `PROVISIONING_SCRIPT` | `https://raw.githubusercontent.com/user/repo/main/setup.sh` | No | URL to a shell script for automatic model/extension setup |
| `CF_TUNNEL_TOKEN` | `your-tunnel-token` | No | Cloudflare named tunnel token for custom domain access |

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
4. Click **"Open"** to access the Instance Portal

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
  --image ghcr.io/mlshdev/facefusion:latest \
  --env '-p 1111:1111 -p 7860:7860' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 50 \
  --ssh \
  --direct
```

> **Note**: If you built your own image, replace `mlshdev` with your GitHub username.

### Full Configuration with All Options

```bash
vastai create instance <OFFER_ID> \
  --image ghcr.io/mlshdev/facefusion:latest \
  --env '-p 1111:1111 -p 7860:7860 \
         -e FACEFUSION_ARGS="--execution-providers tensorrt" \
         -e WORKSPACE=/workspace \
         -e PROVISIONING_SCRIPT=https://raw.githubusercontent.com/user/repo/main/setup.sh' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 100 \
  --ssh \
  --direct \
  --label "FaceFusion-Research"
```

### With Custom Cloudflare Tunnel (Named Tunnel)

For a custom domain instead of random Cloudflare URLs:

```bash
vastai create instance <OFFER_ID> \
  --image ghcr.io/mlshdev/facefusion:latest \
  --env '-p 1111:1111 -p 7860:7860 \
         -e CF_TUNNEL_TOKEN=your-cloudflare-tunnel-token' \
  --onstart-cmd '/opt/entrypoint.sh' \
  --disk 100 \
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
ssh -p <REMAPPED_PORT> -L 7860:localhost:7860 root@<PUBLIC_IP>

# Then access FaceFusion at http://localhost:7860
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WORKSPACE` | `/workspace` | Base workspace directory for FaceFusion and data |
| `FACEFUSION_DIR` | `/workspace/facefusion` | FaceFusion installation directory |
| `GRADIO_SERVER_NAME` | `0.0.0.0` | IP address for Gradio/FaceFusion to listen on |
| `GRADIO_SERVER_PORT` | `7860` | Port for FaceFusion web interface |
| `FACEFUSION_ARGS` | `--execution-providers cuda` | CLI arguments for FaceFusion execution settings |
| `PROVISIONING_SCRIPT` | (none) | URL to a shell script for automatic setup on first boot |
| `CF_TUNNEL_TOKEN` | (none) | Cloudflare named tunnel token for custom domain access |
| `PORTAL_CONFIG` | (see below) | Configuration for Instance Portal applications |

### Default PORTAL_CONFIG

```
localhost:1111:11111:/:Instance Portal|localhost:7860:7860:/:FaceFusion
```

---

## FaceFusion Run Parameters

FaceFusion can be customized using CLI arguments and environment variables.

### Server Configuration (via Environment Variables)

The server settings are configured using Gradio environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `GRADIO_SERVER_NAME` | Bind address | `0.0.0.0` (all interfaces) |
| `GRADIO_SERVER_PORT` | Server port | `7860` |

### Execution Configuration (via FACEFUSION_ARGS)

Set these in the `FACEFUSION_ARGS` environment variable:

| Argument | Description | Example |
|----------|-------------|---------|
| `--execution-providers` | GPU acceleration backend | `cuda`, `tensorrt`, `cpu` |
| `--execution-device-ids` | GPU device(s) to use | `0`, `0 1` (for multi-GPU) |
| `--execution-thread-count` | Processing threads | `4` (default), up to `32` |

### Common FACEFUSION_ARGS Examples

```bash
# Use CUDA (default)
FACEFUSION_ARGS="--execution-providers cuda"

# Use TensorRT for faster inference
FACEFUSION_ARGS="--execution-providers tensorrt"

# Use multiple GPUs
FACEFUSION_ARGS="--execution-providers cuda --execution-device-ids 0 1"

# Increase thread count for faster processing
FACEFUSION_ARGS="--execution-providers cuda --execution-thread-count 16"

# Debug mode
FACEFUSION_ARGS="--execution-providers cuda --log-level debug"
```

### Execution Providers

| Provider | Description | When to Use |
|----------|-------------|-------------|
| `cuda` | NVIDIA CUDA acceleration | Default choice for NVIDIA GPUs |
| `tensorrt` | NVIDIA TensorRT optimization | Maximum performance (requires TensorRT) |
| `cpu` | CPU processing | When no GPU is available |

---

## Ports Reference

### Internal Ports

| Service | Internal Port | Description |
|---------|--------------|-------------|
| Instance Portal | 11111 | Internal portal API |
| Instance Portal UI | 1111 (proxied) | External access via Caddy |
| Tunnel Manager | 11112 | Cloudflare tunnel management API |
| Cloudflare Metrics | 11113 | Cloudflare tunnel metrics |
| FaceFusion | 7860 | FaceFusion Gradio web interface |
| SSH | 22 | SSH access |

### Port Mapping in Docker

Configure port mappings in your Docker options:

```bash
# Instance Portal and FaceFusion
-p 1111:1111 -p 7860:7860

# SSH port (Vast.ai will remap this to a random external port)
-p 22:22
```

### Accessing Applications

1. **Via Instance Portal**: Click **"Open"** on your instance card, then use the portal to launch applications
2. **Via Cloudflare Tunnel**: Use the `https://xxx.trycloudflare.com` URL provided by the Instance Portal
3. **Via Direct IP**: Use `http://PUBLIC_IP:PORT` where PORT is your mapped external port

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
  --image ghcr.io/mlshdev/facefusion:latest \
  --env '-p 1111:1111 -p 7860:7860 -e PROVISIONING_SCRIPT=https://gist.githubusercontent.com/YOUR_USERNAME/GIST_ID/raw/setup.sh' \
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
├── aws-cli/                # AWS CLI installation
└── portal-aio/             # Instance Portal components
    ├── portal/             # Portal web interface
    ├── tunnel_manager/     # Cloudflare tunnel manager
    ├── caddy_manager/      # Caddy reverse proxy
    ├── cloudflared         # Cloudflare tunnel client
    ├── caddy               # Caddy web server
    └── venv/               # Portal Python environment
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

### Instance Portal Logs

Portal logs are stored in `/var/log/portal/`:
- `portal.log` - Portal web interface
- `caddy.log` - Caddy reverse proxy
- `tunnel-manager.log` - Cloudflare tunnel manager

---

## Building

### Building Locally

```bash
# From the repository root
docker build -f facefusion/Dockerfile -t facefusion:local .
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

### Cannot Access Instance Portal

1. Verify portal is running: check `/var/log/portal/portal.log`
2. Verify port 1111 is mapped in your template
3. Try direct IP access: `http://PUBLIC_IP:EXTERNAL_PORT`

### Cloudflare Tunnel Not Working

1. Check tunnel manager logs: `cat /var/log/portal/tunnel-manager.log`
2. Verify cloudflared is working: `pgrep cloudflared`
3. Use the Instance Portal Tunnels page to manually create a tunnel

### Out of VRAM

1. Use lower resolution or smaller batch sizes
2. Try different execution providers in `FACEFUSION_ARGS`
3. Close other GPU-intensive applications

### Cannot Connect to Web Interface

1. Verify FaceFusion is running: `supervisorctl status facefusion`
2. Check port mapping in your Vast.ai instance configuration
3. Try SSH port forwarding as an alternative
4. Use the Instance Portal Cloudflare tunnel

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
- [Vast.ai Instance Portal](https://docs.vast.ai/documentation/instances/connect/instance-portal)
- [Vast.ai Networking & Ports](https://docs.vast.ai/documentation/instances/connect/networking)
- [AWS Mountpoint S3](https://github.com/awslabs/mountpoint-s3)
- [uv Package Manager](https://github.com/astral-sh/uv)
- [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)

---

## License

See [LICENSE.md](../LICENSE.md) for details.

FaceFusion is licensed under the [Open-RAIL-A-S License](https://github.com/facefusion/facefusion/blob/master/LICENSE.md).
