"""
apps/subscriptions/urls_admin.py

Route patterns for the custom Platform Admin Dashboard (Module 8).
"""

from django.urls import path
from . import admin_views

urlpatterns = [
    path('', admin_views.admin_dashboard, name='admin_dashboard'),
    path('users/', admin_views.admin_users, name='admin_dashboard_users'),
    path('users/<int:user_id>/toggle-status/', admin_views.admin_user_toggle_status, name='admin_user_toggle_status'),
    path('events/', admin_views.admin_events, name='admin_dashboard_events'),
    path('events/<int:event_id>/delete/', admin_views.admin_event_delete, name='admin_event_delete'),
    path('businesses/', admin_views.admin_businesses, name='admin_dashboard_businesses'),
    path('businesses/<int:business_id>/toggle-verify/', admin_views.admin_business_toggle_verify, name='admin_business_toggle_verify'),
    path('media/', admin_views.admin_media, name='admin_dashboard_media'),
    path('media/<int:media_id>/<str:action>/', admin_views.admin_media_action, name='admin_media_action'),
    path('subscriptions/', admin_views.admin_subscriptions, name='admin_dashboard_subscriptions'),
    path('audit-logs/', admin_views.admin_audit_logs, name='admin_dashboard_audit_logs'),
]
