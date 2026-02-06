#!/bin/bash
# Fedora IoT Kiosk - Image Viewer Wrapper
# Launches fbi framebuffer image viewer with optimal settings

set -e

IMAGE_DIR="/opt/kiosk/images"
LOG_FILE="/var/log/kiosk-display.log"

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Starting Fedora IoT kiosk image viewer..."

# Check if image directory exists
if [ ! -d "$IMAGE_DIR" ]; then
    log_message "ERROR: Image directory $IMAGE_DIR does not exist"
    exit 1
fi

# Count images in directory
IMAGE_COUNT=$(find "$IMAGE_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | wc -l)

if [ "$IMAGE_COUNT" -eq 0 ]; then
    log_message "ERROR: No images found in $IMAGE_DIR"
    log_message "Please add .jpg or .png images to $IMAGE_DIR"

    # Display error message on screen
    cat > /tmp/error.txt << EOF
========================================
    FEDORA IOT KIOSK - NO IMAGES
========================================

No images found in:
$IMAGE_DIR

Please add .jpg or .png files to the
images directory and restart the service.

Commands:
  sudo cp /path/to/images/*.jpg $IMAGE_DIR/
  sudo systemctl restart kiosk-display.service

Press Ctrl+C to exit.
========================================
EOF

    # Show error indefinitely
    while true; do
        clear
        cat /tmp/error.txt
        sleep 10
    done
    exit 1
fi

log_message "Found $IMAGE_COUNT image(s) in $IMAGE_DIR"

# Find framebuffer device (robust detection for Fedora IoT)
FB_DEVICE="/dev/fb0"
if [ ! -e "$FB_DEVICE" ]; then
    log_message "WARNING: /dev/fb0 not found, searching for alternative framebuffer device..."

    # Search for any framebuffer device
    FB_DEVICE=$(find /dev -name 'fb*' -type c 2>/dev/null | head -1)

    if [ -z "$FB_DEVICE" ]; then
        log_message "ERROR: No framebuffer device found"
        log_message "Available devices in /dev:"
        ls -la /dev/fb* 2>&1 | tee -a "$LOG_FILE" || log_message "No /dev/fb* devices found"

        log_message "Checking if VC4 graphics driver is loaded..."
        if ! lsmod | grep -q vc4; then
            log_message "ERROR: VC4 graphics driver not loaded"
            log_message "To fix, add 'vc4' to /etc/modules-load.d/vc4.conf and reboot"
        fi

        exit 1
    fi

    log_message "Using alternative framebuffer device: $FB_DEVICE"
fi

# Detect framebuffer resolution
FB_SYS_PATH="/sys/class/graphics/$(basename $FB_DEVICE)/virtual_size"
if [ -f "$FB_SYS_PATH" ]; then
    FB_RES=$(cat "$FB_SYS_PATH")
    log_message "Framebuffer resolution: $FB_RES"
else
    log_message "Framebuffer device: $FB_DEVICE (resolution unknown)"
fi

# Check if fbi is installed
if ! command -v fbi &> /dev/null; then
    log_message "ERROR: fbi command not found"
    log_message "Install with: sudo rpm-ostree install fbida && sudo systemctl reboot"
    exit 1
fi

# Disable console blanking
setterm -blank 0 -powerdown 0 -powersave off 2>/dev/null || true

# Hide cursor
setterm -cursor off 2>/dev/null || true

# Clear screen
clear

log_message "Launching fbi image viewer..."
log_message "Framebuffer device: $FB_DEVICE"

# Launch fbi with optimal parameters
# --noverbose: Hide status messages
# --autozoom: Auto-scale images to fit screen
# --nocomments: Hide EXIF data
# --timeout 0: No auto-advance (manual navigation only)
# -T 1: Use console (framebuffer)
# -a: Auto-zoom (fit to screen)
# -u: Hide FBI info
# --device: Specify framebuffer device

exec fbi \
    --noverbose \
    --autozoom \
    --nocomments \
    --timeout 0 \
    -T 1 \
    -a \
    -u \
    --device "$FB_DEVICE" \
    "$IMAGE_DIR"/*.{jpg,jpeg,png,JPG,JPEG,PNG} 2>&1 | tee -a "$LOG_FILE"
