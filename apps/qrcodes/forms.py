"""
apps/qrcodes/forms.py

Form for customizing QR code appearance: fill color, background color, center logo.
"""

from django import forms
from .models import QRCode


class QRCodeCustomizeForm(forms.ModelForm):
    """Form allowing hosts to customize QR colors and center branding logo."""

    fill_color = forms.CharField(
        max_length=20,
        widget=forms.TextInput(attrs={'type': 'color', 'class': 'form-control form-control-color w-100', 'style': 'height:45px;'}),
        help_text="QR code pattern color"
    )
    back_color = forms.CharField(
        max_length=20,
        widget=forms.TextInput(attrs={'type': 'color', 'class': 'form-control form-control-color w-100', 'style': 'height:45px;'}),
        help_text="QR code background color"
    )
    logo = forms.ImageField(
        required=False,
        widget=forms.FileInput(attrs={'class': 'form-control', 'accept': 'image/png,image/jpeg,image/webp'}),
        help_text="Optional center logo or icon (PNG/JPEG recommended, under 2MB)"
    )

    class Meta:
        model = QRCode
        fields = ['fill_color', 'back_color', 'logo']

    def clean_logo(self):
        logo = self.cleaned_data.get('logo')
        if logo and hasattr(logo, 'size'):
            max_size = 3 * 1024 * 1024  # 3 MB
            if logo.size > max_size:
                raise forms.ValidationError("Logo file size must be under 3MB.")
        return logo
