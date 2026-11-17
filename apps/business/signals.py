"""
apps/business/signals.py

Signals to auto-generate or synchronize Business QR codes upon creation or updates.
"""

from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Business


@receiver(post_save, sender=Business)
def auto_generate_business_qr(sender, instance, created, **kwargs):
    """
    Ensure every Business Profile has an active branded QR code pointing
    to its permanent public digital profile URL.
    """
    try:
        from apps.qrcodes.services import generate_or_update_business_qr
        generate_or_update_business_qr(instance)
    except Exception as e:
        pass
