"""eventconnect/urls.py - Root URL configuration."""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from apps.subscriptions import views as subscription_views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('platform-admin/', include('apps.subscriptions.urls_admin')),
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
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
