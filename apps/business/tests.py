"""
apps/business/tests.py

Comprehensive automated test suite for Phase 4:
- Digital Business Profile creation & unique slugs
- vCard 3.0 generation
- Products and Services catalog CRUD
- Business QR code generation & customization
- Printable tabletop standee PDF and PNG downloads
- Public digital business card view (/b/<slug>/) and vCard (.vcf) download
- Django REST Framework APIs for mobile & external integrations
"""

from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from apps.business.models import Business, BusinessService
from apps.qrcodes.models import QRCode
from apps.qrcodes.services import generate_or_update_business_qr, generate_business_qr_pdf

User = get_user_model()


class BusinessModelTests(TestCase):
    """Test suite for Business and BusinessService models and vCard generation."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='bizowner@example.com',
            email='bizowner@example.com',
            password='TestPassword@123',
            first_name='Ananya',
            last_name='Deshmukh'
        )

    def test_business_creation_and_slug(self):
        """Test business creation, unique slug generation and QR code trigger."""
        biz = Business.objects.create(
            owner=self.user,
            name='Elegance Bridal Boutique',
            tagline='Designer lehengas & bridal wear',
            category='retail',
            phone='+91 98765 00001',
            whatsapp='+91 98765 00001',
            email='info@eleganceboutique.com',
            website='https://eleganceboutique.example.com',
            address='12 MG Road',
            city='Pune',
            state='Maharashtra',
            pincode='411001',
            maps_url='https://maps.google.com/?q=Pune+MG+Road'
        )
        self.assertTrue(biz.slug.startswith('elegance-bridal-boutique'))
        self.assertEqual(biz.full_address, '12 MG Road, Pune, Maharashtra, 411001')
        self.assertTrue('wa.me/919876500001' in biz.whatsapp_url)
        self.assertEqual(biz.phone_url, 'tel:+919876500001')

    def test_vcard_generation(self):
        """Test vCard 3.0 string formatting."""
        biz = Business.objects.create(
            owner=self.user,
            name='Vertex Tech Solutions',
            tagline='Custom Cloud & AI Engineering',
            category='tech',
            phone='+91 98765 99999',
            whatsapp='+91 98765 88888',
            email='contact@vertextech.example.com',
            website='https://vertextech.example.com',
            address='Cyber Park Tower B',
            city='Hyderabad',
            state='Telangana',
            pincode='500081',
            description='Enterprise software development.'
        )
        vcard = biz.generate_vcard_string()
        self.assertIn('BEGIN:VCARD', vcard)
        self.assertIn('VERSION:3.0', vcard)
        self.assertIn('FN:Vertex Tech Solutions', vcard)
        self.assertIn('TITLE:Custom Cloud & AI Engineering', vcard)
        self.assertIn('TEL;TYPE=WORK,VOICE:+91 98765 99999', vcard)
        self.assertIn('TEL;TYPE=CELL,WHATSAPP:+91 98765 88888', vcard)
        self.assertIn('EMAIL;TYPE=PREF,INTERNET:contact@vertextech.example.com', vcard)
        self.assertIn('URL:https://vertextech.example.com', vcard)
        self.assertIn('END:VCARD', vcard)

    def test_services_catalog_and_price_display(self):
        """Test adding products/services and checking display price logic."""
        biz = Business.objects.create(
            owner=self.user,
            name='Gourmet Catering Co',
            category='food'
        )
        s1 = BusinessService.objects.create(
            business=biz,
            name='Silver Dining Buffet',
            price=850.00,
            price_type='starting',
            order=1
        )
        s2 = BusinessService.objects.create(
            business=biz,
            name='Custom Menu Tasting',
            price=None,
            price_type='contact',
            order=2
        )
        s3 = BusinessService.objects.create(
            business=biz,
            name='Live BBQ Station',
            price=15000.00,
            price_type='fixed',
            order=3
        )

        self.assertIn('From ₹850.00', s1.price_display)
        self.assertEqual(s2.price_display, 'Price on Request')
        self.assertIn('₹15,000.00', s3.price_display)
        self.assertEqual(biz.get_active_services().count(), 3)


class BusinessViewsWebTests(TestCase):
    """Test suite for web dashboard views, forms, and public card."""

    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            username='user1@example.com',
            email='user1@example.com',
            password='TestPassword@123',
            first_name='Rohan',
            last_name='Verma'
        )
        self.other_user = User.objects.create_user(
            username='user2@example.com',
            email='user2@example.com',
            password='TestPassword@123',
            first_name='Pooja',
            last_name='Singh'
        )
        self.biz = Business.objects.create(
            owner=self.user,
            name='Rohan Events Decor',
            category='event_services',
            city='Delhi',
            phone='+91 98111 22233'
        )
        generate_or_update_business_qr(self.biz)

    def test_business_list_requires_login(self):
        """Unauthenticated user is redirected to login."""
        response = self.client.get(reverse('business_list'))
        self.assertEqual(response.status_code, 302)

    def test_business_list_authenticated(self):
        """Owner sees their own businesses in the list."""
        self.client.login(username='user1@example.com', password='TestPassword@123')
        response = self.client.get(reverse('business_list'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Rohan Events Decor')

    def test_business_detail_and_ownership(self):
        """Owner can view business dashboard; other user receives 404."""
        self.client.login(username='user1@example.com', password='TestPassword@123')
        response = self.client.get(reverse('business_detail', kwargs={'pk': self.biz.pk}))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Rohan Events Decor')
        self.assertContains(response, 'Products & Services Catalog')

        # Other user attempt
        self.client.login(username='user2@example.com', password='TestPassword@123')
        response2 = self.client.get(reverse('business_detail', kwargs={'pk': self.biz.pk}))
        self.assertEqual(response2.status_code, 404)

    def test_business_create_post(self):
        """Test creating a new business profile via web form."""
        self.client.login(username='user1@example.com', password='TestPassword@123')
        post_data = {
            'name': 'Sparkle Cleaners',
            'category': 'other',
            'phone': '+91 98222 33344',
            'city': 'Mumbai',
            'state': 'Maharashtra',
            'is_active': True,
        }
        response = self.client.post(reverse('business_create'), post_data)
        self.assertEqual(response.status_code, 302)
        created_biz = Business.objects.filter(name='Sparkle Cleaners').first()
        self.assertIsNotNone(created_biz)
        self.assertEqual(created_biz.owner, self.user)
        self.assertIsNotNone(created_biz.qr_code)

    def test_public_business_card(self):
        """Public mini-website (/b/<slug>/) is accessible to guests without login."""
        response = self.client.get(reverse('business_public', kwargs={'slug': self.biz.slug}))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Rohan Events Decor')
        self.assertContains(response, 'Event Planning &amp; Decoration')
        self.assertContains(response, 'Save Contact')

    def test_vcard_download(self):
        """Test /b/<slug>/contact.vcf returns valid vCard file."""
        response = self.client.get(reverse('business_vcard', kwargs={'slug': self.biz.slug}))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response['Content-Type'], 'text/vcard; charset=utf-8')
        self.assertIn('attachment; filename="rohan-events-decor.vcf"', response['Content-Disposition'])
        self.assertIn(b'BEGIN:VCARD', response.content)
        self.assertIn(b'FN:Rohan Events Decor', response.content)

    def test_qr_downloads(self):
        """Test downloading Business QR code PNG and printable PDF standee."""
        qr = self.biz.qr_code
        self.assertIsNotNone(qr)

        # PNG download
        png_resp = self.client.get(reverse('qr_download_png', kwargs={'qr_uuid': qr.uuid}))
        self.assertEqual(png_resp.status_code, 200)
        self.assertEqual(png_resp['Content-Type'], 'image/png')

        # PDF standee download
        pdf_resp = self.client.get(reverse('qr_download_pdf', kwargs={'qr_uuid': qr.uuid}))
        self.assertEqual(pdf_resp.status_code, 200)
        self.assertEqual(pdf_resp['Content-Type'], 'application/pdf')
        self.assertIn(b'%PDF', pdf_resp.content[:10])


class BusinessAPITests(TestCase):
    """Test suite for Business Profile REST API endpoints."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='apiuser@example.com',
            email='apiuser@example.com',
            password='TestPassword@123'
        )
        self.client.force_authenticate(user=self.user)
        self.biz = Business.objects.create(
            owner=self.user,
            name='Apex Design Studio',
            tagline='Creative Architecture & Interiors',
            category='real_estate',
            phone='+91 99000 11223',
            city='Chandigarh',
            is_active=True
        )
        generate_or_update_business_qr(self.biz)

    def test_api_business_list(self):
        """GET /api/business/ lists authenticated user's business profiles."""
        url = reverse('api_business_list_create')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Handle paginated response
        results = response.data.get('results', response.data)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['name'], 'Apex Design Studio')

    def test_api_business_create(self):
        """POST /api/business/ creates a new business profile."""
        url = reverse('api_business_list_create')
        payload = {
            'name': 'Lumina Lighting Lab',
            'category': 'retail',
            'tagline': 'Smart lighting solutions',
            'phone': '+91 99111 22334',
            'city': 'Jaipur',
            'is_active': True,
        }
        response = self.client.post(url, payload)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['name'], 'Lumina Lighting Lab')
        self.assertEqual(response.data['category'], 'retail')
        self.assertTrue(Business.objects.filter(name='Lumina Lighting Lab').exists())

    def test_api_business_public_detail(self):
        """GET /api/business/public/<slug>/ returns public profile for mobile scanner."""
        self.client.logout()  # Unauthenticated public request
        url = reverse('api_business_public', kwargs={'slug': self.biz.slug})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Apex Design Studio')
        self.assertIn('services', response.data)

    def test_api_service_list_and_create(self):
        """GET and POST for products/services catalog via REST API."""
        url = reverse('api_service_list_create', kwargs={'business_pk': self.biz.pk})

        # Add a service
        post_resp = self.client.post(url, {
            'name': 'Interior Space Consultation',
            'description': '2-hour onsite assessment with 3D moodboard.',
            'price': '4999.00',
            'price_type': 'fixed',
            'order': 1,
            'is_available': True,
        })
        self.assertEqual(post_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(post_resp.data['name'], 'Interior Space Consultation')

        # List services
        get_resp = self.client.get(url)
        self.assertEqual(get_resp.status_code, status.HTTP_200_OK)
        results = get_resp.data.get('results', get_resp.data)
        self.assertEqual(len(results), 1)
