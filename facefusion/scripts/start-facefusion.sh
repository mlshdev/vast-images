#!/bin/bash

# Start FaceFusion script
# Activates the virtual environment and launches FaceFusion with configured arguments
# Uses Gradio environment variables for server configuration

set -e

FACEFUSION_DIR="${FACEFUSION_DIR:-/workspace/facefusion}"

# FaceFusion CLI arguments for execution settings (server settings use GRADIO_* env vars)
# Common arguments:
#   --execution-providers cuda|tensorrt  - GPU acceleration backend
#   --execution-device-ids 0             - GPU device to use
#   --execution-thread-count 4           - Number of processing threads
FACEFUSION_ARGS="${FACEFUSION_ARGS:---execution-providers cuda}"

cd "${FACEFUSION_DIR}"

# Activate the virtual environment
source .venv/bin/activate

# Configure LD_LIBRARY_PATH for TensorRT native libraries
# The tensorrt-cu12 pip package installs libnvinfer.so.10 and other TensorRT libs
# into site-packages/tensorrt_libs which must be in LD_LIBRARY_PATH for onnxruntime-gpu
TENSORRT_LIBS_PATH="${FACEFUSION_DIR}/.venv/lib/python3.12/site-packages/tensorrt_libs"
if [[ -d "${TENSORRT_LIBS_PATH}" ]]; then
    export LD_LIBRARY_PATH="${TENSORRT_LIBS_PATH}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
    echo "TensorRT libraries path added: ${TENSORRT_LIBS_PATH}"
fi

# Wait for provisioning to complete if needed
# The /.provisioning file is created at boot and removed after provisioning completes
while [ -f "/.provisioning" ]; do
    echo "FaceFusion startup paused until instance provisioning has completed (/.provisioning present)"
    sleep 5
done

# Update requirements after provisioning is complete
# This ensures dependencies stay in sync if FaceFusion was updated during provisioning
echo "Checking FaceFusion requirements..."
# Note: We skip onnxruntime since we have GPU version installed
uv pip install --quiet gradio-rangeslider gradio numpy onnx opencv-python psutil tqdm scipy 2>/dev/null || true

# Log configuration
echo "Starting FaceFusion with:"
echo "  GRADIO_SERVER_NAME=${GRADIO_SERVER_NAME:-0.0.0.0}"
echo "  GRADIO_SERVER_PORT=${GRADIO_SERVER_PORT:-7860}"
echo "  CLI args: run ${FACEFUSION_ARGS}"

# Launch FaceFusion
# Server settings are controlled by environment variables:
#   - GRADIO_SERVER_NAME: Bind address (default: 0.0.0.0)
#   - GRADIO_SERVER_PORT: Server port (default: 7860)
exec python facefusion.py run ${FACEFUSION_ARGS}
