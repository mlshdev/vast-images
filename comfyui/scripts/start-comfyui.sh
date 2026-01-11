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
while [ -f "/.provisioning" ]; do
    echo "ComfyUI startup paused until instance provisioning has completed (/.provisioning present)"
    sleep 5
done

# Update requirements if not first boot
if [[ ! -f /.provisioning ]]; then
    echo "Updating ComfyUI requirements..."
    uv pip install --quiet -r requirements.txt 2>/dev/null || true
fi

echo "Starting ComfyUI with args: ${COMFYUI_ARGS}"

# Launch ComfyUI
exec python main.py ${COMFYUI_ARGS}
