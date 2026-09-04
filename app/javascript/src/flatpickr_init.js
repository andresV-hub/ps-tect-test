// Initialise the date pickers on every Turbo page load.
//
// This used to listen for DOMContentLoaded, which Turbo only fires on the very
// first page load, leaving the pickers dead after any in-app navigation.
document.addEventListener("turbo:load", () => {
  flatpickr(".flatpickr-input", {
    locale: flatpickr.l10ns.es,
    enableTime: true,
    dateFormat: "Y-m-d H:i"
  })
})
