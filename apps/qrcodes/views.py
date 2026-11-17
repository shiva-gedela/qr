"""
apps/qrcodes/views.py

Views for:
 - Downloading high-resolution QR PNG
 - Generating & downloading printable invitation PDF
 - Customizing QR code colors and center logo
 - Real-time QR preview generator
 - Trackable QR scanning & redirect analytics
"""

import io
from django.shortcuts import render, redirect, get_object_or_404
from django.http import HttpResponse, Http404, JsonResponse, FileResponse
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.utils import timezone
from django.db.models import F
from django.views.decorators.http import require_GET

from apps.events.models import Event
from .models import QRCode
from .forms import QRCodeCustomizeForm
from .services import (
    generate_or_update_event_qr,
    generate_event_qr_pdf,
    create_qr_image_buffer,
)


def download_qr_png(request, qr_uuid):
    """Serve QR code PNG as a direct downloadable attachment."""
    qr = get_object_or_404(QRCode, uuid=qr_uuid)

    slug_name = qr.event.slug if qr.event else (qr.business.slug if qr.business else 'qrcode')
    filename = f"{slug_name}-qr.png"

    # Ensure QR image exists
    if not qr.qr_image:
        if qr.event:
            qr = generate_or_update_event_qr(qr.event)
        elif qr.business:
            from .services import generate_or_update_business_qr
            qr = generate_or_update_business_qr(qr.business)
        else:
            buf = create_qr_image_buffer(qr.target_url, qr.fill_color, qr.back_color)
            return HttpResponse(buf.getvalue(), content_type='image/png')

    try:
        qr.qr_image.open('rb')
        response = FileResponse(qr.qr_image, content_type='image/png')
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        return response
    except Exception:
        # Generate on the fly
        buf = create_qr_image_buffer(qr.target_url, qr.fill_color, qr.back_color, qr.logo)
        response = HttpResponse(buf.getvalue(), content_type='image/png')
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        return response


def download_qr_pdf(request, qr_uuid):
    """Generate and return a beautifully formatted A4 printable PDF card (Event or Business)."""
    qr = get_object_or_404(QRCode, uuid=qr_uuid)

    if qr.business:
        from .services import generate_business_qr_pdf
        pdf_buffer = generate_business_qr_pdf(qr)
        filename = f"{qr.business.slug}-business-card.pdf"
    else:
        pdf_buffer = generate_event_qr_pdf(qr)
        filename = f"{qr.event.slug if qr.event else 'event'}-invitation-card.pdf"

    response = HttpResponse(pdf_buffer.getvalue(), content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="{filename}"'
    return response


def qr_scan_redirect(request, qr_uuid):
    """
    Trackable scan endpoint. Increments scan counter and redirects to the public mini-website.
    Also handles physical QR scans.
    """
    qr = get_object_or_404(QRCode, uuid=qr_uuid)

    # Record scan metric atomically
    QRCode.objects.filter(uuid=qr_uuid).update(
        scan_count=F('scan_count') + 1,
        last_scanned_at=timezone.now()
    )

    return redirect(qr.target_url)


@login_required
def customize_event_qr(request, event_pk):
    """Customize QR code colors and center logo for an Event (owner only)."""
    event = get_object_or_404(Event, pk=event_pk, owner=request.user)

    # Get or generate QR code
    qr = getattr(event, 'qr_code', None)
    if not qr:
        qr = generate_or_update_event_qr(event)

    if request.method == 'POST':
        form = QRCodeCustomizeForm(request.POST, request.FILES, instance=qr)
        if form.is_valid():
            fill_color = form.cleaned_data['fill_color']
            back_color = form.cleaned_data['back_color']
            logo = form.cleaned_data.get('logo')

            # Re-generate QR image with custom parameters
            generate_or_update_event_qr(
                event=event,
                fill_color=fill_color,
                back_color=back_color,
                logo_file=logo,
            )

            messages.success(request, "QR code design updated successfully!")
            return redirect('event_detail', pk=event.pk)
    else:
        form = QRCodeCustomizeForm(instance=qr)

    context = {
        'event': event,
        'qr': qr,
        'form': form,
    }
    return render(request, 'qrcodes/customize_qr.html', context)


@login_required
def customize_business_qr(request, business_pk):
    """Customize QR code colors and center logo for a Business Profile (owner only)."""
    from apps.business.models import Business
    business = get_object_or_404(Business, pk=business_pk, owner=request.user)

    qr = getattr(business, 'qr_code', None)
    if not qr:
        from .services import generate_or_update_business_qr
        qr = generate_or_update_business_qr(business)

    if request.method == 'POST':
        form = QRCodeCustomizeForm(request.POST, request.FILES, instance=qr)
        if form.is_valid():
            fill_color = form.cleaned_data['fill_color']
            back_color = form.cleaned_data['back_color']
            logo = form.cleaned_data.get('logo')

            from .services import generate_or_update_business_qr
            generate_or_update_business_qr(
                business=business,
                fill_color=fill_color,
                back_color=back_color,
                logo_file=logo,
            )

            messages.success(request, "Business QR code design updated successfully!")
            return redirect('business_detail', pk=business.pk)
    else:
        form = QRCodeCustomizeForm(instance=qr)

    context = {
        'business': business,
        'qr': qr,
        'form': form,
    }
    return render(request, 'qrcodes/customize_business_qr.html', context)


@require_GET
def qr_live_preview(request):
    """
    Live PNG generator for interactive real-time previews in the browser.
    Params: target_url, fill_color, back_color
    """
    target_url = request.GET.get('target_url', 'https://eventconnect.com')
    fill_color = request.GET.get('fill_color', '#000000')
    back_color = request.GET.get('back_color', '#FFFFFF')

    buf = create_qr_image_buffer(target_url, fill_color=fill_color, back_color=back_color, box_size=8, border=2)
    return HttpResponse(buf.getvalue(), content_type='image/png')
