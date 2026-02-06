# Using Nix with Razem Kiosk

This project includes a Nix flake for reproducible development environments and code formatting.

## Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- Optional: [direnv](https://direnv.net/) for automatic environment activation

### Enable Flakes

Add to `~/.config/nix/nix.conf` (or `/etc/nix/nix.conf`):
```
experimental-features = nix-command flakes
```

## Quick Start

### Development Shell

Enter the development shell with all tools available:

```bash
nix develop
```

This provides:
- `treefmt` - Code formatter
- `shellcheck` - Shell script linter
- `shfmt` - Shell script formatter
- `mdformat` - Markdown formatter
- `nixfmt` - Nix formatter
- `git`, `docker` - Build tools

### Automatic Environment (with direnv)

If you have direnv installed:

```bash
# Allow direnv for this project
direnv allow
```

The development environment will now activate automatically when you `cd` into the project directory.

## Code Formatting

### Format All Files

```bash
# Inside nix develop or with direnv
treefmt
```

This will format:
- Shell scripts (`.sh`) with `shfmt`
- Markdown files (`.md`) with `mdformat`
- Nix files (`.nix`) with `nixfmt`

### Check Formatting

```bash
nix flake check
```

This verifies that all files are properly formatted without making changes.

### Format with Nix (without entering shell)

```bash
nix fmt
```

## Configuration

### treefmt Configuration

Formatting rules are defined in `treefmt.nix`:

- **Shell scripts**: 2-space indentation, simplified syntax
- **Markdown**: Standard formatting
- **Nix**: RFC-style formatting

### Excluded Paths

The following are automatically excluded from formatting:
- `.git/` - Git metadata
- `pi-gen/` - Submodule (external code)
- `result*` - Nix build outputs
- `*.img`, `*.log`, `*.tmp` - Build artifacts

## Build

### Build the Image

The flake provides a package wrapper:

```bash
nix build
# Or run directly:
nix run
```

**Note:** This still requires Docker to be running, as pi-gen builds in containers.

## CI/CD Integration

This project includes a GitHub Actions workflow (`.github/workflows/nix.yml`) that automatically:

1. **Flake Check** - Verifies flake is valid and all checks pass
2. **Formatting** - Ensures code is properly formatted
3. **Dev Shell** - Validates development environment builds correctly

The workflow uses Determinate Systems actions for:
- Fast, reliable Nix installation
- Intelligent build caching (Magic Nix Cache)
- Reduced CI times through binary cache

### Running Locally

Before pushing, verify CI will pass:

```bash
# Run all checks
nix flake check

# Check formatting
nix fmt -- --check --fail-on-change

# Build dev shell
nix develop --command echo "Success"
```

## Flake Outputs

- `devShells.default` - Development environment
- `formatter` - Code formatter (treefmt)
- `checks.formatting` - Formatting verification
- `packages.default` - Build wrapper

## Updating Dependencies

Update flake inputs to latest versions:

```bash
nix flake update
```

## Troubleshooting

### "experimental features" error

Enable flakes in your Nix configuration (see Prerequisites above).

### "Git tree is dirty" warning

This warning appears when you have uncommitted changes. It's safe to ignore, but commit your changes for reproducible builds.

### Permission errors with Docker

The Nix shell doesn't automatically grant Docker permissions. Ensure your user is in the `docker` group:

```bash
sudo usermod -aG docker $USER
# Log out and back in
```

## Resources

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [treefmt-nix](https://github.com/numtide/treefmt-nix)
- [direnv](https://direnv.net/)
