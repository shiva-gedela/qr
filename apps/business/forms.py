"""
apps/business/forms.py

Crispy Forms for Digital Business Profile and Products & Services Catalog.
"""

from django import forms
from crispy_forms.helper import FormHelper
from crispy_forms.layout import Layout, Submit, Row, Column, Field, Fieldset, HTML
from .models import Business, BusinessService


class BusinessForm(forms.ModelForm):
    """Create / Update a Digital Business Profile."""

    class Meta:
        model = Business
        fields = [
            'name', 'category', 'tagline', 'description',
            'logo', 'cover_image',
            'phone', 'whatsapp', 'email', 'website',
            'instagram', 'facebook', 'twitter', 'linkedin', 'youtube',
            'address', 'city', 'state', 'pincode', 'maps_url',
            'working_hours', 'is_active',
        ]
        widgets = {
            'description': forms.Textarea(attrs={'rows': 4, 'placeholder': 'Tell customers about your business, background, specialties...'}),
            'address': forms.Textarea(attrs={'rows': 2, 'placeholder': 'Street address, building, floor...'}),
            'working_hours': forms.Textarea(attrs={'rows': 3, 'placeholder': "Monday - Saturday: 9:00 AM - 8:00 PM\nSunday: Closed"}),
            'maps_url': forms.URLInput(attrs={'placeholder': 'https://maps.google.com/?q=...'}),
            'website': forms.URLInput(attrs={'placeholder': 'https://yourwebsite.com'}),
            'phone': forms.TextInput(attrs={'placeholder': '+91 98765 43210'}),
            'whatsapp': forms.TextInput(attrs={'placeholder': '+91 98765 43210'}),
            'email': forms.EmailInput(attrs={'placeholder': 'contact@yourbusiness.com'}),
            'instagram': forms.TextInput(attrs={'placeholder': 'https://instagram.com/yourhandle'}),
            'facebook': forms.URLInput(attrs={'placeholder': 'https://facebook.com/yourpage'}),
            'twitter': forms.TextInput(attrs={'placeholder': 'https://twitter.com/yourhandle'}),
            'linkedin': forms.URLInput(attrs={'placeholder': 'https://linkedin.com/company/yourbiz'}),
            'youtube': forms.URLInput(attrs={'placeholder': 'https://youtube.com/@yourchannel'}),
        }
        labels = {
            'name': 'Business Name',
            'tagline': 'Short Tagline / Slogan',
            'maps_url': 'Google Maps Directions URL',
            'working_hours': 'Operating Schedule & Hours',
            'is_active': 'Publish business profile publicly',
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.layout = Layout(
            Fieldset('Brand & Identity',
                Row(Column('name', css_class='col-md-6'), Column('category', css_class='col-md-6')),
                'tagline',
                'description',
                Row(Column('logo', css_class='col-md-6'), Column('cover_image', css_class='col-md-6')),
            ),
            Fieldset('Contact & Quick Actions',
                Row(Column('phone', css_class='col-md-6'), Column('whatsapp', css_class='col-md-6')),
                Row(Column('email', css_class='col-md-6'), Column('website', css_class='col-md-6')),
            ),
            Fieldset('Location & Directions',
                'address',
                Row(Column('city', css_class='col-md-4'), Column('state', css_class='col-md-4'), Column('pincode', css_class='col-md-4')),
                'maps_url',
            ),
            Fieldset('Working Hours & Social Links',
                'working_hours',
                Row(Column('instagram', css_class='col-md-4'), Column('facebook', css_class='col-md-4'), Column('twitter', css_class='col-md-4')),
                Row(Column('linkedin', css_class='col-md-6'), Column('youtube', css_class='col-md-6')),
                'is_active',
            ),
            Submit('submit', 'Save Business Profile', css_class='btn btn-primary btn-lg mt-3'),
        )


class BusinessServiceForm(forms.ModelForm):
    """Add / Edit a product or service offered by the business."""

    class Meta:
        model = BusinessService
        fields = ['name', 'description', 'price', 'price_type', 'image', 'order', 'is_available']
        widgets = {
            'name': forms.TextInput(attrs={'placeholder': 'e.g. Bridal Photography Package'}),
            'description': forms.Textarea(attrs={'rows': 3, 'placeholder': 'Describe what is included in this service or product...'}),
            'price': forms.NumberInput(attrs={'step': '0.01', 'placeholder': '9999.00'}),
        }
        labels = {
            'name': 'Product / Service Name',
            'is_available': 'Visible in Public Catalog',
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.layout = Layout(
            'name',
            'description',
            Row(Column('price', css_class='col-md-6'), Column('price_type', css_class='col-md-6')),
            Row(Column('image', css_class='col-md-8'), Column('order', css_class='col-md-4')),
            'is_available',
            Submit('submit', 'Save Item', css_class='btn btn-primary mt-2'),
        )
