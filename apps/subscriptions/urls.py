"""
apps/subscriptions/urls.py

Public and user-facing routes for Pricing, Checkout, Payments, and Invoices.
"""

from django.urls import path
from . import views

urlpatterns = [
    path('', views.pricing_view, name='pricing_root'),
    path('pricing/', views.pricing_view, name='pricing'),
    path('checkout/<str:plan_code>/', views.checkout_view, name='checkout'),
    path('payment/verify/', views.payment_verify_view, name='payment_verify'),
    path('payment/success/<str:invoice_number>/', views.payment_success_view, name='payment_success'),
    path('history/', views.payment_history_view, name='payment_history'),
    path('invoice/<str:invoice_number>/download/', views.download_invoice_view, name='download_invoice'),
]
