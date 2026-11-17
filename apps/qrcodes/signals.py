"""
apps/qrcodes/signals.py

Signals to automatically generate or sync QR codes when Events are created or updated.
"""

from django.db.models.signals import post_save
from django.dispatch import receiver
from apps.events.models import Event
from .services import generate_or_update_event_qr


@receiver(post_save, sender=Event)
def auto_generate_event_qr(sender, instance, created, **kwargs):
    """
    Ensure every event has an active, valid QR code pointing to its public mini-website.
    If the event is already created, only refresh if target_url or slug changed.
    """
    try:
        generate_or_update_event_qr(instance)
    except Exception as e:
        # Don't block event saving if QR generation encounters an issue
        pass
