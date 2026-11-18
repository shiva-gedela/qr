import tempfile
import threading
from concurrent.futures import ThreadPoolExecutor
from datetime import date, timedelta

from django.contrib.auth import get_user_model
from django.db import IntegrityError, transaction
from django.test import Client
from django.test import TransactionTestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from .models import Event, EventCheckIn, EventGuest, EventStaff, Invitation, QRScanLog
from apps.qrcodes.models import QRCode


class EventInvitationAPITests(TransactionTestCase):
    reset_sequences = True

    def setUp(self):
        user_model = get_user_model()
        self.owner = user_model.objects.create_user(
            username='event-owner', email='owner@example.com', password='password123'
        )
        self.scanner = user_model.objects.create_user(
            username='event-scanner', email='scanner@example.com', password='password123'
        )
        self.other_user = user_model.objects.create_user(
            username='unassigned', email='other@example.com', password='password123'
        )
        self.event = Event.objects.create(
            owner=self.owner, title='Test event', host_names='Hosts', event_date=date(2027, 1, 1), capacity=5
        )
        EventStaff.objects.create(event=self.event, user=self.scanner, role='scanner')

    def invitation(self, event=None, status='active', guest_count=1):
        guest = EventGuest.objects.create(
            event=event or self.event,
            name='Guest Name',
            email='guest@example.com',
            guest_count=guest_count,
            invitation_type='vip',
        )
        invitation = Invitation.objects.create(guest=guest, status=status)
        return guest, invitation

    def scanner_client(self):
        client = APIClient()
        client.force_authenticate(user=self.scanner)
        return client

    def test_guest_creation_issues_unique_invitation_qr(self):
        with tempfile.TemporaryDirectory() as media_dir:
            with override_settings(MEDIA_ROOT=media_dir):
                client = APIClient()
                client.force_authenticate(user=self.owner)
                response = client.post(
                    f'/api/events/{self.event.pk}/guests/',
                    {
                        'name': 'New Guest',
                        'mobile': '555-0100',
                        'email': 'new@example.com',
                        'guest_count': 2,
                        'invitation_type': 'vip',
                    },
                    format='json',
                )
                self.assertEqual(response.status_code, 201, response.data)
                guest = EventGuest.objects.get(pk=response.data['id'])
                self.assertEqual(guest.invitation.token, Invitation.objects.get(guest=guest).token)
                self.assertEqual(guest.invitation.qr_code.invitation_id, guest.invitation.pk)
                self.assertIn(str(guest.invitation.token), response.data['invitation_url'])
                self.assertNotIn(guest.email, response.data['invitation_url'])
                invitation_path = f'/events/invitation/{guest.invitation.token}/'
                invitation_page = client.get(invitation_path)
                self.assertEqual(invitation_page.status_code, 200)
                self.assertEqual(invitation_page['X-Robots-Tag'], 'noindex, nofollow')
                self.assertEqual(client.get(
                    f'/qr/download/pdf/{guest.invitation.qr_code.uuid}/'
                ).status_code, 200)
                with self.assertRaises(IntegrityError):
                    with transaction.atomic():
                        QRCode.objects.create(
                            invitation=guest.invitation,
                            target_url=response.data['invitation_url'],
                        )

    def test_check_in_is_approved_once_and_duplicate_is_reported(self):
        guest, invitation = self.invitation(guest_count=2)
        client = self.scanner_client()

        approved = client.post(
            f'/api/events/{self.event.pk}/check-in/', {'token': str(invitation.token)}, format='json'
        )
        duplicate = client.post(
            f'/api/events/{self.event.pk}/check-in/', {'token': str(invitation.token)}, format='json'
        )

        self.assertEqual(approved.data['result'], 'approved')
        self.assertEqual(approved.data['guest']['guest_count'], 2)
        self.assertEqual(duplicate.data['result'], 'already_checked_in')
        self.assertEqual(EventCheckIn.objects.filter(invitation=invitation).count(), 1)
        self.assertEqual(QRScanLog.objects.filter(invitation=invitation).count(), 2)

    def test_wrong_event_cancelled_and_invalid_tokens_are_logged_without_guest_details(self):
        _, invitation = self.invitation()
        other_event = Event.objects.create(
            owner=self.owner, title='Other event', host_names='Hosts', event_date=date(2027, 1, 2)
        )
        client = self.scanner_client()

        wrong_event = client.post(
            f'/api/events/{self.event.pk}/check-in/', {'token': str(Invitation.objects.create(
                guest=EventGuest.objects.create(event=other_event, name='Other Guest')
            ).token)}, format='json',
        )
        cancelled_guest, cancelled = self.invitation(status='cancelled')
        cancelled_response = client.post(
            f'/api/events/{self.event.pk}/check-in/', {'token': str(cancelled.token)}, format='json'
        )
        invalid = client.post(f'/api/events/{self.event.pk}/check-in/', {'token': 'not-a-token'}, format='json')

        self.assertEqual(wrong_event.data, {'result': 'rejected', 'reason': 'wrong_event'})
        self.assertEqual(cancelled_response.data['reason'], 'cancelled')
        self.assertEqual(invalid.data, {'result': 'rejected', 'reason': 'invalid'})
        self.assertEqual(QRScanLog.objects.filter(event=self.event, result='rejected').count(), 3)

    def test_only_assigned_staff_can_check_in(self):
        _, invitation = self.invitation()
        client = APIClient()
        client.force_authenticate(user=self.other_user)

        response = client.post(
            f'/api/events/{self.event.pk}/check-in/', {'token': str(invitation.token)}, format='json'
        )

        self.assertEqual(response.status_code, 403)
        self.assertFalse(EventCheckIn.objects.filter(invitation=invitation).exists())
        self.assertFalse(QRScanLog.objects.exists())

    def test_mobile_login_returns_a_token_and_invitation_rsvp_is_recorded(self):
        guest, invitation = self.invitation()
        login_response = Client().post(
            '/api/login/',
            {'email': self.scanner.email, 'password': 'password123'},
            content_type='application/json',
        )
        self.assertEqual(login_response.status_code, 200)
        token = login_response.json()['token']
        self.assertTrue(token)
        token_response = Client().get('/api/events/', HTTP_AUTHORIZATION=f'Token {token}')
        self.assertEqual(token_response.status_code, 200)
        logout_response = Client().post('/api/logout/', HTTP_AUTHORIZATION=f'Token {token}')
        self.assertEqual(logout_response.status_code, 200)
        revoked_response = Client().get('/api/events/', HTTP_AUTHORIZATION=f'Token {token}')
        self.assertEqual(revoked_response.status_code, 401)

        guest_response = Client().post(
            f'/events/invitation/{invitation.token}/',
            {'action': 'confirm'},
        )
        self.assertEqual(guest_response.status_code, 302)
        guest.refresh_from_db()
        self.assertEqual(guest.status, 'registered')

    def test_owner_guest_dashboard_renders_with_no_invitations(self):
        client = Client()
        client.force_login(self.owner)

        response = client.get(f'/events/{self.event.pk}/guests/')

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Attendance overview')
        self.assertContains(response, 'No guests yet')

    def test_event_capacity_is_enforced(self):
        self.event.capacity = 1
        self.event.save(update_fields=['capacity'])
        _, first = self.invitation()
        _, second = self.invitation()
        client = self.scanner_client()

        self.assertEqual(client.post(
            f'/api/events/{self.event.pk}/check-in/', {'token': str(first.token)}, format='json'
        ).data['result'], 'approved')
        rejected = client.post(
            f'/api/events/{self.event.pk}/check-in/', {'token': str(second.token)}, format='json'
        )
        self.assertEqual(rejected.data, {'result': 'rejected', 'reason': 'capacity_reached'})

    def test_cancelled_guest_cannot_be_reissued_over_capacity(self):
        self.event.capacity = 1
        self.event.save(update_fields=['capacity'])
        cancelled_guest, cancelled_invitation = self.invitation(status='cancelled')
        cancelled_guest.status = 'cancelled'
        cancelled_guest.save(update_fields=['status', 'updated_at'])
        cancelled_invitation.status = 'cancelled'
        cancelled_invitation.save(update_fields=['status'])
        self.invitation()
        client = APIClient()
        client.force_authenticate(user=self.owner)

        response = client.patch(
            f'/api/events/{self.event.pk}/guests/{cancelled_guest.pk}/',
            {'status': 'invited'},
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        cancelled_guest.refresh_from_db()
        self.assertEqual(cancelled_guest.status, 'cancelled')

    def test_expired_invitation_is_rejected(self):
        _, invitation = self.invitation()
        invitation.expires_at = timezone.now() - timedelta(minutes=1)
        invitation.save(update_fields=['expires_at'])

        response = self.scanner_client().post(
            f'/api/events/{self.event.pk}/check-in/', {'token': str(invitation.token)}, format='json'
        )

        self.assertEqual(response.data, {'result': 'rejected', 'reason': 'expired'})
        second_response = self.scanner_client().post(
            f'/api/events/{self.event.pk}/check-in/', {'token': str(invitation.token)}, format='json'
        )
        self.assertEqual(second_response.data, {'result': 'rejected', 'reason': 'expired'})
        invitation.refresh_from_db()
        self.assertEqual(invitation.status, 'expired')
        self.assertFalse(EventCheckIn.objects.filter(invitation=invitation).exists())

    def test_report_and_live_summary_reflect_check_in_and_rejected_scan(self):
        _, invitation = self.invitation(guest_count=2)
        client = self.scanner_client()
        client.post(f'/api/events/{self.event.pk}/check-in/', {'token': str(invitation.token)}, format='json')
        client.post(f'/api/events/{self.event.pk}/check-in/', {'token': 'invalid'}, format='json')

        summary = client.get(f'/api/events/{self.event.pk}/check-in/')
        self.assertEqual(summary.data, {'approved_entries': 1, 'checked_in_guests': 2})
        report_client = APIClient()
        report_client.force_authenticate(user=self.owner)
        report = report_client.get(f'/api/events/{self.event.pk}/reports/?history=true')
        self.assertEqual(report.data['approved_entries'], 1)
        self.assertEqual(report.data['checked_in_guests'], 2)
        self.assertEqual(report.data['rejected_scans'], 1)
        self.assertEqual(len(report.data['scan_history']), 2)
        EventGuest.objects.create(event=self.event, name='=1+1')
        csv_report = report_client.get(f'/api/events/{self.event.pk}/reports/?download=csv')
        self.assertEqual(csv_report.status_code, 200)
        self.assertTrue(csv_report['Content-Type'].startswith('text/csv'))
        self.assertIn(b"'=1+1", csv_report.content)

    def test_simultaneous_scans_create_only_one_check_in(self):
        _, invitation = self.invitation()
        barrier = threading.Barrier(2)

        def scan():
            client = self.scanner_client()
            barrier.wait(timeout=5)
            return client.post(
                f'/api/events/{self.event.pk}/check-in/', {'token': str(invitation.token)}, format='json'
            )

        with ThreadPoolExecutor(max_workers=2) as executor:
            responses = list(executor.map(lambda _index: scan(), range(2)))

        self.assertEqual(EventCheckIn.objects.filter(invitation=invitation).count(), 1)
        self.assertEqual(
            sorted(response.data['result'] for response in responses),
            ['already_checked_in', 'approved'],
        )
