;;; pile-bc.el --- Breadcrumbs for pile -*- lexical-binding: t; -*-

;; Copyright (c) 2018 Abhinav Tushar

;; Author: Abhinav Tushar <lepisma@fastmail.com>

;;; Commentary:

;; Breadcrumbs for pile
;; This file is not a part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Code:


(require 'org)
(require 'ox)
(require 'f)
(require 's)

(defun pile-bc--relative (file-name)
  "Get relative path of the file from pile root"
  (let ((rel-path (f-relative file-name pile-source)))
    (s-chop-suffix ".org" rel-path)))

(defun pile-bc--parents (rel-path)
  "Break path into roots"
  (let* ((splits (reverse (s-split "/" rel-path)))
         (dir-page? (string-equal (car splits) "index"))
         (offset (if dir-page? 2 1))
         (parents (nthcdr offset splits)))
    (reverse
     (-map-indexed (lambda (index item)
                     (let ((item-path))
                       (cons item
                             (concat (s-repeat (+ offset index) "../") item "/index.html"))))
                   parents))))

(defun pile-bc--page-title (rel-path)
  "Return page title for the path given"
  (let ((splits (reverse (s-split "/" rel-path))))
    (if (string-equal (car splits) "index")
        (or (second splits) "home")
      (car splits))))

(defun pile-bc--linkify-parents (parents)
  "Return concatenated html for parents"
  (funcall 's-join " / " (-map (lambda (parent)
                                 (format "<a href='%s'>%s</a>" (cdr parent) (car parent)))
                               parents)))

(defun pile-bc--linkify-root (rel-path)
  "Return link for root file"
  (let* ((root-input-file "index.org")
         (full-path (f-join pile-source rel-path))
         (root-rel-path (f-relative (f-join pile-source root-input-file) full-path))
         (root-output-file (f-swap-ext root-rel-path "html")))
    (format "<a href='%s'>%s</a>" (substring-no-properties root-output-file 1) "≡ index")))

(defun pile-bc-generate-breadcrumbs (rel-path)
  "Generate html breadcrumbs"
  (let ((parents (pile-bc--parents rel-path)))
    (format "#+HTML:<div id='breadcrumbs'>%s / %s %s</div>"
            (pile-bc--linkify-root rel-path)
            (if (zerop (length parents)) "" (format "%s /" (pile-bc--linkify-parents parents)))
            (pile-bc--page-title rel-path))))

(defun pile-bc-hook (_)
  "Function to insert breadcrumbs in the exported file"
  (let ((rel-path (pile-bc--relative (buffer-file-name))))
    (unless (string-equal "sitemap" rel-path)
      (pile--goto-top)
      (insert (pile-bc-generate-breadcrumbs rel-path)))))

(provide 'pile-bc)

;;; pile-bc.el ends here
