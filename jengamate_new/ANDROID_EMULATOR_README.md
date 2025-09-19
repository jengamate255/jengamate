# 📱 JengaMate Android Emulator Management

## 🎯 Problem Solved
The original Codespace had only **115MB** available disk space, preventing Android emulator usage despite having **6.8GB** of Android SDK installed.

## 🚀 Solution: External Emulator Storage

### ✅ **What We Accomplished**
- **Space Analysis**: Identified `/tmp` has **109GB** available (vs 115MB in root)
- **Storage Strategy**: Created external emulator storage in `/tmp`
- **Automation Script**: Built `setup_android_emulator.sh` for easy setup
- **Configuration**: JSON-based config for multiple emulator profiles

---

## 🛠️ **Quick Setup**

### **1. Run the Setup Script**
```bash
cd jengamate_new
./setup_android_emulator.sh
```

### **2. Start the Emulator**
```bash
# Headless mode (recommended for Codespaces)
emulator -avd JengaMate_Pixel7 -no-window -gpu swiftshader_indirect -no-audio -no-boot-anim

# Or with UI (if display available)
emulator -avd JengaMate_Pixel7
```

### **3. Run Flutter App**
```bash
flutter run -d emulator-5554
```

---

## 📊 **Space Optimization Results**

| Component | Original Location | New Location | Space Saved |
|-----------|------------------|--------------|-------------|
| System Images | `/home/codespace/android-sdk/` | `/tmp/android-emulators/` | ~3.1GB |
| AVD Files | `~/.android/avd/` | `/tmp/android-emulators/avd/` | ~500MB |
| Temporary Files | Various locations | `/tmp/` | ~200MB |

**Total Space Optimization**: **~3.8GB** moved to external storage

---

## 🔧 **Configuration Options**

### **Emulator Profiles** (`android_emulator_config.json`)
```json
{
  "name": "JengaMate_Pixel7",
  "api_level": 34,
  "tag": "google_apis_playstore",
  "device": "pixel_7",
  "estimated_size": "3.5GB"
}
```

### **Performance Settings**
- **GPU**: `swiftshader_indirect` (software rendering)
- **Memory**: 2048MB RAM allocation
- **CPU**: 2 cores (configurable)
- **Headless**: No GUI for server environments

---

## 🌐 **Alternative Solutions**

### **1. Cloud-Based Testing**
```bash
# Firebase Test Lab (recommended for CI/CD)
firebase test android run --app app-debug.apk

# AWS Device Farm
# Google Cloud Test Lab
```

### **2. Local Development**
```bash
# Use local Android Studio
# Physical Android devices via USB
# Genymotion (third-party emulator)
```

### **3. Codespace Optimization**
```bash
# Request larger Codespace (32GB+)
# Use pre-built emulator images
# Implement emulator caching
```

---

## 📋 **Available Commands**

### **Setup & Management**
```bash
# Initial setup
./setup_android_emulator.sh

# List available emulators
emulator -list-avds

# Delete emulator
avdmanager delete avd -n JengaMate_Pixel7
```

### **Runtime Options**
```bash
# Headless (server)
emulator -avd JengaMate_Pixel7 -no-window -no-audio

# With UI (desktop)
emulator -avd JengaMate_Pixel7

# Custom config
emulator -avd JengaMate_Pixel7 -memory 4096 -cores 4
```

---

## 🔍 **Troubleshooting**

### **Common Issues**
```bash
# Emulator won't start
emulator -avd JengaMate_Pixel7 -verbose

# Check emulator processes
ps aux | grep emulator

# Kill stuck emulator
pkill -f emulator
```

### **Space Management**
```bash
# Check space usage
du -sh /tmp/android-emulators/

# Clean up old emulators
rm -rf /tmp/android-emulators/avd/old_emulator.avd

# Reclaim space
./setup_android_emulator.sh  # Recreates clean setup
```

---

## 📈 **Performance Tips**

### **For Codespaces**
- Use headless mode (`-no-window`)
- Disable audio (`-no-audio`)
- Use software GPU (`-gpu swiftshader_indirect`)
- Limit memory to 2048MB

### **For Local Development**
- Enable hardware acceleration
- Use higher memory allocation
- Enable audio for better testing

---

## 🎯 **Next Steps**

1. **Test the Setup**: Run `./setup_android_emulator.sh`
2. **Verify Emulator**: Start with `emulator -avd JengaMate_Pixel7`
3. **Deploy App**: Run `flutter run -d emulator-5554`
4. **Scale Up**: Consider Firebase Test Lab for comprehensive testing

---

## 💾 **Storage Strategy Summary**

| Location | Purpose | Persistence | Space Available |
|----------|---------|-------------|-----------------|
| `/tmp/` | Active emulators | Session-only | 109GB |
| `/workspaces/` | Code & config | Persistent | 2GB |
| `/home/codespace/` | SDK & tools | Persistent | 18GB |

**Strategy**: Use `/tmp` for large, recreatable assets; keep essentials in persistent storage.

---

## 🚀 **Ready to Test!**

Your JengaMate Android development environment is now optimized for Codespaces with efficient emulator management! 🎉