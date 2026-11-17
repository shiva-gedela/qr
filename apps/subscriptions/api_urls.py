"""
apps/subscriptions/api_urls.py

DRF API routes for Subscriptions, Plans, and Razorpay Mobile Checkout.
"""

from django.urls import path
from . import api_views

urlpatterns = [
    path('plans/', api_views.SubscriptionPlanListAPIView.as_view(), name='api_subscription_plans'),
    path('current/', api_views.UserSubscriptionDetailAPIView.as_view(), name='api_subscription_current'),
    path('payments/', api_views.UserPaymentListAPIView.as_view(), name='api_subscription_payments'),
    path('create-order/', api_views.CreateRazorpayOrderAPIView.as_view(), name='api_create_razorpay_order'),
    path('verify-payment/', api_views.VerifyPaymentAPIView.as_view(), name='api_verify_payment'),
]
