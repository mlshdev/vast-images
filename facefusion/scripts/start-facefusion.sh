#!/bin/bash

# Start FaceFusion script
# Activates the virtual environment and launches FaceFusion with configured arguments

set -e

FACEFUSION_DIR="${FACEFUSION_DIR:-/workspace/facefusion}"
FACEFUSION_ARGS="${FACEFUSION_ARGS:---open-browser=false --server-name 0.0.0.0 --server-port 17860}"

cd "${FACEFUSION_DIR}"

# Activate the virtual environment
source .venv/bin/activate

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

echo "Starting FaceFusion with args: run ${FACEFUSION_ARGS}"

# Launch FaceFusion
exec python facefusion.py run ${FACEFUSION_ARGS}
