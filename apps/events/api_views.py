"""
apps/events/api_views.py - REST API views for events (Flutter integration).
"""

from rest_framework.views import APIView
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404
from django.http import Http404

from .models import Event
from .serializers import EventSerializer, EventCreateSerializer


class EventListCreateAPIView(ListCreateAPIView):
    """GET /api/events/ - List user's events. POST - Create event."""

    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Event.objects.filter(owner=self.request.user).order_by('-created_at')

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
