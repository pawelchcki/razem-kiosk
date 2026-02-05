#!/bin/bash
# Verification script to check if build setup is complete

echo "Verifying Razem Kiosk Build Setup"
echo "=================================="
echo ""

EXIT_CODE=0

# Check pi-gen submodule
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

# Check build script
echo ""
echo "Checking build script..."
if [ -f "build.sh" ] && [ -x "build.sh" ]; then
    echo "  ✓ build.sh exists and is executable"
else
    echo "  ✗ build.sh missing or not executable"
    EXIT_CODE=1
fi

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
    echo "Ready to build image:"
    echo "  ./build.sh"
else
    echo "✗ Some checks failed"
    echo ""
    echo "Please fix the issues above before building."
fi

exit $EXIT_CODE
