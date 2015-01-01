;;; ocaml-library.el --- List Packages for Ocaml.  -*- coding: utf-8 -*-

;;; Commentary:
;;; ocaml-library

;;; Code:
(eval-when-compile (require 'cl))

(defvar ocaml-library-packages '("ounit" "core" "core_kernel")
  "OCaml package lists.")

(defvar ocaml-library-font-lock-keywords
  '(("\\<\\w+\\.mli\\>" . font-lock-variable-name-face)
    ("\\<\\w+\\.ml\\>" . font-lock-function-name-face)
    ("Implementation files (\\.ml):\\|Interface files (\\.mli):" .
     font-lock-builtin-face)
    ("Package: \\w+\\." . font-lock-comment)))

(defvar ocaml-library-syntax-table
  (let ((table (make-syntax-table)))
    ;; '.', '-' and '_' are now letters
    (modify-syntax-entry ?. "w" table)
    (modify-syntax-entry ?_ "w" table)
    (modify-syntax-entry ?- "w" table)
    table))

(defun ocaml-library-set-mode-map (map)
  "Set mode map for current mode."
  (define-key map [return] 'ocaml-library-find-file)
  (define-key map (kbd "C-m") 'ocaml-library-find-file)
  (define-key map [mouse-2] 'ocaml-library-mouse-find-file))

(defun ocaml-library-insert-package (package)
  "Insert package interface file name and implementation file name."
  (let* ((command (format "ocamlfind query %s" package))
         (result (shell-command-to-string command))
         (dir (substring result 0 -1))
         (sep-len 70))
    (when (and (file-directory-p dir) (file-readable-p dir))
      (insert "\n\n"(make-string sep-len ?=) "\n")
      (insert
       (format "Package: %s.\nDirectory: \"%s\".\n" package dir))
      (insert (make-string sep-len ?=) "\n")
      (insert "Interface files (.mli):\n")
      (insert (make-string sep-len ?-) "\n")
      (insert-directory (concat dir "/*.mli") "-C" t nil)
      (insert (make-string sep-len ?-) "\n\n")
      (insert "Implementation files (.ml):\n")
      (insert (make-string sep-len ?-) "\n")
      (insert-directory (concat dir "/*.ml") "-C" t nil))))

(defun ocaml-library-set-mouse-face ()
  (let ((opoint))
    ;; Every file name is now mouse-sensitive
    (goto-char (point-min))
    (while (< (point) (point-max))
      (re-search-forward "\\.ml.?\\>")
      (setq opoint (point))
      (re-search-backward "\\<" (point-min) 1)
      (put-text-property (point) opoint 'mouse-face 'highlight)
      (goto-char (+ 1 opoint)))))

;;;###autoload
(define-derived-mode ocaml-library-mode nil "ocaml-libarary"
  "List OCaml packages mode.
  Show selected packages' interface(*.mli) and implementation(*.ml)."
  (set-syntax-table ocaml-library-syntax-table)
  (ocaml-library-set-mode-map ocaml-library-mode-map)
  (set (make-local-variable 'font-lock-defaults)
       '(ocaml-library-font-lock-keywords)))

;;;###autoload
(defun ocaml-library-browse ()
  "Browse the OCaml library."
  (interactive)
  (if (not (executable-find "ocamlfind"))
      (error "%s" "Can't find ocamlfind")
    (let ((buf-name "*ocaml-libraries*") (opoint))
      (with-output-to-temp-buffer buf-name
        (buffer-disable-undo standard-output)
        (with-current-buffer buf-name
          (insert "Ocaml Packages\n")
          (insert "Select a file with middle mouse button or RETURN.")
          ;;; List *.ml and *.mli files
          (dolist (package ocaml-library-packages)
            (ocaml-library-insert-package package))
          (ocaml-library-set-mouse-face)
          ;;; Activate tuareg-library mode
          (ocaml-library-mode)
          (setq buffer-read-only t))))))

(defun ocaml-library-find-file ()
  "Load the file whose name is near point."
  (interactive)
  (when (text-properties-at (point))
    (save-excursion
      (let (beg end file-name path)
        (re-search-forward "\\>") (setq end (point))
        (re-search-backward "\\<") (setq beg (point))
        (setq file-name (buffer-substring-no-properties beg end))
        (re-search-backward "Directory: \"\\([^\"]+\\)\".")
        (setq path (match-string 1))
        (find-file-read-only (expand-file-name file-name path))))))

(defun ocaml-library-mouse-find-file (event)
  "Visit the file name you click on."
  (interactive "e")
  (let ((owindow (selected-window)))
    (mouse-set-point event)
    (ocaml-library-find-file)
    (select-window owindow)))

(provide 'ocaml-library)

;;; ocaml-library ends here
