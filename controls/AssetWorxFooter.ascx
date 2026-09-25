<%@ Control Language="C#" AutoEventWireup="true" %>

<footer class="idash-footer" style="margin-top: 24px; padding: 14px 20px; border-top: 1px solid var(--line, #1f2a44); font-size: 12px; color: var(--muted, #8aa0c5); opacity: 0.95; background: var(--bg, #0b1120);">
    <div class="idash-footer-inner" style="display: flex; justify-content: space-between; align-items: center; max-width: 1400px; margin: 0 auto; flex-wrap: wrap; gap: 12px;">

        <div class="idash-left" style="display: flex; align-items: center; gap: 10px;">
            <img src="<%= ResolveUrl("~/Assets/branding/rfid.png") %>"
                 alt="iDash Platform"
                 class="idash-logo" style="height: 20px; width: auto;" />

            <span class="idash-name" style="font-weight: 700; letter-spacing: 0.5px; line-height: 1; font-size: 14px; color: var(--text, #f8fafc);">
                iDash<span class="dot" style="color: var(--accent, #2ea8ff); margin-left: 2px;">.</span>
            </span>

            <span style="color: var(--muted, #8aa0c5); font-size: 11px; font-weight: 500;">RFID Asset Intelligence Platform</span>
        </div>

        <div style="display: flex; align-items: center; gap: 16px;">
            <!-- Theme Toggle -->
            <button type="button" id="theme-toggle-btn" onclick="toggleTheme()" 
                style="background: var(--card, #131d31); color: var(--text, #f8fafc); border: 1px solid var(--line, #1f2a44); padding: 5px 12px; border-radius: 20px; cursor: pointer; font-size: 11px; font-weight: 700; display: flex; align-items: center; gap: 6px; transition: all 0.2s;">
                <span id="theme-icon">&#9728;</span> <span id="theme-text">Light Mode</span>
            </button>

            <div class="idash-right" style="display: flex; align-items: center; gap: 10px;">
                <span class="copy" style="line-height: 1; font-size: 11px;">
                    iDash Platform &mdash; ID Integration Inc. &copy; <%= DateTime.Now.Year %>
                </span>

                <img src="<%= ResolveUrl("~/Assets/branding/IDIntegration.jpg") %>"
                     alt="ID Integration Inc."
                     class="id-logo" style="height: 14px; width: auto; opacity: 0.9;" />
            </div>
        </div>

    </div>

    <script>
        (function() {
            if (!document.getElementById('idash-theme-link')) {
                const link = document.createElement('link');
                link.id = 'idash-theme-link';
                link.rel = 'stylesheet';
                link.href = '<%= ResolveUrl("~/theme.css") %>';
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
                const btn = document.getElementById('theme-toggle-btn');
                const icon = document.getElementById('theme-icon');
                const text = document.getElementById('theme-text');
                if (!btn || !icon || !text) return;
                if (theme === 'dark') {
                    icon.innerHTML = '&#9728;';
                    text.innerText = 'Light Mode';
                } else {
                    icon.innerHTML = '&#9790;';
                    text.innerText = 'Dark Mode';
                }
            }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => updateUI(savedTheme));
            } else {
                updateUI(savedTheme);
            }
        })();
    </script>
</footer>
