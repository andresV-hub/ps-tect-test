// Entry point for the application's JavaScript, loaded through the import map.
//
// Import order matters: jquery3.js is a UMD build that registers window.jQuery
// and window.$ as a side effect, and both cocoon and our own scripts rely on
// those globals being in place before they run.
import "jquery"

// Bootstrap's UMD build reads window.Popper, so the order here matters too.
import "popper"
import "bootstrap"

import "@hotwired/turbo-rails"
import "controllers"

import "cocoon"

import "flatpickr"
import "flatpickr/l10n/es"

import "chartkick"
import "Chart.bundle"

import "src/flatpickr_init"
import "src/question_form_logic"
