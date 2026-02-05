#!/bin/bash -e

# Stage dependencies for stage-kiosk
# This stage requires stage0, stage1, and stage2 to be completed first

# These stages provide:
# - stage0: Bootstrap the base system
# - stage1: Add essential packages and configuration
# - stage2: Install networking and basic utilities

echo "stage-kiosk: Dependencies satisfied (stage0, stage1, stage2)"
