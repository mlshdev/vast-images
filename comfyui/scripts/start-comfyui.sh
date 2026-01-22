#!/bin/bash

# Start ComfyUI script
# Activates the virtual environment and launches ComfyUI with configured arguments

set -e

COMFYUI_DIR="${COMFYUI_DIR:-/workspace/ComfyUI}"
COMFYUI_ARGS="${COMFYUI_ARGS:---disable-auto-launch --port 18188 --enable-cors-header}"

cd "${COMFYUI_DIR}"

# Activate the virtual environment
source .venv/bin/activate

# Configure LD_LIBRARY_PATH for TensorRT native libraries
# The tensorrt pip package installs libnvinfer.so and other TensorRT libs
# into site-packages/tensorrt_libs which must be in LD_LIBRARY_PATH
TENSORRT_LIBS_PATH="${COMFYUI_DIR}/.venv/lib/python3.12/site-packages/tensorrt_libs"
if [[ -d "${TENSORRT_LIBS_PATH}" ]]; then
    export LD_LIBRARY_PATH="${TENSORRT_LIBS_PATH}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
    echo "TensorRT libraries path added: ${TENSORRT_LIBS_PATH}"
fi

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
