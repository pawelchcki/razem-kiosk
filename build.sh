#!/bin/bash
set -e

# Razem Kiosk Image Builder
# Wrapper script to simplify building custom Raspberry Pi OS image with kiosk system

# Show usage
show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -f, --fedora Build Fedora IoT image instead of Raspberry Pi OS"
  echo "  -y, --yes    Skip confirmation prompt"
  echo "  -h, --help   Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0           # Build Raspberry Pi OS image (interactive)"
  echo "  $0 -y        # Build Raspberry Pi OS image (non-interactive)"
  echo "  $0 --fedora  # Build Fedora IoT image (interactive)"
  echo "  $0 -f -y     # Build Fedora IoT image (non-interactive)"
}

# Parse arguments
SKIP_CONFIRM=false
FEDORA_BUILD=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--fedora)
      FEDORA_BUILD=true
      shift
      ;;
    -y|--yes)
      SKIP_CONFIRM=true
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

# Route to Fedora build if requested
if [ "$FEDORA_BUILD" = true ]; then
  echo "Building Fedora IoT image..."
  if [ "$SKIP_CONFIRM" = true ]; then
    exec ./build-fedora.sh --non-interactive
  else
    exec ./build-fedora.sh
  fi
fi

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

# Clean previous builds
echo "Cleaning previous build artifacts..."
rm -rf work deploy

# Copy configuration
echo "Copying build configuration..."
cp ../build-config/config ./config

# Create symlink to custom stage
echo "Linking custom kiosk stage..."
rm -f stage-kiosk
ln -sf ../build-config/stage-kiosk ./stage-kiosk

# Build the image
echo ""
echo "Building image (this will take a while)..."
echo "You can monitor progress in pi-gen/work/ directory"
echo ""

if [ "$BUILD_METHOD" = "docker" ]; then
    # Use Docker build (recommended)
    ./build-docker.sh
else
    # Use native build
    sudo ./build.sh
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
