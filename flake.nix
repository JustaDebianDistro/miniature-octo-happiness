{
  description = "🐙 Miniature Octo Happiness";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      zig = import ./nix/zig-module.nix {inherit pkgs;};
    in
      {
      #  devShells = {
      #    default = zig.shells.buildmode;

      #  };
        devShells.x86_64-linux = zig.devShells.x86_64-linux;
#        devShells.x86_64-linux.testing = pkgs.mkShell{
#          NODE_ENV = "testing";
#          packages = [pkgs.zig_0_12 pkgs.SDL2 pkgs.pkg-config ];
#          shellHook = ''echo "zig + sdl2 loaded"'';
#        };
      };

}
