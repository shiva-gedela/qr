"""
apps/qrcodes/api_views.py - REST API endpoints for QR code handling.
Used by the Flutter mobile application.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db.models import F

from apps.events.models import Event
from .models import QRCode
from .serializers import QRCodeSerializer
from .services import generate_or_update_event_qr


class EventQRCodeAPIView(APIView):
    """
    GET /api/qr/event/<int:event_pk>/ - Retrieve QR code data for an event.
    POST /api/qr/event/<int:event_pk>/customize/ - Update QR code colors/logo.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, event_pk):
        event = get_object_or_404(Event, pk=event_pk, owner=request.user)
        qr = getattr(event, 'qr_code', None)
        if not qr:
            qr = generate_or_update_event_qr(event)

        serializer = QRCodeSerializer(qr, context={'request': request})
        return Response(serializer.data)

    def post(self, request, event_pk):
        event = get_object_or_404(Event, pk=event_pk, owner=request.user)
        fill_color = request.data.get('fill_color')
        back_color = request.data.get('back_color')
        logo = request.FILES.get('logo')

        qr = generate_or_update_event_qr(
            event=event,
            fill_color=fill_color,
            back_color=back_color,
            logo_file=logo,
        )

        serializer = QRCodeSerializer(qr, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)


class ScanQRCodeAPIView(APIView):
    """
    POST /api/qr/scan/<uuid:qr_uuid>/ - Invoked by Flutter scanner when a QR is scanned.
    Records the scan metric and returns the target URL and event details.
    """

    permission_classes = [AllowAny]

    def post(self, request, qr_uuid):
        qr = get_object_or_404(QRCode, uuid=qr_uuid)
        QRCode.objects.filter(uuid=qr_uuid).update(
            scan_count=F('scan_count') + 1,
            last_scanned_at=timezone.now()
        )
        qr.refresh_from_db()

        data = {
            'target_url': qr.target_url,
            'qr_type': qr.qr_type,
            'scan_count': qr.scan_count,
        }
        if qr.event:
            data['event'] = {
                'id': qr.event.id,
                'slug': qr.event.slug,
                'title': qr.event.title,
                'is_published': qr.event.is_published,
                'is_private': qr.event.is_private,
            }

        return Response(data, status=status.HTTP_200_OK)
