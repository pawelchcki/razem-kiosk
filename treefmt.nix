{
  # Used to find the project root
  projectRootFile = "flake.nix";

  programs = {
    # Shell script formatting
    shfmt = {
      enable = true;
      # Options: -i 2 (indent 2 spaces), -s (simplify), -sr (space redirects)
      indent_size = 2;
    };

    # Markdown formatting
    mdformat = {
      enable = true;
    };

    # Nix formatting
    nixfmt = {
      enable = true;
      package = "nixfmt-rfc-style";
    };
  };

  # Global excludes
  settings.global.excludes = [
    # Git
    ".git/**"

    # Nix
    "result"
    "result-*"

    # pi-gen submodule
    "pi-gen/**"

    # Build artifacts
    "*.img"
    "*.img.zip"
    "*.img.xz"

    # Temporary files
    "*.log"
    "*.tmp"
    "*~"
  ];
}
