# Fedora IoT Kiosk - Quick Reference

## Build Commands

```bash
# Build Fedora IoT image
./build.sh --fedora              # Via main script
./build-fedora.sh                # Direct script

# Build options
./build-fedora.sh --build-only       # Container only, skip image creation
./build-fedora.sh --non-interactive  # No prompts (CI/CD)

# Verify environment
./verify-build-setup.sh --fedora
```

## System Management

### Package Management
```bash
# Install packages
sudo rpm-ostree install package-name
sudo systemctl reboot

# Upgrade system
sudo rpm-ostree upgrade
sudo systemctl reboot

# Rollback to previous version
sudo rpm-ostree rollback
sudo systemctl reboot

# Check status
rpm-ostree status
```

### Immutability
```bash
# Check immutability status
sudo kiosk-overlay status
rpm-ostree status

# Root filesystem is ALWAYS immutable on Fedora IoT
# No enable/disable commands needed
```

### Kernel Arguments
```bash
# View current kernel arguments
rpm-ostree kargs

# Add kernel argument
sudo rpm-ostree kargs --append='new_arg=value'
sudo systemctl reboot

# Remove kernel argument
sudo rpm-ostree kargs --delete='old_arg=value'
sudo systemctl reboot
```

## Kiosk Operations

### Service Management
```bash
# Check service status
sudo systemctl status kiosk-display.service

# View logs (live)
sudo journalctl -u kiosk-display.service -f

# View logs (last 50 lines)
sudo journalctl -u kiosk-display.service -n 50

# Restart service
sudo systemctl restart kiosk-display.service

# Stop service
sudo systemctl stop kiosk-display.service

# Start service
sudo systemctl start kiosk-display.service
```

### Image Management
```bash
# Add images (system is writable in /opt/kiosk/images/)
sudo cp my-images/*.jpg /opt/kiosk/images/

# Check images
ls -lh /opt/kiosk/images/

# Set permissions
sudo chmod 644 /opt/kiosk/images/*.jpg

# Remove images
sudo rm /opt/kiosk/images/old-image.jpg

# Restart to show new images
sudo systemctl restart kiosk-display.service
```

## Troubleshooting

### Check System Health
```bash
# System status
rpm-ostree status

# Service status
systemctl status kiosk-display.service

# View all logs
journalctl -xe

# Check framebuffer
ls -la /dev/fb*

# Check SELinux status
getenforce

# View SELinux denials
sudo ausearch -m avc -ts recent
```

### Fix Common Issues
```bash
# Framebuffer not found
sudo lsmod | grep vc4
echo "vc4" | sudo tee /etc/modules-load.d/vc4.conf
sudo systemctl reboot

# SELinux denials
sudo restorecon -R /opt/kiosk/

# Service fails after upgrade
sudo rpm-ostree rollback
sudo systemctl reboot

# Pending deployment stuck
rpm-ostree cleanup -p
```

## Network Configuration

### Check Network
```bash
# View network status
ip addr show

# Check hostname
hostnamectl

# Test connectivity
ping -c 4 google.com
```

### Configure WiFi (if needed)
```bash
# Using nmcli
sudo nmcli device wifi connect "SSID" password "password"

# Check connection
nmcli connection show
```

## System Information

```bash
# OS version
cat /etc/os-release

# Kernel version
uname -a

# Hardware info
cat /proc/cpuinfo | grep Model

# Memory
free -h

# Disk usage
df -h

# Temperature (if available)
vcgencmd measure_temp
```

## Container Development

### Test Container Locally
```bash
# Build container
podman build -f build-config-fedora/Containerfile -t test-kiosk .

# Run interactively
podman run -it test-kiosk /bin/bash

# Inside container:
rpm -qa | grep fbida              # Check packages
systemctl list-units              # Check services
ls -la /opt/kiosk/                # Check files
```

### Inspect Container
```bash
# List images
podman images

# Inspect image
podman inspect localhost/razem-kiosk-fedora:latest

# Remove old images
podman rmi localhost/razem-kiosk-fedora:old-tag

# Clean up
podman system prune -a
```

## Keyboard Shortcuts

### In Kiosk Display
- **Right Arrow** / **Space**: Next image
- **Left Arrow** / **Backspace**: Previous image
- **Home**: First image
- **End**: Last image
- **Q**: Exit viewer (service auto-restarts)

### System Navigation
- **Alt+F1**: Return to kiosk display (TTY1)
- **Alt+F2**: Switch to console (TTY2)
- **Alt+F3-F6**: Additional consoles
- **Ctrl+Alt+Del**: Reboot

## File Locations

```
/opt/kiosk/
├── images/              # Your images (writable)
├── logs/                # Log files (writable)
└── scripts/
    ├── image-viewer.sh
    └── overlayfs-setup.sh

/etc/systemd/system/
└── kiosk-display.service

/var/log/
└── kiosk-display.log    # Service logs

/usr/local/bin/
└── kiosk-overlay        # Symlink to overlayfs-setup.sh
```

## Important Notes

### Immutability
- Root filesystem (/) is **ALWAYS read-only** on Fedora IoT
- /var, /etc, /home are **writable**
- /opt/kiosk/images/ is **writable** (on /var)
- No need to disable overlay to update images

### Updates
- System updates require **reboot** to take effect
- Use `rpm-ostree upgrade` not `dnf upgrade`
- Can **rollback** to previous version if issues occur

### Differences from Raspberry Pi OS
- No `apt-get` → Use `rpm-ostree install`
- No `cmdline.txt` → Use `rpm-ostree kargs`
- No `boot=overlay` → Already immutable
- No `raspi-config` → Use `rpm-ostree` and config files

### SELinux
- SELinux is **enforcing** by default
- If service fails, check: `sudo ausearch -m avc -ts recent`
- Fix contexts: `sudo restorecon -R /path/`
- Avoid setting to permissive in production

## Quick Comparison

| Task | Raspberry Pi OS | Fedora IoT |
|------|----------------|------------|
| Install package | `sudo apt install pkg` | `sudo rpm-ostree install pkg && reboot` |
| Update system | `sudo apt update && upgrade` | `sudo rpm-ostree upgrade && reboot` |
| Enable overlay | `sudo kiosk-overlay enable` | Already immutable |
| Add images | Disable overlay first | Just copy files |
| Boot config | Edit cmdline.txt | `rpm-ostree kargs` |
| Rollback | Not available | `rpm-ostree rollback && reboot` |

## Getting Help

```bash
# Command help
rpm-ostree --help
podman --help
systemctl --help

# Man pages
man rpm-ostree
man systemd.service

# Online resources
# Fedora IoT: https://fedoraproject.org/iot/
# rpm-ostree: https://coreos.github.io/rpm-ostree/
# bootc: https://containers.github.io/bootc/

# Project documentation
cat docs/building-fedora.md
cat docs/installation.md
cat QUICKSTART.md
```

## Default Credentials

- **Username**: pi
- **Password**: raspberry
- **Hostname**: kiosk.local

⚠️ **Change password immediately**: `passwd`

## Support

- GitHub Issues: https://github.com/razem/razem-kiosk/issues
- Documentation: docs/
- Logs: `sudo journalctl -u kiosk-display.service`
