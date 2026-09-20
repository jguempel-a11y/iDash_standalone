/* iDash Theme Initializer — must load BEFORE first paint.
   Reads the saved theme preference from localStorage and applies
   the data-theme attribute to <html> immediately. */
(function() {
    var saved = localStorage.getItem('idash_theme') || localStorage.getItem('aw_theme_preference');
    if (saved === 'light') {
        document.documentElement.setAttribute('data-theme', 'light');
    } else if (saved === 'dark') {
        document.documentElement.removeAttribute('data-theme');
    } else if (saved) {
        document.documentElement.setAttribute('data-theme', saved);
    }

    window.toggleTheme = function() {
        var html = document.documentElement;
        var isLight = html.getAttribute('data-theme') === 'light';
        if (isLight) {
            html.removeAttribute('data-theme');
            localStorage.removeItem('idash_theme');
            localStorage.setItem('aw_theme_preference', 'dark');
        } else {
            html.setAttribute('data-theme', 'light');
            localStorage.setItem('idash_theme', 'light');
            localStorage.setItem('aw_theme_preference', 'light');
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
