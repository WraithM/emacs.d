(setq my-haskell-packages
      '(haskell-mode
        haskell-snippets

        hindent
        flycheck

        intero))
(mapc #'package-install my-haskell-packages)


(require 'haskell)
(require 'haskell-mode)
(require 'haskell-snippets)
(require 'flycheck)
(require 'intero)
(require 'hindent)

;; (load-file "~/.emacs.d/lisp/ghcid.el")
;; (require 'ghcid)

;; Sub-mode Hooks
(add-hook 'haskell-mode-hook 'intero-mode)
(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)
;; (add-hook 'haskell-mode-hook 'subword-mode)
(add-hook 'haskell-mode-hook #'hindent-mode)

(flycheck-add-next-checker 'intero '(warning . haskell-hlint))

;; Variables
(add-hook
 'haskell-mode-hook
 (setq
  compile-command "stack build --fast --test --bench --no-run-tests --no-run-benchmarks --ghc-options=-Werror"
  hindent-style "johan-tibell"

  haskell-stylish-on-save t
  ;; haskell-tags-on-save t

  haskell-indentation-layout-offset 4
  haskell-indentation-left-offset 4
  haskell-indentation-ifte-offset 4
  haskell-indentation-show-indentations t
  haskell-indentation-show-indentations-after-eol t))

;; Key bindings
(define-key haskell-mode-map (kbd "M-,") 'haskell-who-calls)
(define-key haskell-mode-map (kbd "M-]") 'intero-goto-definition)

(evil-define-motion my-haskell-navigate-imports ()
  "Navigate imports with evil motion"
  :jump t
  :type line
  (haskell-navigate-imports))
(evil-leader/set-key-for-mode 'haskell-mode "i" 'my-haskell-navigate-imports)

(defun my-intero-insert-type ()
  "Insert type at point"
  (interactive)
  (intero-type-at t))
(evil-leader/set-key-for-mode 'haskell-mode "t" 'my-intero-insert-type)
(evil-define-key 'normal haskell-mode-map (kbd "C-c C-t") 'my-intero-insert-type)

(evil-set-initial-state 'intero-repl-mode 'emacs)

;; Alignment
(eval-after-load "align"
  '(add-to-list 'align-rules-list
                '(haskell-types
                   (regexp . "\\(\\s-+\\)\\(::\\|∷\\)\\s-+")
                   (modes quote (haskell-mode literate-haskell-mode)))))
(eval-after-load "align"
  '(add-to-list 'align-rules-list
                '(haskell-assignment
                  (regexp . "\\(\\s-+\\)=\\s-+")
                  (modes quote (haskell-mode literate-haskell-mode)))))
(eval-after-load "align"
  '(add-to-list 'align-rules-list
                '(haskell-arrows
                  (regexp . "\\(\\s-+\\)\\(->\\|→\\)\\s-+")
                  (modes quote (haskell-mode literate-haskell-mode)))))
(eval-after-load "align"
  '(add-to-list 'align-rules-list
                '(haskell-left-arrows
                  (regexp . "\\(\\s-+\\)\\(<-\\|←\\)\\s-+")
                  (modes quote (haskell-mode literate-haskell-mode)))))

;; Fun functions
(defun haskell-who-calls (&optional prompt)
  "Grep the codebase to see who uses the symbol at point."
  (interactive "P")
  (let ((sym (if prompt
                 (read-from-minibuffer "Look for: ")
               (haskell-ident-at-point))))
    (let ((existing (get-buffer "*who-calls*")))
      (when existing
        (kill-buffer existing)))
    (let ((buffer
           (grep-find (format "cd %s && find . -name '*.hs' -exec ag -i --numbers %s {} +"
                              (haskell-session-current-dir (haskell-session))
                              sym))))
      (with-current-buffer buffer
        (rename-buffer "*who-calls*")
        (switch-to-buffer-other-window buffer)))))

;; Evil indentation helper
(defun haskell-indentation-indent-line ()
  "Indent current line, cycle though indentation positions.
Do nothing inside multiline comments and multiline strings.
Start enumerating the indentation points to the right.  The user
can continue by repeatedly pressing TAB.  When there is no more
indentation points to the right, we switch going to the left."
  (interactive)
  ;; try to repeat
  (when (not (haskell-indentation-indent-line-repeat))
    (setq haskell-indentation-dyn-last-direction nil)
    ;; parse error is intentionally not caught here, it may come from
    ;; `haskell-indentation-find-indentations', but escapes the scope
    ;; and aborts the operation before any moving happens
    (let* ((cc (current-column))
           (ci (haskell-indentation-current-indentation))
           (inds (save-excursion
                   (move-to-column ci)
                   (or (haskell-indentation-find-indentations)
                       '(0))))
           (valid (memq ci inds))
           (cursor-in-whitespace (< cc ci))
           ;; certain evil commands need the behaviour seen in
           ;; `haskell-indentation-newline-and-indent'
           (evil-special-command (and (bound-and-true-p evil-mode)
                                      (memq this-command '(evil-open-above
                                                           evil-open-below
                                                           evil-replace))))
           (on-last-indent (eq ci (car (last inds)))))
      (if (and valid cursor-in-whitespace)
          (move-to-column ci)
        (haskell-indentation-reindent-to
         (funcall
          (if on-last-indent
              #'haskell-indentation-previous-indentation
            #'haskell-indentation-next-indentation)
          (if evil-special-command
              (save-excursion
                (end-of-line 0)
                (1- (haskell-indentation-current-indentation)))
            ci)
          inds
          'nofail)
         cursor-in-whitespace))
      (setq haskell-indentation-dyn-last-direction (if on-last-indent 'left 'right)
            haskell-indentation-dyn-last-indentations inds))))

(message "Loading haskell-init... Done.")
(provide 'intero-init)
