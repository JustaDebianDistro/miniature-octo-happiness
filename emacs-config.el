;; Basic Emacs config for Zig development
(require 'use-package)

;; Zig mode
(use-package zig-mode
  :ensure t
  :mode "\\.zig\\'")

;; LSP
(use-package lsp-mode
  :ensure t
  :hook (zig-mode . lsp-deferred))

;; Auto-completion
(use-package company
  :ensure t
  :config (global-company-mode))

;; Git
(use-package magit
  :ensure t)

;; Project management
(use-package projectile
  :ensure t
  :config (projectile-mode +1))
