{
  description = "Razem Kiosk - Raspberry Pi Display System";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, nixpkgs, flake-utils, treefmt-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      {
        # Formatting configuration
        formatter = treefmtEval.config.build.wrapper;

        # Check formatting
        checks = {
          formatting = treefmtEval.config.build.check self;
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Formatting tools
            treefmtEval.config.build.wrapper

            # Build tools
            git
            docker

            # Shell script tools
            shellcheck
            shfmt

            # Documentation tools
            mdformat

            # Nix tools
            nixfmt-rfc-style
          ];

          shellHook = ''
            echo "Razem Kiosk Development Environment"
            echo "===================================="
            echo ""
            echo "Available commands:"
            echo "  treefmt          - Format all files"
            echo "  shellcheck *.sh  - Lint shell scripts"
            echo "  ./build.sh       - Build kiosk image (requires Docker)"
            echo ""
            echo "Run 'treefmt' to format all files before committing."
          '';
        };

        # Build the image (placeholder - actual build requires Docker)
        packages.default = pkgs.writeShellScriptBin "build-kiosk-image" ''
          echo "Building Razem Kiosk image..."
          echo "This requires Docker to be running."
          exec ${./build.sh}
        '';
      }
    );
}
