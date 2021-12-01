;;; fortune-mode.el --- Major mode for editing fortune cookie collections -*- lexical-binding: t -*-

;; Copyright 2021 Lassi Kortela
;; SPDX-License-Identifier: ISC

;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-fortune-mode
;; Version: 0.1.0
;; Package-Requires: ((emacs "24"))
;; Keywords: games

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This major mode helps you edit collections of fortune cookies.  The
;; file format is the one used by the Unix `fortune` program.  A line
;; with a single '%' separates each pair of adjacent fortunes.

;;; Code:

(defface fortune-mode-dividing-line-face
  '((t :background "gray20"
       :foreground "gray50"
       :extend t))
  "Face for the '%' line between two fortune cookies."
  :group 'fortune)

(defconst fortune-mode-font-lock-keywords
  '(

    ;; Dividing '%' line between two fortune cookies.
    ("^%\n"
     (0 'fortune-mode-dividing-line-face))

    ;; Common notation for source of citation: "-- John Doe".
    ("^[ \t]*-- .*"
     (0 'font-lock-variable-name-face))

    ;; FOO: <said something>
    ("^[A-Z]+:"
     (0 'font-lock-variable-name-face))

    ;; Incorrectly spelled dividing '%' line.
    ("^[ \t]*%+[ \t%]*\n"
     (0 'font-lock-warning-face))

    ;; Warn about hard tabs.
    ("\t+"
     (0 'font-lock-warning-face t)))
  "Font lock keywords for `fortune-mode'.")

;;;###autoload
(define-derived-mode fortune-mode text-mode "Fortune"
  "Major mode for writing fortune cookie files.

The file format is the one used by the Unix `fortune` program.  A
line with a single '%' separates each pair of adjacent fortunes."
  (set (make-local-variable 'font-lock-defaults)
       '(fortune-mode-font-lock-keywords nil t))
  (set (make-local-variable 'paragraph-separate)
       "[ \t%]*$")
  (auto-fill-mode 0)
  (visual-line-mode 1))

;;;###autoload
(add-to-list 'auto-mode-alist '("/fortunes/" . fortune-mode))

(provide 'fortune-mode)

;;; fortune-mode.el ends here
