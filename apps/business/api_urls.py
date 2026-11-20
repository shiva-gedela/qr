"""
apps/business/api_urls.py

REST API route configuration for Business Profiles & Catalog.
"""

from django.urls import path
from . import api_views

urlpatterns = [
    # Business CRUD
    path('', api_views.BusinessListCreateAPIView.as_view(), name='api_business_list_create'),
    path('<int:pk>/', api_views.BusinessDetailAPIView.as_view(), name='api_business_detail'),

    # Public profile (slug-based lookup for mobile QR scan)
    path('public/<slug:slug>/', api_views.BusinessPublicAPIView.as_view(), name='api_business_public'),

    # Services / Products CRUD
    path('<int:business_pk>/services/', api_views.BusinessServiceListCreateAPIView.as_view(), name='api_service_list_create'),
    path('<int:business_pk>/services/<int:pk>/', api_views.BusinessServiceDetailAPIView.as_view(), name='api_service_detail'),

    # Table & Service Bookings (Web & Mobile Flutter synchronization)
    path('bookings/', api_views.UserBookingListAPIView.as_view(), name='api_user_bookings'),
    path('bookings/<str:booking_code>/cancel/', api_views.BookingCancelAPIView.as_view(), name='api_booking_cancel'),
    path('<int:business_pk>/bookings/', api_views.BusinessBookingListCreateAPIView.as_view(), name='api_business_bookings'),
    path('<int:business_pk>/bookings/<str:booking_code>/status/', api_views.VendorBookingStatusAPIView.as_view(), name='api_vendor_booking_status'),
]
