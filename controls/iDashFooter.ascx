<%@ Control Language="C#" AutoEventWireup="true" %>

<footer class="idash-footer" style="margin-top: 15px; padding: 12px 16px; border-top: 1px solid var(--line, #1f2a44); font-size: 11px; color: var(--muted, #8aa0c5); opacity: 0.95;">
    <div class="idash-footer-inner" style="display: flex; justify-content: space-between; align-items: center; max-width: 1400px; margin: 0 auto;">

        <div class="idash-left" style="display: flex; align-items: center; gap: 8px;">
            <img src="<%= ResolveUrl("~/Assets/branding/IDIntegration.jpg") %>"
                 alt="ID Integration Inc."
                 class="id-logo" style="height: 18px; width: auto; border-radius: 3px;" />

            <span class="idash-name" style="font-weight: 700; letter-spacing: 0.5px; line-height: 1; font-size: 14px; color: var(--text);">
                iDash<span class="bang" style="color: var(--accent, #2ea8ff); margin-left: 1px;">.</span>
            </span>

            <span style="color: var(--muted, #8aa0c5); font-size: 11px; margin-left: 4px;">by ID Integration Inc.</span>
        </div>

        <div style="display: flex; align-items: center; gap: 15px;">
            <!-- Theme Toggle -->
            <button type="button" id="theme-toggle-btn" onclick="toggleTheme()" 
                style="background: var(--card); color: var(--text); border: 1px solid var(--line); padding: 5px 12px; border-radius: 20px; cursor: pointer; font-size: 11px; font-weight: 700; display: flex; align-items: center; gap: 6px; transition: all 0.2s;">
                <span id="theme-icon">&#9728;</span> <span id="theme-text">Light Mode</span>
            </button>

            <div class="idash-right" style="display: flex; align-items: center; gap: 8px;">
                <span class="copy" style="line-height: 1; color: var(--muted, #8aa0c5);">
                    RFID Asset Intelligence &bull; &copy; <%= DateTime.Now.Year %> ID Integration Inc.
                </span>
            </div>
        </div>

    </div>

    <script>
        (function() {
            // Inject global theme styles
            if (!document.getElementById('idash-theme-link')) {
                const link = document.createElement('link');
                link.id = 'idash-theme-link';
                link.rel = 'stylesheet';
                link.href = '/iDash/theme.css';
                document.head.appendChild(link);
            }

            const savedTheme = localStorage.getItem('idash_theme') || 'dark';
            document.documentElement.setAttribute('data-theme', savedTheme);
            
            window.toggleTheme = function() {
                const current = document.documentElement.getAttribute('data-theme');
                const next = current === 'dark' ? 'light' : 'dark';
                document.documentElement.setAttribute('data-theme', next);
                localStorage.setItem('idash_theme', next);
                updateUI(next);
            };

            function updateUI(theme) {
                const icon = document.getElementById('theme-icon');
                const text = document.getElementById('theme-text');
                if (icon && text) {
                    icon.innerHTML = theme === 'dark' ? '&#9728;' : '&#9790;';
                    text.innerHTML = theme === 'dark' ? 'Light Mode' : 'Dark Mode';
                }
            }

            // Initial UI sync
            updateUI(savedTheme);
        })();
    </script>
</footer>
