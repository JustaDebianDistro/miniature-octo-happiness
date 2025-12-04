{
  description = "🐙 Miniature Octo Happiness";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    zig.url = "github:mitchellh/zig-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
      {
        devShells.x86_64-linux.testing = pkgs.mkShell{
          NODE_ENV = "testing";
          packages = [pkgs.zig pkgs.sdl2 ];
          shellHook = ''echo "zig + sdl2 loaded"'';
        };
      };

}
