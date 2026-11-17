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

from .models import Business, BusinessService
from .serializers import (
    BusinessListSerializer,
    BusinessDetailSerializer,
    BusinessPublicSerializer,
    BusinessServiceSerializer,
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
