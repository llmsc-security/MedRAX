#!/bin/bash
# Entrypoint script for MedRAX Docker container
# Handles initialization, validation, and startup
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function: print log message with timestamp
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Function: print warning message
warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Function: print error message
error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Function: validate environment variables
validate_environment() {
    log "Validating environment variables..."

    # Check for OpenAI API key (required)
    if [ -z "$OPENAI_API_KEY" ]; then
        warn "OPENAI_API_KEY environment variable is not set!"
        warn "The application may fail when trying to use AI features"
        warn "Set it using: -e OPENAI_API_KEY='your-api-key'"
        warn "Or use a .env file mounted to /medrax/.env"
        # Don't exit - let the app try to run and show its own error
    fi

    # Log optional environment variables
    if [ -n "$OPENAI_BASE_URL" ]; then
        log "Using custom OpenAI base URL: $OPENAI_BASE_URL"
    else
        log "Using default OpenAI API endpoint"
    fi

    # Check device setting
    local device="${DEVICE:-cuda}"
    log "Device setting: $device"

    # Check model setting
    local model="${MODEL:-gpt-4o}"
    log "Model: $model"

    # Check temperature and top_p
    local temperature="${TEMPERATURE:-0.7}"
    local top_p="${TOP_P:-0.95}"
    log "Temperature: $temperature, Top-p: $top_p"

    log "Environment validation completed"
}

# Function: check directory structure
check_directories() {
    log "Checking directory structure..."

    # Create necessary directories if they don't exist
    mkdir -p /medrax/temp /medrax/logs

    # Check for model weights directory
    if [ ! -d "/model-weights" ]; then
        warn "Model weights directory not mounted at /model-weights"
        warn "Some tools may fail or download models at runtime"
        warn "To use pre-downloaded models, mount with: -v /path/to/weights:/model-weights:rw"
    else
        log "Model weights directory found at /model-weights"
    fi
    
    # Check for cache directory
    if [ ! -d "/cache" ]; then
        warn "Cache directory not mounted at /cache"
        warn "Models will download to container (not persistent)"
        warn "To use pre-downloaded models, mount with: -v /path/to/cache:/cache:rw"
        warn "See download-models.sh for pre-download instructions"
        # Create temporary cache inside container
        mkdir -p /cache/huggingface /cache/torchxrayvision /cache/.cache
    else
        log "Cache directory found at /cache"
        # Check if cache has models
        if [ -d "/cache/huggingface" ] && [ "$(ls -A /cache/huggingface 2>/dev/null)" ]; then
            log "Pre-downloaded HuggingFace models detected"
        fi
        if [ -d "/cache/torchxrayvision/models_data" ] && [ "$(ls -A /cache/torchxrayvision/models_data 2>/dev/null)" ]; then
            log "Pre-downloaded TorchXRayVision models detected"
        fi
    fi

    # Check for assets directory
    if [ ! -d "/medrax/assets" ]; then
        warn "Assets directory not found, creating..."
        mkdir -p /medrax/assets
    fi
    
    # Create symlink for torchxrayvision cache if needed
    if [ -d "/cache/torchxrayvision" ]; then
        mkdir -p /medrax
        if [ ! -L "/medrax/.torchxrayvision" ]; then
            ln -s /cache/torchxrayvision /medrax/.torchxrayvision 2>/dev/null || true
        fi
    fi

    log "Directory check completed"
}

# Function: check required files
check_required_files() {
    log "Checking required application files..."

    local required_files=(
        "main.py"
        "interface.py"
        "medrax/docs/system_prompts.txt"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "/medrax/$file" ]; then
            error "Required file not found: $file"
            exit 1
        fi
    done

    log "All required files present"
}

# Function: print startup banner
print_banner() {
    cat << "EOF"
    
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🏥 MedRAX - Medical Reasoning Agent for Chest X-ray    ║
║                                                           ║
║   Starting Gradio Interface...                           ║
║   Internal Port: 8585 → Host Port: 11180                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

EOF
}

# Function: start the Gradio web application
start_web_app() {
    log "Starting MedRAX Gradio server..."

    # Parse environment variables with defaults
    export DEVICE="${DEVICE:-cuda}"
    export MODEL="${MODEL:-gpt-4o}"
    export TEMP_DIR="${TEMP_DIR:-temp}"
    export TEMPERATURE="${TEMPERATURE:-0.7}"
    export TOP_P="${TOP_P:-0.95}"

    log "Application configuration:"
    log "  - Model: $MODEL"
    log "  - Device: $DEVICE"
    log "  - Temp Directory: $TEMP_DIR"
    log "  - Temperature: $TEMPERATURE"
    log "  - Top-p: $TOP_P"
    log ""
    log "Starting server (this may take a minute on first run)..."
    log "If you see errors, check that OPENAI_API_KEY is set correctly"
    log ""

    # Execute main.py with error handling
    set +e  # Don't exit on error
    python main.py 2>&1
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -ne 0 ]; then
        error "Application exited with code $EXIT_CODE"
        error "Check the logs above for details"
        sleep 5  # Give time to see the error before restart
        exit $EXIT_CODE
    fi
}

# Function: run health check
run_health_check() {
    log "Running health check..."
    
    # Check if Python is available
    if ! command -v python &> /dev/null; then
        error "Python is not available"
        exit 1
    fi

    # Check Python version
    python_version=$(python --version 2>&1)
    log "Python version: $python_version"

    # Check if main dependencies are importable
    python -c "import gradio; import torch; import transformers" 2>/dev/null
    if [ $? -eq 0 ]; then
        log "Core dependencies verified"
    else
        warn "Some dependencies may be missing"
    fi

    log "Health check passed"
    exit 0
}

# Function: start interactive shell
start_shell() {
    log "Starting interactive shell..."
    log "You are now in the MedRAX container environment"
    log "Run 'python main.py' to start the application manually"
    exec /bin/bash
}

# =============================================================================
# Main execution logic
# =============================================================================

print_banner
log "MedRAX Docker container starting..."

# Perform checks
check_directories
check_required_files

# Handle different startup modes
case "$1" in
    "web"|"")
        # Default mode: start web application
        validate_environment
        start_web_app
        ;;
    "bash"|"sh"|"shell")
        # Interactive shell mode
        start_shell
        ;;
    "health")
        # Health check mode
        run_health_check
        ;;
    "validate")
        # Validation only mode
        validate_environment
        log "Validation completed successfully"
        exit 0
        ;;
    *)
        # Custom command mode
        log "Executing custom command: $*"
        exec "$@"
        ;;
esac

