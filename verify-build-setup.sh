#!/bin/bash
# Verification script to check if build setup is complete

# Parse arguments
FEDORA_CHECK=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--fedora)
      FEDORA_CHECK=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -f, --fedora  Verify Fedora IoT build environment"
      echo "  -h, --help    Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ "$FEDORA_CHECK" = true ]; then
  echo "Verifying Fedora IoT Build Environment"
else
  echo "Verifying Raspberry Pi OS Build Setup"
fi
echo "=================================="
echo ""

EXIT_CODE=0

if [ "$FEDORA_CHECK" = true ]; then
    # Fedora IoT specific checks
    echo "Checking Fedora IoT build requirements..."

    if command -v podman &> /dev/null; then
        PODMAN_VERSION=$(podman --version)
        echo "  ✓ podman found: $PODMAN_VERSION"
    else
        echo "  ✗ podman not found"
        echo "    Install: sudo dnf install podman"
        EXIT_CODE=1
    fi

    if command -v xz &> /dev/null; then
        echo "  ✓ xz compression tool found"
    else
        echo "  ✗ xz not found"
        echo "    Install: sudo dnf install xz"
        EXIT_CODE=1
    fi

    # Check Fedora build configuration
    echo ""
    echo "Checking Fedora build configuration..."
    if [ -f "build-config-fedora/config" ]; then
        echo "  ✓ build-config-fedora/config exists"
    else
        echo "  ✗ build-config-fedora/config missing"
        EXIT_CODE=1
    fi

    if [ -f "build-config-fedora/Containerfile" ]; then
        echo "  ✓ build-config-fedora/Containerfile exists"
    else
        echo "  ✗ build-config-fedora/Containerfile missing"
        EXIT_CODE=1
    fi

    # Check build script
    echo ""
    echo "Checking Fedora build script..."
    if [ -f "build-fedora.sh" ] && [ -x "build-fedora.sh" ]; then
        echo "  ✓ build-fedora.sh exists and is executable"
    else
        echo "  ✗ build-fedora.sh missing or not executable"
        EXIT_CODE=1
    fi
else
    # Raspberry Pi OS specific checks
    echo "Checking pi-gen submodule..."
    if [ -e "pi-gen/.git" ] && [ -f "pi-gen/build.sh" ]; then
        echo "  ✓ pi-gen submodule present"
    else
        echo "  ✗ pi-gen submodule missing"
        EXIT_CODE=1
    fi

    # Check build configuration
    echo ""
    echo "Checking build configuration..."
    if [ -f "build-config/config" ]; then
        echo "  ✓ build-config/config exists"
    else
        echo "  ✗ build-config/config missing"
        EXIT_CODE=1
    fi

    # Check stage-kiosk structure
    echo ""
    echo "Checking stage-kiosk structure..."
    REQUIRED_FILES=(
        "build-config/stage-kiosk/prerun.sh"
        "build-config/stage-kiosk/00-packages/00-packages.sh"
        "build-config/stage-kiosk/01-kiosk-setup/00-run.sh"
        "build-config/stage-kiosk/02-overlay-setup/00-run.sh"
    )

    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$file" ]; then
            echo "  ✓ $file"
        else
            echo "  ✗ $file missing"
            EXIT_CODE=1
        fi
    done

    # Check build script
    echo ""
    echo "Checking build script..."
    if [ -f "build.sh" ] && [ -x "build.sh" ]; then
        echo "  ✓ build.sh exists and is executable"
    else
        echo "  ✗ build.sh missing or not executable"
        EXIT_CODE=1
    fi
fi

# Check image-files structure
echo ""
echo "Checking image-files structure..."
IMAGE_FILES=(
    "image-files/opt/kiosk/scripts/image-viewer.sh"
    "image-files/opt/kiosk/scripts/overlayfs-setup.sh"
    "image-files/etc/systemd/system/kiosk-display.service"
)

for file in "${IMAGE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file missing"
        EXIT_CODE=1
    fi
done


# Check documentation
echo ""
echo "Checking documentation..."
if [ -f "docs/building.md" ]; then
    echo "  ✓ docs/building.md exists"
else
    echo "  ✗ docs/building.md missing"
    EXIT_CODE=1
fi

if [ -f "docs/installation.md" ]; then
    echo "  ✓ docs/installation.md exists"
else
    echo "  ✗ docs/installation.md missing"
    EXIT_CODE=1
fi

# Check .gitignore
echo ""
echo "Checking .gitignore..."
if [ -f ".gitignore" ]; then
    if grep -q "pi-gen/work/" .gitignore; then
        echo "  ✓ .gitignore configured for build artifacts"
    else
        echo "  ✗ .gitignore missing build artifact entries"
        EXIT_CODE=1
    fi
else
    echo "  ✗ .gitignore missing"
    EXIT_CODE=1
fi

# Summary
echo ""
echo "=================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ All checks passed!"
    echo ""
    if [ "$FEDORA_CHECK" = true ]; then
        echo "Ready to build Fedora IoT image:"
        echo "  ./build.sh --fedora"
        echo "  or"
        echo "  ./build-fedora.sh"
    else
        echo "Ready to build Raspberry Pi OS image:"
        echo "  ./build.sh"
    fi
else
    echo "✗ Some checks failed"
    echo ""
    echo "Please fix the issues above before building."
fi

exit $EXIT_CODE
