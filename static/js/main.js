/**
 * EventConnect QR - Main JavaScript
 * Provides: auto-dismiss alerts, file upload preview, copy link, tooltips.
 */

document.addEventListener('DOMContentLoaded', () => {

    // ── Auto-dismiss alerts after 6 seconds ──────────────────────────────
    document.querySelectorAll('.alert.alert-dismissible').forEach(alert => {
        setTimeout(() => {
            const bsAlert = bootstrap.Alert.getOrCreateInstance(alert);
            if (bsAlert) bsAlert.close();
        }, 6000);
    });

    // ── Enable Bootstrap Tooltips ─────────────────────────────────────────
    document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
        new bootstrap.Tooltip(el);
    });

    // ── Enable Bootstrap Popovers ─────────────────────────────────────────
    document.querySelectorAll('[data-bs-toggle="popover"]').forEach(el => {
        new bootstrap.Popover(el);
    });

    // ── File Upload Preview ───────────────────────────────────────────────
    const fileInputs = document.querySelectorAll('input[type="file"][multiple]');
    fileInputs.forEach(input => {
        input.addEventListener('change', () => {
            const files = Array.from(input.files);
            const count = files.length;
            const totalMb = (files.reduce((sum, f) => sum + f.size, 0) / 1024 / 1024).toFixed(2);

            // Find or create preview badge
            let badge = input.parentElement.querySelector('.upload-preview-badge');
            if (!badge) {
                badge = document.createElement('div');
                badge.className = 'upload-preview-badge alert alert-info mt-2 py-2 px-3 small mb-0';
                input.parentElement.appendChild(badge);
            }
            badge.innerHTML = `<i class="bi bi-files me-2"></i><strong>${count}</strong> file${count !== 1 ? 's' : ''} selected &mdash; ${totalMb} MB total`;
        });
    });

    // ── Copy to Clipboard utility (global function) ───────────────────────
    window.copyToClipboard = function(text, btn) {
        navigator.clipboard.writeText(text).then(() => {
            if (btn) {
                const original = btn.innerHTML;
                btn.innerHTML = '<i class="bi bi-check-lg me-1"></i>Copied!';
                btn.classList.add('btn-success');
                btn.classList.remove('btn-outline-secondary');
                setTimeout(() => {
                    btn.innerHTML = original;
                    btn.classList.remove('btn-success');
                    btn.classList.add('btn-outline-secondary');
                }, 2500);
            }
        }).catch(() => {
            // Fallback for older browsers
            const textarea = document.createElement('textarea');
            textarea.value = text;
            document.body.appendChild(textarea);
            textarea.select();
            document.execCommand('copy');
            document.body.removeChild(textarea);
        });
    };

    // ── Confirm dangerous actions ─────────────────────────────────────────
    document.querySelectorAll('[data-confirm]').forEach(el => {
        el.addEventListener('click', (e) => {
            if (!confirm(el.dataset.confirm)) {
                e.preventDefault();
            }
        });
    });

    // ── Smooth scroll for anchor links ────────────────────────────────────
    document.querySelectorAll('a[href^="#"]').forEach(link => {
        link.addEventListener('click', (e) => {
            const target = document.querySelector(link.getAttribute('href'));
            if (target) {
                e.preventDefault();
                target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        });
    });

});
