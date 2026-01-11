#!/bin/bash

# Start ComfyUI script
# Activates the virtual environment and launches ComfyUI with configured arguments

set -e

COMFYUI_DIR="${COMFYUI_DIR:-/workspace/ComfyUI}"
COMFYUI_ARGS="${COMFYUI_ARGS:---disable-auto-launch --port 18188 --enable-cors-header}"

cd "${COMFYUI_DIR}"

# Activate the virtual environment
source .venv/bin/activate

# Wait for provisioning to complete if needed
# The /.provisioning file is created at boot and removed after provisioning completes
while [ -f "/.provisioning" ]; do
    echo "ComfyUI startup paused until instance provisioning has completed (/.provisioning present)"
    sleep 5
done

# Update requirements after provisioning is complete
# This ensures dependencies stay in sync if ComfyUI was updated during provisioning
echo "Checking ComfyUI requirements..."
uv pip install --quiet -r requirements.txt 2>/dev/null || true

echo "Starting ComfyUI with args: ${COMFYUI_ARGS}"

# Launch ComfyUI
exec python main.py ${COMFYUI_ARGS}
