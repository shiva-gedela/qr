"""
apps/subscriptions/admin_views.py

Production-ready Admin Management Dashboard (Module 8).
Full administrative control over:
 - System analytics & revenue reports
 - User management & block/unblock toggle
 - Event moderation & deletion
 - Business profiles & verification badges
 - Media uploads moderation queue (approve/reject/delete)
 - Subscriptions & manual tier overrides
 - Audit trail viewer
"""

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib import messages
from django.db.models import Sum, Count, Q
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.http import HttpResponse

from .models import SubscriptionPlan, Subscription, Payment, AuditLog
from apps.events.models import Event, EventMedia
from apps.business.models import Business

User = get_user_model()


@staff_member_required
def admin_dashboard(request):
    """
    Main Administration Dashboard Overview.
    Presents high-level metrics, revenue stats, and quick moderation queues.
    """
    # High-level counters
    total_users = User.objects.count()
    active_users = User.objects.filter(is_active=True).count()
    blocked_users = User.objects.filter(is_active=False).count()

    total_events = Event.objects.count()
    published_events = Event.objects.filter(is_published=True).count()

    total_businesses = Business.objects.count()
    verified_businesses = Business.objects.filter(is_verified=True).count()

    total_media = EventMedia.objects.count()
    pending_media = EventMedia.objects.filter(is_approved=False).count()

    # Revenue metrics
    total_revenue = Payment.objects.filter(status='captured').aggregate(Sum('amount'))['amount__sum'] or 0.00
    active_subscriptions = Subscription.objects.filter(status='active').count()

    # Recent activity
    recent_users = User.objects.order_by('-created_at')[:6]
    recent_payments = Payment.objects.filter(status='captured').order_by('-created_at')[:6]
    recent_audit_logs = AuditLog.objects.order_by('-created_at')[:8]

    context = {
        'total_users': total_users,
        'active_users': active_users,
        'blocked_users': blocked_users,
        'total_events': total_events,
        'published_events': published_events,
        'total_businesses': total_businesses,
        'verified_businesses': verified_businesses,
        'total_media': total_media,
        'pending_media': pending_media,
        'total_revenue': total_revenue,
        'active_subscriptions': active_subscriptions,
        'recent_users': recent_users,
        'recent_payments': recent_payments,
        'recent_audit_logs': recent_audit_logs,
    }
    return render(request, 'admin_dashboard/dashboard.html', context)


@staff_member_required
def admin_users(request):
    """Manage all registered user accounts with block/unblock and search."""
    query = request.GET.get('q', '').strip()
    status_filter = request.GET.get('status', '')

    users = User.objects.all().order_by('-created_at')
    if query:
        users = users.filter(
            Q(email__icontains=query) |
            Q(first_name__icontains=query) |
            Q(last_name__icontains=query)
        )
    if status_filter == 'active':
        users = users.filter(is_active=True)
    elif status_filter == 'blocked':
        users = users.filter(is_active=False)

    return render(request, 'admin_dashboard/users.html', {
        'users': users,
        'query': query,
        'status_filter': status_filter,
    })


@staff_member_required
def admin_user_toggle_status(request, user_id):
    """Block or unblock a user account."""
    target_user = get_object_or_404(User, pk=user_id)

    # Protect self-blocking
    if target_user == request.user:
        messages.error(request, "You cannot block your own superuser account.")
        return redirect('admin_dashboard_users')

    target_user.is_active = not target_user.is_active
    target_user.save(update_fields=['is_active'])

    action_label = "unblocked" if target_user.is_active else "blocked"
    action_code = "USER_UNBLOCK" if target_user.is_active else "USER_BLOCK"

    AuditLog.objects.create(
        user=request.user,
        action=action_code,
        resource_type='User',
        resource_id=str(target_user.pk),
        ip_address=request.META.get('REMOTE_ADDR', ''),
        details=f"Admin {request.user.email} {action_label} user {target_user.email}"
    )

    messages.success(request, f"User {target_user.email} has been {action_label}.")
    return redirect('admin_dashboard_users')


@staff_member_required
def admin_events(request):
    """Manage and moderate all platform events."""
    query = request.GET.get('q', '').strip()
    events = Event.objects.select_related('owner').order_by('-created_at')

    if query:
        events = events.filter(
            Q(title__icontains=query) |
            Q(owner__email__icontains=query) |
            Q(host_names__icontains=query)
        )

    return render(request, 'admin_dashboard/events.html', {
        'events': events,
        'query': query,
    })


@staff_member_required
def admin_event_delete(request, event_id):
    """Administrative force delete of an event."""
    event = get_object_or_404(Event, pk=event_id)
    if request.method == 'POST':
        title = event.title
        owner_email = event.owner.email
        event.delete()

        AuditLog.objects.create(
            user=request.user,
            action='EVENT_DELETE',
            resource_type='Event',
            resource_id=str(event_id),
            ip_address=request.META.get('REMOTE_ADDR', ''),
            details=f"Admin deleted event '{title}' owned by {owner_email}"
        )
        messages.success(request, f"Event '{title}' deleted by administrator.")
        return redirect('admin_dashboard_events')

    return render(request, 'admin_dashboard/event_confirm_delete.html', {'event': event})


@staff_member_required
def admin_businesses(request):
    """Manage all digital business profiles and verification statuses."""
    query = request.GET.get('q', '').strip()
    businesses = Business.objects.select_related('owner').order_by('-created_at')

    if query:
        businesses = businesses.filter(
            Q(name__icontains=query) |
            Q(owner__email__icontains=query) |
            Q(city__icontains=query)
        )

    return render(request, 'admin_dashboard/businesses.html', {
        'businesses': businesses,
        'query': query,
    })


@staff_member_required
def admin_business_toggle_verify(request, business_id):
    """Toggle verified badge for a business profile."""
    biz = get_object_or_404(Business, pk=business_id)
    biz.is_verified = not biz.is_verified
    biz.save(update_fields=['is_verified'])

    action_label = "verified" if biz.is_verified else "unverified"
    AuditLog.objects.create(
        user=request.user,
        action='BUSINESS_VERIFY',
        resource_type='Business',
        resource_id=str(biz.pk),
        ip_address=request.META.get('REMOTE_ADDR', ''),
        details=f"Business '{biz.name}' marked as {action_label}"
    )

    messages.success(request, f"Business '{biz.name}' is now {action_label}.")
    return redirect('admin_dashboard_businesses')


@staff_member_required
def admin_media(request):
    """Universal media moderation queue for uploaded event photos and videos."""
    status_filter = request.GET.get('status', 'pending')
    media_qs = EventMedia.objects.select_related('event', 'uploaded_by').order_by('-created_at')

    if status_filter == 'pending':
        media_qs = media_qs.filter(is_approved=False)
    elif status_filter == 'approved':
        media_qs = media_qs.filter(is_approved=True)

    return render(request, 'admin_dashboard/media.html', {
        'media_items': media_qs,
        'status_filter': status_filter,
    })


@staff_member_required
def admin_media_action(request, media_id, action):
    """Approve, reject or delete uploaded media."""
    item = get_object_or_404(EventMedia, pk=media_id)

    if action == 'approve':
        item.is_approved = True
        item.save(update_fields=['is_approved'])
        AuditLog.objects.create(
            user=request.user,
            action='MEDIA_APPROVE',
            resource_type='EventMedia',
            resource_id=str(item.pk),
            ip_address=request.META.get('REMOTE_ADDR', ''),
            details=f"Media #{item.pk} approved for event '{item.event.title}'"
        )
        messages.success(request, "Media item approved.")
    elif action == 'reject':
        item.is_approved = False
        item.save(update_fields=['is_approved'])
        AuditLog.objects.create(
            user=request.user,
            action='MEDIA_REJECT',
            resource_type='EventMedia',
            resource_id=str(item.pk),
            ip_address=request.META.get('REMOTE_ADDR', ''),
            details=f"Media #{item.pk} rejected for event '{item.event.title}'"
        )
        messages.info(request, "Media item rejected.")
    elif action == 'delete':
        item.delete()
        messages.success(request, "Media item permanently removed.")

    return redirect('admin_dashboard_media')


@staff_member_required
def admin_subscriptions(request):
    """View and manage user subscriptions and revenue transactions."""
    subscriptions = Subscription.objects.select_related('user', 'plan').order_by('-created_at')
    payments = Payment.objects.select_related('user', 'plan').order_by('-created_at')

    return render(request, 'admin_dashboard/subscriptions.html', {
        'subscriptions': subscriptions,
        'payments': payments,
    })


@staff_member_required
def admin_audit_logs(request):
    """View security and moderation audit trail."""
    action_filter = request.GET.get('action', '')
    logs = AuditLog.objects.select_related('user').order_by('-created_at')

    if action_filter:
        logs = logs.filter(action=action_filter)

    return render(request, 'admin_dashboard/audit_logs.html', {
        'logs': logs[:200],
        'action_filter': action_filter,
        'action_choices': AuditLog.ACTION_CHOICES,
    })
