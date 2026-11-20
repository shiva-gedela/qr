"""
apps/business/urls_public.py

Public vanity route patterns mounted directly at /b/<slug>/
"""

from django.urls import path
from . import views

urlpatterns = [
    path('<slug:slug>/', views.business_public, name='business_public'),
    path('<slug:slug>/contact.vcf', views.business_vcard, name='business_vcard'),
    path('<slug:slug>/book/', views.business_public_book, name='business_public_book'),
]
