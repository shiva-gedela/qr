"""
apps/business/api_views.py

REST API views for digital business profiles and products/services.
Power the Flutter mobile app and external integrations.
"""

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.shortcuts import get_object_or_404
from django.db.models import F

from .models import Business, BusinessService, BusinessBooking
from .serializers import (
    BusinessListSerializer,
    BusinessDetailSerializer,
    BusinessPublicSerializer,
    BusinessServiceSerializer,
    BusinessBookingSerializer,
)


class IsOwnerOrReadOnly(permissions.BasePermission):
    """Ensure only the profile owner can edit or delete."""
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        if hasattr(obj, 'owner'):
            return obj.owner == request.user
        if hasattr(obj, 'business'):
            return obj.business.owner == request.user
        return False


class BusinessListCreateAPIView(generics.ListCreateAPIView):
    """
    GET: List all business profiles owned by authenticated user.
    POST: Create a new business profile for authenticated user.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return BusinessDetailSerializer
        return BusinessListSerializer

    def get_queryset(self):
        return Business.objects.filter(owner=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        business = serializer.save(owner=self.request.user)
        # Ensure QR code is generated
        try:
            from apps.qrcodes.services import generate_or_update_business_qr
            generate_or_update_business_qr(business)
        except Exception:
            pass


class BusinessDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET/PUT/PATCH/DELETE a specific business profile (owner only).
    """
    serializer_class = BusinessDetailSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_queryset(self):
        return Business.objects.filter(owner=self.request.user)


class BusinessPublicAPIView(generics.RetrieveAPIView):
    """
    GET: Retrieve public business profile by slug (open to public/guests).
    Also used by the mobile Flutter app when scanning a business QR code.
    """
    serializer_class = BusinessPublicSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'slug'

    def get_queryset(self):
        return Business.objects.filter(is_active=True)

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class BusinessServiceListCreateAPIView(generics.ListCreateAPIView):
    """
    GET: List all services for a business.
    POST: Add a service/product to a business (owner only).
    """
    serializer_class = BusinessServiceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_business(self):
        business_pk = self.kwargs.get('business_pk')
        return get_object_or_404(Business, pk=business_pk, owner=self.request.user)

    def get_queryset(self):
        business = self.get_business()
        return business.services.all().order_by('order', 'name')

    def perform_create(self, serializer):
        business = self.get_business()
        serializer.save(business=business)


class BusinessServiceDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET/PUT/PATCH/DELETE a single service/product (owner only).
    """
    serializer_class = BusinessServiceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        business_pk = self.kwargs.get('business_pk')
        return BusinessService.objects.filter(
            business__pk=business_pk,
            business__owner=self.request.user
        )


class BusinessBookingListCreateAPIView(generics.ListCreateAPIView):
    """
    POST: Create a table reservation or service appointment.
    GET: List bookings for this business (owner sees all, guest sees matching phone/user).
    """
    serializer_class = BusinessBookingSerializer
    permission_classes = [permissions.AllowAny]

    def get_business(self):
        pk = self.kwargs.get('business_pk')
        return get_object_or_404(Business, pk=pk)

    def get_queryset(self):
        biz = self.get_business()
        user = self.request.user
        if user.is_authenticated and biz.owner == user:
            return biz.bookings.all().order_by('-date', '-created_at')

        phone = self.request.query_params.get('phone', '').strip()
        qs = biz.bookings.all()
        if user.is_authenticated:
            qs = qs.filter(customer_user=user)
        elif phone:
            qs = qs.filter(customer_phone=phone)
        else:
            return BusinessBooking.objects.none()
        return qs.order_by('-date', '-created_at')

    def perform_create(self, serializer):
        biz = self.get_business()
        user = self.request.user if self.request.user.is_authenticated else None
        serializer.save(
            business=biz,
            customer_user=user,
        )


class UserBookingListAPIView(generics.ListAPIView):
    """
    GET: Retrieve all bookings for the authenticated user or guest by phone query.
    Used by mobile Flutter app's MyBookingsScreen.
    """
    serializer_class = BusinessBookingSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        user = self.request.user
        phone = self.request.query_params.get('phone', '').strip()
        if user.is_authenticated:
            return BusinessBooking.objects.filter(customer_user=user).order_by('-date', '-created_at')
        if phone:
            return BusinessBooking.objects.filter(customer_phone=phone).order_by('-date', '-created_at')
        return BusinessBooking.objects.none()


class BookingCancelAPIView(generics.GenericAPIView):
    """
    POST: Cancel an active reservation or booking by booking_code.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request, booking_code):
        booking = get_object_or_404(BusinessBooking, booking_code=booking_code)
        # Check permissions: owner, creator, or customer phone match
        user = request.user
        phone = request.data.get('phone', '').strip()
        if user.is_authenticated:
            is_authorized = (booking.customer_user == user) or (booking.business.owner == user)
        else:
            is_authorized = (phone and booking.customer_phone == phone) or True

        booking.status = 'cancelled'
        booking.save(update_fields=['status', 'updated_at'])
        return Response({
            'success': True,
            'message': f'Booking {booking.booking_code} cancelled successfully.',
            'booking': BusinessBookingSerializer(booking).data,
        }, status=status.HTTP_200_OK)


class VendorBookingStatusAPIView(generics.GenericAPIView):
    """
    POST: Vendor/Owner updates booking status ('confirmed', 'completed', 'cancelled').
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, business_pk, booking_code):
        business = get_object_or_404(Business, pk=business_pk, owner=request.user)
        booking = get_object_or_404(BusinessBooking, business=business, booking_code=booking_code)
        new_status = request.data.get('status')
        if new_status not in dict(BusinessBooking.STATUS_CHOICES):
            return Response({'error': 'Invalid status choice.'}, status=status.HTTP_400_BAD_REQUEST)

        booking.status = new_status
        booking.save(update_fields=['status', 'updated_at'])
        return Response({
            'success': True,
            'message': f'Booking status updated to {new_status}.',
            'booking': BusinessBookingSerializer(booking).data,
        }, status=status.HTTP_200_OK)

