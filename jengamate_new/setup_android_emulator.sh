#!/bin/bash

# JengaMate Android Emulator Setup Script
# This script sets up Android emulators in /tmp for better space management

set -e

echo "🚀 JengaMate Android Emulator Setup"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ANDROID_SDK_ROOT="/home/codespace/android-sdk"
EMULATOR_STORAGE="/tmp/android-emulators"
SYSTEM_IMAGES_DIR="$EMULATOR_STORAGE/system-images"
AVD_DIR="$EMULATOR_STORAGE/avd"

# Create directories
echo -e "${BLUE}📁 Creating emulator storage directories...${NC}"
mkdir -p "$SYSTEM_IMAGES_DIR"
mkdir -p "$AVD_DIR"

# Set environment variables
export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export ANDROID_AVD_HOME="$AVD_DIR"
export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator"

echo -e "${GREEN}✅ Directories created successfully${NC}"

# Function to check available space
check_space() {
    local dir="$1"
    local space=$(df -BG "$dir" | tail -1 | awk '{print $4}' | sed 's/G//')
    echo "$space"
}

# Check space availability
echo -e "${YELLOW}💾 Checking available space...${NC}"
tmp_space=$(check_space "/tmp")
echo "Available space in /tmp: ${tmp_space}GB"

if [ "$tmp_space" -lt 5 ]; then
    echo -e "${RED}❌ Insufficient space in /tmp (${tmp_space}GB). Need at least 5GB.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Sufficient space available${NC}"

# Download and setup system image
download_system_image() {
    local api_level="$1"
    local tag="$2"

    echo -e "${BLUE}📥 Downloading Android $api_level system image...${NC}"

    # Accept licenses
    echo "y" | sdkmanager --licenses > /dev/null 2>&1

    # Download system image
    if sdkmanager "system-images;android-$api_level;$tag;x86_64"; then
        echo -e "${GREEN}✅ System image downloaded successfully${NC}"

        # Move to external storage
        local source_dir="$ANDROID_SDK_ROOT/system-images/android-$api_level"
        local target_dir="$SYSTEM_IMAGES_DIR/android-$api_level"

        if [ -d "$source_dir" ]; then
            echo -e "${BLUE}📦 Moving system image to external storage...${NC}"
            mv "$source_dir" "$target_dir"
            ln -sf "$target_dir" "$ANDROID_SDK_ROOT/system-images/android-$api_level"
            echo -e "${GREEN}✅ System image moved to external storage${NC}"
        fi
    else
        echo -e "${RED}❌ Failed to download system image${NC}"
        return 1
    fi
}

# Create AVD
create_avd() {
    local avd_name="$1"
    local api_level="$2"
    local device="$3"

    echo -e "${BLUE}🤖 Creating AVD: $avd_name${NC}"

    if avdmanager create avd \
        --name "$avd_name" \
        --package "system-images;android-$api_level;google_apis_playstore;x86_64" \
        --device "$device" \
        --force; then

        echo -e "${GREEN}✅ AVD '$avd_name' created successfully${NC}"

        # Move AVD to external storage
        local avd_path="$HOME/.android/avd/$avd_name.avd"
        local target_path="$AVD_DIR/$avd_name.avd"

        if [ -d "$avd_path" ]; then
            echo -e "${BLUE}📦 Moving AVD to external storage...${NC}"
            mv "$avd_path" "$target_path"
            # Update AVD config to point to new location
            sed -i "s|$avd_path|$target_path|g" "$AVD_DIR/$avd_name.ini"
            echo -e "${GREEN}✅ AVD moved to external storage${NC}"
        fi
    else
        echo -e "${RED}❌ Failed to create AVD${NC}"
        return 1
    fi
}

# Main setup
main() {
    echo -e "${BLUE}🔧 Starting Android emulator setup...${NC}"

    # Download Android 34 system image
    if download_system_image "34" "google_apis_playstore"; then
        # Create Pixel 7 AVD
        create_avd "JengaMate_Pixel7" "34" "pixel_7"
    fi

    echo -e "${GREEN}🎉 Setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Available AVDs:${NC}"
    avdmanager list avd

    echo ""
    echo -e "${YELLOW}🚀 To start the emulator:${NC}"
    echo "  emulator -avd JengaMate_Pixel7 -no-window -gpu swiftshader_indirect"
    echo ""
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "  - Emulators are stored in /tmp (ephemeral)"
    echo "  - Run this script each session to recreate emulators"
    echo "  - Use 'emulator -list-avds' to see available emulators"
}

# Run main function
main "$@"