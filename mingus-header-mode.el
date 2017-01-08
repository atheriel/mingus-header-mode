;;; mingus-header-mode.el --- A minor mode for displaying MPD information in the header-line -*- lexical-binding: t -*-

;; Copyright (C) 2017 Aaron Jacobs

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'mingus)
(require 'powerline)

;;;; Customization

(defgroup mingus-header nil
  "Customizations for `mingus-header-mode'."
  :group 'mingus)

(defcustom mingus-header-use-powerline t
  "Use `powerline' to create the header."
  :group 'mingus-header)

;;;; Header Line Creation

(defun mingus-header-line-format ()
  "Create a header line for `mingus-playlist-mode'."
  (if mingus-header-use-powerline
      (mingus-header-powerline-format)
    "not yet implemented"))

;;;;; Powerline version

(defun mingus-header-powerline-format ()
  "Create a header line for `mingus-playlist-mode' using the
`powerline' package."
  (let* ((status (mpd-get-status mpd-inter-conn))
         ;; Whether to show the current song's information.
         (show-song (member (plist-get status 'state) '(play pause)))
         ;; Powerline information.
         (active (powerline-selected-window-active))
         (face1 (if active 'mode-line 'mode-line-inactive))
         (face2 (if active 'powerline-active1 'powerline-inactive1))
         (face3 (if active 'powerline-active2 'powerline-inactive2))
         (face4 (if active 'mode-line-buffer-id 'mode-line-buffer-id-inactive))
         (sep-left (intern (format "powerline-%s-%s"
                                   (powerline-current-separator)
                                   (car powerline-default-separator-dir))))
         (sep-right (intern (format "powerline-%s-%s"
                                    (powerline-current-separator)
                                    (cdr powerline-default-separator-dir))))
         ;; MPD state string.
         (state  (case (plist-get status 'state)
                   (play  "playing ")
                   (pause "paused ")
                   (stop  "stopped ")
                   (t     "error ")))
         ;; Volume string.
         (volume (if (= (plist-get status 'volume) 100) "Vol: 100%% "
                   (format "Vol:  %d%%%% " (plist-get status 'volume))))
         ;; Playback string.
         (single (plist-get status 'single))
         (consume (plist-get status 'consume))
         (playback (format "%s%s%s%s- "
                           (if (eq (plist-get status 'repeat) 1) "r" "-")
                           (if (eq (plist-get status 'random) 1) "z" "-")
                           (if (and single (string= single "1")) "s" "-")
                           (if (and consume (string= consume "1")) "c" "-")))
         ;; Elapsed time string (only when playing/paused).
         (time (if (not show-song) ""
                 (format "%s/%s "
                         (mingus-sec->min:sec (plist-get status 'time-elapsed))
                         (mingus-sec->min:sec (plist-get status 'time-total)))))
         (lhs (list (powerline-raw (propertize state 'face face4) face1 'l)
                    (when show-song
                      (funcall sep-left face1 face2))
                    (when show-song
                      (powerline-raw time face2 'l))
                    (funcall sep-left face2 face3)))
         (rhs (list (funcall sep-right face3 face2)
                    (powerline-raw volume face2 'l)
                    (funcall sep-right face2 face1)
                    (powerline-raw playback face1 'l))))
    (concat (powerline-render lhs)
            (powerline-fill face3 (powerline-width rhs))
            (powerline-render rhs))))

;;;; Minor Mode Definition

(define-minor-mode mingus-header-mode
  "A minor mode for displaying MPD information in the header line
of `mingus-playlist-mode' buffers.

Note that toggling this mode will fail in all other modes."
  :group 'mingus-header
  (if (not (eq major-mode 'mingus-playlist-mode))
      (progn
        ;; Toggling this minor mode only works in `mingus-playlist-mode'.
        (setq mingus-header-mode (not mingus-header-mode))
        (user-error "`mingus-header-mode' can only be enabled in `mingus-playlist-mode' buffers."))
    (if (not mingus-header-mode)
        (setq header-line-format nil)
      (setq header-line-format
            '("%e" (:eval (mingus-header-line-format)))))))

(provide 'mingus-header-mode)

;; Local Variables:
;; coding: utf-8
;; End:

;;; mingus-header-mode.el ends here
