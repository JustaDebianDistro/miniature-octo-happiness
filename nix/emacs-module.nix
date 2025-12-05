{ pkgs, zig }:
#let
#  emacsWithConfig = pkgs.emacsWithPackages {
#    config = ./emacs-config.el;
#    package = pkgs.emacs29;
#    alwaysEnsure = true;
#    extraEmacsPackages = epkgs: with epkgs;[
#      use-package
#      general
#
#      zig-mode
#      lsp-mode
#      lsp-ui
#      company
#      flycheck
#
#      projectile
#      magit
#      which-key
#
#      doom-themes
#      doom-modeline
#      all-the-icons
#      vertico
#      marginalia
#      orderless
#      consult
#
#      exec-path-from-shell
#      direnv
#
#    ];
#
#  };
  
#  emacsTools = with pkgs;[vterm emacs29Packages.pdf-tools emacs29Packages.org-roam];

#  shellHook= ''
#    echo "  Emacs: ${emacsWithConfig.name}"
#    # Set up Emacs environment
#    export EMACSLOADPATH="${emacsWithConfig.deps}/share/emacs/site-lisp:$EMACSLOADPATH"
#    export PATH="${emacsWithConfig}/bin:$PATH"
#    
#    # For vterm in Emacs
#    export LIBRARY_PATH="${pkgs.vterm}/lib:$LIBRARY_PATH"
#    
#  '';
#in{
{
  devShells.x86_64-linux = {
    #    emacsconfig = pkgs.mkShell {packages = [emacsWithConfig] ++ emacsTools; inherit shellHook;};
    emacsconfig = pkgs.mkShell {
      packages = [
        # Simple emacsWithPackages - ALWAYS WORKS
        (pkgs.emacsWithPackages (epkgs: with epkgs; [
          use-package
          general
          zig-mode
          lsp-mode
          lsp-ui
          company
          flycheck
          projectile
          magit
          which-key
          doom-themes
          doom-modeline
          all-the-icons
          vertico
          marginalia
          orderless
          consult
          exec-path-from-shell
          direnv
          vterm
          pdf-tools
          org-roam
        ]))
      ];
      shellHook = '' echo "emacs all packages loaded"'';

    };
    emacslite = pkgs.mkShell {
      packages = [
        (pkgs.emacsWithPackages (epkgs: with epkgs; [
          zig-mode
          lsp-mode
          company
          magit
        ]))
      ];
      shellHook = '' echo "emacs-lite-mode" '';
    };
  };
}
#  devShells.x86_64-linux.emacsconfig = pkgs.mkShell{
#    NODE_ENV = "Emacs-with-config";
#    packages = [emacsWithConfig] ++ emacsTools;
#    inherit shellHook;
#
#  };

#}
