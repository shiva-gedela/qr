"""
apps/core/views.py - Public home and utility views.
"""

from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
from django.db import models
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


# ─── Location-Based SEO Landing Pages ──────────────────────────────────────────

CITY_METADATA = {
    'hyderabad': {
        'name': 'Hyderabad',
        'state': 'Telangana',
        'state_code': 'TG',
        'tagline': 'Top Event Venues, Wedding Planners, Caterers & Smart QR Passes in Hyderabad',
        'meta_description': 'Explore top weddings, cultural galas, and verified event vendors in Hyderabad. Create instant digital invitation QR codes with turn-by-turn Google Maps GPS route navigation.',
        'popular_areas': ['Banjara Hills', 'Jubilee Hills', 'Gachibowli', 'Madhapur', 'Hitec City', 'Secunderabad', 'Begumpet'],
    },
    'bengaluru': {
        'name': 'Bengaluru',
        'state': 'Karnataka',
        'state_code': 'KA',
        'tagline': 'Top Tech Conferences, Grand Weddings & Event Vendors in Bengaluru',
        'meta_description': 'Discover premier events, wedding halls, caterers, and decorators in Bengaluru. Build smart QR invitation passes with GPS navigation and ride booking.',
        'popular_areas': ['Koramangala', 'Indiranagar', 'Whitefield', 'HSR Layout', 'MG Road', 'Jayanagar'],
    },
    'mumbai': {
        'name': 'Mumbai',
        'state': 'Maharashtra',
        'state_code': 'MH',
        'tagline': 'Premier Weddings, Banquets & Creative Event Vendors in Mumbai',
        'meta_description': 'Find luxury banquet halls, photographers, and event planners in Mumbai. Share digital QR invitations with 1-click GPS routes for your guests.',
        'popular_areas': ['Bandra', 'Andheri', 'Juhu', 'Colaba', 'Worli', 'Powai'],
    },
    'delhi': {
        'name': 'Delhi NCR',
        'state': 'Delhi',
        'state_code': 'DL',
        'tagline': 'Grand Farmhouse Weddings, Exhibitions & Event Services in Delhi NCR',
        'meta_description': 'Plan grand celebrations across Delhi, Gurgaon, and Noida. Smart QR passes with instant Google Maps navigation and guest verification.',
        'popular_areas': ['Chhatarpur', 'Aerocity', 'Connaught Place', 'Gurgaon CyberHub', 'Noida Sector 18'],
    },
    'chennai': {
        'name': 'Chennai',
        'state': 'Tamil Nadu',
        'state_code': 'TN',
        'tagline': 'Traditional Mandapams, Beach Venues & Event Vendors in Chennai',
        'meta_description': 'Explore traditional weddings, kalyana mandapams, and catering services in Chennai with smart QR invitations and GPS redirection.',
        'popular_areas': ['ECR', 'Adyar', 'T. Nagar', 'Mylapore', 'Anna Nagar'],
    },
    'pune': {
        'name': 'Pune',
        'state': 'Maharashtra',
        'state_code': 'MH',
        'tagline': 'Destination Celebrations, Banquets & Vendors in Pune',
        'meta_description': 'Connect with top wedding planners, photographers, and venues in Pune. Instant digital QR passes with turn-by-turn route directions.',
        'popular_areas': ['Koregaon Park', 'Baner', 'Kothrud', 'Viman Nagar', 'Hinjewadi'],
    },
}


def city_landing(request, city_slug):
    """
    Location-specific SEO landing page for cities (e.g. /city/hyderabad/).
    Targets high-intent queries:
    - 'Event vendors in Hyderabad'
    - 'Wedding invitation QR codes Hyderabad'
    - 'Restaurant table bookings Hyderabad'
    """
    slug = city_slug.lower().strip()
    city_info = CITY_METADATA.get(slug)
    if not city_info:
        # Generic fallback
        city_name = slug.replace('-', ' ').title()
        city_info = {
            'name': city_name,
            'state': 'India',
            'state_code': 'IN',
            'tagline': f'Discover Top Events, Vendors & Smart QR Passes in {city_name}',
            'meta_description': f'Explore verified events, venues, and event vendors in {city_name}. Create digital QR invitations with GPS route navigation.',
            'popular_areas': ['Central City', 'Downtown', 'Suburbs'],
        }

    # Query events matching this city
    city_name = city_info['name']
    events = Event.objects.filter(
        is_published=True,
        is_private=False,
    ).filter(
        models.Q(venue_address__icontains=city_name) |
        models.Q(venue_name__icontains=city_name) |
        models.Q(description__icontains=city_name)
    ).order_by('-event_date')[:6]

    if not events:
        events = Event.objects.filter(is_published=True, is_private=False).order_by('-created_at')[:6]

    # Query businesses/vendors matching this city
    businesses = Business.objects.filter(is_active=True).filter(
        models.Q(city__icontains=city_name) |
        models.Q(address__icontains=city_name) |
        models.Q(description__icontains=city_name)
    ).prefetch_related('services').order_by('-created_at')[:8]

    if not businesses:
        businesses = Business.objects.filter(is_active=True).prefetch_related('services').order_by('-created_at')[:8]

    # Rich FAQs for Schema markup and user engagement
    faqs = [
        {
            'q': f'How do I create a digital QR wedding invitation for an event in {city_name}?',
            'a': f'Simply create a free event on QRouteX, set your venue address in {city_name}, and click Generate QR Pass. Your guests can scan the QR pass using any smartphone camera to view the schedule and start 1-click GPS navigation.',
        },
        {
            'q': f'How does Google Maps GPS route navigation help outstation guests traveling in {city_name}?',
            'a': f'QRouteX embeds direct turn-by-turn Google Maps navigation and ride-booking links (Uber, Rapido) into every guest pass so your attendees arrive smoothly at your {city_name} venue without calling for directions.',
        },
        {
            'q': f'Can I hire verified wedding planners, photographers, and caterers in {city_name}?',
            'a': f'Yes! QRouteX lists verified event vendors, banquet halls, caterers, and decorators in {city_name}. You can review portfolios, request bookings, and chat directly via WhatsApp.',
        },
        {
            'q': f'How does the Live Celebration Moments photo wall work at {city_name} celebrations?',
            'a': f'Each guest pass includes instant photo and video uploads. Guests upload snaps from their tables, and you can moderate and download full-resolution albums as a single ZIP file.',
        },
    ]

    return render(request, 'core/city_landing.html', {
        'city': city_info,
        'city_slug': slug,
        'events': events,
        'businesses': businesses,
        'faqs': faqs,
    })


# ─── Technical SEO & Deep Linking Endpoints ────────────────────────────────────

def robots_txt(request):
    """
    Search engine crawler directives.
    Allows indexable marketing, event, business, and city pages.
    Disallows private user dashboards, API endpoints, checkout, and admin pages.
    """
    site_url = getattr(settings, 'SITE_URL', 'https://qroutex.com').rstrip('/')
    content = f"""# QRouteX Robots Directives
User-agent: *
Allow: /
Allow: /events/e/
Allow: /b/
Allow: /city/
Allow: /pricing/
Allow: /about/

# Exclude private dashboards and sensitive data
Disallow: /admin/
Disallow: /platform-admin/
Disallow: /accounts/
Disallow: /api/
Disallow: /checkout/
Disallow: /subscriptions/history/
Disallow: /events/create/
Disallow: /events/*/edit/
Disallow: /events/*/delete/
Disallow: /events/*/guests/
Disallow: /events/invitation/
Disallow: /business/create/
Disallow: /business/*/edit/
Disallow: /business/*/delete/

# Sitemaps declaration
Sitemap: {site_url}/sitemap.xml
"""
    return HttpResponse(content.strip(), content_type="text/plain; charset=utf-8")


def assetlinks_json(request):
    """
    Android App Links Digital Asset Links protocol.
    Enables https://qroutex.com/events/e/* and /b/* URLs to open directly
    in the Qroutex Flutter Android application.
    """
    data = [
        {
            "relation": ["delegate_permission/common.handle_all_urls"],
            "target": {
                "namespace": "android_app",
                "package_name": "com.qroutex.app",
                "sha256_cert_fingerprints": [
                    # Official Play Store / Release key SHA-256 fingerprint
                    "FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C",
                    # Debug fallback keystore fingerprint
                    "27:52:6A:1A:1D:6E:71:03:C6:E9:98:99:99:C9:83:5F:8B:D8:1A:F9:6E:19:D9:F3:33:45:A4:77:B4:DF:22:90"
                ]
            }
        }
    ]
    return JsonResponse(data, safe=False)


def apple_app_site_association(request):
    """
    iOS Universal Links configuration.
    Enables https://qroutex.com/events/e/* and /b/* to open directly
    in the Qroutex Flutter iOS application.
    """
    data = {
        "applinks": {
            "apps": [],
            "details": [
                {
                    "appID": "TEAMID1234.com.qroutex.app",
                    "paths": [
                        "/events/e/*",
                        "/b/*",
                        "/city/*"
                    ]
                }
            ]
        }
    }
    return JsonResponse(data)


def handler404(request, exception):
    return render(request, 'core/404.html', status=404)


def handler500(request):
    return render(request, 'core/500.html', status=500)
