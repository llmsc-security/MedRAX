#!/bin/bash
# Invoke script for MedRAX Docker container
# Provides easy-to-use commands for managing the MedRAX container
# =============================================================================

set -e

# Configuration
CONTAINER_NAME="medrax-container"
IMAGE_NAME="bowang-lab--medrax_image:latest"
HOST_PORT=11180
CONTAINER_PORT=8585

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function: print colored message
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function: check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Function: check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Function: build the Docker image
build_image() {
    print_info "Building MedRAX Docker image..."
    print_info "This may take several minutes on first build..."

    if ! docker build -t "$IMAGE_NAME" .; then
        print_error "Failed to build Docker image"
        exit 1
    fi

    print_success "Docker image built successfully: $IMAGE_NAME"
}

# Function: start the container
start_container() {
    print_info "Starting MedRAX container..."

    # Check if image exists, if not build it
    if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}$"; then
        print_warning "Docker image not found. Building..."
        build_image
    fi

    # Stop and remove existing container if it exists
    if container_exists; then
        print_info "Removing existing container..."
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi

    # Create necessary directories
    mkdir -p temp logs

    # Load environment variables from .env if it exists
    ENV_FILE_ARGS=""
    if [ -f ".env" ]; then
        print_info "Loading environment variables from .env file..."
        ENV_FILE_ARGS="--env-file .env"
    fi

    # Set default values for environment variables
    DEVICE="${DEVICE:-cuda}"
    MODEL="${MODEL:-gpt-4o}"
    TEMP_DIR="${TEMP_DIR:-temp}"
    TEMPERATURE="${TEMPERATURE:-0.7}"
    TOP_P="${TOP_P:-0.95}"
    MODEL_WEIGHTS_PATH="${MODEL_WEIGHTS_PATH:-./model-weights}"
    MODEL_CACHE_DIR="${MODEL_CACHE_DIR:-./model-cache}"

    # Check if OPENAI_API_KEY is set
    if [ -z "$OPENAI_API_KEY" ] && [ ! -f ".env" ]; then
        print_error "OPENAI_API_KEY is not set!"
        print_info "Please either:"
        print_info "  1. Set it as environment variable: export OPENAI_API_KEY='your-key'"
        print_info "  2. Create a .env file with: OPENAI_API_KEY=your-key"
        exit 1
    fi

    # Ensure directories exist
    mkdir -p "$MODEL_WEIGHTS_PATH"
    mkdir -p "$MODEL_CACHE_DIR"
    mkdir -p "$MODEL_CACHE_DIR/huggingface"
    mkdir -p "$MODEL_CACHE_DIR/torchxrayvision"
    mkdir -p "$MODEL_CACHE_DIR/.cache"

    # Fix permissions - IMPORTANT for container to write to cache
    print_info "Setting cache directory permissions..."
    chmod -R 777 "$MODEL_CACHE_DIR" 2>/dev/null || {
        print_warning "Could not set permissions on $MODEL_CACHE_DIR"
        print_warning "You may need to run: sudo chmod -R 777 $MODEL_CACHE_DIR"
    }
    chmod -R 777 "$MODEL_WEIGHTS_PATH" 2>/dev/null || {
        print_warning "Could not set permissions on $MODEL_WEIGHTS_PATH"
    }

    print_info "Container configuration:"
    print_info "  - Host Port: $HOST_PORT → Container Port: $CONTAINER_PORT"
    print_info "  - Device: $DEVICE"
    print_info "  - Model: $MODEL"
    print_info "  - Model Weights: $MODEL_WEIGHTS_PATH"
    print_info "  - Cache Directory: $MODEL_CACHE_DIR"

    # Prepare GPU flags
    GPU_FLAGS=""
    if [ "$DEVICE" = "cuda" ]; then
        # Check if nvidia-smi is available on host
        if command -v nvidia-smi &> /dev/null; then
            GPU_FLAGS="--gpus all"
            print_info "  - GPU: Enabled (--gpus all)"
        else
            print_warning "NVIDIA GPU requested but nvidia-smi not found"
            print_warning "Container will start without GPU access"
            print_warning "Set DEVICE=cpu to suppress this warning"
        fi
    else
        print_info "  - GPU: Disabled (CPU mode)"
    fi

    # Run the container
    docker run -d \
        --name "$CONTAINER_NAME" \
        -p $HOST_PORT:$CONTAINER_PORT \
        $GPU_FLAGS \
        -v "$(pwd)/temp:/medrax/temp:rw" \
        -v "$(pwd)/logs:/medrax/logs:rw" \
        -v "$(realpath $MODEL_WEIGHTS_PATH):/model-weights:rw" \
        -v "$(realpath $MODEL_CACHE_DIR):/cache:rw" \
        $ENV_FILE_ARGS \
        -e PYTHONUNBUFFERED=1 \
        -e DEVICE="$DEVICE" \
        -e MODEL="$MODEL" \
        -e TEMP_DIR="$TEMP_DIR" \
        -e TEMPERATURE="$TEMPERATURE" \
        -e TOP_P="$TOP_P" \
        -e HF_HOME="/cache/huggingface" \
        -e TORCH_HOME="/cache/.cache/torch" \
        -e XDG_CACHE_HOME="/cache/.cache" \
        ${OPENAI_API_KEY:+-e OPENAI_API_KEY="$OPENAI_API_KEY"} \
        ${OPENAI_BASE_URL:+-e OPENAI_BASE_URL="$OPENAI_BASE_URL"} \
        --shm-size=2g \
        --restart=unless-stopped \
        "$IMAGE_NAME" \
        "$@"

    if [ $? -eq 0 ]; then
        print_success "Container started successfully!"
        print_info ""
        print_info "🌐 Access the Gradio web UI at: ${GREEN}http://localhost:$HOST_PORT${NC}"
        print_info ""
        print_info "Useful commands:"
        print_info "  - View logs: ./invoke.sh logs"
        print_info "  - Stop container: ./invoke.sh stop"
        print_info "  - Check status: ./invoke.sh status"
    else
        print_error "Failed to start container"
        exit 1
    fi
}

# Function: stop the container
stop_container() {
    if ! container_exists; then
        print_warning "Container does not exist"
        return
    fi

    print_info "Stopping MedRAX container..."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
    print_success "Container stopped and removed"
}

# Function: restart the container
restart_container() {
    print_info "Restarting MedRAX container..."
    stop_container
    sleep 2
    start_container
}

# Function: show container logs
show_logs() {
    if ! container_running; then
        print_error "Container is not running"
        exit 1
    fi

    print_info "Showing container logs (Ctrl+C to exit)..."
    docker logs -f --tail=100 "$CONTAINER_NAME"
}

# Function: show container status
show_status() {
    if container_running; then
        print_success "Container is running"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        print_info ""
        print_info "Access URL: ${GREEN}http://localhost:$HOST_PORT${NC}"
    elif container_exists; then
        print_warning "Container exists but is not running"
        docker ps -a --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}"
    else
        print_warning "Container does not exist"
    fi
}

# Function: execute command in running container
exec_container() {
    if ! container_running; then
        print_error "Container is not running"
        exit 1
    fi

    print_info "Executing command in container..."
    docker exec -it "$CONTAINER_NAME" "$@"
}

# Function: open shell in running container
shell_container() {
    if ! container_running; then
        print_error "Container is not running"
        print_info "Starting container in shell mode..."
        
        # Prepare GPU flags
        GPU_FLAGS=""
        DEVICE="${DEVICE:-cuda}"
        if [ "$DEVICE" = "cuda" ] && command -v nvidia-smi &> /dev/null; then
            GPU_FLAGS="--gpus all"
        fi
        
        MODEL_CACHE_DIR="${MODEL_CACHE_DIR:-./model-cache}"
        mkdir -p "$MODEL_CACHE_DIR"
        
        docker run -it --rm \
            --name "${CONTAINER_NAME}-shell" \
            $GPU_FLAGS \
            -v "$(pwd):/medrax" \
            -v "$(realpath ${MODEL_WEIGHTS_PATH:-./model-weights}):/model-weights:rw" \
            -v "$(realpath $MODEL_CACHE_DIR):/cache:rw" \
            -e HF_HOME="/cache/huggingface" \
            -e TORCH_HOME="/cache/.cache/torch" \
            -e XDG_CACHE_HOME="/cache/.cache" \
            ${OPENAI_API_KEY:+-e OPENAI_API_KEY="$OPENAI_API_KEY"} \
            ${OPENAI_BASE_URL:+-e OPENAI_BASE_URL="$OPENAI_BASE_URL"} \
            "$IMAGE_NAME" \
            bash
    else
        exec_container /bin/bash
    fi
}

# Function: clean up resources
cleanup() {
    print_info "Cleaning up MedRAX resources..."
    
    # Stop and remove container
    if container_exists; then
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi
    
    # Remove temporary files
    if [ -d "temp" ]; then
        print_info "Removing temp directory..."
        rm -rf temp
    fi
    
    print_success "Cleanup completed"
}

# Function: show help
show_help() {
    cat << EOF
MedRAX Docker Container Management Script

Usage: $0 <command> [options]

Commands:
    build       Build the Docker image
    start       Start the container (default)
    stop        Stop and remove the container
    restart     Restart the container
    logs        Show container logs (follow mode)
    status      Show container status
    shell       Open interactive shell in container
    exec        Execute command in running container
    cleanup     Stop container and clean up temp files
    help        Show this help message

Environment Variables:
    OPENAI_API_KEY       OpenAI API key (required)
    OPENAI_BASE_URL      Custom OpenAI API endpoint (optional)
    DEVICE               Device to use: cuda or cpu (default: cuda)
    MODEL                Model name (default: gpt-4o)
    TEMPERATURE          Model temperature (default: 0.7)
    TOP_P                Model top-p (default: 0.95)
    MODEL_WEIGHTS_PATH   Path to model weights (default: ./model-weights)

Examples:
    # Start container with default settings
    $0 start

    # Start with custom model
    MODEL=gpt-4o-mini $0 start

    # Start with CPU only
    DEVICE=cpu $0 start

    # View logs
    $0 logs

    # Open shell
    $0 shell

    # Execute custom command
    $0 exec python --version

For more information, visit: https://github.com/bowang-lab/MedRAX

EOF
}

# =============================================================================
# Main execution logic
# =============================================================================

# Parse command
COMMAND="${1:-start}"
shift || true

case "$COMMAND" in
    build)
        build_image
        ;;
    start|run)
        start_container "$@"
        ;;
    stop)
        stop_container
        ;;
    restart)
        restart_container
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    shell|bash|sh)
        shell_container
        ;;
    exec)
        exec_container "$@"
        ;;
    cleanup|clean)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac

exit 0

