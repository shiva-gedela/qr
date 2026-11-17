"""eventconnect/asgi.py - ASGI config for EventConnect QR."""

import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'eventconnect.settings')
application = get_asgi_application()
