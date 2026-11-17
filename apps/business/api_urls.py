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
]
