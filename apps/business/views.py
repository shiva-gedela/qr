"""
apps/business/views.py

CRUD views for Digital Business Profiles, Product/Service catalog,
Business QR Code actions, and public digital business cards (/b/<slug>/).
"""

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import Http404, HttpResponse
from django.conf import settings

from .models import Business, BusinessService
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
    """Owner's business dashboard with products/services and QR actions."""
    business = get_object_or_404(Business, pk=pk, owner=request.user)
    services = business.services.all().order_by('order', 'name')
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
