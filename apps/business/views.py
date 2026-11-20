"""
apps/business/views.py

CRUD views for Digital Business Profiles, Product/Service catalog,
Business QR Code actions, and public digital business cards (/b/<slug>/).
"""

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_POST
from django.contrib import messages
from django.http import Http404, HttpResponse, JsonResponse
from django.conf import settings

from .models import Business, BusinessService, BusinessBooking
from .forms import BusinessForm, BusinessServiceForm


# ─── Business Marketplace & Management ────────────────────────────────────────

def business_list(request):
    """Browse marketplace of verified vendors, restaurants, and manage owned profiles."""
    my_businesses = []
    if request.user.is_authenticated:
        my_businesses = Business.objects.filter(owner=request.user).order_by('-created_at')

    category = request.GET.get('category', 'all')
    search_q = request.GET.get('q', '').strip()

    all_businesses = Business.objects.filter(is_active=True).order_by('-created_at')
    if category != 'all' and category:
        all_businesses = all_businesses.filter(category=category)
    if search_q:
        all_businesses = all_businesses.filter(name__icontains=search_q)

    return render(request, 'business/business_list.html', {
        'my_businesses': my_businesses,
        'businesses': all_businesses,
        'selected_category': category,
        'search_q': search_q,
    })



@login_required
def business_create(request):
    """Create a new digital business profile."""
    if request.method == 'POST':
        form = BusinessForm(request.POST, request.FILES)
        if form.is_valid():
            business = form.save(commit=False)
            business.owner = request.user
            business.save()

            # Ensure QR code is generated
            try:
                from apps.qrcodes.services import generate_or_update_business_qr
                generate_or_update_business_qr(business)
            except Exception:
                pass

            messages.success(request, f"Business profile '{business.name}' created successfully!")
            return redirect('business_detail', pk=business.pk)
    else:
        form = BusinessForm()

    return render(request, 'business/business_form.html', {
        'form': form,
        'title': 'Create Business Profile',
        'submit_label': 'Create Profile',
    })


@login_required
def business_detail(request, pk):
    """Owner's business dashboard with products/services, bookings, and QR actions."""
    business = get_object_or_404(Business, pk=pk, owner=request.user)
    services = business.services.all().order_by('order', 'name')
    bookings = business.bookings.all().order_by('-date', '-created_at')[:30]
    service_form = BusinessServiceForm()

    # Get or generate QR code
    qr = getattr(business, 'qr_code', None)
    if not qr:
        try:
            from apps.qrcodes.services import generate_or_update_business_qr
            qr = generate_or_update_business_qr(business, base_url=settings.SITE_URL)
        except Exception:
            qr = None

    context = {
        'business': business,
        'services': services,
        'bookings': bookings,
        'service_form': service_form,
        'qr': qr,
        'site_url': settings.SITE_URL,
    }
    return render(request, 'business/business_detail.html', context)


@login_required
def business_edit(request, pk):
    """Edit existing business profile (owner only)."""
    business = get_object_or_404(Business, pk=pk, owner=request.user)

    if request.method == 'POST':
        form = BusinessForm(request.POST, request.FILES, instance=business)
        if form.is_valid():
            form.save()
            messages.success(request, "Business profile updated successfully!")
            return redirect('business_detail', pk=business.pk)
    else:
        form = BusinessForm(instance=business)

    return render(request, 'business/business_form.html', {
        'form': form,
        'business': business,
        'title': f'Edit: {business.name}',
        'submit_label': 'Save Changes',
    })


@login_required
def business_delete(request, pk):
    """Delete business profile and associated services/QR code."""
    business = get_object_or_404(Business, pk=pk, owner=request.user)

    if request.method == 'POST':
        name = business.name
        business.delete()
        messages.success(request, f"Business '{name}' has been deleted.")
        return redirect('business_list')

    return render(request, 'business/business_confirm_delete.html', {'business': business})


# ─── Products & Services CRUD ────────────────────────────────────────────────

@login_required
def service_create(request, pk):
    """Add a new product or service to a business."""
    business = get_object_or_404(Business, pk=pk, owner=request.user)

    if request.method == 'POST':
        form = BusinessServiceForm(request.POST, request.FILES)
        if form.is_valid():
            service = form.save(commit=False)
            service.business = business
            service.save()
            messages.success(request, f"Item '{service.name}' added to catalog!")
        else:
            messages.error(request, "Please check the form inputs.")

    return redirect('business_detail', pk=pk)


@login_required
def service_edit(request, pk, service_id):
    """Edit a product or service."""
    business = get_object_or_404(Business, pk=pk, owner=request.user)
    service = get_object_or_404(BusinessService, pk=service_id, business=business)

    if request.method == 'POST':
        form = BusinessServiceForm(request.POST, request.FILES, instance=service)
        if form.is_valid():
            form.save()
            messages.success(request, f"Item '{service.name}' updated!")
            return redirect('business_detail', pk=pk)
    else:
        form = BusinessServiceForm(instance=service)

    return render(request, 'business/service_form.html', {
        'business': business,
        'service': service,
        'form': form,
    })


@login_required
def service_delete(request, pk, service_id):
    """Delete a product or service."""
    business = get_object_or_404(Business, pk=pk, owner=request.user)
    service = get_object_or_404(BusinessService, pk=service_id, business=business)

    if request.method == 'POST':
        service.delete()
        messages.success(request, "Catalog item deleted.")

    return redirect('business_detail', pk=pk)


# ─── Public Digital Business Profile ──────────────────────────────────────────

def business_public(request, slug):
    """
    Public digital business card / mini-website (`/b/<slug>/`).
    Direct landing page when a business QR code is scanned.
    """
    business = get_object_or_404(Business, slug=slug)

    # Check active state
    if not business.is_active:
        if not request.user.is_authenticated or request.user != business.owner:
            raise Http404("This business profile is currently private or inactive.")

    services = business.get_active_services()

    # Get or generate QR code
    qr = getattr(business, 'qr_code', None)
    if not qr:
        try:
            from apps.qrcodes.services import generate_or_update_business_qr
            qr = generate_or_update_business_qr(business, base_url=settings.SITE_URL)
        except Exception:
            qr = None

    context = {
        'business': business,
        'services': services,
        'qr': qr,
        'is_owner': request.user.is_authenticated and request.user == business.owner,
        'site_url': settings.SITE_URL,
    }
    return render(request, 'business/business_public.html', context)


def business_vcard(request, slug):
    """Download standard .vcf vCard contact card for instant smartphone import."""
    business = get_object_or_404(Business, slug=slug)
    vcard_text = business.generate_vcard_string()

    response = HttpResponse(vcard_text, content_type='text/vcard; charset=utf-8')
    response['Content-Disposition'] = f'attachment; filename="{business.slug}.vcf"'
    return response


@require_POST
def business_public_book(request, slug):
    """
    Handle web booking submissions from the public profile page.
    Saves the booking in the database, validates availability, and returns booking info + WhatsApp URL.
    """
    business = get_object_or_404(Business, slug=slug, is_active=True)
    try:
        if request.content_type == 'application/json':
            import json
            data = json.loads(request.body.decode('utf-8'))
        else:
            data = request.POST
    except Exception:
        data = request.POST

    name = data.get('name', '').strip()
    phone = data.get('phone', '').strip()
    date_str = data.get('date', '').strip()
    time_slot = data.get('time_slot', '').strip()
    try:
        guests = int(data.get('guests', 2) or 2)
    except (ValueError, TypeError):
        guests = 2
    notes = data.get('notes', '').strip()
    service_id = data.get('service_id')

    if not name or not phone or not date_str:
        return JsonResponse({'success': False, 'error': 'Name, phone number, and date are required.'}, status=400)

    try:
        from datetime import datetime
        book_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return JsonResponse({'success': False, 'error': 'Invalid date format (use YYYY-MM-DD).'}, status=400)

    # Check for duplicate active booking
    existing = BusinessBooking.objects.filter(
        business=business,
        customer_phone=phone,
        date=book_date,
        time_slot=time_slot or 'Standard Slot',
    ).exclude(status='cancelled').first()

    if existing:
        return JsonResponse({
            'success': False,
            'error': f'You already have an active reservation (Booking ID: {existing.booking_code}) at this time.'
        }, status=400)

    service = None
    if service_id:
        service = business.services.filter(pk=service_id, is_available=True).first()

    customer_user = request.user if request.user.is_authenticated else None
    booking = BusinessBooking.objects.create(
        business=business,
        service=service,
        service_name=service.name if service else '',
        service_price=service.price if service else None,
        customer_user=customer_user,
        customer_name=name,
        customer_phone=phone,
        customer_email=data.get('email', '').strip(),
        date=book_date,
        time_slot=time_slot or 'Standard Slot',
        guests_count=guests,
        special_requests=notes,
        status='confirmed',
    )

    import urllib.parse
    biz_name = business.name
    clean_num = business.clean_whatsapp_number or '919876543210'
    msg = f"Hello {biz_name}! I have booked a table/service via QRouteX (ID: {booking.booking_code}):\n- Name: {name}\n- Phone: {phone}\n- Date: {booking.date}\n- Time Slot: {booking.time_slot}\n- Guests: {guests}\n- Notes: {notes or 'None'}"
    wa_url = f"https://wa.me/{clean_num}?text={urllib.parse.quote(msg)}"

    return JsonResponse({
        'success': True,
        'booking_code': booking.booking_code,
        'message': f'Booking {booking.booking_code} confirmed successfully!',
        'whatsapp_url': wa_url,
    })

