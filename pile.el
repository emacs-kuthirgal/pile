;;; pile.el --- Pile management

;; Copyright (c) 2018 Abhinav Tushar

;; Author: Abhinav Tushar <lepisma@fastmail.com>
;; Version: 0.0.1
;; Package-Requires: ((emacs "25") (dash "2.13.0") (dash-functional "2.13.0") (f "0.20.0") (s "1.12.0"))
;; URL: https://github.com/lepisma/pile.el

;;; Commentary:

;; Org pile management
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

(require 'dash)
(require 'dash-functional)
(require 'f)
(require 'pile-bc)
(require 'pile-index)
(require 'pile-link)
(require 'pile-serve)
(require 'pile-sitemap)
(require 'org)
(require 'ox-html)
(require 'ox-publish)
(require 's)


(defgroup pile nil
  "Pile wiki")

(defcustom pile-source nil
  "Source directory for pile"
  :type 'directory
  :group 'pile)

(defcustom pile-output nil
  "Output directory for pile"
  :type 'directory
  :group 'pile)

(defcustom pile-base-url ""
  "Url with respect to / at the host"
  :type 'string
  :group 'pile)

;;;###autoload
(defun pile-clear-cache ()
  "Clear org-publish-cache"
  (interactive)
  (setq org-publish-cache nil)
  (let ((cache-root (f-full "~/.emacs.d/.cache/.org-timestamps/")))
    (->> '("pile-pages.cache" "pile-static.cache")
       (-map (-cut f-join cache-root <>))
       (-filter #'f-exists?)
       (-map #'f-delete))))

(defmacro with-pile-hooks (&rest body)
  "Run body with pile related export hooks set"
  (let* ((hooks '(#'pile-bc-hook))
         (add-forms (-map (lambda (hook) `(add-hook 'org-export-before-parsing-hook ,hook)) hooks))
         (remove-forms (-map (lambda (hook) `(remove-hook 'org-export-before-parsing-hook ,hook)) hooks)))
    `(condition-case err
         (progn
           ,@add-forms
           ,@body
           ,@remove-forms)
       (error (progn
                ,@remove-forms
                (signal (car err) (cdr err)))))))

(defun pile-publish-current-file (arg)
  (interactive "P")
  (with-pile-hooks
   (org-publish-current-file arg)))

;;;###autoload
(defun pile-publish (arg)
  (interactive "P")
  (with-pile-hooks
   (org-publish-project "pile" arg)))

;;;###autoload
(defun pile-setup ()
  "Setup for pile"
  (let ((preamble (format "<header>
  <div class='site-title'>
    <a href='/'>
      <img src='/assets/images/avatar32.png'>
    </a>
  </div>
  <div class='site-nav'>
    <a href='/%s'> pile</a>
    <a href='/feed.xml'> feed</a>
    <a href='/archive'> blog</a>
    <a href='/about'> about</a>
  </div>
  <div class='clearfix'>
  </div>
</header>

<div class='page-header'>
  <div class='page-meta'>
    Last modified: %%d %%C
  </div>
  <h1>%%t</h1>
</div>" pile-base-url))
        (postamble "<footer id='footer'></footer>"))
    (setq org-publish-project-alist
          `(("pile-pages"
             :auto-sitemap t
             :sitemap-filename "sitemap.org"
             :sitemap-title "Sitemap"
             :sitemap-format-entry pile-sitemap-entry
             :sitemap-function pile-sitemap
             :base-directory ,pile-source
             :base-extension "org"
             :recursive t
             :publishing-directory ,pile-output
             :publishing-function org-html-publish-to-html
             :htmlized-source nil
             :html-checkbox-type unicode
             :html-doctype "html5"
             :html-html5-fancy t
             :html-postamble ,postamble
             :html-preamble ,preamble)
            ("pile-static"
             :base-directory ,pile-source
             :base-extension ".*"
             :exclude ".*\.org\\|.*export\.setup\\|.*auto/.*\.el\\|.*\.tex\\|.*\.bib"
             :recursive t
             :publishing-directory ,pile-output
             :publishing-function org-publish-attachment)
            ("pile" :components ("pile-pages" "pile-static")))
          org-html-htmlize-output-type 'css
          org-ref-bibliography-entry-format '(("article" . "%a. %y. \"%t.\" <i>%j</i>, %v(%n), %p. <a class=\"bib-link\" href=\"%U\">link</a>. <a class=\"bib-link\" href=\"http://dx.doi.org/%D\">doi</a>.")
                                              ("book" . "%a. %y. <i>%t</i>. %u.")
                                              ("techreport" . "%a. %y. \"%t\", %i, %u.")
                                              ("proceedings" . "%e. %y. \"%t\" in %S, %u.")
                                              ("inproceedings" . "%a. %y. \"%t\", %p, in %b, edited by %e, %u")))))

(provide 'pile)

;;; pile.el ends here
