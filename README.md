# EventConnect QR

**Production-ready Django platform for creating event invitations with QR codes, event mini-websites, photo/video galleries, and digital business profiles.**

---

## 🚀 Quick Start (Windows 11 + VS Code)

### Prerequisites
- Python 3.12+ (installed via PyManager at `C:\Program Files\PyManager`)  
- MySQL 8.x + phpMyAdmin (via XAMPP recommended)
- Git

---

## Phase 1: Setup & Installation

### Step 1 — Clone / open the project
```powershell
cd "C:\Users\omics\Downloads\New folder\qr"
code .
```

### Step 2 — Activate virtual environment
```powershell
.\venv\Scripts\activate
```

### Step 3 — Install all packages
```powershell
pip install -r requirements.txt
```

### Step 4 — Configure environment
The `.env` file is already created. Edit it with your MySQL credentials:
```powershell
notepad .env
```
Key settings to change:
```env
SECRET_KEY=your-very-long-random-secret-key-here
DB_NAME=eventconnect_qr
DB_USER=root
DB_PASSWORD=          # your MySQL root password (blank for XAMPP default)
DB_HOST=127.0.0.1
DB_PORT=3306
```

### Step 5 — Create MySQL database
Open phpMyAdmin at `http://localhost/phpmyadmin` and run:
```sql
CREATE DATABASE eventconnect_qr CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### Step 6 — Run migrations
```powershell
# Using MySQL (production mode)
python manage.py migrate

# Using SQLite (dev/test without MySQL)
$env:DJANGO_SETTINGS_MODULE="eventconnect.settings_test"
python manage.py migrate
```

### Step 7 — Seed sample data
```powershell
python manage.py seed_data
```

### Step 8 — Start development server
```powershell
# With MySQL
python manage.py runserver

# With SQLite test database
$env:DJANGO_SETTINGS_MODULE="eventconnect.settings_test"
python manage.py runserver
```

Open `http://127.0.0.1:8000` in your browser.

---

## 🔐 Default Login Credentials

| Role    | Email                              | Password    |
|---------|------------------------------------|-------------|
| Admin   | admin@eventconnect.com             | Admin@1234  |
| User 1  | ravi@sample.eventconnect.com       | Test@1234   |
| User 2  | priya@sample.eventconnect.com      | Test@1234   |
| User 3  | arjun@sample.eventconnect.com      | Test@1234   |

Admin panel: `http://127.0.0.1:8000/admin/`

---

## 📂 Project Structure

```
qr/
├── eventconnect/              # Django project package
│   ├── settings.py            # Main settings (MySQL, AWS S3, etc.)
│   ├── settings_test.py       # SQLite override for local testing
│   ├── urls.py                # Root URL configuration
│   ├── wsgi.py                # WSGI entry point
│   └── asgi.py                # ASGI entry point
│
├── apps/
│   ├── core/                  # Home page, error handlers, context processors
│   │   ├── management/commands/seed_data.py   # Sample data command
│   │   ├── views.py
│   │   └── urls.py
│   │
│   ├── accounts/              # User auth: register, login, profile, dashboard
│   │   ├── models.py          # Custom User model (email login)
│   │   ├── forms.py           # Registration, login, profile forms
│   │   ├── views.py           # Auth views with email verification
│   │   ├── serializers.py     # DRF serializers for Flutter API
│   │   ├── api_views.py       # REST API views for mobile app
│   │   ├── urls.py            # Web URLs
│   │   ├── api_urls.py        # API URLs
│   │   └── admin.py           # Custom admin configuration
│   │
│   ├── events/                # Event CRUD, gallery, public mini-website
│   │   ├── models.py          # Event, EventMedia models
│   │   ├── forms.py           # Event creation/edit forms
│   │   ├── views.py           # CRUD + public event views + calendar.ics
│   │   ├── serializers.py     # DRF serializers
│   │   ├── api_views.py       # REST API for Flutter
│   │   ├── urls.py            # Web URLs
│   │   ├── api_urls.py        # API URLs
│   │   └── admin.py           # Event admin
│   │
│   └── qrcodes/               # QR Code generator engine & printable cards
│       ├── models.py          # QRCode model (db_table: qr_codes)
│       ├── services.py        # QR image engine (Pillow + qrcode) + ReportLab PDF
│       ├── forms.py           # QR customization form (color pickers, logo)
│       ├── views.py           # PNG/PDF downloads, customization, scan tracker
│       ├── serializers.py     # DRF serializers for Flutter app
│       ├── api_views.py       # QR REST API endpoints
│       ├── urls.py            # Web routes
│       ├── api_urls.py        # API routes
│       ├── signals.py         # Auto QR generation on Event creation
│       └── admin.py           # QRCode admin with thumbnail previews
│
├── templates/
│   ├── base.html              # Bootstrap 5 base layout with navbar/footer
│   ├── core/                  # home.html, about.html, 404.html, 500.html
│   ├── accounts/              # register, login, dashboard, profile, password reset
│   ├── events/                # event list, form, detail, public, delete
│   └── qrcodes/               # customize_qr.html (live preview, presets)
│
├── static/
│   ├── css/main.css           # Custom Bootstrap 5 styles
│   └── js/main.js             # Utility JavaScript
│
├── media/                     # Uploaded files (dev only; use S3 in production)
├── .env                       # Environment variables (never commit to git!)
├── .env.example               # Template for .env
├── requirements.txt           # Python dependencies
└── manage.py                  # Django management CLI
```

---

## 🌐 URL Reference

### Web URLs
| URL | Description |
|-----|-------------|
| `/` | Home/landing page |
| `/about/` | About page |
| `/accounts/register/` | User registration |
| `/accounts/login/` | Login |
| `/accounts/logout/` | Logout (POST) |
| `/accounts/dashboard/` | User dashboard |
| `/accounts/profile/` | Edit profile |
| `/accounts/verify-email/<token>/` | Email verification |
| `/accounts/password-reset/` | Request password reset |
| `/events/` | List user's events |
| `/events/create/` | Create new event |
| `/events/<pk>/` | Manage event (owner) |
| `/events/<pk>/edit/` | Edit event |
| `/events/<pk>/delete/` | Delete event |
| `/events/<pk>/toggle-publish/` | Publish/unpublish |
| `/events/<pk>/upload/` | Upload media (owner) |
| `/events/<pk>/media/<id>/download/` | Download single media file |
| `/events/<pk>/media/<id>/toggle-approval/` | Approve/reject guest media |
| `/events/<pk>/media/approve-all/` | Bulk approve all pending media |
| `/events/<pk>/gallery/download-zip/` | **Download all approved photos as ZIP** |
| `/events/e/<slug>/` | **Public event mini-website (QR landing page)** |
| `/events/e/<slug>/calendar.ics` | Download iCalendar (.ics) invite file |
| `/events/e/<slug>/guest-upload/` | Guest photo/video upload from public site |
| `/qr/download/png/<uuid>/` | Download high-resolution QR PNG |
| `/qr/download/pdf/<uuid>/` | Download printable A4 invitation PDF card |
| `/qr/event/<pk>/customize/` | Customize QR colors & center logo |
| `/qr/scan/<uuid>/` | Trackable QR scan redirect endpoint |
| `/admin/` | Django admin |

### REST API URLs (for Flutter)
| Method | URL | Description |
|--------|-----|-------------|
| POST | `/api/auth/register/` | Register |
| POST | `/api/auth/login/` | Login |
| POST | `/api/auth/logout/` | Logout |
| GET/PATCH | `/api/auth/profile/` | Get/update profile |
| GET/POST | `/api/events/` | List/create events |
| GET/PUT/DELETE | `/api/events/<pk>/` | Event detail (includes QR & storage info) |
| POST | `/api/events/<pk>/publish/` | Toggle publish |
| GET/POST | `/api/events/<pk>/media/` | List / Upload event media |
| DELETE | `/api/events/<pk>/media/<id>/` | Delete event media file |
| POST | `/api/events/<pk>/media/<id>/toggle-approval/` | Toggle media approval status |
| GET | `/api/events/public/<slug>/` | Public event data |
| GET | `/api/events/public/<slug>/media/` | Public gallery items with category filter |
| POST | `/api/events/public/<slug>/guest-upload/` | Guest photo/video upload via mobile app |
| GET | `/api/qr/event/<pk>/` | Get event QR code details |
| POST | `/api/qr/event/<pk>/customize/` | Customize event QR code via API |
| POST | `/api/qr/scan/<uuid>/` | Record scan event from Flutter QR Scanner |

---

## 🗄️ Database Schema

### Key Tables
- **users** — Custom user model (email login, avatar, email_verified, is_premium)
- **events** — Event records with slug, type, date, venue, permanent public URL, storage quota & approval settings
- **event_media** — Photos and videos with categories, thumbnails, approval flags & file size tracking
- **qr_codes** — Normalized QR codes for events & businesses (colors, center logo, PNG, scan metrics)

---

## 🔧 Development Phases

| Phase | Status | Description |
|-------|--------|-------------|
| **1** | ✅ Complete | Django setup, MySQL, Auth, Event CRUD |
| **2** | ✅ Complete | Event QR generation, downloadable QR PNG/PDF, public mini-website |
| **3** | ✅ Complete | Event photo/video upload, category gallery, approval queue, ZIP download |
| **4** | 🔜 Next | Business profiles and business QR generator |
| **5** | 🔜 | Admin dashboard, subscriptions, Razorpay |
| **6** | 🔜 | Flutter Android app connected to Django REST API |
| **7** | 🔜 | AWS S3 media storage, deployment, security & testing |

---

## 🛡️ Security Notes

- Never commit `.env` to Git — add it to `.gitignore`
- Change `SECRET_KEY` before deployment
- Set `DEBUG=False` and configure `ALLOWED_HOSTS` in production
- All private views enforce ownership checks
- File uploads are validated for type and size
- CSRF protection is active on all forms

---

## 📦 Key Packages

| Package | Version | Purpose |
|---------|---------|---------|
| Django | 6.1.3 | Web framework |
| djangorestframework | 3.18.3 | REST API for Flutter |
| mysqlclient | 2.3.1 | MySQL database adapter |
| Pillow | 13.0.0 | Image processing |
| qrcode[pil] | 8.2 | QR code generation (Phase 2) |
| django-crispy-forms | 2.7 | Bootstrap 5 forms |
| whitenoise | 6.12.0 | Static file serving |
| reportlab | 5.1.0 | PDF generation (Phase 2) |
| python-dotenv | 1.2.4 | Environment variable management |

---

## 🐛 Troubleshooting

**MySQL connection error:** Start XAMPP MySQL service, check `.env` credentials  
**Migration error:** Ensure the database `eventconnect_qr` exists in phpMyAdmin  
**Static files 404:** Run `python manage.py collectstatic`  
**Testing without MySQL:** Use `$env:DJANGO_SETTINGS_MODULE="eventconnect.settings_test"` prefix
