#!/bin/bash
set -e

# Fedora IoT Kiosk Image Builder
# Uses Containerfile-based customization with bootc-image-builder

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load configuration
if [ -f build-config-fedora/config ]; then
    source build-config-fedora/config
else
    echo "ERROR: Configuration file build-config-fedora/config not found"
    exit 1
fi

# Command line arguments
BUILD_ONLY=0
NON_INTERACTIVE=0

for arg in "$@"; do
    case $arg in
        --build-only)
            BUILD_ONLY=1
            shift
            ;;
        --non-interactive)
            NON_INTERACTIVE=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --build-only          Only build container, skip image creation"
            echo "  --non-interactive     Run without user prompts"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
    esac
done

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
echo_info "Checking prerequisites..."

if ! command -v podman &> /dev/null; then
    echo_error "podman is not installed. Install it with: sudo dnf install podman"
    exit 1
fi

if ! command -v xz &> /dev/null; then
    echo_warn "xz is not installed. Compression will be skipped."
    COMPRESS_XZ=0
fi

# Check disk space (need at least 10GB free)
AVAILABLE_SPACE=$(df -BG "$SCRIPT_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 10 ]; then
    echo_error "Insufficient disk space. Need at least 10GB free, have ${AVAILABLE_SPACE}GB"
    exit 1
fi

# Generate image filename with timestamp
IMAGE_DATE=$(date +%Y-%m-%d)
IMAGE_TIME=$(date +%H%M%S)
OUTPUT_NAME="${IMAGE_NAME}-${IMAGE_DATE}"
CONTAINER_TAG="${CONTAINER_NAME}:${IMAGE_DATE}-${IMAGE_TIME}"

echo_info "Build Configuration:"
echo "  Image name: ${OUTPUT_NAME}"
echo "  Container tag: ${CONTAINER_TAG}"
echo "  Base image: ${BASE_IMAGE}"
echo "  Architecture: ${ARCH}"
echo "  Output directory: ${OUTPUT_DIR}"
echo ""

# Confirmation prompt
if [ $NON_INTERACTIVE -eq 0 ]; then
    read -p "Continue with build? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Build cancelled."
        exit 0
    fi
fi

# Build container image
echo_info "Building container image from Containerfile..."
echo_info "This may take 10-20 minutes..."

if ! podman build --isolation=chroot -f build-config-fedora/Containerfile -t "${CONTAINER_TAG}" -t "${CONTAINER_NAME}:latest" .; then
    echo_error "Container build failed"
    exit 1
fi

echo_info "Container image built successfully: ${CONTAINER_TAG}"

# Exit if build-only mode
if [ $BUILD_ONLY -eq 1 ]; then
    echo_info "Build-only mode: Skipping image creation"
    echo_info "Container image: ${CONTAINER_TAG}"
    echo_info "To create bootable image, run: $0 (without --build-only)"
    exit 0
fi

# Create bootable image using bootc-image-builder
echo_info "Creating bootable raw disk image..."
echo_info "This may take 15-30 minutes..."

# Clean and create output directory
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Run bootc-image-builder
# Note: Requires privileged mode and access to container storage
if ! podman run --rm --privileged \
    -v "${SCRIPT_DIR}/${OUTPUT_DIR}:/output" \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type "${OUTPUT_TYPE}" \
    "${CONTAINER_TAG}"; then
    echo_error "Image creation failed"
    exit 1
fi

# Check if disk.raw was created
if [ ! -f "${OUTPUT_DIR}/disk.raw" ]; then
    echo_error "Expected output file disk.raw not found in ${OUTPUT_DIR}/"
    echo "Contents of ${OUTPUT_DIR}:"
    ls -la "${OUTPUT_DIR}/"
    exit 1
fi

echo_info "Raw disk image created successfully"

# Get image size
RAW_SIZE=$(du -h "${OUTPUT_DIR}/disk.raw" | cut -f1)
echo_info "Raw image size: ${RAW_SIZE}"

# Compress image
if [ $COMPRESS_XZ -eq 1 ]; then
    echo_info "Compressing image with xz (level ${XZ_LEVEL})..."
    echo_info "This may take 10-20 minutes..."

    if ! xz -${XZ_LEVEL} -T${XZ_THREADS} -v "${OUTPUT_DIR}/disk.raw"; then
        echo_error "Compression failed"
        exit 1
    fi

    COMPRESSED_SIZE=$(du -h "${OUTPUT_DIR}/disk.raw.xz" | cut -f1)
    echo_info "Compressed image size: ${COMPRESSED_SIZE}"

    # Move to project root with descriptive name
    mv "${OUTPUT_DIR}/disk.raw.xz" "${OUTPUT_NAME}.raw.xz"
    FINAL_IMAGE="${OUTPUT_NAME}.raw.xz"
else
    # Move uncompressed image
    mv "${OUTPUT_DIR}/disk.raw" "${OUTPUT_NAME}.raw"
    FINAL_IMAGE="${OUTPUT_NAME}.raw"
fi

# Cleanup output directory
rm -rf "${OUTPUT_DIR}"

# Build complete
echo ""
echo_info "=========================================="
echo_info "Build completed successfully!"
echo_info "=========================================="
echo ""
echo_info "Output image: ${FINAL_IMAGE}"
echo_info "Image size: $(du -h "${FINAL_IMAGE}" | cut -f1)"
echo ""
echo_info "Next steps:"
echo "  1. Flash to SD card (8GB minimum):"
if [ $COMPRESS_XZ -eq 1 ]; then
    echo "     xz -d ${FINAL_IMAGE}"
    echo "     sudo dd if=${OUTPUT_NAME}.raw of=/dev/sdX bs=4M status=progress conv=fsync"
else
    echo "     sudo dd if=${FINAL_IMAGE} of=/dev/sdX bs=4M status=progress conv=fsync"
fi
echo "  2. Boot Raspberry Pi 3+ or Pi 4"
echo "  3. Login: pi / raspberry"
echo "  4. View service status: systemctl status kiosk-display.service"
echo ""
echo_info "Container image: ${CONTAINER_TAG}"
echo_info "To rebuild image from container: podman run ... ${CONTAINER_TAG}"
echo ""
