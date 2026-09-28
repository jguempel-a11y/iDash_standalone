/* iDash Theme Initializer - must load BEFORE first paint.
   Reads the saved theme preference from localStorage and applies
   the data-theme attribute to <html> immediately. Default is light mode. */
(function() {
    var saved = localStorage.getItem('idash_theme');
    if (saved === 'dark') {
        document.documentElement.removeAttribute('data-theme');
    } else {
        document.documentElement.setAttribute('data-theme', 'light');
    }
})();
