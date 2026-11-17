"""
apps/core/views.py - Public home and utility views.
"""

from django.shortcuts import render
from django.conf import settings


def home(request):
    """Public home / landing page with featured event types and pitch features."""
    event_types = [
        {'code': 'wedding', 'name': 'Wedding', 'icon': '💍'},
        {'code': 'birthday', 'name': 'Birthday', 'icon': '🎂'},
        {'code': 'engagement', 'name': 'Engagement', 'icon': '💑'},
        {'code': 'anniversary', 'name': 'Anniversary', 'icon': '❤️'},
        {'code': 'housewarming', 'name': 'Housewarming', 'icon': '🏠'},
        {'code': 'graduation', 'name': 'Graduation', 'icon': '🎓'},
    ]
    return render(request, 'core/home.html', {
        'site_name': settings.SITE_NAME,
        'event_types': event_types,
    })


def about(request):
    """About page."""
    return render(request, 'core/about.html')


def handler404(request, exception):
    return render(request, 'core/404.html', status=404)


def handler500(request):
    return render(request, 'core/500.html', status=500)
