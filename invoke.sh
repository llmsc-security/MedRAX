#!/bin/bash
# Invoke script for MedRAX Docker container
# Usage: ./invoke.sh [mode] [options]

set -e

CONTAINER_NAME="medrax"
PORT=11180
IMAGE_NAME="medrax:latest"

# Parse arguments
MODE="${1:-start}"
shift || true

# Function to start the container
start_container() {
    echo "Starting MedRAX container on port $PORT..."

    # Check if container already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container already exists, removing..."
        docker rm -f "$CONTAINER_NAME" || true
    fi

    # Create temp directory
    mkdir -p temp logs

    # Run the container
    docker run -d \
        --name "$CONTAINER_NAME" \
        -p $PORT:8585 \
        -v "$(pwd)/temp:/medrax/temp:rw" \
        -v "$(pwd)/logs:/medrax/logs:rw" \
        -v "${MODEL_WEIGHTS_PATH:-/tmp/model-weights}:/model-weights:ro" \
        -e PYTHONUNBUFFERED=1 \
        -e MODEL="${MODEL:-gpt-4o}" \
        -e TEMP_DIR="${TEMP_DIR:-temp}" \
        -e DEVICE="${DEVICE:-cuda}" \
        --shm-size=2g \
        --restart=unless-stopped \
        "$IMAGE_NAME" \
        "$@"
}

# Function to stop the container
stop_container() {
    echo "Stopping MedRAX container..."
    docker stop "$CONTAINER_NAME" || true
    docker rm -f "$CONTAINER_NAME" || true
}

# Function to show logs
show_logs() {
    docker logs -f "$CONTAINER_NAME"
}

# Main logic
case "$MODE" in
    start)
        start_container
        echo "Container started successfully!"
        echo "Access the Gradio web UI at http://localhost:$PORT"
        ;;
    stop)
        stop_container
        echo "Container stopped successfully!"
        ;;
    logs)
        show_logs
        ;;
    *)
        echo "Usage: $0 {start|stop|logs}"
        echo ""
        echo "Modes:"
        echo "  start    - Start the container in daemon mode"
        echo "  stop     - Stop and remove the container"
        echo "  logs     - Follow container logs"
        exit 1
        ;;
esac
