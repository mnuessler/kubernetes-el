;;; configmaps-list-compile-test.el --- Test rendering of the configmaps list  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(eval-and-compile
  (require 'f)

  (defvar project-root
    (locate-dominating-file default-directory ".git"))

  (defvar this-directory
    (f-join project-root "test")))

(require 'kubernetes (f-join project-root "kubernetes.el"))

(defconst sample-get-configmaps-response
  (let* ((path (f-join this-directory "get-configmaps-output.json"))
         (sample-response (f-read-text path)))
    (json-read-from-string sample-response)))

(defun draw-configmaps-section (state)
  (kubernetes--eval-ast (kubernetes--render-configmaps-section state)))


;; Shows "Fetching..." when state isn't initialized yet.

(defconst drawing-configmaps-section-loading-result
  (s-trim-left "

Configmaps
  Name                             Data    Age
  Fetching...
"))

(ert-deftest drawing-configmaps-section--empty-state ()
  (with-temp-buffer
    (save-excursion (magit-insert-section (root)
                      (draw-configmaps-section nil)))
    (should (equal drawing-configmaps-section-loading-result
                   (substring-no-properties (buffer-string))))
    (forward-line 1)
    (forward-to-indentation)
    (should (equal 'kubernetes-progress-indicator (get-text-property (point) 'face)))))


;; Shows "None" when there are no configmaps.

(defconst drawing-configmaps-section-empty-result
  (s-trim-left "

Configmaps
  None.
"))

(ert-deftest drawing-configmaps-section--no-configmaps ()
  (let ((empty-state `((configmaps . ((items . ,(vector)))))))
    (with-temp-buffer
      (save-excursion (magit-insert-section (root)
                        (draw-configmaps-section empty-state)))
      (should (equal drawing-configmaps-section-empty-result
                     (substring-no-properties (buffer-string))))
      (search-forward "None")
      (should (equal 'magit-dimmed (get-text-property (point) 'face))))))


;; Shows configmap lines when there are configmaps.

(defconst drawing-configmaps-section-sample-result
  (s-trim-left "

Configmaps (2)
  Name                             Data    Age
  example-configmap-1                 2    79d
    Namespace:  example-ns
    Created:    2017-01-13T00:24:47Z

  example-configmap-2                 1   331d
    Namespace:  example-ns
    Created:    2016-05-06T02:54:41Z

"))

(ert-deftest drawing-configmaps-section--sample-response ()
  (let ((state `((configmaps . ,sample-get-configmaps-response)
                 (current-time . ,(date-to-time "2017-04-03 00:00Z")))))
    (with-temp-buffer
      (save-excursion (magit-insert-section (root)
                        (draw-configmaps-section state)))
      (should (equal drawing-configmaps-section-sample-result
                     (substring-no-properties (buffer-string)))))))

(ert-deftest drawing-configmaps-section--sample-response-text-properties ()
  (let ((state `((configmaps . ,sample-get-configmaps-response))))
    (with-temp-buffer
      (save-excursion (magit-insert-section (root)
                        (draw-configmaps-section state)))
      ;; Skip past header.
      (forward-line 2)

      (dolist (key '("Namespace"
                     "Created"))
        (save-excursion
          (search-forward key)
          (should (equal 'magit-header-line (get-text-property (point) 'face))))))))

;;; configmaps-list-compile-test.el ends here
