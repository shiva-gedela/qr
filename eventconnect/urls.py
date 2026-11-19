"""eventconnect/urls.py - Root URL configuration."""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.contrib.sitemaps.views import sitemap
from apps.subscriptions import views as subscription_views
from apps.core import views as core_views
from apps.core.sitemaps import StaticViewSitemap, EventSitemap, BusinessSitemap, CitySitemap

sitemaps = {
    'static': StaticViewSitemap,
    'events': EventSitemap,
    'businesses': BusinessSitemap,
    'cities': CitySitemap,
}

urlpatterns = [
    path('admin/', admin.site.urls),
    path('platform-admin/', include('apps.subscriptions.urls_admin')),
    path('sitemap.xml', sitemap, {'sitemaps': sitemaps}, name='django.contrib.sitemaps.views.sitemap'),
    path('robots.txt', core_views.robots_txt, name='robots_txt'),
    path('.well-known/assetlinks.json', core_views.assetlinks_json, name='assetlinks_json'),
    path('.well-known/apple-app-site-association', core_views.apple_app_site_association, name='apple_app_site_association'),
    path('', include('apps.core.urls')),
    path('accounts/', include('apps.accounts.urls')),
    path('events/', include('apps.events.urls')),
    path('business/', include('apps.business.urls')),
    path('b/', include('apps.business.urls_public')),
    path('pricing/', subscription_views.pricing_view, name='pricing'),
    path('subscriptions/', include('apps.subscriptions.urls')),
    path('qr/', include('apps.qrcodes.urls')),
    path('api/', include('apps.accounts.api_urls')),
    path('api/events/', include('apps.events.api_urls')),
    path('api/business/', include('apps.business.api_urls')),
    path('api/subscriptions/', include('apps.subscriptions.api_urls')),
    path('api/qr/', include('apps.qrcodes.api_urls')),
]

if settings.DEBUG:
    from apps.accounts.models import User
    from apps.events.models import Event
    from apps.accounts import views as acc_views
    from apps.events import views as ev_views
    from apps.qrcodes import views as qr_views

    def _preview_dashboard(request):
        request.user = User.objects.filter(email='demo@eventconnect.com').first() or User.objects.first()
        return acc_views.dashboard_view(request)

    def _preview_events(request):
        request.user = User.objects.filter(email='demo@eventconnect.com').first() or User.objects.first()
        return ev_views.event_list(request)

    def _preview_event_detail(request):
        ev = Event.objects.first()
        request.user = ev.owner
        return ev_views.event_detail(request, pk=ev.pk)

    def _preview_qr_customize(request):
        ev = Event.objects.first()
        request.user = ev.owner
        return qr_views.customize_event_qr(request, event_pk=ev.pk)

    urlpatterns += [
        path('preview/dashboard/', _preview_dashboard),
        path('preview/events/', _preview_events),
        path('preview/event-detail/', _preview_event_detail),
        path('preview/qr-customize/', _preview_qr_customize),
    ]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
