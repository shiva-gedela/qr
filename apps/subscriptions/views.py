"""
apps/subscriptions/views.py

User-facing views for Pricing plans, Razorpay checkout, Payment verification,
Transaction history, and Tax invoice PDF downloads.
"""

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import HttpResponse, Http404, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings
from django.utils import timezone

from .models import SubscriptionPlan, Subscription, Payment
from .services import (
    seed_default_plans,
    create_razorpay_order,
    verify_and_activate_payment,
)


def pricing_view(request):
    """Public pricing page presenting all 4 subscription tiers."""
    plans = SubscriptionPlan.objects.filter(is_active=True).order_by('order', 'price')
    if not plans.exists():
        plans = seed_default_plans()

    user_sub = None
    if request.user.is_authenticated:
        user_sub = Subscription.objects.filter(user=request.user, status='active').order_by('-created_at').first()

    context = {
        'plans': plans,
        'user_sub': user_sub,
        'current_plan_code': user_sub.plan.code if user_sub else 'free',
    }
    return render(request, 'subscriptions/pricing.html', context)


@login_required
def checkout_view(request, plan_code):
    """
    Initialize Razorpay order and present checkout page.
    If plan is free, provision immediately.
    """
    plan = get_object_or_404(SubscriptionPlan, code=plan_code, is_active=True)

    # Free plan instant activation
    if plan.is_free:
        Subscription.objects.filter(user=request.user, status='active').update(status='expired')
        Subscription.objects.create(
            user=request.user,
            plan=plan,
            status='active',
            start_date=timezone.now(),
            end_date=None
        )
        messages.success(request, f"You are now on the {plan.name}!")
        return redirect('accounts_dashboard')

    # Paid plan: generate Razorpay order
    order_context = create_razorpay_order(request.user, plan)

    context = {
        'plan': plan,
        'order': order_context,
        'user': request.user,
        'site_name': getattr(settings, 'SITE_NAME', 'EventConnect QR'),
    }
    return render(request, 'subscriptions/checkout.html', context)


@login_required
@csrf_exempt
def payment_verify_view(request):
    """
    POST callback from Razorpay Checkout modal or form submission.
    Verifies cryptographic signature and provisions the plan.
    """
    if request.method != 'POST':
        return redirect('pricing')

    order_id = request.POST.get('razorpay_order_id')
    payment_id = request.POST.get('razorpay_payment_id', '')
    signature = request.POST.get('razorpay_signature', '')

    if not order_id:
        messages.error(request, "Invalid payment callback data.")
        return redirect('pricing')

    client_ip = request.META.get('REMOTE_ADDR', '')
    success, message, payment = verify_and_activate_payment(
        user=request.user,
        razorpay_order_id=order_id,
        razorpay_payment_id=payment_id,
        razorpay_signature=signature,
        ip_address=client_ip
    )

    if success:
        messages.success(request, f"🎉 Payment successful! Your {payment.plan.name} is now active.")
        return redirect('payment_success', invoice_number=payment.invoice_number)
    else:
        messages.error(request, f"Payment failed: {message}")
        return redirect('pricing')


@login_required
def payment_success_view(request, invoice_number):
    """Post-checkout success confirmation with receipt & invoice download."""
    payment = get_object_or_404(Payment, invoice_number=invoice_number, user=request.user)
    return render(request, 'subscriptions/payment_success.html', {'payment': payment})


@login_required
def payment_history_view(request):
    """User transaction history and invoice download list."""
    payments = Payment.objects.filter(user=request.user).order_by('-created_at')
    active_sub = Subscription.objects.filter(user=request.user, status='active').first()
    return render(request, 'subscriptions/payment_history.html', {
        'payments': payments,
        'active_sub': active_sub,
    })


@login_required
def download_invoice_view(request, invoice_number):
    """Generate and return a tax invoice PDF for a specific transaction."""
    payment = get_object_or_404(Payment, invoice_number=invoice_number)

    # Permission check: must be owner or staff
    if payment.user != request.user and not request.user.is_staff:
        raise Http404("Invoice not found.")

    pdf_buffer = payment.generate_invoice_pdf()
    response = HttpResponse(pdf_buffer.getvalue(), content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="Invoice-{payment.invoice_number}.pdf"'
    return response
