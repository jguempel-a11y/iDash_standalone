/* iDash Theme Initializer - must load BEFORE first paint.
   Light mode is DEFAULT for all users unless explicitly set to 'dark'.
   Saved preference is stored in localStorage('idash_theme') and cookie for future logins. */
(function() {
    // Clear legacy keys if present
    try {
        localStorage.removeItem('aw_theme_preference');
        localStorage.removeItem('idash-theme');
    } catch(e) {}

    function getSavedTheme() {
        try {
            if (window.location.search.indexOf('theme=light') !== -1) return 'light';
            if (window.location.search.indexOf('theme=dark') !== -1) return 'dark';
            var t = localStorage.getItem('idash_theme');
            if (t === 'dark' || t === 'light') return t;
            var m = document.cookie.match(/(?:^|;\s*)idash_theme=([^;]+)/);
            if (m && (m[1] === 'dark' || m[1] === 'light')) return m[1];
        } catch(e) {}
        return 'light'; // Default is light mode for all users
    }

    var current = getSavedTheme();
    if (current === 'dark') {
        document.documentElement.removeAttribute('data-theme');
    } else {
        document.documentElement.setAttribute('data-theme', 'light');
    }

    window.toggleTheme = function() {
        var html = document.documentElement;
        var isLight = html.getAttribute('data-theme') === 'light';
        var next = isLight ? 'dark' : 'light';
        if (next === 'dark') {
            html.removeAttribute('data-theme');
        } else {
            html.setAttribute('data-theme', 'light');
        }
        try {
            localStorage.setItem('idash_theme', next);
            document.cookie = 'idash_theme=' + next + '; path=/; max-age=31536000; SameSite=Lax';
        } catch(e) {}

        if (typeof updateThemeIcon === 'function') {
            updateThemeIcon();
        }
        if (typeof updateThemeBtn === 'function') {
            updateThemeBtn();
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

    window.toggleIdashTheme = window.toggleTheme;
})();
