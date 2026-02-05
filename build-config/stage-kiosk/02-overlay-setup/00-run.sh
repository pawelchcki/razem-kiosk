#!/bin/bash -e

# Overlay filesystem setup script
# Pre-configures the system for overlay mode (disabled by default)
# Users can enable it after adding their images using: sudo kiosk-overlay enable

on_chroot << EOF
# Create symlink for easy overlay management
ln -sf /opt/kiosk/scripts/overlayfs-setup.sh /usr/local/bin/kiosk-overlay

# Configure tmpfs mounts in fstab for when overlay is enabled
# These will only be active when overlay mode is enabled
cat >> /etc/fstab <<FSTAB

# Tmpfs mounts for overlay mode (active when enabled)
tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100m 0 0
tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=100m 0 0
tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=50m 0 0
FSTAB

# Create a README in /opt/kiosk explaining overlay mode
cat > /opt/kiosk/README.txt <<README
Razem Kiosk Display System
==========================

This Raspberry Pi is configured as a kiosk image viewer.

Getting Started:
1. Add your images to /opt/kiosk/images/ directory
2. Supported formats: JPG, PNG, BMP, GIF
3. Images will be displayed in alphabetical order

Keyboard Controls:
- Right Arrow / Space: Next image
- Left Arrow: Previous image
- Home: First image
- End: Last image
- Q / Escape: Exit viewer (will auto-restart via systemd)

Management Commands:
- View logs: sudo journalctl -u kiosk-display.service
- Restart viewer: sudo systemctl restart kiosk-display.service
- Check status: sudo systemctl status kiosk-display.service

Read-Only Filesystem Protection:
For power-loss protection, enable overlay filesystem mode:
- Enable: sudo kiosk-overlay enable
- Disable: sudo kiosk-overlay disable
- Status: sudo kiosk-overlay status

Note: Enable overlay AFTER adding all your images, as the filesystem
becomes read-only. To add more images later, disable overlay first.

Default credentials: pi / raspberry
PLEASE CHANGE THE PASSWORD: passwd

For more information, see: https://github.com/razem-io/kiosk
README

chown ${FIRST_USER_NAME}:${FIRST_USER_NAME} /opt/kiosk/README.txt

# Add helpful message to login prompt
cat > /etc/profile.d/kiosk-motd.sh <<MOTD
#!/bin/bash
if [ "\\\$(tty)" != "/dev/tty1" ] && [ -n "\\\$SSH_CONNECTION" ]; then
    echo ""
    echo "Welcome to Razem Kiosk Display System"
    echo "======================================"
    echo ""
    echo "Quick commands:"
    echo "  cat /opt/kiosk/README.txt  - View full documentation"
    echo "  sudo kiosk-overlay enable  - Enable read-only protection"
    echo "  sudo systemctl status kiosk-display.service - Check viewer status"
    echo ""
fi
MOTD

chmod +x /etc/profile.d/kiosk-motd.sh

EOF

echo "Overlay filesystem pre-configuration completed"
