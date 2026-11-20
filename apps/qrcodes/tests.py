"""
apps/qrcodes/tests.py

Automated test suite for QR Code functionality:
- QR code generation and customization
- PNG and PDF download responses
- Dynamic scan redirect and counter increment
- REST API QR endpoints for mobile apps
"""

import uuid
from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from apps.events.models import Event
from apps.qrcodes.models import QRCode
from apps.qrcodes.services import generate_or_update_event_qr, generate_event_qr_pdf

User = get_user_model()


class QRCodeTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email='qr_tester@example.com',
            username='qr_tester@example.com',
            password='TestPassword123!',
        )
        self.event = Event.objects.create(
            owner=self.user,
            title='Tech Fest Hyderabad',
            event_type='conference',
            event_date='2026-12-10',
            event_time='10:00:00',
            host_names='QRouteX Events',
            venue_name='HICC Novotel',
            venue_address='HITEC City, Hyderabad, Telangana',
            is_published=True,
        )
        self.qr = generate_or_update_event_qr(self.event)
        self.client = Client()
        self.api_client = APIClient()

    def test_qr_code_creation_and_attributes(self):
        self.assertIsNotNone(self.qr)
        self.assertEqual(self.qr.event, self.event)
        self.assertIsNotNone(self.qr.uuid)
        self.assertTrue(self.qr.qr_image)

    def test_qr_download_png(self):
        url = reverse('qr_download_png', kwargs={'qr_uuid': self.qr.uuid})
        resp = self.client.get(url)
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp['Content-Type'], 'image/png')

    def test_qr_download_pdf(self):
        url = reverse('qr_download_pdf', kwargs={'qr_uuid': self.qr.uuid})
        resp = self.client.get(url)
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp['Content-Type'], 'application/pdf')
        self.assertIn(b'%PDF', resp.content[:10])

    def test_qr_scan_redirect_increments_counter(self):
        initial_scans = self.qr.scan_count
        url = reverse('qr_scan_redirect', kwargs={'qr_uuid': self.qr.uuid})
        resp = self.client.get(url)
        self.assertEqual(resp.status_code, 302)
        self.qr.refresh_from_db()
        self.assertEqual(self.qr.scan_count, initial_scans + 1)

    def test_api_event_qr_endpoint(self):
        self.api_client.force_authenticate(user=self.user)
        url = reverse('api_event_qr', kwargs={'event_pk': self.event.pk})
        resp = self.api_client.get(url)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['uuid'], str(self.qr.uuid))
        self.assertIn('download_png_url', resp.data)
        self.assertIn('download_pdf_url', resp.data)

    def test_api_qr_scan_metadata(self):
        url = reverse('api_qr_scan', kwargs={'qr_uuid': self.qr.uuid})
        resp = self.api_client.post(url)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('target_url', resp.data)
        self.assertIn('event', resp.data)
        self.assertEqual(resp.data['event']['title'], 'Tech Fest Hyderabad')
