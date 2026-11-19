"""
apps/core/views.py - Public home and utility views.
"""

from django.shortcuts import render
from django.conf import settings
from apps.events.models import Event
from apps.business.models import Business


def home(request):
    """Public home / landing page with featured event types, live events, and popular businesses."""
    event_types = [
        {'code': 'wedding', 'name': 'Wedding', 'icon': '💍', 'desc': 'Grand mandap, guest passes & directions'},
        {'code': 'birthday', 'name': 'Birthday', 'icon': '🎂', 'desc': 'Celebration themes & live photo wall'},
        {'code': 'engagement', 'name': 'Engagement', 'icon': '💑', 'desc': 'Ceremony invitations & GPS routes'},
        {'code': 'anniversary', 'name': 'Anniversary', 'icon': '❤️', 'desc': 'Milestone memories & guest RSVPs'},
        {'code': 'housewarming', 'name': 'Housewarming', 'icon': '🏠', 'desc': 'Griha Pravesh navigation & passes'},
        {'code': 'graduation', 'name': 'Graduation', 'icon': '🎓', 'desc': 'Convocation & party passes'},
    ]

    # Fetch published events for preview
    featured_events = list(
        Event.objects.filter(is_published=True).order_by('-event_date')[:6]
    )
    if not featured_events:
        featured_events = list(Event.objects.all().order_by('-created_at')[:6])

    # Fetch popular businesses/restaurants/vendors
    popular_businesses = list(
        Business.objects.filter(is_active=True).prefetch_related('services').order_by('-created_at')[:6]
    )

    # Celebration Moments Feed (Sample & Real highlights)
    moments = [
        {
            'title': 'Grand Sangeet & Dhol Night',
            'host': 'Priya & Rahul Wedding',
            'time': '2 hours ago',
            'likes': 142,
            'tag': '#PriyaWedsRahul',
            'image': 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=600&q=80',
            'badge': '💍 Wedding'
        },
        {
            'title': 'Aarav 5th Birthday Blast',
            'host': 'Sharma Family',
            'time': '5 hours ago',
            'likes': 98,
            'tag': '#AaravTurns5',
            'image': 'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?auto=format&fit=crop&w=600&q=80',
            'badge': '🎂 Birthday'
        },
        {
            'title': 'Sunset Ring Exchange Ceremony',
            'host': 'Neha & Vikram',
            'time': 'Yesterday',
            'likes': 210,
            'tag': '#NehaVikramEngagement',
            'image': 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=600&q=80',
            'badge': '💑 Engagement'
        },
        {
            'title': 'Silver Jubilee Celebration',
            'host': 'Sunil & Anita 25th',
            'time': '2 days ago',
            'likes': 185,
            'tag': '#SunilAnita25',
            'image': 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=600&q=80',
            'badge': '❤️ Anniversary'
        },
    ]

    return render(request, 'core/home.html', {
        'site_name': settings.SITE_NAME,
        'event_types': event_types,
        'featured_events': featured_events,
        'popular_businesses': popular_businesses,
        'moments': moments,
    })


def about(request):
    """About page."""
    return render(request, 'core/about.html')


def handler404(request, exception):
    return render(request, 'core/404.html', status=404)


def handler500(request):
    return render(request, 'core/500.html', status=500)
