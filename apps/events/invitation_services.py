import uuid

from django.conf import settings
from django.core.files.base import ContentFile
from django.db import transaction
from django.urls import reverse

from apps.qrcodes.models import QRCode
from apps.qrcodes.services import create_qr_image_buffer
from .models import EventGuest, Invitation


def ensure_invitation_qr(guest: EventGuest, base_url=None):
    invitation, created_invitation = Invitation.objects.get_or_create(guest=guest)
    if not created_invitation and invitation.status != 'cancelled' and (
        invitation.status == 'expired' or invitation.is_expired
    ):
        invitation.status = 'active'
        invitation.token = uuid.uuid4()
        invitation.expires_at = None
        invitation.save(update_fields=['status', 'token', 'expires_at'])
    if not base_url:
        base_url = getattr(settings, 'SITE_URL', 'http://127.0.0.1:8000')
    target_url = f"{base_url.rstrip('/')}{reverse('event_invitation', kwargs={'token': invitation.token})}"
    qr, created = QRCode.objects.get_or_create(
        invitation=invitation,
        defaults={'qr_type': 'event', 'target_url': target_url},
    )
    target_changed = qr.target_url != target_url
    if target_changed:
        qr.target_url = target_url
    regenerate = created or target_changed or not qr.qr_image
    if regenerate:
        old_image_name = qr.qr_image.name if qr.qr_image else None
        image = create_qr_image_buffer(target_url, fill_color=qr.fill_color, back_color=qr.back_color)
        qr.qr_image.save(f"invitation_{invitation.token}.png", ContentFile(image.getvalue()), save=False)
        qr.save()
        if target_changed and old_image_name:
            storage = qr.qr_image.storage
            transaction.on_commit(lambda: storage.delete(old_image_name))
    return invitation, qr
