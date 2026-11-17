"""
apps/qrcodes/urls.py - URL patterns for web QR code interactions.
"""

from django.urls import path
from . import views

urlpatterns = [
    # Downloads & Scan
    path('download/png/<uuid:qr_uuid>/', views.download_qr_png, name='qr_download_png'),
    path('download/pdf/<uuid:qr_uuid>/', views.download_qr_pdf, name='qr_download_pdf'),
    path('scan/<uuid:qr_uuid>/', views.qr_scan_redirect, name='qr_scan_redirect'),

    # Event QR customization
    path('event/<int:event_pk>/customize/', views.customize_event_qr, name='event_qr_customize'),

    # Business QR customization
    path('business/<int:business_pk>/customize/', views.customize_business_qr, name='business_qr_customize'),

    # Live preview helper
    path('preview/', views.qr_live_preview, name='qr_live_preview'),
]
