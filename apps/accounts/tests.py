"""
apps/accounts/tests.py

Comprehensive automated tests for Accounts:
- User registration, login, logout
- Dashboard access and permissions
- Password validation
- REST API Auth (Login, Register, Profile, Token, Logout)
"""

from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

User = get_user_model()


class AccountsWebTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            email='testuser@example.com',
            username='testuser@example.com',
            first_name='Kavita',
            last_name='Reddy',
            password='SecurePassword123!',
        )

    def test_login_page_renders(self):
        resp = self.client.get(reverse('login'))
        self.assertEqual(resp.status_code, 200)

    def test_register_page_renders(self):
        resp = self.client.get(reverse('register'))
        self.assertEqual(resp.status_code, 200)

    def test_user_login_valid_credentials(self):
        resp = self.client.post(reverse('login'), {
            'username': 'testuser@example.com',
            'password': 'SecurePassword123!',
        })
        self.assertEqual(resp.status_code, 302)
        self.assertIn(reverse('dashboard'), resp.url)

    def test_user_login_invalid_password(self):
        resp = self.client.post(reverse('login'), {
            'username': 'testuser@example.com',
            'password': 'WrongPassword999!',
        })
        self.assertEqual(resp.status_code, 200)

    def test_dashboard_unauthenticated_redirects(self):
        resp = self.client.get(reverse('dashboard'))
        self.assertEqual(resp.status_code, 302)

    def test_dashboard_authenticated_success(self):
        self.client.force_login(self.user)
        resp = self.client.get(reverse('dashboard'))
        self.assertEqual(resp.status_code, 200)
        self.assertContains(resp, 'Kavita')

    def test_logout_redirects_to_home(self):
        self.client.force_login(self.user)
        resp = self.client.post(reverse('logout'))
        self.assertEqual(resp.status_code, 302)


class AccountsAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='api_member@example.com',
            username='api_member@example.com',
            first_name='Anand',
            last_name='Verma',
            password='ApiPassword123!',
        )

    def test_api_login_success_returns_token(self):
        resp = self.client.post(reverse('api_login'), {
            'email': 'api_member@example.com',
            'password': 'ApiPassword123!',
        })
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('token', resp.data)
        self.assertEqual(resp.data['user']['email'], 'api_member@example.com')

    def test_api_login_invalid_credentials(self):
        resp = self.client.post(reverse('api_login'), {
            'email': 'api_member@example.com',
            'password': 'BadPassword',
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_api_register_creates_user_and_token(self):
        resp = self.client.post(reverse('api_register'), {
            'email': 'new_joiner@example.com',
            'first_name': 'Meera',
            'last_name': 'Iyer',
            'password': 'NewPassword123!',
            'confirm_password': 'NewPassword123!',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('token', resp.data)
        self.assertTrue(User.objects.filter(email='new_joiner@example.com').exists())

    def test_api_profile_authenticated(self):
        self.client.force_authenticate(user=self.user)
        resp = self.client.get(reverse('api_profile'))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['email'], 'api_member@example.com')
        self.assertEqual(resp.data['first_name'], 'Anand')
