"""
apps/qrcodes/api_urls.py - REST API endpoints for QR code functionality.
"""

from django.urls import path
from . import api_views

urlpatterns = [
    path('event/<int:event_pk>/', api_views.EventQRCodeAPIView.as_view(), name='api_event_qr'),
    path('event/<int:event_pk>/customize/', api_views.EventQRCodeAPIView.as_view(), name='api_event_qr_customize'),
    path('scan/<uuid:qr_uuid>/', api_views.ScanQRCodeAPIView.as_view(), name='api_qr_scan'),
]
