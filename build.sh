#!/bin/bash
set -e

# Razem Kiosk Image Builder
# Wrapper script to simplify building custom Raspberry Pi OS image with kiosk system

# Show usage
show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -y, --yes     Skip confirmation prompt"
  echo "  --clean       Clean work directory (start from scratch)"
  echo "  -h, --help    Show this help message"
  echo ""
  echo "Note: By default, builds continue from where they left off."
  echo "      Use --clean to start completely fresh."
  echo ""
  echo "Examples:"
  echo "  $0              # Continue previous build (interactive)"
  echo "  $0 -y           # Continue previous build (auto-confirm)"
  echo "  $0 -y --clean   # Start fresh build (auto-confirm)"
}

# Parse arguments
SKIP_CONFIRM=false
CLEAN_BUILD=false  # Default: continue from previous build
while [[ $# -gt 0 ]]; do
  case $1 in
    -y|--yes)
      SKIP_CONFIRM=true
      shift
      ;;
    --clean)
      CLEAN_BUILD=true
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
done

echo "=================================="
echo "Razem Kiosk Image Builder"
echo "=================================="
echo ""

# Check if pi-gen directory exists
if [ ! -d "pi-gen" ]; then
    echo "Error: pi-gen directory not found. Did you initialize submodules?"
    echo "Run: git submodule update --init --recursive"
    exit 1
fi

# Check if Docker is available (recommended build method)
if command -v docker &> /dev/null; then
    echo "Docker found - will use containerized build (recommended)"
    BUILD_METHOD="docker"
else
    echo "Docker not found - will use native build"
    echo "Note: Native builds require build dependencies to be installed"
    BUILD_METHOD="native"
fi

echo ""
echo "Build configuration:"
echo "  Image name: razem-kiosk"
echo "  Release: bookworm (Debian 12)"
echo "  Stages: stage0, stage1, stage2, stage-kiosk"
echo "  Build method: $BUILD_METHOD"
echo ""

# Ask for confirmation (unless -y flag is used)
if [ "$SKIP_CONFIRM" = false ]; then
    read -p "Start build? This will take 30-60 minutes. [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Build cancelled."
        exit 0
    fi
else
    echo "Auto-confirmed with -y flag. Starting build..."
fi

echo ""
echo "Starting build..."
echo ""

cd pi-gen

# Clean previous builds only if --clean flag is set
if [ "$CLEAN_BUILD" = true ]; then
    echo "Cleaning previous build artifacts (--clean specified)..."
    rm -rf work deploy stage-kiosk
else
    echo "Continuing from previous build (use --clean to start fresh)..."
    # Only remove stage-kiosk to refresh it with latest changes
    rm -rf stage-kiosk
fi

# Copy configuration
echo "Copying build configuration..."
cp ../build-config/config ./config

# Copy custom stage (not symlink, for Docker compatibility)
echo "Copying custom kiosk stage..."
rm -rf stage-kiosk
cp -r ../build-config/stage-kiosk ./stage-kiosk

# Build the image
echo ""
echo "Building image (this will take a while)..."
echo "You can monitor progress in pi-gen/work/ directory"
echo ""

if [ "$BUILD_METHOD" = "docker" ]; then
    # Use Docker build (recommended)
    if [ "$CLEAN_BUILD" = false ]; then
        # Continue from previous build
        CONTINUE=1 ./build-docker.sh
    else
        # Clean build
        ./build-docker.sh
    fi
else
    # Use native build
    if [ "$CLEAN_BUILD" = false ]; then
        CONTINUE=1 sudo ./build.sh
    else
        sudo ./build.sh
    fi
fi

# Check if build succeeded
if [ $? -eq 0 ] && [ -d "deploy" ]; then
    echo ""
    echo "=================================="
    echo "Build completed successfully!"
    echo "=================================="
    echo ""

    # Copy result to parent directory
    echo "Copying image to project root..."
    cp deploy/*.img ../
    cp deploy/*.img.zip ../ 2>/dev/null || true

    echo ""
    echo "Output files:"
    ls -lh ../razem-kiosk-*.img* | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
    echo "Next steps:"
    echo "  1. Flash image to SD card: Use Raspberry Pi Imager or dd"
    echo "  2. Boot Raspberry Pi"
    echo "  3. SSH to kiosk.local (user: pi, password: raspberry)"
    echo "  4. Add images to /opt/kiosk/images/"
    echo "  5. Enable overlay protection: sudo kiosk-overlay enable"
    echo ""
    echo "See docs/installation.md for detailed instructions"
else
    echo ""
    echo "=================================="
    echo "Build failed!"
    echo "=================================="
    echo ""
    echo "Check pi-gen/work/*/build.log for errors"
    exit 1
fi
