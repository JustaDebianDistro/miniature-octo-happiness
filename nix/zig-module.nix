{pkgs}:
let
  zigPkgs = with pkgs; [zig_0_12 zls pkg-config SDL2];
  shellHook = ''
    echo "Zig tools loaded"
   '';
in{
#  packages = zigPkgs;
  #  zig = pkgs.zig_0_12;
  devShells.x86_64-linux.buildmode = pkgs.mkShell{
    NODE_ENV = "BuildMODE";
    packages = zigPkgs;
    # shellHook = '' echo "Zig build tools loaded" '';
    inherit shellHook;

  }; 

}
