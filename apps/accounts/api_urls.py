"""
apps/accounts/api_urls.py - REST API URL patterns for accounts.
"""

from django.urls import path
from . import api_views

urlpatterns = [
    # Direct routes
    path('login/', api_views.LoginAPIView.as_view(), name='api_login_direct'),
    path('register/', api_views.RegisterAPIView.as_view(), name='api_register_direct'),
    path('profile/', api_views.ProfileAPIView.as_view(), name='api_profile_direct'),
    path('logout/', api_views.LogoutAPIView.as_view(), name='api_logout_direct'),

    # Namespaced auth routes
    path('auth/register/', api_views.RegisterAPIView.as_view(), name='api_register'),
    path('auth/login/', api_views.LoginAPIView.as_view(), name='api_login'),
    path('auth/logout/', api_views.LogoutAPIView.as_view(), name='api_logout'),
    path('auth/profile/', api_views.ProfileAPIView.as_view(), name='api_profile'),
]
