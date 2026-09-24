/* iDash Theme Initializer - must load BEFORE first paint.
   Reads the saved theme preference from localStorage and applies
   the data-theme attribute to <html> immediately. Default is light mode. */
(function() {
    var saved = localStorage.getItem('idash_theme') || localStorage.getItem('aw_theme_preference');
    if (saved === 'dark') {
        document.documentElement.removeAttribute('data-theme');
    } else {
        document.documentElement.setAttribute('data-theme', 'light');
    }

    window.toggleTheme = function() {
        var html = document.documentElement;
        var isLight = html.getAttribute('data-theme') === 'light';
        if (isLight) {
            html.removeAttribute('data-theme');
            localStorage.setItem('idash_theme', 'dark');
            localStorage.setItem('aw_theme_preference', 'dark');
        } else {
            html.setAttribute('data-theme', 'light');
            localStorage.setItem('idash_theme', 'light');
            localStorage.setItem('aw_theme_preference', 'light');
        }
        if (typeof updateThemeIcon === 'function') {
            updateThemeIcon();
        }

        // Auto re-focus scanner input if present so scanner is not left paused
        setTimeout(function() {
            if (typeof focusScan === 'function') {
                focusScan();
            } else {
                var scanBox = document.getElementById('raw');
                if (scanBox) {
                    try { scanBox.focus(); } catch (e) {}
                }
            }
        }, 60);
    };
})();
