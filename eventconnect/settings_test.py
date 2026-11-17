"""
eventconnect/settings_test.py

SQLite-based settings for local testing without MySQL.
Extends the main settings with SQLite override.
"""

from .settings import *  # noqa: F401, F403

# Override database to use SQLite for local dev without MySQL
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db_test.sqlite3',
    }
}

ALLOWED_HOSTS = ['*']

# Disable whitenoise static compression for fast test startup
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.StaticFilesStorage'
