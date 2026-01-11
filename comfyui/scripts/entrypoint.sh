#!/bin/bash

# Entrypoint script for ComfyUI container on vast.ai
# Handles SSH key propagation, environment setup, and supervisor launch

set -e

# Setup workspace directory
mkdir -p "${WORKSPACE:-/workspace}"
cd "${WORKSPACE:-/workspace}"

# Propagate SSH keys for vast.ai compatibility
if [[ -f /opt/propagate-ssh-keys.sh ]]; then
    /opt/propagate-ssh-keys.sh
fi

# Setup environment variables for SSH sessions
if [[ -n "${CONTAINER_ID:-${VAST_CONTAINERLABEL:-${CONTAINER_LABEL:-}}}" ]]; then
    instance_identifier=$(echo "${CONTAINER_ID:-${VAST_CONTAINERLABEL:-${CONTAINER_LABEL:-}}}")
    message="# Template controlled environment for C.${instance_identifier}"
    if ! grep -q "$message" /etc/environment 2>/dev/null; then
        echo "$message" > /etc/environment
        echo 'PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"' >> /etc/environment
        env -0 | grep -zEv "^(HOME=|SHLVL=)" | while IFS= read -r -d '' line; do
            name=${line%%=*}
            value=${line#*=}
            printf '%s="%s"\n' "$name" "$value"
        done >> /etc/environment
    fi
fi

# Create SSH host keys if they don't exist
if [[ ! -f /etc/ssh/ssh_host_rsa_key ]]; then
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' -q
fi
if [[ ! -f /etc/ssh/ssh_host_ecdsa_key ]]; then
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' -q
fi
if [[ ! -f /etc/ssh/ssh_host_ed25519_key ]]; then
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' -q
fi

# Execute provisioning script if provided
if [[ -n "${PROVISIONING_SCRIPT:-}" && ! -f /.provisioning_complete ]]; then
    echo "Running provisioning script from ${PROVISIONING_SCRIPT}"
    curl -Lo /tmp/provisioning.sh "$PROVISIONING_SCRIPT"
    chmod +x /tmp/provisioning.sh
    /tmp/provisioning.sh || echo "Provisioning script encountered errors"
    touch /.provisioning_complete
fi

# Start supervisor in the foreground
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
