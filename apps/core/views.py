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

    # Celebration Moments Feed (Rich, curated live highlights)
    moments = [
        {
            'id': 1,
            'title': 'Grand Sangeet & Dhol Night',
            'host': 'Priya & Rahul Wedding',
            'category': 'wedding',
            'location': 'Taj Palace, Bengaluru',
            'time': '10 mins ago',
            'likes': 284,
            'tag': '#PriyaWedsRahul',
            'image': 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=800&q=80',
            'badge': '💍 Royal Wedding',
            'audio': '🎵 London Thumakda & Live Dhol',
            'caption': 'Electrifying sangeet performance! The entire bride and groom squad brought the house down!',
            'event_slug': 'test-wedding-event'
        },
        {
            'id': 2,
            'title': 'Aarav 5th Safari Birthday Blast',
            'host': 'Sharma Family',
            'category': 'birthday',
            'location': 'Jungle Fiesta Club, Indiranagar',
            'time': '1 hour ago',
            'likes': 142,
            'tag': '#AaravTurns5',
            'image': 'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?auto=format&fit=crop&w=800&q=80',
            'badge': '🎂 Birthday Bash',
            'audio': '🎵 Happy Birthday Jungle Beats',
            'caption': 'Unwrapping the 3-tier jungle cake with all his preschool besties! Pure joy.',
            'event_slug': 'test-wedding-event'
        },
        {
            'id': 3,
            'title': 'Sunset Ring Exchange & Fireworks',
            'host': 'Neha & Vikram',
            'category': 'engagement',
            'location': 'Leela Raviz Lakeview, Whitefield',
            'time': '3 hours ago',
            'likes': 389,
            'tag': '#NehaVikramEngagement',
            'image': 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=800&q=80',
            'badge': '💑 Engagement',
            'audio': '🎵 Kesariya - Acoustic Violin',
            'caption': 'Under the golden sunset sky, they said forever with sparkling lakefront fireworks!',
            'event_slug': 'test-wedding-event'
        },
        {
            'id': 4,
            'title': 'Silver Jubilee 25th Gala Dinner',
            'host': 'Sunil & Anita 25th',
            'category': 'anniversary',
            'location': 'ITC Gardenia Ballroom',
            'time': '5 hours ago',
            'likes': 225,
            'tag': '#SunilAnita25',
            'image': 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=800&q=80',
            'badge': '❤️ 25th Anniversary',
            'audio': '🎵 Classic Retro Medley',
            'caption': '25 years of love, laughter, and lifelong memories celebrated with 200 loved ones.',
            'event_slug': 'test-wedding-event'
        },
        {
            'id': 5,
            'title': 'Sunset Cocktail & Neon DJ Night',
            'host': 'Rohan & Ananya Pre-Wedding',
            'category': 'party',
            'location': 'High Ultra Rooftop Lounge',
            'time': 'Yesterday',
            'likes': 312,
            'tag': '#RohanAnanyaCocktail',
            'image': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=800&q=80',
            'badge': '🍸 Cocktail Party',
            'audio': '🎵 Deep House & Bollywood Remix',
            'caption': 'Panoramic city skyline views, signature mocktails, and non-stop dancing under the stars!',
            'event_slug': 'test-wedding-event'
        },
        {
            'id': 6,
            'title': 'Haldi Sunshine Carnival',
            'host': 'Kavya & Siddharth',
            'category': 'wedding',
            'location': 'Windsor Manor Greens',
            'time': '2 days ago',
            'likes': 415,
            'tag': '#KavyaSidHaldi',
            'image': 'https://images.unsplash.com/photo-1583939003579-730e3918a45a?auto=format&fit=crop&w=800&q=80',
            'badge': '🌼 Haldi Carnival',
            'audio': '🎵 Genda Phool - Carnival Mix',
            'caption': 'Yellow marigold rain, dhol players, and endless laughter with family and friends.',
            'event_slug': 'test-wedding-event'
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
