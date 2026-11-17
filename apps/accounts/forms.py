"""
apps/accounts/forms.py

Registration, login, password change and profile update forms.
All forms use Bootstrap 5 styling via crispy-forms.
"""

from django import forms
from django.contrib.auth.forms import AuthenticationForm, PasswordChangeForm
from django.contrib.auth import password_validation
from crispy_forms.helper import FormHelper
from crispy_forms.layout import Layout, Submit, Row, Column, Field
from .models import User


class RegisterForm(forms.ModelForm):
    """User registration form with password confirmation."""

    first_name = forms.CharField(max_length=50, required=True,
                                 widget=forms.TextInput(attrs={'placeholder': 'First name'}))
    last_name = forms.CharField(max_length=50, required=True,
                                widget=forms.TextInput(attrs={'placeholder': 'Last name'}))
    email = forms.EmailField(required=True,
                             widget=forms.EmailInput(attrs={'placeholder': 'Email address'}))
    phone = forms.CharField(max_length=20, required=False,
                            widget=forms.TextInput(attrs={'placeholder': '+91 98765 43210'}))
    password1 = forms.CharField(label='Password', widget=forms.PasswordInput(attrs={'placeholder': 'Password'}))
    password2 = forms.CharField(label='Confirm Password',
                                widget=forms.PasswordInput(attrs={'placeholder': 'Repeat password'}))

    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email', 'phone']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.layout = Layout(
            Row(Column('first_name', css_class='col-md-6'), Column('last_name', css_class='col-md-6')),
            'email', 'phone', 'password1', 'password2',
            Submit('submit', 'Create Account', css_class='btn btn-primary w-100 mt-3'),
        )

    def clean_email(self):
        email = self.cleaned_data.get('email', '').lower()
        if User.objects.filter(email=email).exists():
            raise forms.ValidationError("An account with this email already exists.")
        return email

    def clean_password1(self):
        password = self.cleaned_data.get('password1')
        if password:
            password_validation.validate_password(password)
        return password

    def clean(self):
        cleaned_data = super().clean()
        p1 = cleaned_data.get('password1')
        p2 = cleaned_data.get('password2')
        if p1 and p2 and p1 != p2:
            self.add_error('password2', "Passwords do not match.")
        return cleaned_data

    def save(self, commit=True):
        user = super().save(commit=False)
        # Generate a unique username from email
        base = self.cleaned_data['email'].split('@')[0]
        username = base
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f"{base}{counter}"
            counter += 1
        user.username = username
        user.phone = self.cleaned_data.get('phone', '')
        user.set_password(self.cleaned_data['password1'])
        if commit:
            user.save()
        return user


class LoginForm(AuthenticationForm):
    """Login form using email as username."""

    username = forms.EmailField(
        label='Email Address',
        widget=forms.EmailInput(attrs={'placeholder': 'Email address', 'autofocus': True})
    )
    password = forms.CharField(
        label='Password',
        widget=forms.PasswordInput(attrs={'placeholder': 'Password'})
    )
    remember_me = forms.BooleanField(required=False, label='Remember me')

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.layout = Layout(
            'username', 'password', 'remember_me',
            Submit('submit', 'Sign In', css_class='btn btn-primary w-100 mt-3'),
        )


class ProfileUpdateForm(forms.ModelForm):
    """User profile update form."""

    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'phone', 'bio', 'avatar']
        widgets = {
            'bio': forms.Textarea(attrs={'rows': 4}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.layout = Layout(
            Row(Column('first_name', css_class='col-md-6'), Column('last_name', css_class='col-md-6')),
            'phone', 'bio', 'avatar',
            Submit('submit', 'Save Profile', css_class='btn btn-primary mt-3'),
        )


class PasswordResetRequestForm(forms.Form):
    """Request a password reset email."""

    email = forms.EmailField(label='Email Address',
                             widget=forms.EmailInput(attrs={'placeholder': 'Your registered email'}))

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.layout = Layout(
            'email',
            Submit('submit', 'Send Reset Link', css_class='btn btn-primary w-100 mt-3'),
        )


class SetNewPasswordForm(forms.Form):
    """Set a new password after reset."""

    password1 = forms.CharField(label='New Password', widget=forms.PasswordInput())
    password2 = forms.CharField(label='Confirm Password', widget=forms.PasswordInput())

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.layout = Layout(
            'password1', 'password2',
            Submit('submit', 'Set New Password', css_class='btn btn-primary w-100 mt-3'),
        )

    def clean(self):
        cleaned_data = super().clean()
        p1 = cleaned_data.get('password1')
        p2 = cleaned_data.get('password2')
        if p1 and p2 and p1 != p2:
            raise forms.ValidationError("Passwords do not match.")
        if p1:
            password_validation.validate_password(p1)
        return cleaned_data
