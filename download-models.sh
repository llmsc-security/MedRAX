
#!/bin/bash
# Pre-download all model weights to host machine
# Run this BEFORE starting the container for the first time
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   MedRAX Model Weights Pre-Download Script          ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Configuration
CACHE_DIR="./model-cache"
mkdir -p "$CACHE_DIR"

echo -e "${GREEN}➜${NC} Creating cache directory: $CACHE_DIR"
echo -e "${YELLOW}⚠${NC}  This will download ~5-10 GB of model weights"
echo -e "${YELLOW}⚠${NC}  Make sure you have stable internet connection"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Create subdirectories
mkdir -p "$CACHE_DIR/huggingface"
mkdir -p "$CACHE_DIR/torchxrayvision"
mkdir -p "$CACHE_DIR/models"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Step 1:${NC} Downloading TorchXRayVision models"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

# TorchXRayVision models
mkdir -p "$CACHE_DIR/torchxrayvision/models_data"

echo "Downloading DenseNet-121 classifier..."
wget -c https://github.com/mlmed/torchxrayvision/releases/download/v1/nih-pc-chex-mimic_ch-google-openi-kaggle-densenet121-d121-tw-lr001-rot45-tr15-sc15-seed0-best.pt \
    -O "$CACHE_DIR/torchxrayvision/models_data/nih-pc-chex-mimic_ch-google-openi-kaggle-densenet121-d121-tw-lr001-rot45-tr15-sc15-seed0-best.pt"

echo "Downloading PSPNet segmentation model..."
wget -c https://github.com/mlmed/torchxrayvision/releases/download/v1/pspnet_chestxray_best_model_4.pth \
    -O "$CACHE_DIR/torchxrayvision/models_data/pspnet_chestxray_best_model_4.pth"

echo -e "${GREEN}✓${NC} TorchXRayVision models downloaded"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Step 2:${NC} Downloading HuggingFace models"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

# Set HuggingFace cache
export HF_HOME="$CACHE_DIR/huggingface"
export TRANSFORMERS_CACHE="$CACHE_DIR/huggingface"

# Install Python if needed for downloading
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗${NC} Python3 not found. Please install Python3 to download HuggingFace models."
    exit 1
fi

# Create Python download script
cat > /tmp/download_models.py << 'PYEOF'
import os
from transformers import AutoTokenizer, AutoModel, VisionEncoderDecoderModel, AutoProcessor
from huggingface_hub import snapshot_download

cache_dir = os.environ.get("TRANSFORMERS_CACHE", "./model-cache/huggingface")
print(f"Downloading to: {cache_dir}")

models_to_download = [
    # CheXagent VQA
    ("StanfordAIMI/CheXagent-2-3b", "tokenizer"),
    ("StanfordAIMI/CheXagent-2-3b", "model"),
    
    # Report Generation
    ("IAMJB/chexpert-mimic-cxr-findings-baseline", "vision-encoder-decoder"),
    ("microsoft/swin-base-patch4-window7-224", "model"),
    
    # Phrase Grounding (Maira-2)
    ("microsoft/maira-2", "model"),
]

for model_name, model_type in models_to_download:
    print(f"\n{'='*60}")
    print(f"Downloading: {model_name} ({model_type})")
    print(f"{'='*60}")
    
    try:
        if model_type == "tokenizer":
            AutoTokenizer.from_pretrained(model_name, cache_dir=cache_dir)
        elif model_type == "model":
            AutoModel.from_pretrained(model_name, cache_dir=cache_dir)
        elif model_type == "vision-encoder-decoder":
            VisionEncoderDecoderModel.from_pretrained(model_name, cache_dir=cache_dir)
        elif model_type == "processor":
            AutoProcessor.from_pretrained(model_name, cache_dir=cache_dir)
        
        print(f"✓ Downloaded: {model_name}")
    except Exception as e:
        print(f"✗ Failed to download {model_name}: {e}")
        print(f"  You can download this manually later")

print("\n" + "="*60)
print("HuggingFace models download complete!")
print("="*60)
PYEOF

# Check if transformers is installed
if ! python3 -c "import transformers" 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC}  Installing required Python packages..."
    pip install --user transformers huggingface_hub torch torchvision || {
        echo -e "${RED}✗${NC} Failed to install packages"
        echo "You can skip this step and let the container download models"
        rm /tmp/download_models.py
    }
fi

# Run download script
if [ -f /tmp/download_models.py ]; then
    echo "Starting HuggingFace model downloads..."
    python3 /tmp/download_models.py || {
        echo -e "${YELLOW}⚠${NC}  Some models failed to download"
        echo "The container will download them on first run"
    }
    rm /tmp/download_models.py
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Step 3:${NC} Setting up cache structure"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

# Create .cache directory structure for container
mkdir -p "$CACHE_DIR/.cache/huggingface"
mkdir -p "$CACHE_DIR/.cache/torch"

# Copy huggingface cache to .cache location
if [ -d "$CACHE_DIR/huggingface" ]; then
    echo "Copying HuggingFace cache to .cache directory..."
    cp -r "$CACHE_DIR/huggingface"/* "$CACHE_DIR/.cache/huggingface/" 2>/dev/null || true
fi

echo -e "${GREEN}✓${NC} Cache structure created"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Download Summary${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

# Show what was downloaded
echo ""
echo "Cache directory structure:"
du -sh "$CACHE_DIR" 2>/dev/null || echo "Cache dir: $CACHE_DIR"
echo ""
echo "Contents:"
ls -lh "$CACHE_DIR/" 2>/dev/null || true
echo ""

# Set proper permissions
echo "Setting permissions..."
chmod -R 755 "$CACHE_DIR"

echo -e "${GREEN}✓${NC} Permissions set"
echo ""

echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Download Complete!                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "1. Models are cached in: $CACHE_DIR"
echo "2. Update your environment:"
echo "   export MODEL_CACHE_DIR=$(realpath $CACHE_DIR)"
echo "3. Start container:"
echo "   ./invoke.sh start"
echo ""
echo "The container will use these pre-downloaded models!"
echo ""
