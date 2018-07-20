;; Org
(defvar my-org-mode-packages
  '(org-bullets
    ox-pandoc))
(mapc #'package-install my-org-mode-packages)

;; variables
(require 'org)
(require 'evil-org)
(require 'org-bullets)

;; Directories
(setq org-directory "~/Dropbox/org")
(defun org-file-path (filename)
  "Return the absolute address of an org file, given its relative name."
  (concat (file-name-as-directory org-directory) filename))
(defvar org-index-file (org-file-path "index.org"))
(setq org-archive-location (concat (org-file-path "archive.org") "::* From %s"))
(setq org-agenda-files (list org-index-file))

;; Settings
(setq org-log-done 'time)
(setq org-src-fontify-natively t)
(setq org-src-tab-acts-natively t)

;; hooks
(add-hook 'org-capture-mode-hook 'evil-insert-state)
(add-hook
 'org-mode-hook
 (lambda ()
   ;; (face-remap-add-relative 'default :height 1.1) ; increase font size by 10%
   (linum-mode -1)
   (text-scale-adjust 1)
   (turn-on-auto-fill)
   (org-bullets-mode)
   (evil-org-mode)))
(setq org-todo-keywords
      '((sequence "TODO" "WORK" "DONE")))

(with-eval-after-load 'ox
  (require 'ox-pandoc))

(defun mark-done-and-archive ()
  "Mark the state of an org-mode item as DONE and archive it."
  (interactive)
  (org-todo 'done)
  (org-archive-subtree))

(defvar org-capture-templates
      `(("t" "Todo" entry
         (file org-index-file)
         "* TODO %?\n")

        ("w" "Work tasks" entry
         (file ,(org-file-path "work.org"))
         "* TODO %?\n")

        ("j" "Work journal" entry
         (file+datetree ,(org-file-path "work-journal.org"))
         "* %?\nEntered on %U\n  %i\n  %a")

        ("f" "Fun facts and tips and tricks" entry
         (file ,(org-file-path "fun-facts.org"))
         "* %?\nEntered on %U\n  %i\n  %a")
        ))

;; Key bindings
(define-key global-map (kbd "C-c C-x C-s") 'mark-done-and-archive)
(define-key global-map (kbd "C-c c") 'org-capture)
(define-key global-map (kbd "C-c f") 'org-agenda)
(define-key global-map (kbd "C-c l") 'org-store-link)

(evil-leader/set-key-for-mode 'org-mode
  "s" 'org-narrow-to-subtree
  "i" 'widen)

(message "Loading org-init... Done.")
(provide 'org-init)
