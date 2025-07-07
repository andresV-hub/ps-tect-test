document.addEventListener('DOMContentLoaded', () => {
    flatpickr('.flatpickr-input', {
        locale: flatpickr.l10ns.es,
        enableTime: true,
        dateFormat: "Y-m-d H:i",
    });
});