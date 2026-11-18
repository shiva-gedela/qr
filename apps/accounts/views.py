"""
apps/accounts/views.py

Authentication views: register, login, logout, email verification,
password reset, profile update and user dashboard.
"""

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout, update_session_auth_hash
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from django.db.models import Count
import uuid

from .models import User
from .forms import RegisterForm, LoginForm, ProfileUpdateForm, PasswordResetRequestForm, SetNewPasswordForm
from apps.events.models import Event


def register_view(request):
    """Handle new user registration and send verification email."""
    if request.user.is_authenticated:
        return redirect('dashboard')

    if request.method == 'POST':
        form = RegisterForm(request.POST)
        if form.is_valid():
            user = form.save()
            _send_verification_email(request, user)
            messages.success(
                request,
                f"Welcome {user.first_name}! Check your email to verify your account."
                " You can also log in and verify later."
            )
            # Auto-login after registration
            login(request, user, backend='django.contrib.auth.backends.ModelBackend')
            return redirect('dashboard')
    else:
        form = RegisterForm()

    return render(request, 'accounts/register.html', {'form': form})


def login_view(request):
    """Handle user login with email/password."""
    if request.user.is_authenticated:
        return redirect('dashboard')

    if request.method == 'POST':
        form = LoginForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            remember = form.cleaned_data.get('remember_me')
            if not remember:
                request.session.set_expiry(0)   # Session expires on browser close
            login(request, user)
            messages.success(request, f"Welcome back, {user.first_name}!")
            next_url = request.GET.get('next', 'dashboard')
            return redirect(next_url)
        else:
            messages.error(request, "Invalid email or password. Please try again.")
    else:
        form = LoginForm()

    return render(request, 'accounts/login.html', {'form': form})


def logout_view(request):
    """Log out the current user."""
    if request.method == 'POST':
        logout(request)
        messages.info(request, "You have been logged out.")
    return redirect('home')


@login_required
def dashboard_view(request):
    """Main user dashboard showing stats and recent activity."""
    user = request.user
    events = Event.objects.filter(owner=user).order_by('-created_at')
    published_events = events.filter(is_published=True).count()
    draft_events = events.filter(is_published=False).count()
    recent_events = events[:5]

    try:
        from apps.business.models import Business
        businesses = Business.objects.filter(owner=user).order_by('-created_at')
        total_businesses = businesses.count()
        recent_businesses = businesses[:3]
    except Exception:
        businesses = []
        total_businesses = 0
        recent_businesses = []

    context = {
        'user': user,
        'events': events,
        'published_events': published_events,
        'draft_events': draft_events,
        'recent_events': recent_events,
        'total_events': events.count(),
        'total_businesses': total_businesses,
        'recent_businesses': recent_businesses,
    }
    return render(request, 'accounts/dashboard.html', context)


@login_required
def profile_view(request):
    """View and update the user's profile."""
    if request.method == 'POST':
        form = ProfileUpdateForm(request.POST, request.FILES, instance=request.user)
        if form.is_valid():
            form.save()
            messages.success(request, "Profile updated successfully!")
            return redirect('profile')
    else:
        form = ProfileUpdateForm(instance=request.user)

    return render(request, 'accounts/profile.html', {'form': form})


def verify_email(request, token):
    """Verify a user's email via the token link sent by email."""
    user = get_object_or_404(User, email_verification_token=token)
    if user.email_verified:
        messages.info(request, "Email already verified.")
    else:
        user.email_verified = True
        user.save(update_fields=['email_verified'])
        messages.success(request, "Email verified successfully! Your account is now fully active.")
    return redirect('dashboard')


@login_required
def resend_verification(request):
    """Resend the email verification link."""
    user = request.user
    if user.email_verified:
        messages.info(request, "Your email is already verified.")
    else:
        _send_verification_email(request, user)
        messages.success(request, f"Verification email sent to {user.email}.")
    return redirect('dashboard')


def password_reset_request(request):
    """Request a password reset - sends email with reset link."""
    if request.method == 'POST':
        form = PasswordResetRequestForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email'].lower()
            try:
                user = User.objects.get(email=email)
                # Regenerate token for security
                user.email_verification_token = uuid.uuid4()
                user.save(update_fields=['email_verification_token'])
                _send_password_reset_email(request, user)
            except User.DoesNotExist:
                pass   # Don't reveal whether email exists
            messages.success(
                request,
                "If that email is registered, you will receive a reset link shortly."
            )
            return redirect('login')
    else:
        form = PasswordResetRequestForm()

    return render(request, 'accounts/password_reset_request.html', {'form': form})


def password_reset_confirm(request, token):
    """Confirm and set a new password via the reset token."""
    user = get_object_or_404(User, email_verification_token=token)

    if request.method == 'POST':
        form = SetNewPasswordForm(request.POST)
        if form.is_valid():
            user.set_password(form.cleaned_data['password1'])
            user.email_verification_token = uuid.uuid4()   # Invalidate token after use
            user.email_verified = True
            user.save()
            messages.success(request, "Password reset successful. Please log in with your new password.")
            return redirect('login')
    else:
        form = SetNewPasswordForm()

    return render(request, 'accounts/password_reset_confirm.html', {'form': form, 'token': token})


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _send_verification_email(request, user):
    """Send email verification link to the user."""
    verify_url = request.build_absolute_uri(
        f"/accounts/verify-email/{user.email_verification_token}/"
    )
    send_mail(
        subject="Verify your QRouteX email",
        message=(
            f"Hi {user.first_name},\n\n"
            f"Please verify your email by clicking the link below:\n{verify_url}\n\n"
            "If you did not register, ignore this email.\n\nQRouteX Team • https://qroutex.com"
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=True,
    )


def _send_password_reset_email(request, user):
    """Send password reset link to the user."""
    reset_url = request.build_absolute_uri(
        f"/accounts/password-reset-confirm/{user.email_verification_token}/"
    )
    send_mail(
        subject="Reset your QRouteX password",
        message=(
            f"Hi {user.first_name},\n\n"
            f"Click the link below to reset your password:\n{reset_url}\n\n"
            "This link expires when you use it.\n\nQRouteX Team • https://qroutex.com"
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=True,
    )
