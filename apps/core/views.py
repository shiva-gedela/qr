"""
apps/core/views.py - Public home and utility views.
"""

from django.shortcuts import render
from django.conf import settings


def home(request):
    """Public home / landing page."""
    return render(request, 'core/home.html', {'site_name': settings.SITE_NAME})


def about(request):
    """About page."""
    return render(request, 'core/about.html')


def handler404(request, exception):
    return render(request, 'core/404.html', status=404)


def handler500(request):
    return render(request, 'core/500.html', status=500)
