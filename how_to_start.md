# 🏥 MedRAX Docker - Getting Started

Get MedRAX running in 3 simple steps!

---

## ✅ What You Need

- **Docker** - [Install here](https://docs.docker.com/get-docker/)
- **OpenAI API Key** - [Get one here](https://platform.openai.com/api-keys)
- **Optional:** NVIDIA GPU + [nvidia-docker](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

---

## 🚀 Quick Start

### Step 1: Configure API Key

```bash
cp .env.example .env
nano .env  # or use any editor
```

Add your API key:
```bash
OPENAI_API_KEY=sk-your-actual-key-here
```

### Step 2: Build Container

```bash
chmod +x invoke.sh
./invoke.sh build
```

⏱️ Takes ~10 minutes first time

### Step 3: Start MedRAX

```bash
./invoke.sh start
```

⏱️ First run downloads models (~5-10 minutes)

🎉 **Done!** Open: **http://localhost:11180**

---

## 🎮 Using MedRAX

1. **Upload X-ray**: Click "📎 Upload X-Ray" or "📄 Upload DICOM"
2. **Ask questions**: Type in chat box
   - "What abnormalities do you see?"
   - "Generate a medical report"
   - "Is there pneumonia?"
3. **Get results**: AI analyzes and responds

---

## 🛠️ Common Commands

```bash
./invoke.sh start      # Start MedRAX
./invoke.sh stop       # Stop MedRAX
./invoke.sh restart    # Restart
./invoke.sh logs       # View logs
./invoke.sh status     # Check if running
```

---

## 🐛 Quick Fixes

### "OPENAI_API_KEY is not set"
```bash
# Check your .env file
cat .env | grep OPENAI_API_KEY

# Should look like:
OPENAI_API_KEY=sk-xxx    # ✅ Correct
# NOT:
OPENAI_API_KEY = sk-xxx  # ❌ Wrong (spaces)
```

### "Permission denied" errors
```bash
./invoke.sh stop
chmod -R 777 model-cache model-weights temp logs
./invoke.sh start
```

### "Port 11180 already in use"
```bash
# Find what's using it
lsof -i :11180

# Or change port in invoke.sh
nano invoke.sh
# Change: HOST_PORT=11180 → HOST_PORT=8080
```

### "No NVIDIA driver found" (GPU errors)
```bash
# Option 1: Use CPU mode instead
DEVICE=cpu ./invoke.sh start

# Option 2: Install nvidia-docker
# Follow: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
```

### Container crashes or won't start
```bash
# Check logs first
./invoke.sh logs

# Common fixes:
./invoke.sh restart    # Try restart
chmod -R 777 model-cache model-weights  # Fix permissions
DEVICE=cpu ./invoke.sh start  # Use CPU if GPU issues
```

---

## ⚡ Speed Up Startup (Optional)

**Problem:** First run takes 10+ minutes downloading models.

**Solution:** Pre-download models once, reuse forever.

```bash
# 1. Download models to host (one time, ~10-30 min)
chmod +x download-models.sh
./download-models.sh

# 2. Configure cache
echo "MODEL_CACHE_DIR=./model-cache" >> .env

# 3. Fix permissions
chmod -R 777 model-cache

# 4. Restart
./invoke.sh restart

# Now starts in ~30 seconds instead of ~10 minutes!
# Models persist even after container rebuilds.
```

---

## 💡 Tips

### Use CPU (No GPU Required)
```bash
# Edit .env
DEVICE=cpu

# Or run directly
DEVICE=cpu ./invoke.sh start
```

### Use Local LLM (No OpenAI Cost)

**Ollama:**
```bash
# 1. Install Ollama: https://ollama.com/
# 2. Start it: ollama serve
# 3. Pull model: ollama pull llama3.2-vision
# 4. Edit .env:
OPENAI_BASE_URL=http://host.docker.internal:11434/v1
OPENAI_API_KEY=ollama
MODEL=llama3.2-vision
```

**Chinese Users (Qwen):**
```bash
# Edit .env:
OPENAI_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
OPENAI_API_KEY=sk-your-dashscope-key
MODEL=qwen3-vl-235b-a22b-instruct
```

### Change Model
```bash
# Edit .env:
MODEL=gpt-4o-mini    # Cheaper
# or
MODEL=gpt-4o         # Better quality (default)
```

---

## 📊 What Happens on First Start?

```
1. Container starts           ✓ (~30 sec)
2. Models download            ⏳ (~5-10 min, one time only)
   - DenseNet-121
   - PSPNet
   - SwinV2
   - CheXagent
   - Others
3. Server starts              ✓ (~10 sec)
4. Ready to use!              🎉
```

Monitor progress: `./invoke.sh logs`

---

## 🆘 Still Having Issues?

1. **Check logs**: `./invoke.sh logs`
2. **Fix permissions**: `chmod -R 777 model-cache model-weights temp logs`
3. **Verify setup**: `./verify-setup.sh` (if available)
4. **Try CPU mode**: `DEVICE=cpu ./invoke.sh start`
5. **Restart fresh**: `./invoke.sh stop && ./invoke.sh start`

---

## 📁 File Locations

```
your-project/
├── temp/              # Temp files (auto-cleared)
├── logs/              # Error logs
├── model-cache/       # Downloaded models (~5-10 GB)
├── model-weights/     # Additional weights
├── .env               # YOUR API KEY (don't share!)
└── invoke.sh          # Management script
```

**Important:** Never share your `.env` file - it contains your API key!

---

## 🎯 Quick Reference

```bash
# First Time Setup
cp .env.example .env          # Create config
nano .env                     # Add API key
./invoke.sh build             # Build (~10 min)
./invoke.sh start             # Start (~5-10 min first run)

# Daily Use
./invoke.sh start             # Start
# Use: http://localhost:11180
./invoke.sh stop              # Stop when done

# Troubleshooting
./invoke.sh logs              # Check errors
./invoke.sh restart           # Try restart
chmod -R 777 model-cache model-weights  # Fix permissions
```

---

## 📚 More Help

- **Permission errors**: See `PERMISSION_FIX.md`
- **Pre-download models**: See `PRE_DOWNLOAD_GUIDE.md`
- **Detailed docs**: See `DOCKER_SETUP.md`
- **GitHub**: https://github.com/bowang-lab/MedRAX

---

**That's it!** Just 3 steps to get started. Questions? Check the troubleshooting section above. 🚀

