/* iDash Theme Initializer — must load BEFORE first paint.
   Reads the saved theme preference from localStorage and applies
   the data-theme attribute to <html> immediately. */
(function() {
    var saved = localStorage.getItem('idash_theme');
    if (saved) {
        document.documentElement.setAttribute('data-theme', saved);
    }
})();
