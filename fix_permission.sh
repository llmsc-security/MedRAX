#!/bin/bash
# Quick fix for permission issues with model cache
# Run this if you see "Permission denied" errors

set -e

echo "Fixing permissions for MedRAX cache directories..."

# Fix model-cache
if [ -d "./model-cache" ]; then
    echo "Fixing ./model-cache permissions..."
    chmod -R 777 ./model-cache
    echo "✓ model-cache permissions fixed"
else
    echo "✓ model-cache directory not found (will be created)"
fi

# Fix model-weights
if [ -d "./model-weights" ]; then
    echo "Fixing ./model-weights permissions..."
    chmod -R 777 ./model-weights
    echo "✓ model-weights permissions fixed"
else
    echo "✓ model-weights directory not found (will be created)"
fi

# Fix temp
if [ -d "./temp" ]; then
    echo "Fixing ./temp permissions..."
    chmod -R 777 ./temp
    echo "✓ temp permissions fixed"
fi

# Fix logs
if [ -d "./logs" ]; then
    echo "Fixing ./logs permissions..."
    chmod -R 777 ./logs
    echo "✓ logs permissions fixed"
fi

echo ""
echo "All permissions fixed!"
echo "Now restart your container:"
echo "  ./invoke.sh restart"

