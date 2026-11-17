"""
apps/subscriptions/api_views.py

REST API endpoints for Subscriptions, Razorpay Orders & Verification.
Enables Flutter mobile application checkout and plan management.
"""

from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone

from .models import SubscriptionPlan, Subscription, Payment
from .serializers import (
    SubscriptionPlanSerializer,
    SubscriptionSerializer,
    PaymentSerializer,
)
from .services import (
    seed_default_plans,
    create_razorpay_order,
    verify_and_activate_payment,
)


class SubscriptionPlanListAPIView(generics.ListAPIView):
    """
    GET /api/subscriptions/plans/
    List all active subscription plans (accessible to all users and Flutter app).
    """
    serializer_class = SubscriptionPlanSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = SubscriptionPlan.objects.filter(is_active=True).order_by('order', 'price')
        if not qs.exists():
            seed_default_plans()
            qs = SubscriptionPlan.objects.filter(is_active=True).order_by('order', 'price')
        return qs


class UserSubscriptionDetailAPIView(APIView):
    """
    GET /api/subscriptions/current/
    Get authenticated user's current active subscription.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        sub = Subscription.objects.filter(user=request.user, status='active').order_by('-created_at').first()
        if not sub:
            # Fallback to free plan
            free_plan = SubscriptionPlan.objects.filter(code='free').first()
            if not free_plan:
                seed_default_plans()
                free_plan = SubscriptionPlan.objects.filter(code='free').first()
            if free_plan:
                sub = Subscription.objects.create(
                    user=request.user,
                    plan=free_plan,
                    status='active',
                    start_date=timezone.now(),
                    end_date=None
                )
        serializer = SubscriptionSerializer(sub)
        return Response(serializer.data)


class UserPaymentListAPIView(generics.ListAPIView):
    """
    GET /api/subscriptions/payments/
    List transaction history for authenticated user.
    """
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Payment.objects.filter(user=self.request.user).order_by('-created_at')


class CreateRazorpayOrderAPIView(APIView):
    """
    POST /api/subscriptions/create-order/
    Body: {"plan_code": "premium_event"}
    Creates a Razorpay order and returns order_id, amount in paise, currency, key_id.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        plan_code = request.data.get('plan_code')
        if not plan_code:
            return Response({'error': 'plan_code is required.'}, status=status.HTTP_400_BAD_REQUEST)

        plan = get_object_or_404(SubscriptionPlan, code=plan_code, is_active=True)

        if plan.is_free:
            # Free plan doesn't require Razorpay
            Subscription.objects.filter(user=request.user, status='active').update(status='expired')
            sub = Subscription.objects.create(
                user=request.user,
                plan=plan,
                status='active',
                start_date=timezone.now(),
                end_date=None
            )
            return Response({
                'is_free': True,
                'message': f'Activated {plan.name} successfully.',
                'subscription': SubscriptionSerializer(sub).data
            })

        order_data = create_razorpay_order(request.user, plan)
        return Response({
            'is_free': False,
            'order_id': order_data['order_id'],
            'amount': order_data['amount'],
            'amount_display': str(order_data['amount_display']),
            'currency': order_data['currency'],
            'key_id': order_data['key_id'],
            'invoice_number': order_data['invoice_number'],
            'plan_name': order_data['plan_name'],
        })


class VerifyPaymentAPIView(APIView):
    """
    POST /api/subscriptions/verify-payment/
    Body: {
      "razorpay_order_id": "...",
      "razorpay_payment_id": "...",
      "razorpay_signature": "..."
    }
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        order_id = request.data.get('razorpay_order_id')
        payment_id = request.data.get('razorpay_payment_id', '')
        signature = request.data.get('razorpay_signature', '')

        if not order_id:
            return Response({'error': 'razorpay_order_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

        client_ip = request.META.get('REMOTE_ADDR', '')
        success, message, payment = verify_and_activate_payment(
            user=request.user,
            razorpay_order_id=order_id,
            razorpay_payment_id=payment_id,
            razorpay_signature=signature,
            ip_address=client_ip
        )

        if success:
            return Response({
                'success': True,
                'message': message,
                'invoice_number': payment.invoice_number,
                'plan_name': payment.plan.name,
                'amount': str(payment.amount),
            })
        else:
            return Response({'success': False, 'error': message}, status=status.HTTP_400_BAD_REQUEST)
