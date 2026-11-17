"""
apps/qrcodes/apps.py - AppConfig for the qrcodes app.
"""

from django.apps import AppConfig


class QrcodesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.qrcodes'
    label = 'qrcodes'
    verbose_name = 'QR Codes'

    def ready(self):
        import apps.qrcodes.signals  # Connect post_save signals for automatic QR generation
