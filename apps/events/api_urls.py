"""
apps/events/api_urls.py - REST API URLs for events (used by Flutter app).
"""

from django.urls import path
from . import api_views

urlpatterns = [
    path('', api_views.EventListCreateAPIView.as_view(), name='api_event_list_create'),
    path('<int:pk>/', api_views.EventRetrieveUpdateDestroyAPIView.as_view(), name='api_event_detail'),
    path('<int:pk>/publish/', api_views.EventTogglePublishAPIView.as_view(), name='api_event_toggle_publish'),
    path('<int:pk>/media/', api_views.EventMediaListCreateAPIView.as_view(), name='api_event_media_list'),
    path('<int:pk>/media/upload/', api_views.EventMediaListCreateAPIView.as_view(), name='api_event_media_upload'),
    path('<int:pk>/media/<int:media_id>/', api_views.EventMediaDeleteAPIView.as_view(), name='api_event_media_delete'),
    path('<int:pk>/media/<int:media_id>/toggle-approval/', api_views.EventMediaToggleApprovalAPIView.as_view(), name='api_event_media_toggle_approval'),
    path('public/<slug:slug>/', api_views.EventPublicAPIView.as_view(), name='api_event_public'),
    path('public/<slug:slug>/media/', api_views.PublicEventGalleryAPIView.as_view(), name='api_public_event_gallery'),
    path('public/<slug:slug>/guest-upload/', api_views.PublicEventGuestUploadAPIView.as_view(), name='api_public_event_guest_upload'),
]
