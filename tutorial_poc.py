#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
tutorial_poc.py - MedRAX Tutorial Proof of Concept

This script demonstrates how to use MedRAX through Docker for medical
X-ray analysis tasks.
"""

import os
import sys


def print_section(title):
    """Print a formatted section header."""
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70 + "\n")


def demo_supported_tools():
    """Show supported tools."""
    print_section("Supported Medical Analysis Tools")

    tools = '''
MedRAX provides the following specialized tools for chest X-ray analysis:

1. CHEST_X_RAY_CLASSIFIER
   - Pneumonia detection
   - Tuberculosis screening
   - Lung opacity classification

2. CHEST_X_RAY_SEGMENTATION
   - Lung segmentation
   - Heart segmentation
   - Thoracic structure delineation

3. LLAVA_MED_TOOL
   - Medical image understanding
   - Multi-modal analysis
   - Clinical report generation

4. X_RAY_VQA_TOOL
   - Visual question answering
   - Finding identification
   - Abnormality detection

5. CHEST_X_RAY_REPORT_GENERATOR
   - Automated report writing
   - Clinical terminology
   - Structure report formatting

6. X_RAY_PHRASE_GROUNDING
   - Finding localization
   - Anatomical labeling
   --abnormality mapping

7. IMAGE_VISUALIZER
   - Image display
   - Annotation visualization
   - Comparison views

8. DICOM_PROCESSOR
   - DICOM file reading
   - Metadata extraction
   - Series processing
'''
    print(tools)


def demo_docker_usage():
    """Demo Docker usage."""
    print_section("Docker Usage Examples")

    docker_commands = '''
# Build the Docker image
cd MedRAX
docker build -t medrax:latest .

# Start container with model weights
docker run -d \\
    --name medrax \\
    -p 11180:8585 \\
    -v $(pwd)/temp:/medrax/temp:rw \\
    -v $(pwd)/logs:/medrax/logs:rw \\
    -v /path/to/model-weights:/model-weights:ro \\
    -e MODEL=gpt-4o \\
    -e DEVICE=cuda \\
    --gpus all \\
    medrax:latest

# View logs
docker logs -f medrax

# Access the Gradio web UI
open http://localhost:11180

# Stop the container
docker stop medrax
'''
    print(docker_commands)


def demo_configuration():
    """Show configuration options."""
    print_section("Configuration Options")

    config_info = '''
Environment Variables:
- MODEL: LLM model to use (default: gpt-4o)
- DEVICE: Device for model inference (default: cuda)
- TEMP_DIR: Temporary directory for processing (default: temp)

Required Mounts:
- /model-weights: Directory containing model weights
- /medrax/temp: Temporary files directory
- /medrax/logs: Log files directory

Optional Environment Variables:
- OPENAI_API_KEY: Your OpenAI API key
- OPENAI_BASE_URL: Custom OpenAI base URL
'''
    print(config_info)


def demo_workflow():
    """Show the analysis workflow."""
    print_section("Medical Analysis Workflow")

    workflow = '''
1. PREPARATION
   ├── Ensure model weights are available at /model-weights
   ├── Prepare DICOM or image files
   └── Configure API keys if needed

2. IMAGE LOADING
   ├── Upload X-ray image (JPG/PNG/DICOM)
   └── System extracts image data

3. ANALYSIS PIPELINE
   ├── Selection of tools based on task:
   │   ├── Classification: Pneumonia/TB detection
   │   ├── Segmentation: Lung/Heart boundaries
   │   ├── VQA: Answer clinical questions
   │   └── Report Generation: Full clinical report

4. AI PROCESSING
   ├── Model inference on image
   └── Generation of analysis results

5. OUTPUT
   ├── Visual annotations
   ├── Text reports
   └── Exportable results
'''
    print(workflow)


def demo_python_api():
    """Demo Python API usage."""
    print_section("Python API Examples")

    api_code = '''
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from interface import create_demo
from medrax.agent import *
from medrax.tools import *

# Initialize the agent with specific tools
selected_tools = [
    "ImageVisualizerTool",
    "DicomProcessorTool",
    "ChestXRayClassifierTool",
]

agent, tools_dict = initialize_agent(
    "medrax/docs/system_prompts.txt",
    tools_to_use=selected_tools,
    model_dir="/model-weights",
    temp_dir="temp",
    device="cuda",
    model="gpt-4o",
)

# Create the Gradio interface
demo = create_demo(agent, tools_dict)
demo.launch(server_name="0.0.0.0", server_port=8585, share=True)
'''
    print(api_code)


def demo_supported_models():
    """Show available models."""
    print_section("Available Models")

    models = '''
LLM Models:
- gpt-4o (recommended for best quality)
- gpt-4o-mini (cost-effective)
- claude-3-5-sonnet
- gemini-1.5-pro

Medical Imaging Models:
- LlavaMed: Multi-modal medical vision-language model
- ChestXRayClassifier: Pneumonia/TB detection
- Segmentation models for lung/heart

Text-to-Speech:
- Edge-TTS: Free Microsoft voices
- OpenAI TTS: High-quality voices
- Local TTS models
'''
    print(models)


def demo_storage():
    """Show storage requirements."""
    print_section("Storage and Requirements")

    storage = '''
Disk Space:
- Models: 10GB-50GB depending on selected models
- Temporary files: 5GB+
- Logs: 1GB+

GPU Requirements:
- Minimum: 8GB VRAM
- Recommended: 16GB+ VRAM
- With CUDA support for faster inference

RAM:
- Minimum: 16GB
- Recommended: 32GB+
'''
    print(storage)


def demo_quick_start():
    """Quick start guide."""
    print_section("Quick Start Guide")

    quick_start = '''
1. PREREQUISITES
   Docker installed with CUDA support (optional)
   Model weights downloaded
   OpenAI API key (or local LLM)

2. SETUP
   git clone https://github.com/bowang-lab/MedRAX.git
   cd MedRAX

3. CONFIGURATION
   # Download model weights to /path/to/model-weights
   # Update OPENAI_API_KEY in environment

4. BUILD AND RUN
   docker build -t medrax:latest .
   ./invoke.sh start

5. FIRST USE
   Open http://localhost:11180
   Upload a chest X-ray image
   Select analysis tools
   Run analysis
'''
    print(quick_start)


def main():
    """Main entry point."""
    print("\n" + "/MedRAX Tutorial POC".center(70, "="))
    print("  Medical Reasoning Agent for Chest X-ray".center(70))
    print("=" * 70)

    # Run demos
    demo_supported_tools()
    demo_docker_usage()
    demo_configuration()
    demo_workflow()
    demo_python_api()
    demo_supported_models()
    demo_storage()
    demo_quick_start()

    # Summary
    print_section("Quick Start Summary")

    summary = '''
1. SETUP
   - Install Docker with CUDA (optional)
   - Download model weights
   - Get OpenAI API key

2. DEPLOY
   - Build: docker build -t medrax:latest .
   - Run: ./invoke.sh start

3. USE
   - Access http://localhost:11180
   - Upload chest X-ray images
   - Run medical analysis

For more information, visit: https://github.com/bowang-lab/MedRAX
'''
    print(summary)

    return 0


if __name__ == "__main__":
    sys.exit(main())
