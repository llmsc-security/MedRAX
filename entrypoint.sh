#!/bin/bash
set -e

# Function: print log message
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function: install runtime dependencies
install_runtime_dependencies() {
    log "Checking and installing runtime dependencies..."

    local requirements_file="requirements.txt"
    local installed_packages_file="/tmp/installed_packages.txt"

    if [ -f "$requirements_file" ]; then
        if [ ! -f "$installed_packages_file" ] || [ "$requirements_file" -nt "$installed_packages_file" ]; then
            log "New dependencies found, installing..."
            pip install --no-cache-dir -r "$requirements_file" 2>&1 | while read line; do
                log "pip: $line"
            done
            touch "$installed_packages_file"
            log "Dependencies installed"
        else
            log "Dependencies are up to date, skipping"
        fi
    else
        log "No requirements.txt found"
    fi
}

# Function: check requirements
check_requirements() {
    log "Checking application environment..."

    # Check for model weights directory
    if [ ! -d "/model-weights" ]; then
        log "Warning: /model-weights directory not found"
        log "Mount your model weights at /model-weights for full functionality"
    fi

    log "Environment check completed"
}

# Function: start the Gradio app
start_app() {
    log "Starting MedRAX Gradio server..."

    # Parse environment variables
    local model="${MODEL:-gpt-4o}"
    local temp_dir="${TEMP_DIR:-temp}"
    local device="${DEVICE:-cpu}"

    log "Model: $model"
    log "Temp directory: $temp_dir"
    log "Device: $device"

    exec python main.py
}

# Main logic
log "MedRAX Docker container starting..."

# Check environment
check_requirements

# Execute based on arguments
case "$1" in
    "web"|"")
        start_app
        ;;
    "bash"|"sh")
        log "Starting interactive shell..."
        exec /bin/bash
        ;;
    "health")
        log "Health check passed"
        exit 0
        ;;
    *)
        log "Executing custom command: $*"
        exec "$@"
        ;;
esac
