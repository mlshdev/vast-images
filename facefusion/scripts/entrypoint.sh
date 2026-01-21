#!/bin/bash

# Entrypoint script for FaceFusion container on vast.ai
# Handles SSH key propagation, environment setup, Instance Portal, and supervisor launch

set -e

# Setup workspace directory
mkdir -p "${WORKSPACE:-/workspace}"
cd "${WORKSPACE:-/workspace}"

# Create log directories
mkdir -p /var/log/portal /var/log/supervisor

# Propagate SSH keys for vast.ai compatibility
if [[ -f /opt/propagate-ssh-keys.sh ]]; then
    /opt/propagate-ssh-keys.sh
fi

# Setup environment variables for SSH sessions
# Export environment variables to /etc/environment for SSH sessions
# This allows SSH users to have the same environment as the container
if [[ -n "${CONTAINER_ID:-${VAST_CONTAINERLABEL:-${CONTAINER_LABEL:-}}}" ]]; then
    instance_identifier=$(echo "${CONTAINER_ID:-${VAST_CONTAINERLABEL:-${CONTAINER_LABEL:-}}}")
    message="# Template controlled environment for C.${instance_identifier}"
    if ! grep -q "$message" /etc/environment 2>/dev/null; then
        echo "$message" > /etc/environment
        echo 'PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"' >> /etc/environment
        # Export all environment variables (except HOME and SHLVL) to /etc/environment
        # Using null-byte separation (-0) to handle values with newlines safely
        # grep -z filters null-separated input, grep -E excludes HOME= and SHLVL= variables
        # read -d '' reads null-terminated strings
        env -0 | grep -zEv "^(HOME=|SHLVL=)" | while IFS= read -r -d '' line; do
            name=${line%%=*}
            value=${line#*=}
            printf '%s="%s"\n' "$name" "$value"
        done >> /etc/environment
    fi
fi

# Generate authentication token for Instance Portal if not set
if [[ -z "${OPEN_BUTTON_TOKEN:-}" ]]; then
    export OPEN_BUTTON_TOKEN=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 32)
    echo "OPEN_BUTTON_TOKEN=\"${OPEN_BUTTON_TOKEN}\"" >> /etc/environment
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
# SECURITY NOTE: This feature is designed for vast.ai users to customize their instances.
# Users should only set PROVISIONING_SCRIPT to URLs they control and trust.
# Consider using HTTPS URLs and hosting scripts in trusted repositories.
if [[ -n "${PROVISIONING_SCRIPT:-}" && ! -f /.provisioning_complete ]]; then
    echo "Running provisioning script from ${PROVISIONING_SCRIPT}"
    # Validate URL starts with https:// for security (warn if not)
    if [[ ! "${PROVISIONING_SCRIPT}" =~ ^https:// ]]; then
        echo "WARNING: Provisioning script URL is not using HTTPS. This is less secure."
    fi
    curl -fsSL -o /tmp/provisioning.sh "$PROVISIONING_SCRIPT"
    chmod +x /tmp/provisioning.sh
    /tmp/provisioning.sh || echo "Provisioning script encountered errors"
    rm -f /tmp/provisioning.sh
    touch /.provisioning_complete
fi

# Start Instance Portal components in background
# This launches Caddy (reverse proxy), tunnel manager, and portal UI
echo "Starting Instance Portal components..."
/opt/portal-aio/launch.sh &

# Start supervisor in the foreground (manages FaceFusion and SSHD)
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
