"""
eventconnect/settings.py - Main Django configuration for EventConnect QR Platform.

Loads environment variables from .env for security.
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env file
load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

# ─── Security ────────────────────────────────────────────────────────────────
SECRET_KEY = os.getenv('SECRET_KEY', 'dev-fallback-secret-change-in-production')
DEBUG = os.getenv('DEBUG', 'True') == 'True'
ALLOWED_HOSTS = [h.strip() for h in os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1,.onrender.com,qroutex.com,www.qroutex.com,testserver,*').split(',') if h.strip()]
CSRF_TRUSTED_ORIGINS = [o.strip() for o in os.getenv('CSRF_TRUSTED_ORIGINS', 'http://localhost:8000,http://127.0.0.1:8000,https://*.onrender.com,https://qroutex.com,https://www.qroutex.com').split(',') if o.strip()]

# ─── Application Definition ──────────────────────────────────────────────────
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.sitemaps',
    # Third party
    'rest_framework',
    'rest_framework.authtoken',
    'crispy_forms',
    'crispy_bootstrap5',
    # Local apps
    'apps.core',
    'apps.accounts',
    'apps.events',
    'apps.qrcodes',
    'apps.business',
    'apps.subscriptions',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'eventconnect.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
                'apps.core.context_processors.site_settings',
            ],
        },
    },
]

WSGI_APPLICATION = 'eventconnect.wsgi.application'

# ─── Database ─────────────────────────────────────────────────────────────────
import dj_database_url
import socket

DATABASE_URL = os.getenv('DATABASE_URL')
if DATABASE_URL:
    try:
        parsed_db = dj_database_url.parse(DATABASE_URL)
        db_host = parsed_db.get('HOST', '')
        can_resolve = True
        if db_host and db_host not in ('127.0.0.1', 'localhost'):
            try:
                socket.getaddrinfo(db_host, parsed_db.get('PORT', 5432) or 5432)
            except (socket.gaierror, OSError):
                can_resolve = False
        
        if can_resolve:
            DATABASES = {
                'default': dj_database_url.parse(
                    DATABASE_URL,
                    conn_max_age=600,
                    conn_health_checks=True,
                    ssl_require=True if ('render.com' in DATABASE_URL or 'postgres' in DATABASE_URL or 'supabase' in DATABASE_URL) else False,
                )
            }
        else:
            print(f"[Database Notice] Remote host '{db_host}' is unreachable from this local network (IPv6-only host). Falling back to local SQLite.")
            DATABASES = {
                'default': {
                    'ENGINE': 'django.db.backends.sqlite3',
                    'NAME': BASE_DIR / 'db.sqlite3',
                }
            }
    except Exception as e:
        print(f"[Database Error] Failed to parse DATABASE_URL: {e}. Falling back to SQLite.")
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': BASE_DIR / 'db.sqlite3',
            }
        }
else:
    DB_ENGINE = os.getenv('DB_ENGINE', '')
    if DB_ENGINE == 'django.db.backends.mysql':
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.mysql',
                'NAME': os.getenv('DB_NAME', 'eventconnect_qr'),
                'USER': os.getenv('DB_USER', 'root'),
                'PASSWORD': os.getenv('DB_PASSWORD', ''),
                'HOST': os.getenv('DB_HOST', '127.0.0.1'),
                'PORT': os.getenv('DB_PORT', '3306'),
                'OPTIONS': {
                    'charset': 'utf8mb4',
                    'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
                },
            }
        }
    else:
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': BASE_DIR / 'db.sqlite3',
            }
        }

# ─── Password Validation ──────────────────────────────────────────────────────
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# ─── Internationalization ─────────────────────────────────────────────────────
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Kolkata'
USE_I18N = True
USE_TZ = True

# ─── Static & Media Files ─────────────────────────────────────────────────────
STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / 'static']
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# ─── Default Primary Key ──────────────────────────────────────────────────────
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ─── Authentication ───────────────────────────────────────────────────────────
AUTH_USER_MODEL = 'accounts.User'
LOGIN_URL = '/accounts/login/'
LOGIN_REDIRECT_URL = '/dashboard/'
LOGOUT_REDIRECT_URL = '/'

# ─── Email ────────────────────────────────────────────────────────────────────
EMAIL_BACKEND = os.getenv('EMAIL_BACKEND', 'django.core.mail.backends.console.EmailBackend')
EMAIL_HOST = os.getenv('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', 587))
EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS', 'True') == 'True'
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD', '')
# ─── Email ────────────────────────────────────────────────────────────────────
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL', 'QRouteX <noreply@qroutex.com>')

# ─── Crispy Forms ─────────────────────────────────────────────────────────────
CRISPY_ALLOWED_TEMPLATE_PACKS = 'bootstrap5'
CRISPY_TEMPLATE_PACK = 'bootstrap5'

# ─── REST Framework ───────────────────────────────────────────────────────────
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}

# ─── Site Settings ────────────────────────────────────────────────────────────
SITE_NAME = 'QRouteX'
SITE_DOMAIN = 'qroutex.com'
SITE_URL = os.getenv('SITE_URL', 'https://qroutex.com')
GOOGLE_MAPS_API_KEY = os.getenv('GOOGLE_MAPS_API_KEY', '')

# ─── File Upload Limits ───────────────────────────────────────────────────────
DATA_UPLOAD_MAX_MEMORY_SIZE = 20 * 1024 * 1024    # 20 MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 20 * 1024 * 1024    # 20 MB
MAX_IMAGE_SIZE_MB = 5
MAX_VIDEO_SIZE_MB = 100

# ─── Razorpay ─────────────────────────────────────────────────────────────────
RAZORPAY_KEY_ID = os.getenv('RAZORPAY_KEY_ID', '')
RAZORPAY_KEY_SECRET = os.getenv('RAZORPAY_KEY_SECRET', '')

# ─── AWS S3 (Phase 7) ─────────────────────────────────────────────────────────
USE_S3 = os.getenv('USE_S3', 'False') == 'True'
if USE_S3:
    AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
    AWS_STORAGE_BUCKET_NAME = os.getenv('AWS_STORAGE_BUCKET_NAME')
    AWS_S3_REGION_NAME = os.getenv('AWS_S3_REGION_NAME', 'ap-south-1')
    AWS_DEFAULT_ACL = 'public-read'
    AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.amazonaws.com'
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    MEDIA_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/media/'
