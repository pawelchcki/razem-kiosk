# Build Environment Requirements

## Raspberry Pi OS Image

**Works on any system with Docker:**
- Linux (any distribution)
- macOS with Docker Desktop
- Windows with Docker Desktop or WSL2
- Build time: 30-60 minutes

```bash
./build.sh
```

**Requirements:**
- Docker or Podman
- 10GB free disk space
- 4GB RAM (8GB recommended)

## Fedora IoT Image

⚠️ **Requires native Linux environment**

### ✅ Supported Build Environments

1. **Fedora Linux 39+** (Recommended)
   ```bash
   sudo dnf install podman buildah xz
   ./build-fedora.sh
   ```

2. **RHEL/CentOS Stream 9+**
   ```bash
   sudo dnf install podman buildah xz
   ./build-fedora.sh
   ```

3. **Ubuntu 22.04+** (with recent Podman)
   ```bash
   sudo apt install podman buildah xz-utils
   ./build-fedora.sh
   ```

4. **GitHub Actions** (Linux runners)
   - Native Linux environment
   - Works perfectly for CI/CD
   - See `.github/workflows/build-fedora.yml` example

### ❌ NOT Supported

1. **WSL2** (Windows Subsystem for Linux)
   - rpm-ostree conflicts with podman mounts
   - See `.claude/BUILD_LIMITATION_WSL2.md` for details

2. **macOS** with Docker Desktop
   - rpm-ostree compatibility issues
   - Limited support for ostree

3. **Windows** (native)
   - Linux-only build process

### Requirements

- **OS**: Native Linux (Fedora/RHEL preferred)
- **Podman**: 4.0+
- **Disk**: 15GB free
- **RAM**: 4GB minimum (8GB recommended)
- **Time**: 20-40 minutes

## Quick Environment Check

```bash
# Check your environment
./verify-build-setup.sh --fedora
```

**If you see:**
- ✅ "All checks passed!" → You can build
- ❌ Errors about podman/tools → Install missing tools
- ❌ WSL2 detected → Use alternative environment

## Workaround for WSL2 Users

If you're on Windows/WSL2 and need to build Fedora images:

### Option 1: Fedora VM
1. Install VirtualBox/VMware/Hyper-V
2. Create Fedora 39+ VM
3. Clone repo inside VM
4. Build there

### Option 2: GitHub Actions
1. Push code to GitHub
2. Use GitHub Actions to build
3. Download artifact

### Option 3: Cloud Build
Use cloud-based Linux build system:
- Google Cloud Build
- AWS CodeBuild
- Azure Pipelines

## Summary

| Environment | Pi OS Build | Fedora Build |
|-------------|-------------|--------------|
| Linux (native) | ✅ | ✅ |
| macOS | ✅ | ❌ |
| Windows + WSL2 | ✅ | ❌ |
| Windows native | ✅ | ❌ |
| GitHub Actions | ✅ | ✅ |

**Recommendation**: For Fedora IoT builds, use **native Fedora/RHEL Linux** or **GitHub Actions**.
