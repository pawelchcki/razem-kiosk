#!/bin/bash -e

# Install required packages for kiosk display
# fbi - framebuffer image viewer
# kbd - keyboard utilities for console
apt-get install -y fbi kbd

# Clean up to reduce image size
apt-get clean
