"""
apps/accounts/api_views.py - REST API views for authentication.
Used by the Flutter mobile app.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import login, logout
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit
from rest_framework.authtoken.models import Token

from .serializers import UserSerializer, RegisterSerializer, LoginSerializer


class RegisterAPIView(APIView):
    """POST /api/auth/register/ - Register a new user."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token, _ = Token.objects.get_or_create(user=user)
            return Response(
                {
                    'message': 'Registration successful.',
                    'token': token.key,
                    'user': UserSerializer(user).data,
                },
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@method_decorator(ratelimit(key='ip', rate='10/m', method='POST', block=True), name='dispatch')
class LoginAPIView(APIView):
    """POST /api/auth/login/ - Login and start session."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            login(request, user, backend='django.contrib.auth.backends.ModelBackend')
            return Response(
                {
                    'message': 'Login successful.',
                    'token': Token.objects.get_or_create(user=user)[0].key,
                    'user': UserSerializer(user).data,
                },
                status=status.HTTP_200_OK
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogoutAPIView(APIView):
    """POST /api/auth/logout/ - End the current session."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        Token.objects.filter(user=request.user).delete()
        logout(request)
        return Response({'message': 'Logged out successfully.'}, status=status.HTTP_200_OK)


class ProfileAPIView(APIView):
    """GET/PATCH /api/auth/profile/ - Get or update profile."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
