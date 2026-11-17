"""
apps/events/urls.py - URL patterns for events app.
"""

from django.urls import path
from . import views

urlpatterns = [
    # Owner / private event management
    path('', views.event_list, name='event_list'),
    path('create/', views.event_create, name='event_create'),
    path('<int:pk>/', views.event_detail, name='event_detail'),
    path('<int:pk>/edit/', views.event_edit, name='event_edit'),
    path('<int:pk>/delete/', views.event_delete, name='event_delete'),
    path('<int:pk>/toggle-publish/', views.event_toggle_publish, name='event_toggle_publish'),
    path('<int:pk>/upload/', views.media_upload, name='media_upload'),
    path('<int:pk>/media/<int:media_id>/delete/', views.media_delete, name='media_delete'),
    path('<int:pk>/media/<int:media_id>/toggle-approval/', views.media_toggle_approval, name='media_toggle_approval'),
    path('<int:pk>/media/approve-all/', views.media_approve_all, name='media_approve_all'),
    path('<int:pk>/media/<int:media_id>/download/', views.media_download, name='media_download'),
    path('<int:pk>/gallery/download-zip/', views.media_download_zip, name='media_download_zip'),

    # Public event mini-website (QR landing page)
    path('e/<slug:slug>/', views.event_public, name='event_public'),
    path('e/<slug:slug>/gps/', views.event_gps_redirect, name='event_gps_redirect'),
    path('e/<slug:slug>/navigate/', views.event_gps_redirect, name='event_navigate'),
    path('e/<slug:slug>/calendar.ics', views.event_calendar_ics, name='event_calendar_ics'),
    path('e/<slug:slug>/guest-upload/', views.guest_media_upload, name='guest_media_upload'),
]
