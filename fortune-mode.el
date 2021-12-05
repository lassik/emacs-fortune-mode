;;; fortune-mode.el --- Major mode for editing fortune cookie collections -*- lexical-binding: t -*-

;; Copyright 1999 Association April
;; Copyright 2000 Michael Shulman
;; Copyright 2021 Lassi Kortela
;; SPDX-License-Identifier: GPL-2.0-or-later

;; Author: Benjamin Drieu <drieu@alpha12.bocal.cs.univ-paris8.fr>
;; Author: Michael Abraham Shulman <viritrilbia@users.sourceforge.net>
;; Author: Lassi Kortela <lassi@lassi.io>
;; Maintainer: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-fortune-mode
;; Version: 2.0.0
;; Package-Requires: ((emacs "24"))
;; Keywords: games

;; This file is NOT part of GNU Emacs.

;; This is free software; you can redistribute them and/or modify them
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This software is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This major mode helps you edit collections of fortune cookies.  The
;; file format is the one used by the Unix `fortune` program.  A line
;; with a single '%' separates each pair of adjacent fortunes.

;; This is designed to extend the `fortune' package that comes
;; standard with GNU Emacs.

;;; Code:

;; This package is a merge of the `fortune-mode.el' found on EmacsWiki
;; (written in 1999-2000) with new code written in 2021. After the old
;; `fortune-mode.el' was written, an unrelated `fortune.el' package
;; was added into the standard GNU Emacs distribution. Unlike the old
;; `fortune-mode.el', this one relies on the standard `fortune.el' for
;; as much functionality as possible.

(require 'fortune)

(defface fortune-mode-dividing-line-face
  '((t :background "gray20"
       :foreground "gray20"
       :extend t))
  "Face for the '%' line between two fortune cookies."
  :group 'fortune)

(defconst fortune-mode-author-line-regexp "[ \t]*-+[ \t]*"
  "Regular expression matching citation strings.

See also `fortune-author-line-prefix'.")

(defconst fortune-mode-font-lock-keywords
  `(

    ;; Dividing '%' line between two fortune cookies.
    ("^%\n"
     (0 'fortune-mode-dividing-line-face))

    ;; Common notation for source of citation: "-- John Doe".
    (,(concat "^" fortune-mode-author-line-regexp ".*")
     (0 'font-lock-variable-name-face))

    ;; FOO: <said something>
    ("^[A-Z]+:"
     (0 'font-lock-variable-name-face))

    ;; Incorrectly spelled dividing '%' line.
    ("^[ \t]*%+[ \t%]*$"
     (0 'font-lock-warning-face))

    ;; Warn about hard tabs.
    ("\t+"
     (0 'font-lock-warning-face t)))
  "Font lock keywords for `fortune-mode'.")

(defun fortune-mode-cite-author (arg)
  "Insert \"-- Citation Author\" at beginning of current line.

If such a string is already there, do nothing unless ARG is
greater than 1, in which case delete it and add a new
\(standardized) one. With negative ARG, remove any citation
string on this line."
  (interactive "p")
  (save-excursion
    (beginning-of-line)
    (cond ((= arg 1)
           (unless (looking-at fortune-mode-author-line-regexp)
             (insert fortune-author-line-prefix)))
          ((> arg 1)
           (when (looking-at fortune-mode-author-line-regexp)
             (replace-match ""))
           (insert fortune-author-line-prefix))
          (t
           (when (looking-at fortune-mode-author-line-regexp)
             (replace-match ""))))))

(defun fortune-mode-newline ()
  "Insert a newline and an appropriate string.

If the current line has a citation, begin a new fortune. Else
begin a citation."
  (interactive)
  (end-of-line)
  (cond
   ((string= fortune-author-line-prefix
             (buffer-substring
              (save-excursion (beginning-of-line) (point))
              (save-excursion (end-of-line) (point))))
    (delete-region
     (save-excursion (beginning-of-line) (point))
     (save-excursion (end-of-line) (point)))
    (insert "%\n"))
   ((save-excursion
      (beginning-of-line)
      (looking-at fortune-mode-author-line-regexp))
    (insert "\n%\n"))
   ((save-excursion
      (beginning-of-line)
      (looking-at "$"))
    (insert fortune-author-line-prefix))
   (t
    (insert "\n" fortune-author-line-prefix))))

(defun fortune-mode-take-action ()
  "Take appropriate action on the current `fortune-mode' buffer.

If it is visiting a file, compile that file using
`fortune-compile'. Else append the text in the buffer to a
fortune file and compile that fle."
  (interactive)
  (cond ((buffer-file-name)
         (fortune-compile (buffer-file-name)))
        ((use-region-p)
         (when (y-or-n-p (format "Add region to %s? " fortune-file))
           (fortune-from-region (region-beginning)
                                (region-end)
                                fortune-file)))
        (t
         (when (y-or-n-p (format "Add buffer to %s? " fortune-file))
           (fortune-from-region (point-min)
                                (point-max)
                                fortune-file)))))

(defvar fortune-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-a" 'fortune-mode-cite-author)
    (define-key map [remap newline] 'fortune-mode-newline)
    (define-key map "\C-c\C-c" 'fortune-mode-take-action)
    map))

;;;###autoload
(define-derived-mode fortune-mode text-mode "Fortune"
  "Major mode for writing fortune cookie files.

The file format is the one used by the Unix `fortune` program. A
line with a single '%' separates each pair of adjacent fortunes."
  (set (make-local-variable 'font-lock-defaults)
       '(fortune-mode-font-lock-keywords nil t))
  (set (make-local-variable 'paragraph-start)
       "[\n\f]\\|%")
  (set (make-local-variable 'paragraph-separate)
       "[\f]*$\\|%$")
  (visual-line-mode 1))

;; Add the fortune pattern last in `auto-mode-alist', which means it
;; has lower priority than other filename patterns.  Fortune files
;; don't have a filename extension; it's better to first match files
;; that have an extension since that's a better clue of the file type.

;;;###autoload
(add-to-list 'auto-mode-alist
             '("/fortunes?/" . fortune-mode)
             t)

(provide 'fortune-mode)

;;; fortune-mode.el ends here
