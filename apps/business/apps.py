"""
apps/business/apps.py - AppConfig for the business profiles app.
"""

from django.apps import AppConfig


class BusinessConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.business'
    label = 'business'
    verbose_name = 'Business Profiles'

    def ready(self):
        import apps.business.signals  # Connect signals for auto QR code generation
