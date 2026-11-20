"""
apps/core/tests.py

Automated test suite for Core website functionality:
- Homepage rendering, navbar, and SEO metadata
- City landing pages (Hyderabad, Bengaluru, Mumbai, Delhi, etc.)
- Robots.txt search engine directives and privacy disallows
- Sitemap.xml dynamic indexing
- Android App Links (assetlinks.json) & Apple Universal Links
"""

from django.test import TestCase, Client
from django.urls import reverse


class CoreWebTests(TestCase):
    def setUp(self):
        self.client = Client()

    def test_homepage_renders_200(self):
        resp = self.client.get(reverse('home'))
        self.assertEqual(resp.status_code, 200)
        self.assertContains(resp, 'QRouteX')
        self.assertContains(resp, 'canonical')
        self.assertContains(resp, 'schema.org')

    def test_city_landing_page_hyderabad(self):
        resp = self.client.get(reverse('city_landing', kwargs={'city_slug': 'hyderabad'}))
        self.assertEqual(resp.status_code, 200)
        self.assertContains(resp, 'Hyderabad')
        self.assertContains(resp, 'Telangana')

    def test_city_landing_page_bengaluru(self):
        resp = self.client.get(reverse('city_landing', kwargs={'city_slug': 'bengaluru'}))
        self.assertEqual(resp.status_code, 200)
        self.assertContains(resp, 'Bengaluru')

    def test_robots_txt(self):
        resp = self.client.get(reverse('robots_txt'))
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp['Content-Type'], 'text/plain; charset=utf-8')
        self.assertIn(b'User-agent: *', resp.content)
        self.assertIn(b'Disallow: /admin/', resp.content)
        self.assertIn(b'Disallow: /api/', resp.content)
        self.assertIn(b'Sitemap:', resp.content)

    def test_sitemap_xml(self):
        resp = self.client.get(reverse('django.contrib.sitemaps.views.sitemap'))
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp['Content-Type'], 'application/xml')
        self.assertIn(b'<urlset', resp.content)
        self.assertIn(b'<loc>', resp.content)

    def test_assetlinks_json(self):
        resp = self.client.get(reverse('assetlinks_json'))
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp['Content-Type'], 'application/json')
        data = resp.json()
        self.assertTrue(isinstance(data, list))
        self.assertEqual(data[0]['target']['package_name'], 'com.qroutex.app')

    def test_apple_app_site_association(self):
        resp = self.client.get(reverse('apple_app_site_association'))
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp['Content-Type'], 'application/json')
        data = resp.json()
        self.assertIn('applinks', data)
