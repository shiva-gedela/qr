"""
apps/core/urls.py - URL patterns for core app.
"""

from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('about/', views.about, name='about'),
    path('city/<slug:city_slug>/', views.city_landing, name='city_landing'),
    path('robots.txt', views.robots_txt, name='robots_txt'),
    path('.well-known/assetlinks.json', views.assetlinks_json, name='assetlinks_json'),
    path('.well-known/apple-app-site-association', views.apple_app_site_association, name='apple_app_site_association'),
]
