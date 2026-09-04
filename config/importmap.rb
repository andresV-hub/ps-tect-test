# Pin npm packages by running ./bin/importmap

pin "application", preload: true

# Hotwire.
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

# Bootstrap's JavaScript (dropdowns, modals, tooltips). The UMD build reads
# Popper off the global scope when loaded as an ES module, so popper must be
# imported before bootstrap.
pin "popper", to: "popper.js", preload: true
pin "bootstrap", to: "bootstrap.min.js", preload: true

# jQuery is still required by cocoon and by the nested question form logic.
# jquery3.js is a UMD build: importing it for its side effects registers
# window.jQuery and window.$, which is what those libraries expect.
pin "jquery", to: "jquery3.js", preload: true

# Dynamic nested forms (questions and their options).
pin "cocoon", to: "cocoon.js", preload: true

# Date pickers.
pin "flatpickr", to: "flatpickr.js", preload: true
pin "flatpickr/l10n/es", to: "flatpickr/l10n/es.js", preload: true

# Charts on the analytics dashboard.
pin "chartkick", to: "chartkick.js", preload: true
pin "Chart.bundle", to: "Chart.bundle.js", preload: true

# Application code that is not a Stimulus controller.
pin_all_from "app/javascript/src", under: "src"
