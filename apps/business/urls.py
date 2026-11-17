"""
apps/business/urls.py

URL patterns for digital business profiles and services.
"""

from django.urls import path
from . import views

urlpatterns = [
    # Dashboard & Management (owner only)
    path('', views.business_list, name='business_list'),
    path('create/', views.business_create, name='business_create'),
    path('<int:pk>/', views.business_detail, name='business_detail'),
    path('<int:pk>/edit/', views.business_edit, name='business_edit'),
    path('<int:pk>/delete/', views.business_delete, name='business_delete'),

    # Services / Products CRUD (owner only)
    path('<int:pk>/services/add/', views.service_create, name='service_create'),
    path('<int:pk>/services/<int:service_id>/edit/', views.service_edit, name='service_edit'),
    path('<int:pk>/services/<int:service_id>/delete/', views.service_delete, name='service_delete'),

    # Public mini-website & vCard download
    path('b/<slug:slug>/', views.business_public, name='business_public'),
    path('b/<slug:slug>/contact.vcf', views.business_vcard, name='business_vcard'),
]
