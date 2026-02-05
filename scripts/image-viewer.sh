#!/bin/bash
# Raspberry Pi Kiosk - Image Viewer Wrapper
# Launches fbi framebuffer image viewer with optimal settings

set -e

IMAGE_DIR="/opt/kiosk/images"
LOG_FILE="/var/log/kiosk-display.log"

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Starting kiosk image viewer..."

# Check if image directory exists
if [ ! -d "$IMAGE_DIR" ]; then
    log_message "ERROR: Image directory $IMAGE_DIR does not exist"
    exit 1
fi

# Count images in directory
IMAGE_COUNT=$(find "$IMAGE_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wc -l)

if [ "$IMAGE_COUNT" -eq 0 ]; then
    log_message "ERROR: No images found in $IMAGE_DIR"
    log_message "Please add .jpg or .png images to $IMAGE_DIR"

    # Display error message on screen
    cat > /tmp/error.txt << EOF
========================================
    KIOSK DISPLAY ERROR
========================================

No images found in:
$IMAGE_DIR

Please add .jpg or .png files to the
images directory and restart the service.

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

# Detect framebuffer resolution
if [ -f /sys/class/graphics/fb0/virtual_size ]; then
    FB_RES=$(cat /sys/class/graphics/fb0/virtual_size)
    log_message "Framebuffer resolution: $FB_RES"
fi

# Disable console blanking
setterm -blank 0 -powerdown 0 -powersave off 2>/dev/null || true

# Hide cursor
setterm -cursor off 2>/dev/null || true

# Clear screen
clear

log_message "Launching fbi image viewer..."

# Launch fbi with optimal parameters
# --noverbose: Hide status messages
# --autozoom: Auto-scale images to fit screen
# --nocomments: Hide EXIF data
# --timeout 0: No auto-advance (manual navigation only)
# -T 1: Use console (framebuffer)
# -a: Auto-zoom (fit to screen)
# -u: Hide FBI info

exec fbi \
    --noverbose \
    --autozoom \
    --nocomments \
    --timeout 0 \
    -T 1 \
    -a \
    -u \
    --device /dev/fb0 \
    "$IMAGE_DIR"/*.{jpg,jpeg,png,JPG,JPEG,PNG} 2>&1 | tee -a "$LOG_FILE"
