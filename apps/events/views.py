"""
apps/events/views.py

CRUD views for events, media upload and public event mini-website.
All private/owner views are login-required with ownership enforcement.
"""

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import Http404, JsonResponse, HttpResponse, FileResponse
from django.conf import settings
from django.core.paginator import Paginator
from django.views.decorators.http import require_POST
import os
import io

from .models import Event, EventMedia
from .forms import EventForm, MediaUploadForm


# ─── Event CRUD ──────────────────────────────────────────────────────────────

@login_required
def event_list(request):
    """List all events owned by the logged-in user."""
    events = Event.objects.filter(owner=request.user).order_by('-created_at')
    return render(request, 'events/event_list.html', {'events': events})


@login_required
def event_create(request):
    """Create a new event."""
    if request.method == 'POST':
        form = EventForm(request.POST, request.FILES)
        if form.is_valid():
            event = form.save(commit=False)
            event.owner = request.user
            event.save()
            messages.success(request, f"Event '{event.title}' created successfully!")
            return redirect('event_detail', pk=event.pk)
    else:
        initial = {}
        if request.GET.get('type'):
            initial['event_type'] = request.GET.get('type')
        form = EventForm(initial=initial)

    return render(request, 'events/event_form.html', {
        'form': form,
        'title': 'Create New Event',
        'submit_label': 'Create Event',
    })


@login_required
def event_detail(request, pk):
    """Owner's private event detail/management page."""
    event = get_object_or_404(Event, pk=pk, owner=request.user)

    # Category filter
    selected_category = request.GET.get('category', 'all')
    photos = event.get_photos(category=selected_category)
    videos = event.get_videos(category=selected_category)
    pending_media = event.get_pending_media()
    categories_with_counts = event.get_categories_with_counts()

    media_form = MediaUploadForm()

    # Fetch or auto-generate QR code
    qr = getattr(event, 'qr_code', None)
    if not qr:
        try:
            from apps.qrcodes.services import generate_or_update_event_qr
            qr = generate_or_update_event_qr(event, base_url=settings.SITE_URL)
        except Exception:
            qr = None

    context = {
        'event': event,
        'photos': photos,
        'videos': videos,
        'pending_media': pending_media,
        'categories': categories_with_counts,
        'selected_category': selected_category,
        'media_form': media_form,
        'qr': qr,
        'site_url': settings.SITE_URL,
    }
    return render(request, 'events/event_detail.html', context)


@login_required
def event_edit(request, pk):
    """Edit an existing event (owner only)."""
    event = get_object_or_404(Event, pk=pk, owner=request.user)

    if request.method == 'POST':
        form = EventForm(request.POST, request.FILES, instance=event)
        if form.is_valid():
            form.save()
            messages.success(request, "Event updated successfully!")
            return redirect('event_detail', pk=event.pk)
    else:
        form = EventForm(instance=event)

    return render(request, 'events/event_form.html', {
        'form': form,
        'event': event,
        'title': f'Edit: {event.title}',
        'submit_label': 'Save Changes',
    })


@login_required
def event_delete(request, pk):
    """Delete an event after confirmation (owner only)."""
    event = get_object_or_404(Event, pk=pk, owner=request.user)

    if request.method == 'POST':
        title = event.title
        event.delete()
        messages.success(request, f"Event '{title}' has been deleted.")
        return redirect('event_list')

    return render(request, 'events/event_confirm_delete.html', {'event': event})


@login_required
def event_toggle_publish(request, pk):
    """Toggle event published/draft status."""
    event = get_object_or_404(Event, pk=pk, owner=request.user)
    event.is_published = not event.is_published
    event.save(update_fields=['is_published'])
    status_text = "published" if event.is_published else "set to draft"
    messages.success(request, f"Event '{event.title}' has been {status_text}.")
    return redirect('event_detail', pk=pk)


# ─── Public Event Mini-Website ────────────────────────────────────────────────

def event_public(request, slug):
    """Public-facing event mini-website (the QR landing page)."""
    event = get_object_or_404(Event, slug=slug)

    # Check if event is published
    if not event.is_published:
        # Allow owner to preview even if unpublished
        if not request.user.is_authenticated or request.user != event.owner:
            raise Http404("Event not found or not yet published.")

    # Private event password check
    if event.is_private:
        session_key = f"event_access_{event.pk}"
        if not request.session.get(session_key):
            if request.method == 'POST':
                entered = request.POST.get('password', '')
                if entered == event.private_password:
                    request.session[session_key] = True
                else:
                    messages.error(request, "Incorrect password.")
                    return render(request, 'events/event_private_access.html', {'event': event})
            else:
                return render(request, 'events/event_private_access.html', {'event': event})

    # Category filter
    selected_category = request.GET.get('category', 'all')
    photos = event.get_photos(category=selected_category)
    videos = event.get_videos(category=selected_category)
    categories_with_counts = event.get_categories_with_counts()

    # Fetch or auto-generate QR code
    qr = getattr(event, 'qr_code', None)
    if not qr:
        try:
            from apps.qrcodes.services import generate_or_update_event_qr
            qr = generate_or_update_event_qr(event, base_url=settings.SITE_URL)
        except Exception:
            qr = None

    from .forms import GuestMediaUploadForm
    guest_upload_form = GuestMediaUploadForm() if event.allow_guest_uploads else None

    context = {
        'event': event,
        'photos': photos,
        'videos': videos,
        'categories': categories_with_counts,
        'selected_category': selected_category,
        'guest_upload_form': guest_upload_form,
        'qr': qr,
        'is_owner': request.user.is_authenticated and request.user == event.owner,
        'maps_api_key': settings.GOOGLE_MAPS_API_KEY,
    }
    return render(request, 'events/event_public.html', context)


def event_calendar_ics(request, slug):
    """Generate an iCalendar (.ics) downloadable file for the event."""
    from django.http import HttpResponse
    from datetime import datetime, time, timedelta

    event = get_object_or_404(Event, slug=slug)

    ev_time = event.event_time or time(10, 0)
    start_dt = datetime.combine(event.event_date, ev_time)

    if event.event_end_date:
        end_time = event.event_end_time or time(22, 0)
        end_dt = datetime.combine(event.event_end_date, end_time)
    else:
        end_dt = start_dt + timedelta(hours=4)

    dt_format = "%Y%m%dT%H%M%S"
    start_str = start_dt.strftime(dt_format)
    end_str = end_dt.strftime(dt_format)

    clean_summary = event.title.replace('\n', ' ')
    clean_desc = (event.description or f"Hosted by {event.host_names}").replace('\n', '\\n')
    clean_location = f"{event.venue_name}, {event.venue_address}".replace('\n', ' ').strip(', ')

    ics_content = (
        "BEGIN:VCALENDAR\r\n"
        "VERSION:2.0\r\n"
        "PRODID:-//EventConnect QR//Event Invitation//EN\r\n"
        "CALSCALE:GREGORIAN\r\n"
        "METHOD:PUBLISH\r\n"
        "BEGIN:VEVENT\r\n"
        f"UID:{event.uuid}@eventconnect.com\r\n"
        f"DTSTAMP:{datetime.now().strftime(dt_format)}\r\n"
        f"DTSTART:{start_str}\r\n"
        f"DTEND:{end_str}\r\n"
        f"SUMMARY:{clean_summary}\r\n"
        f"DESCRIPTION:{clean_desc}\r\n"
        f"LOCATION:{clean_location}\r\n"
        f"URL:{settings.SITE_URL}/events/e/{event.slug}/\r\n"
        "STATUS:CONFIRMED\r\n"
        "END:VEVENT\r\n"
        "END:VCALENDAR\r\n"
    )

    response = HttpResponse(ics_content, content_type='text/calendar; charset=utf-8')
    response['Content-Disposition'] = f'attachment; filename="{event.slug}.ics"'
    return response


# ─── Media Upload & Management ────────────────────────────────────────────────

@login_required
def media_upload(request, pk):
    """Handle multiple file uploads by the event owner."""
    event = get_object_or_404(Event, pk=pk, owner=request.user)

    if request.method == 'POST':
        if event.is_storage_full:
            messages.error(request, f"Storage limit reached ({event.max_storage_mb} MB). Please delete older files to upload more.")
            return redirect('event_detail', pk=pk)

        files = request.FILES.getlist('files')
        category = request.POST.get('category', 'general')
        caption = request.POST.get('caption', '')
        is_public = request.POST.get('is_public', 'true') == 'true'

        if not files:
            messages.error(request, "No files selected.")
            return redirect('event_detail', pk=pk)

        uploaded_count = 0
        errors = []

        for f in files:
            media_type, error = _validate_media_file(f)
            if error:
                errors.append(f"{f.name}: {error}")
                continue

            # Check if this single file exceeds remaining storage
            remaining_bytes = (event.max_storage_mb * 1024 * 1024) - event.get_used_storage_bytes()
            if f.size > remaining_bytes:
                errors.append(f"{f.name}: Exceeds remaining storage quota.")
                break

            media = EventMedia(
                event=event,
                uploaded_by=request.user,
                media_type=media_type,
                caption=caption,
                category=category,
                is_public=is_public,
                is_approved=True,  # Owner uploads are approved immediately
                file_size=f.size,
            )
            media.file = f
            media.save()
            uploaded_count += 1

        if uploaded_count:
            messages.success(request, f"{uploaded_count} file(s) uploaded successfully!")
        for err in errors:
            messages.warning(request, err)

    return redirect('event_detail', pk=pk)


def guest_media_upload(request, slug):
    """Handle guest photo/video uploads from the public event mini-website."""
    event = get_object_or_404(Event, slug=slug, is_published=True)

    if not event.allow_guest_uploads:
        messages.error(request, "Guest uploads are disabled for this event.")
        return redirect('event_public', slug=slug)

    if request.method == 'POST':
        if event.is_storage_full:
            messages.error(request, "Event gallery storage is currently full.")
            return redirect('event_public', slug=slug)

        files = request.FILES.getlist('files')
        category = request.POST.get('category', 'candid')
        uploader_name = request.POST.get('uploader_name', '').strip()
        caption_text = request.POST.get('caption', '').strip()

        if uploader_name:
            full_caption = f"{caption_text} — by {uploader_name}".strip(' — by ')
        else:
            full_caption = caption_text

        if not files:
            messages.error(request, "Please select at least one photo or video.")
            return redirect('event_public', slug=slug)

        uploaded_count = 0
        errors = []
        is_approved = not event.require_media_approval

        for f in files:
            media_type, error = _validate_media_file(f)
            if error:
                errors.append(f"{f.name}: {error}")
                continue

            remaining_bytes = (event.max_storage_mb * 1024 * 1024) - event.get_used_storage_bytes()
            if f.size > remaining_bytes:
                errors.append(f"{f.name}: Storage limit reached.")
                break

            media = EventMedia(
                event=event,
                uploaded_by=request.user if request.user.is_authenticated else None,
                media_type=media_type,
                caption=full_caption,
                category=category,
                is_public=True,
                is_approved=is_approved,
                file_size=f.size,
            )
            media.file = f
            media.save()
            uploaded_count += 1

        if uploaded_count:
            if is_approved:
                messages.success(request, f"Thank you! {uploaded_count} photo(s) have been added to the gallery.")
            else:
                messages.success(request, f"Thank you! {uploaded_count} photo(s) submitted. They will appear once reviewed by the host.")

        for err in errors:
            messages.warning(request, err)

    return redirect('event_public', slug=slug)


@login_required
def media_toggle_approval(request, pk, media_id):
    """Approve or unapprove a media item (owner only)."""
    event = get_object_or_404(Event, pk=pk, owner=request.user)
    media = get_object_or_404(EventMedia, pk=media_id, event=event)

    if request.method == 'POST':
        media.is_approved = not media.is_approved
        media.save(update_fields=['is_approved'])
        status_text = "approved and is now visible" if media.is_approved else "moved to pending approval"
        messages.success(request, f"Media item has been {status_text}.")

    return redirect('event_detail', pk=pk)


@login_required
def media_approve_all(request, pk):
    """Approve all pending media items for an event (owner only)."""
    event = get_object_or_404(Event, pk=pk, owner=request.user)

    if request.method == 'POST':
        count = event.media.filter(is_approved=False).update(is_approved=True)
        messages.success(request, f"{count} pending media item(s) approved!")

    return redirect('event_detail', pk=pk)


def media_download(request, pk, media_id):
    """Download a specific media file directly."""
    event = get_object_or_404(Event, pk=pk)
    media = get_object_or_404(EventMedia, pk=media_id, event=event)

    # Allow if approved & public, or if requester is owner
    is_owner = request.user.is_authenticated and request.user == event.owner
    if not is_owner and (not media.is_approved or not media.is_public):
        raise Http404("Media not available.")

    from django.http import FileResponse
    try:
        media.file.open('rb')
        filename = os.path.basename(media.file.name)
        response = FileResponse(media.file, as_attachment=True, filename=filename)
        return response
    except Exception:
        raise Http404("File not found on storage.")


@login_required
def media_download_zip(request, pk):
    """Download all approved gallery photos as a single .zip archive."""
    import zipfile
    import io
    from django.http import HttpResponse

    event = get_object_or_404(Event, pk=pk, owner=request.user)
    media_items = event.media.filter(is_approved=True)

    if not media_items.exists():
        messages.info(request, "No media files available to download.")
        return redirect('event_detail', pk=pk)

    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zf:
        for idx, item in enumerate(media_items, start=1):
            if item.file:
                try:
                    ext = os.path.splitext(item.file.name)[1]
                    zip_path = f"{item.category}/{item.media_type}_{idx}{ext}"
                    zf.writestr(zip_path, item.file.read())
                except Exception:
                    continue

    zip_buffer.seek(0)
    filename = f"{event.slug}-gallery.zip"
    response = HttpResponse(zip_buffer.getvalue(), content_type='application/zip')
    response['Content-Disposition'] = f'attachment; filename="{filename}"'
    return response


@login_required
def media_delete(request, pk, media_id):
    """Delete a specific media item and its thumbnail (owner only)."""
    event = get_object_or_404(Event, pk=pk, owner=request.user)
    media = get_object_or_404(EventMedia, pk=media_id, event=event)

    if request.method == 'POST':
        # Delete files from storage
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
        messages.success(request, "Media deleted.")

    return redirect('event_detail', pk=pk)


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _validate_media_file(f):
    """
    Validate uploaded file: check type and size.
    Returns (media_type, error_string). error_string is None if valid.
    """
    max_image_bytes = settings.MAX_IMAGE_SIZE_MB * 1024 * 1024
    max_video_bytes = settings.MAX_VIDEO_SIZE_MB * 1024 * 1024

    image_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    video_types = ['video/mp4', 'video/quicktime', 'video/avi', 'video/webm', 'video/x-matroska']

    content_type = f.content_type or ''

    if content_type in image_types:
        if f.size > max_image_bytes:
            return None, f"Image exceeds {settings.MAX_IMAGE_SIZE_MB} MB limit"
        return 'image', None

    if content_type in video_types:
        if f.size > max_video_bytes:
            return None, f"Video exceeds {settings.MAX_VIDEO_SIZE_MB} MB limit"
        return 'video', None

    return None, f"Unsupported file type ({content_type}). Allowed: JPG, PNG, WEBP, GIF, MP4, WEBM, MOV."


def event_gps_redirect(request, slug):
    """
    Direct GPS redirection endpoint: /events/e/<slug>/gps/ or /events/e/<slug>/navigate/
    Redirects scanner / guest directly into Google Maps GPS navigation for the event venue.
    """
    event = get_object_or_404(Event, slug=slug)
    return redirect(event.google_maps_directions_url)

