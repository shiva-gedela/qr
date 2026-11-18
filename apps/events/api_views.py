"""
apps/events/api_views.py - REST API views for events (Flutter integration).
"""

import csv
import uuid
from threading import RLock

from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.db import IntegrityError, connection, transaction
from django.db.models import Q, Sum
from django.http import HttpResponse
from django.utils import timezone
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from rest_framework.views import APIView
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404
from django.http import Http404

from .invitation_services import ensure_invitation_qr
from .models import Event, EventCheckIn, EventGuest, EventStaff, Invitation, QRScanLog
from .permissions import can_access_event, can_manage_guests
from .serializers import (
    EventCreateSerializer, EventGuestSerializer, EventSerializer, EventStaffSerializer,
)

_SQLITE_CHECK_IN_LOCK = RLock()


def _csv_safe(value):
    text = str(value or '')
    if text.lstrip().startswith(('=', '+', '-', '@', '\t', '\r')):
        return f"'{text}"
    return text


class EventListCreateAPIView(ListCreateAPIView):
    """GET /api/events/ - List user's events. POST - Create event."""

    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Event.objects.filter(
            Q(owner=self.request.user) | Q(staff_members__user=self.request.user)
        ).distinct().order_by('-created_at')

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return EventCreateSerializer
        return EventSerializer

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class EventRetrieveUpdateDestroyAPIView(RetrieveUpdateDestroyAPIView):
    """GET/PUT/PATCH/DELETE /api/events/<pk>/ - Manage a single event (owner only)."""

    permission_classes = [IsAuthenticated]
    serializer_class = EventSerializer

    def get_object(self):
        return get_object_or_404(Event, pk=self.kwargs['pk'], owner=self.request.user)


class EventTogglePublishAPIView(APIView):
    """POST /api/events/<pk>/publish/ - Toggle published state."""

    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        event = get_object_or_404(Event, pk=pk, owner=request.user)
        event.is_published = not event.is_published
        event.save(update_fields=['is_published'])
        return Response({'is_published': event.is_published})


class EventPublicAPIView(APIView):
    """GET /api/events/public/<slug>/ - Public event data for Flutter."""

    permission_classes = [AllowAny]

    def get(self, request, slug):
        event = get_object_or_404(Event, slug=slug, is_published=True)
        serializer = EventSerializer(event, context={'request': request})
        return Response(serializer.data)


# ─── Media REST API Endpoints ────────────────────────────────────────────────

class EventMediaListCreateAPIView(APIView):
    """
    GET /api/events/<int:pk>/media/ - List media items (owner only).
    POST /api/events/<int:pk>/media/upload/ - Upload photos/videos.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        event = get_object_or_404(Event, pk=pk, owner=request.user)
        category = request.query_params.get('category')
        media_type = request.query_params.get('type')
        approved = request.query_params.get('approved')

        qs = event.media.all()
        if category and category != 'all':
            qs = qs.filter(category=category)
        if media_type:
            qs = qs.filter(media_type=media_type)
        if approved is not None:
            qs = qs.filter(is_approved=(approved.lower() == 'true'))

        from .serializers import EventMediaSerializer
        serializer = EventMediaSerializer(qs, many=True, context={'request': request})
        return Response({
            'count': qs.count(),
            'storage': {
                'used_mb': event.used_storage_mb,
                'max_mb': event.max_storage_mb,
                'percentage': event.storage_percentage,
                'is_full': event.is_storage_full,
            },
            'results': serializer.data,
        })

    def post(self, request, pk):
        event = get_object_or_404(Event, pk=pk, owner=request.user)

        if event.is_storage_full:
            return Response({'error': 'Storage limit reached.'}, status=status.HTTP_400_BAD_REQUEST)

        files = request.FILES.getlist('files')
        if not files and 'file' in request.FILES:
            files = [request.FILES['file']]

        if not files:
            return Response({'error': 'No file provided.'}, status=status.HTTP_400_BAD_REQUEST)

        from .views import _validate_media_file
        from .models import EventMedia
        from .serializers import EventMediaSerializer

        category = request.data.get('category', 'general')
        caption = request.data.get('caption', '')
        is_public = str(request.data.get('is_public', 'true')).lower() == 'true'

        uploaded_items = []
        errors = []

        for f in files:
            m_type, err = _validate_media_file(f)
            if err:
                errors.append(f"{f.name}: {err}")
                continue

            media = EventMedia(
                event=event,
                uploaded_by=request.user,
                media_type=m_type,
                caption=caption,
                category=category,
                is_public=is_public,
                is_approved=True,
                file_size=f.size,
            )
            media.file = f
            media.save()
            uploaded_items.append(media)

        return Response({
            'uploaded_count': len(uploaded_items),
            'errors': errors,
            'items': EventMediaSerializer(uploaded_items, many=True, context={'request': request}).data
        }, status=status.HTTP_201_CREATED if uploaded_items else status.HTTP_400_BAD_REQUEST)


class EventMediaDeleteAPIView(APIView):
    """DELETE /api/events/<int:pk>/media/<int:media_id>/ - Delete a media file."""

    permission_classes = [IsAuthenticated]

    def delete(self, request, pk, media_id):
        from .models import EventMedia
        event = get_object_or_404(Event, pk=pk, owner=request.user)
        media = get_object_or_404(EventMedia, pk=media_id, event=event)

        if media.file:
            try:
                media.file.delete(save=False)
            except Exception:
                pass
        if media.thumbnail:
            try:
                media.thumbnail.delete(save=False)
            except Exception:
                pass
        media.delete()
        return Response({'message': 'Media deleted successfully.'}, status=status.HTTP_200_OK)


class EventMediaToggleApprovalAPIView(APIView):
    """POST /api/events/<int:pk>/media/<int:media_id>/toggle-approval/ - Approve/unapprove media."""

    permission_classes = [IsAuthenticated]

    def post(self, request, pk, media_id):
        from .models import EventMedia
        from .serializers import EventMediaSerializer

        event = get_object_or_404(Event, pk=pk, owner=request.user)
        media = get_object_or_404(EventMedia, pk=media_id, event=event)
        media.is_approved = not media.is_approved
        media.save(update_fields=['is_approved'])
        return Response(EventMediaSerializer(media, context={'request': request}).data)


class PublicEventGalleryAPIView(APIView):
    """GET /api/events/public/<slug>/media/ - Public gallery items with category filter."""

    permission_classes = [AllowAny]

    def get(self, request, slug):
        event = get_object_or_404(Event, slug=slug, is_published=True)
        category = request.query_params.get('category')
        media_type = request.query_params.get('type')

        qs = event.media.filter(is_approved=True, is_public=True)
        if category and category != 'all':
            qs = qs.filter(category=category)
        if media_type:
            qs = qs.filter(media_type=media_type)

        from .serializers import EventMediaSerializer
        serializer = EventMediaSerializer(qs, many=True, context={'request': request})
        return Response({
            'event': event.title,
            'count': qs.count(),
            'categories': event.get_categories_with_counts(),
            'results': serializer.data,
        })


class PublicEventGuestUploadAPIView(APIView):
    """POST /api/events/public/<slug>/guest-upload/ - Guest uploads from mobile or web."""

    permission_classes = [AllowAny]

    def post(self, request, slug):
        event = get_object_or_404(Event, slug=slug, is_published=True)

        if not event.allow_guest_uploads:
            return Response({'error': 'Guest uploads disabled for this event.'}, status=status.HTTP_403_FORBIDDEN)

        if event.is_storage_full:
            return Response({'error': 'Gallery storage limit reached.'}, status=status.HTTP_400_BAD_REQUEST)

        files = request.FILES.getlist('files')
        if not files and 'file' in request.FILES:
            files = [request.FILES['file']]

        if not files:
            return Response({'error': 'No file provided.'}, status=status.HTTP_400_BAD_REQUEST)

        from .views import _validate_media_file
        from .models import EventMedia
        from .serializers import EventMediaSerializer

        category = request.data.get('category', 'candid')
        uploader_name = request.data.get('uploader_name', '').strip()
        caption_text = request.data.get('caption', '').strip()
        full_caption = f"{caption_text} — by {uploader_name}".strip(' — by ') if uploader_name else caption_text

        is_approved = not event.require_media_approval
        uploaded_items = []
        errors = []

        for f in files:
            m_type, err = _validate_media_file(f)
            if err:
                errors.append(f"{f.name}: {err}")
                continue

            media = EventMedia(
                event=event,
                uploaded_by=request.user if request.user.is_authenticated else None,
                media_type=m_type,
                caption=full_caption,
                category=category,
                is_public=True,
                is_approved=is_approved,
                file_size=f.size,
            )
            media.file = f
            media.save()
            uploaded_items.append(media)

        return Response({
            'uploaded_count': len(uploaded_items),
            'is_approved': is_approved,
            'message': 'Upload successful' if is_approved else 'Submitted and awaiting host approval.',
            'errors': errors,
        }, status=status.HTTP_201_CREATED if uploaded_items else status.HTTP_400_BAD_REQUEST)


class EventGuestListCreateAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        if not can_manage_guests(request.user, event):
            return Response({'detail': 'You do not have permission to manage this event.'}, status=status.HTTP_403_FORBIDDEN)
        guests = event.guests.select_related('invitation', 'invitation__qr_code')
        search = request.query_params.get('search', '').strip()
        if search:
            guests = guests.filter(
                Q(name__icontains=search) | Q(email__icontains=search) | Q(mobile__icontains=search)
            )
        invitation_type = request.query_params.get('type')
        if invitation_type in dict(EventGuest.INVITATION_TYPES):
            guests = guests.filter(invitation_type=invitation_type)
        guest_status = request.query_params.get('status')
        if guest_status in dict(EventGuest.STATUSES):
            guests = guests.filter(status=guest_status)
        return Response(EventGuestSerializer(
            guests, many=True, context={'request': request}
        ).data)

    def post(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        if not can_manage_guests(request.user, event):
            return Response({'detail': 'You do not have permission to manage this event.'}, status=status.HTTP_403_FORBIDDEN)
        data = request.data.copy()
        serializer = EventGuestSerializer(data=data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        guest_count = serializer.validated_data.get('guest_count', 1)
        with transaction.atomic():
            locked_event = Event.objects.select_for_update().get(pk=event.pk)
            if locked_event.capacity:
                reserved = locked_event.guests.exclude(status='cancelled').aggregate(total=Sum('guest_count'))['total'] or 0
                if reserved + guest_count > locked_event.capacity:
                    return Response({'detail': 'Adding this invitation would exceed event capacity.'}, status=status.HTTP_400_BAD_REQUEST)
            guest = serializer.save(event=locked_event)
            ensure_invitation_qr(guest, request.build_absolute_uri('/').rstrip('/'))
        guest = EventGuest.objects.select_related('invitation', 'invitation__qr_code').get(pk=guest.pk)
        return Response(EventGuestSerializer(guest, context={'request': request}).data, status=status.HTTP_201_CREATED)


class EventGuestDetailAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk, guest_id):
        event = get_object_or_404(Event, pk=pk)
        if not can_manage_guests(request.user, event):
            return Response({'detail': 'You do not have permission to manage this event.'}, status=status.HTTP_403_FORBIDDEN)
        guest = get_object_or_404(EventGuest.objects.select_related('invitation', 'invitation__qr_code'), pk=guest_id, event=event)
        was_cancelled = guest.status == 'cancelled'
        serializer = EventGuestSerializer(guest, data=request.data, partial=True, context={'request': request})
        serializer.is_valid(raise_exception=True)
        new_count = serializer.validated_data.get('guest_count', guest.guest_count)
        new_status = serializer.validated_data.get('status', guest.status)
        with transaction.atomic():
            locked_event = Event.objects.select_for_update().get(pk=event.pk)
            restoring_cancelled = was_cancelled and new_status != 'cancelled'
            if locked_event.capacity and (new_count > guest.guest_count or restoring_cancelled):
                reserved = locked_event.guests.exclude(status='cancelled').exclude(pk=guest.pk).aggregate(total=Sum('guest_count'))['total'] or 0
                if reserved + new_count > locked_event.capacity:
                    return Response({'detail': 'This update would exceed event capacity.'}, status=status.HTTP_400_BAD_REQUEST)
            guest = serializer.save()
            invitation = getattr(guest, 'invitation', None)
            if invitation and guest.status == 'cancelled':
                invitation.status = 'cancelled'
                invitation.save(update_fields=['status'])
            elif invitation and was_cancelled and guest.status != 'cancelled':
                invitation.status = 'active'
                invitation.token = uuid.uuid4()
                invitation.expires_at = None
                invitation.save(update_fields=['status', 'token', 'expires_at'])
                ensure_invitation_qr(guest, request.build_absolute_uri('/').rstrip('/'))
        guest = EventGuest.objects.select_related('invitation', 'invitation__qr_code').get(pk=guest.pk)
        return Response(EventGuestSerializer(guest, context={'request': request}).data)


class EventCheckInAPIView(APIView):
    permission_classes = [IsAuthenticated]

    @method_decorator(ratelimit(key='user_or_ip', rate='600/m', method='POST', block=True))
    def dispatch(self, request, *args, **kwargs):
        if request.method == 'POST' and connection.vendor == 'sqlite':
            # SQLite ignores select_for_update; serialize local scanner threads.
            with _SQLITE_CHECK_IN_LOCK:
                return super().dispatch(request, *args, **kwargs)
        return super().dispatch(request, *args, **kwargs)

    def get(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        if not can_access_event(request.user, event):
            return Response({'detail': 'You are not assigned to this event.'}, status=status.HTTP_403_FORBIDDEN)
        check_ins = EventCheckIn.objects.filter(invitation__guest__event=event)
        return Response({
            'approved_entries': check_ins.count(),
            'checked_in_guests': check_ins.aggregate(total=Sum('invitation__guest__guest_count'))['total'] or 0,
        })

    def post(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        if not can_access_event(request.user, event):
            return Response({'detail': 'You are not assigned to this event.'}, status=status.HTTP_403_FORBIDDEN)
        try:
            token = uuid.UUID(str(request.data.get('token', '')).strip())
        except (ValueError, TypeError, AttributeError):
            token = None

        invitation = None
        if token is not None:
            invitation = Invitation.objects.filter(token=token).select_related('guest', 'guest__event').first()

        if invitation is None:
            QRScanLog.objects.create(event=event, scanned_by=request.user, result='rejected', reason='invalid')
            return Response({'result': 'rejected', 'reason': 'invalid'}, status=status.HTTP_200_OK)

        if invitation.guest.event_id != event.pk:
            QRScanLog.objects.create(
                event=event, invitation=invitation, scanned_by=request.user,
                result='rejected', reason='wrong_event',
            )
            return Response({'result': 'rejected', 'reason': 'wrong_event'}, status=status.HTTP_200_OK)

        try:
            with transaction.atomic():
                invitation = Invitation.objects.select_for_update().select_related('guest', 'guest__event').get(pk=invitation.pk)
                guest = invitation.guest
                if invitation.status == 'cancelled' or guest.status == 'cancelled':
                    QRScanLog.objects.create(
                        event=event, invitation=invitation, scanned_by=request.user,
                        result='rejected', reason='cancelled',
                    )
                    return Response({'result': 'rejected', 'reason': 'cancelled'}, status=status.HTTP_200_OK)
                if invitation.status == 'expired' or invitation.is_expired:
                    invitation.status = 'expired'
                    invitation.save(update_fields=['status'])
                    QRScanLog.objects.create(
                        event=event, invitation=invitation, scanned_by=request.user,
                        result='rejected', reason='expired',
                    )
                    return Response({'result': 'rejected', 'reason': 'expired'}, status=status.HTTP_200_OK)
                if invitation.status != 'active':
                    QRScanLog.objects.create(
                        event=event, invitation=invitation, scanned_by=request.user,
                        result='rejected', reason='cancelled',
                    )
                    return Response({'result': 'rejected', 'reason': 'cancelled'}, status=status.HTTP_200_OK)

                existing = EventCheckIn.objects.filter(invitation=invitation).first()
                if existing:
                    QRScanLog.objects.create(
                        event=event, invitation=invitation, scanned_by=request.user,
                        result='already_checked_in', reason='already_checked_in',
                    )
                    return Response({
                        'result': 'already_checked_in',
                        'guest': {'name': guest.name, 'guest_count': guest.guest_count, 'invitation_type': guest.invitation_type},
                        'checked_in_at': existing.checked_in_at,
                    }, status=status.HTTP_200_OK)

                locked_event = Event.objects.select_for_update().get(pk=event.pk)
                if locked_event.capacity:
                    checked_in = EventCheckIn.objects.filter(
                        invitation__guest__event=event
                    ).aggregate(total=Sum('invitation__guest__guest_count'))['total'] or 0
                    if checked_in + guest.guest_count > locked_event.capacity:
                        QRScanLog.objects.create(
                            event=event, invitation=invitation, scanned_by=request.user,
                            result='rejected', reason='capacity_reached',
                        )
                        return Response({'result': 'rejected', 'reason': 'capacity_reached'}, status=status.HTTP_200_OK)

                check_in = EventCheckIn.objects.create(invitation=invitation, checked_in_by=request.user)
                if guest.status == 'invited':
                    guest.status = 'registered'
                    guest.save(update_fields=['status', 'updated_at'])
                QRScanLog.objects.create(
                    event=event, invitation=invitation, scanned_by=request.user, result='approved',
                )
                return Response({
                    'result': 'approved',
                    'guest': {'name': guest.name, 'guest_count': guest.guest_count, 'invitation_type': guest.invitation_type},
                    'checked_in_at': check_in.checked_in_at,
                }, status=status.HTTP_200_OK)
        except IntegrityError:
            check_in = EventCheckIn.objects.filter(invitation=invitation).first()
            if check_in is None:
                raise
            QRScanLog.objects.create(
                event=event, invitation=invitation, scanned_by=request.user,
                result='already_checked_in', reason='already_checked_in',
            )
            return Response({
                'result': 'already_checked_in',
                'guest': {'name': invitation.guest.name, 'guest_count': invitation.guest.guest_count, 'invitation_type': invitation.guest.invitation_type},
                'checked_in_at': check_in.checked_in_at,
            }, status=status.HTTP_200_OK)


class EventReportAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        event = get_object_or_404(Event, pk=pk)
        if not can_manage_guests(request.user, event):
            return Response({'detail': 'You do not have permission to view this report.'}, status=status.HTTP_403_FORBIDDEN)

        guests = event.guests.all()
        check_ins = EventCheckIn.objects.filter(invitation__guest__event=event)
        rejected = event.scan_logs.filter(result='rejected')
        stats = {
            'total_invitations': guests.count(),
            'registered_guests': guests.filter(status='registered').count(),
            'approved_entries': check_ins.count(),
            'checked_in_guests': check_ins.aggregate(total=Sum('invitation__guest__guest_count'))['total'] or 0,
            'pending_guests': guests.filter(status='invited').count(),
            'rejected_scans': rejected.count(),
            'vip_entries': check_ins.filter(invitation__guest__invitation_type='vip').aggregate(
                total=Sum('invitation__guest__guest_count')
            )['total'] or 0,
        }
        if request.query_params.get('download') == 'csv':
            response = HttpResponse(content_type='text/csv')
            response['Content-Disposition'] = f'attachment; filename="event-{event.pk}-report.csv"'
            writer = csv.writer(response)
            writer.writerow(['Metric', 'Count'])
            writer.writerows(stats.items())
            writer.writerow([])
            writer.writerow(['Guest', 'Email', 'Mobile', 'Type', 'Guest Count', 'Status', 'Checked In At'])
            for guest in guests.select_related('invitation').order_by('name'):
                check_in = EventCheckIn.objects.filter(invitation__guest=guest).first()
                writer.writerow([
                    _csv_safe(guest.name), _csv_safe(guest.email), _csv_safe(guest.mobile), guest.invitation_type,
                    guest.guest_count, guest.status, check_in.checked_in_at.isoformat() if check_in else '',
                ])
            return response
        if request.query_params.get('history') == 'true':
            stats['scan_history'] = list(event.scan_logs.select_related(
                'invitation__guest', 'scanned_by'
            ).values(
                'result', 'reason', 'scanned_at', 'invitation__guest__name', 'scanned_by__email'
            )[:200])
        return Response(stats)


class EventStaffListCreateAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        event = get_object_or_404(Event, pk=pk, owner=request.user)
        return Response(EventStaffSerializer(event.staff_members.select_related('user'), many=True).data)

    def post(self, request, pk):
        event = get_object_or_404(Event, pk=pk, owner=request.user)
        email = str(request.data.get('email', '')).strip().lower()
        role = request.data.get('role', 'scanner')
        if role not in dict(EventStaff.ROLES):
            return Response({'role': ['Select a valid role.']}, status=status.HTTP_400_BAD_REQUEST)
        user = get_user_model().objects.filter(email=email).first()
        if not user:
            return Response({'email': ['No account exists for this email.']}, status=status.HTTP_404_NOT_FOUND)
        staff, created = EventStaff.objects.get_or_create(event=event, user=user, defaults={'role': role})
        if not created:
            staff.role = role
            staff.save(update_fields=['role'])
        return Response(EventStaffSerializer(staff).data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class EventStaffRemoveAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk, staff_id):
        event = get_object_or_404(Event, pk=pk, owner=request.user)
        staff = get_object_or_404(EventStaff, pk=staff_id, event=event)
        staff.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class EventInvitationEmailAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk, guest_id):
        event = get_object_or_404(Event, pk=pk)
        if not can_manage_guests(request.user, event):
            return Response({'detail': 'You do not have permission to send invitations.'}, status=status.HTTP_403_FORBIDDEN)
        guest = get_object_or_404(EventGuest, pk=guest_id, event=event)
        if guest.status == 'cancelled':
            return Response({'detail': 'This guest invitation is cancelled.'}, status=status.HTTP_400_BAD_REQUEST)
        if not guest.email:
            return Response({'detail': 'This guest has no email address.'}, status=status.HTTP_400_BAD_REQUEST)
        invitation, _qr = ensure_invitation_qr(guest, request.build_absolute_uri('/').rstrip('/'))
        invitation_url = request.build_absolute_uri(
            f"/events/invitation/{invitation.token}/"
        )
        send_mail(
            subject=f"You're invited: {event.title}",
            message=(
                f"Hello {guest.name},\n\n"
                f"You are invited to {event.title} on {event.event_date}.\n"
                f"Your invitation for {guest.guest_count} guest(s): {invitation_url}\n"
            ),
            from_email=None,
            recipient_list=[guest.email],
            fail_silently=False,
        )
        return Response({'message': 'Invitation email sent.'}, status=status.HTTP_200_OK)
