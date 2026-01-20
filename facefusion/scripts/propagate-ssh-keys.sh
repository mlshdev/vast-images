#!/bin/bash

# SSH key propagation script for vast.ai compatibility
# Ensures uploaded SSH keys are valid for both root and user accounts

set -euo pipefail

ROOT_AUTH_KEYS="/root/.ssh/authorized_keys"
SSH_DIR_PERMISSIONS="700"
AUTH_KEYS_PERMISSIONS="600"

# Function to check if a key exists in a file
key_exists() {
    local key="$1"
    local file="$2"
    grep -qF "$key" "$file" 2>/dev/null
}

# Function to ensure directory exists with correct permissions
ensure_dir() {
    local dir="$1"
    local permissions="$2"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        chmod "$permissions" "$dir"
    fi
}

# Function to get user's primary group
get_primary_group() {
    local username="$1"
    id -gn "$username"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Setup root SSH directory
mkdir -p /root/.ssh
touch "$ROOT_AUTH_KEYS"

# Ensure root keys have correct permissions
chmod $SSH_DIR_PERMISSIONS /root/.ssh
chmod $AUTH_KEYS_PERMISSIONS "$ROOT_AUTH_KEYS"

# Iterate over users in /home
for user_home in /home/*; do
    if [[ ! -d "$user_home" ]]; then
        continue
    fi

    username=$(basename "$user_home")
    user_group=$(get_primary_group "$username")
    user_ssh_dir="$user_home/.ssh"
    user_auth_keys="$user_ssh_dir/authorized_keys"

    # Ensure .ssh directory exists with correct permissions
    ensure_dir "$user_ssh_dir" "$SSH_DIR_PERMISSIONS"
    chown "$username:$user_group" "$user_ssh_dir"

    # Create authorized_keys file if it doesn't exist
    if [[ ! -f "$user_auth_keys" ]]; then
        touch "$user_auth_keys"
        chmod "$AUTH_KEYS_PERMISSIONS" "$user_auth_keys"
        chown "$username:$user_group" "$user_auth_keys"
    fi

    # Check and add root's keys to user
    while IFS= read -r key || [ -n "$key" ]; do
        # Skip empty or whitespace-only keys
        if [[ -n "$key" && ! "$key" =~ ^[[:space:]]*$ ]] && ! key_exists "$key" "$user_auth_keys"; then
            echo "$key" >> "$user_auth_keys"
            echo "Added SSH key for $username"
        fi
    done < "$ROOT_AUTH_KEYS"

    # Ensure correct permissions
    chmod "$AUTH_KEYS_PERMISSIONS" "$user_auth_keys"
    chown "$username:$user_group" "$user_auth_keys"
done

echo "SSH key propagation complete."
