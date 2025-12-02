{
  description = "3D File Browser for Orange Pi Zero 3 with Zig";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    zig2nix.url = "github:Cloudef/zig2nix";
    flake-utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    
    # For cross-compilation to ARM
    nixpkgs-cross.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, zig2nix, flake-utils, zig-overlay, nixpkgs-cross }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ zig-overlay.overlays.default ];
        };
        
        # ARM cross-compilation packages
        crossPkgs = nixpkgs-cross.legacyPackages.${system};
        
        # Zig version - using latest stable
        zig = zig-overlay.packages.${system}."0.12.0";
        
        # Development dependencies
        devDeps = with pkgs; [
          zig
          
          # x86 development (SDL/OpenGL)
          pkg-config
          cmake
          ninja
          
          # Graphics libraries (x86)
          libGL
          libglvnd
          glfw
          glew
          SDL2
          
          # Image/video processing
          ffmpeg
          stdenv.cc
          
          # ARM cross-compilation toolchain
          crossPkgs.pkgsCross.aarch64-multiplatform.buildPackages.gcc
          crossPkgs.pkgsCross.aarch64-multiplatform.stdenv.cc
          
          # Tools
          file
          tree
          htop
          glxinfo
          
          # Shader tools
          glslang
          shaderc
          
          # File monitoring
          inotify-tools
          
          # Debugging
          gdb
          lldb
          strace
          ltrace
          
          # Build tools
          bear  # For compile_commands.json
          clang-tools  # clangd for LSP
        ];
        
        # ARM target dependencies (for cross-compilation)
        armDeps = with crossPkgs.pkgsCross.aarch64-multiplatform; [
          # Mali GPU libraries
          mesa
          libdrm
          
          # Video decoding (CedarX)
          v4l-utils
          
          # System libraries for ARM
          glibc
          libgcc
          alsa-lib
          libxkbcommon
        ];
        
      in
      {
        # Development shell (nix develop)
        devShells.default = pkgs.mkShell {
          packages = devDeps;
          
          # Environment variables
          shellHook = ''
            echo "🔧 3D File Browser Development Environment"
            echo "📦 Zig: ${zig.version}"
            echo "🎯 Targets: x86_64-linux, aarch64-linux"
            echo ""
            echo "Available commands:"
            echo "  zig build                   - Build for host (x86_64)"
            echo "  zig build -Dtarget=aarch64-linux-gnu -Dcpu=cortex_a53"
            echo "                               - Cross-compile for Orange Pi Zero 3"
            echo "  zig build run               - Run on host"
            echo "  zig build test              - Run tests"
            echo "  zig build -Drelease-safe    - Release build"
            echo ""
            echo "Cross-compilation helpers:"
            echo "  build-arm                   - Build for ARM with hardware acceleration"
            echo "  deploy-pi                   - Build and deploy to Orange Pi"
            echo "  qemu-test                   - Test ARM binary with QEMU"
            echo ""
            
            # Create helper scripts in the shell
            cat > $PWD/build-arm << 'EOF'
            #!/usr/bin/env bash
            # Build for Orange Pi Zero 3 with hardware acceleration enabled
            zig build -Dtarget=aarch64-linux-gnu -Dcpu=cortex_a53 -Doptimize=ReleaseSafe -Dhw_accel=true
            echo "✅ ARM binary built: ./zig-out/bin/3d-file-browser"
            EOF
            
            cat > $PWD/deploy-pi << 'EOF'
            #!/usr/bin/env bash
            # Build and deploy to Orange Pi (set ORANGEPI_HOST in .env)
            if [ -z "$ORANGEPI_HOST" ]; then
                echo "❌ Set ORANGEPI_HOST environment variable"
                echo "Example: export ORANGEPI_HOST=orangepi@192.168.1.100"
                exit 1
            fi
            
            echo "🔨 Building for ARM..."
            zig build -Dtarget=aarch64-linux-gnu -Dcpu=cortex_a53 -Doptimize=ReleaseSafe
            
            echo "🚀 Deploying to $ORANGEPI_HOST..."
            scp ./zig-out/bin/3d-file-browser $ORANGEPI_HOST:/tmp/
            
            echo "📦 Installing on Orange Pi..."
            ssh $ORANGEPI_HOST "sudo mv /tmp/3d-file-browser /usr/local/bin/ && sudo chmod +x /usr/local/bin/3d-file-browser"
            
            echo "✅ Deployed successfully!"
            EOF
            
            cat > $PWD/qemu-test << 'EOF'
            #!/usr/bin/env bash
            # Test ARM binary with QEMU user emulation
            echo "🤖 Testing ARM binary with QEMU..."
            
            # Create a simple test environment
            TEST_DIR=$(mktemp -d)
            mkdir -p $TEST_DIR/home/user
            cd $TEST_DIR/home/user
            
            # Copy the binary
            cp ../../../../zig-out/bin/3d-file-browser .
            
            # Run with QEMU user mode
            ${pkgs.qemu}/bin/qemu-aarch64 -L ${crossPkgs.pkgsCross.aarch64-multiplatform.glibc} ./3d-file-browser --help
            
            rm -rf $TEST_DIR
            EOF
            
            chmod +x $PWD/build-arm $PWD/deploy-pi $PWD/qemu-test
            
            # Set up development environment
            export ZIG_LOCAL_CACHE_DIR="$PWD/.zig-cache"
            export ZIG_GLOBAL_CACHE_DIR="$HOME/.cache/zig"
            export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" devDeps}:$PKG_CONFIG_PATH"
            
            # For GLFW and other graphics libs
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (with pkgs; [ libGL glfw glew SDL2 ])}:$LD_LIBRARY_PATH"
            
            # Generate compile_commands.json for LSP
            if [ ! -f compile_commands.json ]; then
                echo "⚙️  Generating compile_commands.json for editor support..."
                bear -- zig build
            fi
            
            echo "🚀 Ready to develop!"
          '';
          
          # Build inputs
          nativeBuildInputs = devDeps;
          
          # Runtime dependencies
          buildInputs = devDeps;
          
          # Cross-compilation setup
          CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "${crossPkgs.pkgsCross.aarch64-multiplatform.stdenv.cc}/bin/aarch64-unknown-linux-gnu-gcc";
        };
        
        # Packages (nix build)
        packages = {
          default = pkgs.stdenv.mkDerivation {
            pname = "3d-file-browser";
            version = "0.1.0";
            
            src = self;
            
            nativeBuildInputs = [ zig cmake ninja pkg-config ];
            
            buildInputs = with pkgs; [ libGL glfw glew SDL2 ffmpeg ];
            
            buildPhase = ''
              # Build for host architecture
              zig build -Drelease-safe
            '';
            
            installPhase = ''
              mkdir -p $out/bin
              cp zig-out/bin/3d-file-browser $out/bin/
              
              # Install assets if any
              if [ -d assets ]; then
                mkdir -p $out/share/3d-file-browser
                cp -r assets/* $out/share/3d-file-browser/
              fi
            '';
          };
          
          # ARM package for Orange Pi
          arm = pkgs.stdenv.mkDerivation {
            pname = "3d-file-browser-arm";
            version = "0.1.0";
            
            src = self;
            
            nativeBuildInputs = [ zig ] ++ devDeps;
            
            # Cross-compilation setup
            preBuild = ''
              export ZIG_SYSTEM_LINKER_HACK=1
            '';
            
            buildPhase = ''
              # Cross-compile for ARM
              zig build -Dtarget=aarch64-linux-gnu -Dcpu=cortex_a53 -Drelease-safe -Dhw_accel=true
            '';
            
            installPhase = ''
              mkdir -p $out/bin
              cp zig-out/bin/3d-file-browser $out/bin/3d-file-browser-arm
              
              # Create a deployment script
              mkdir -p $out/share
              cat > $out/share/deploy.sh << 'EOF'
              #!/usr/bin/env bash
              # Deployment script for Orange Pi Zero 3
              TARGET="''${1:-orangepi@192.168.1.100}"
              echo "Deploying to $TARGET..."
              scp $out/bin/3d-file-browser-arm $TARGET:/tmp/
              ssh $TARGET "sudo mv /tmp/3d-file-browser-arm /usr/local/bin/3d-file-browser && sudo chmod +x /usr/local/bin/3d-file-browser"
              echo "✅ Deployed!"
              EOF
              chmod +x $out/share/deploy.sh
            '';
          };
          
          # Docker image for testing
          docker = pkgs.dockerTools.buildImage {
            name = "3d-file-browser";
            tag = "latest";
            
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = with pkgs; [
                # Minimal runtime dependencies
                glibc
                libgcc
                mesa
                libdrm
              ];
              pathsToLink = [ "/bin" "/lib" ];
            };
            
            config = {
              Cmd = [ "${self.packages.${system}.default}/bin/3d-file-browser" ];
              ExposedPorts = {
                "8080/tcp" = {};  # For web interface if added later
              };
            };
          };
        };
        
        # NixOS module (optional)
        nixosModules.default = { config, lib, ... }: {
          options.services.3d-file-browser = {
            enable = lib.mkEnableOption "3D File Browser service";
            user = lib.mkOption {
              type = lib.types.str;
              default = "3dfb";
            };
            dataDir = lib.mkOption {
              type = lib.types.str;
              default = "/var/lib/3d-file-browser";
            };
          };
          
          config = lib.mkIf config.services.3d-file-browser.enable {
            systemd.services."3d-file-browser" = {
              description = "3D File Browser";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              
              serviceConfig = {
                ExecStart = "${self.packages.${system}.default}/bin/3d-file-browser --daemon";
                User = config.services.3d-file-browser.user;
                StateDirectory = "3d-file-browser";
                Restart = "on-failure";
              };
            };
            
            users.users.${config.services.3d-file-browser.user} = {
              isSystemUser = true;
              group = config.services.3d-file-browser.user;
              home = config.services.3d-file-browser.dataDir;
            };
            
            users.groups.${config.services.3d-file-browser.user} = {};
          };
        };
        
        # App (nix run)
        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/3d-file-browser";
          };
          
          arm = {
            type = "app";
            program = "${self.packages.${system}.arm}/share/deploy.sh";
          };
          
          dev = {
            type = "app";
            program = toString (pkgs.writeShellScript "dev" ''
              # Development server with hot reload
              ${pkgs.entr}/bin/entr -rz << 'EOF' | ${pkgs.fzf}/bin/fzf
              find src/ shaders/ assets/ -type f -name "*.zig" -o -name "*.glsl" -o -name "*.png"
              EOF
              
              echo "🔄 Changes detected, rebuilding..."
              zig build run
            '');
          };
        };
      }
    );
}
