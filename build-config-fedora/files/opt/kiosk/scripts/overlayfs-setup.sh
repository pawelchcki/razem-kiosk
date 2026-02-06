#!/bin/bash
# Fedora IoT Kiosk - Immutability Management
# Manages rpm-ostree based system immutability

set -e

echo "=== Fedora IoT Kiosk - Immutability Management ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Check if running on Fedora IoT
if ! command -v rpm-ostree &> /dev/null; then
    echo "ERROR: This script is for Fedora IoT systems only"
    echo "rpm-ostree command not found"
    exit 1
fi

# Function to show status
show_status() {
    echo "=== Fedora IoT System Status ==="
    echo ""
    echo "Immutability: ENABLED (rpm-ostree)"
    echo "Root filesystem: Read-only (always)"
    echo "Writable areas: /var, /etc, /home"
    echo ""
    echo "rpm-ostree deployment status:"
    echo ""
    rpm-ostree status
    echo ""
    echo "Kernel arguments:"
    rpm-ostree kargs
    echo ""
}

# Function to optimize system
optimize_system() {
    echo "Optimizing system for kiosk operation..."
    echo ""

    # Configure tmpfs for logs if not already configured
    echo "- Configuring tmpfs for volatile directories..."
    if ! grep -q "tmpfs /var/log tmpfs" /etc/fstab 2>/dev/null; then
        echo "tmpfs /var/log tmpfs nodev,nosuid,size=32M 0 0" >> /etc/fstab
        echo "  Added /var/log tmpfs to /etc/fstab"
    else
        echo "  /var/log tmpfs already configured"
    fi

    # Disable unnecessary services
    echo ""
    echo "- Disabling unnecessary services..."
    systemctl disable bluetooth.service 2>/dev/null || true
    systemctl disable avahi-daemon.service 2>/dev/null || true
    echo "  Services disabled"

    echo ""
    echo "System optimization complete."
    echo "Reboot for tmpfs changes to take effect: sudo systemctl reboot"
}

# Function to show info about immutability
show_info() {
    echo "=== Fedora IoT Immutability ==="
    echo ""
    echo "On Fedora IoT, the root filesystem is ALWAYS immutable via rpm-ostree."
    echo "This provides protection against corruption and allows atomic updates."
    echo ""
    echo "Key features:"
    echo "  - Root filesystem (/) is read-only"
    echo "  - /var, /etc, /home are writable"
    echo "  - System updates are atomic and can be rolled back"
    echo "  - No need to enable/disable overlay mode"
    echo ""
    echo "To make system changes:"
    echo "  - Install packages: sudo rpm-ostree install <package>"
    echo "  - Update system: sudo rpm-ostree upgrade"
    echo "  - Rollback: sudo rpm-ostree rollback"
    echo "  - All changes require reboot to take effect"
    echo ""
    echo "To update kiosk images:"
    echo "  - Images are stored in /var/opt/kiosk/images (writable)"
    echo "  - Just copy new images and restart service"
    echo "  - No need to disable immutability"
    echo ""
}

# Main menu
case "${1:-}" in
    enable)
        echo "Fedora IoT: Root filesystem is ALREADY immutable via rpm-ostree"
        echo ""
        show_status
        echo ""
        echo "No action needed - system is already protected."
        ;;
    disable)
        echo "Fedora IoT: Root filesystem immutability CANNOT be disabled"
        echo ""
        echo "This is a core feature of rpm-ostree and ensures system reliability."
        echo ""
        echo "To make system changes, use:"
        echo "  sudo rpm-ostree install <package>    # Install packages"
        echo "  sudo rpm-ostree usroverlay           # Temporary overlay (development only)"
        echo ""
        ;;
    status)
        show_status
        ;;
    optimize)
        optimize_system
        ;;
    info)
        show_info
        ;;
    *)
        show_status
        echo ""
        echo "Usage: $0 {status|info|optimize}"
        echo ""
        echo "Commands:"
        echo "  status    - Show current system and deployment status"
        echo "  info      - Show information about Fedora IoT immutability"
        echo "  optimize  - Optimize system for kiosk operation"
        echo ""
        echo "Note: 'enable' and 'disable' are not applicable on Fedora IoT"
        echo "      The system is always immutable via rpm-ostree"
        echo ""
        echo "Examples:"
        echo "  sudo $0 status     # Show system status"
        echo "  sudo $0 info       # Learn about immutability"
        echo "  sudo $0 optimize   # Configure system optimizations"
        exit 1
        ;;
esac
