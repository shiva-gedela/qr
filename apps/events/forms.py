"""
apps/events/forms.py

Event creation and editing forms with Bootstrap 5 crispy layout.
"""

from django import forms
from crispy_forms.helper import FormHelper
from crispy_forms.layout import Layout, Submit, Row, Column, Field, Fieldset, HTML
from .models import Event, EventMedia


class MultipleFileInput(forms.FileInput):
    """Custom FileInput widget that supports multiple file selection (Django 6+)."""
    allow_multiple_selected = True


class EventForm(forms.ModelForm):
    """Create / edit an event."""

    class Meta:
        model = Event
        fields = [
            'event_type', 'title', 'host_names', 'description',
            'event_date', 'event_time', 'event_end_date', 'event_end_time',
            'venue_name', 'venue_address', 'maps_url',
            'instagram_url', 'facebook_url', 'youtube_url', 'event_hashtag', 'dress_code',
            'cover_image', 'is_published', 'is_private', 'private_password',
            'allow_guest_uploads', 'require_media_approval',
        ]
        widgets = {
            'event_date': forms.DateInput(attrs={'type': 'date', 'class': 'form-control'}),
            'event_time': forms.TimeInput(attrs={'type': 'time', 'class': 'form-control'}),
            'event_end_date': forms.DateInput(attrs={'type': 'date', 'class': 'form-control'}),
            'event_end_time': forms.TimeInput(attrs={'type': 'time', 'class': 'form-control'}),
            'description': forms.Textarea(attrs={'rows': 5}),
            'venue_address': forms.Textarea(attrs={'rows': 3}),
            'maps_url': forms.URLInput(attrs={'placeholder': 'https://maps.google.com/...'}),
            'instagram_url': forms.URLInput(attrs={'placeholder': 'https://instagram.com/...'}),
            'facebook_url': forms.URLInput(attrs={'placeholder': 'https://facebook.com/...'}),
            'youtube_url': forms.URLInput(attrs={'placeholder': 'https://youtube.com/live/... (Live Stream)'}),
            'event_hashtag': forms.TextInput(attrs={'placeholder': '#PriyaWedsRam'}),
            'dress_code': forms.TextInput(attrs={'placeholder': 'e.g. Traditional Indian / Black Tie'}),
        }
        labels = {
            'host_names': 'Host Name(s)',
            'maps_url': 'Google Maps URL (GPS)',
            'instagram_url': 'Instagram Page / Profile',
            'facebook_url': 'Facebook Event / Page',
            'youtube_url': 'YouTube Live Stream URL',
            'event_hashtag': 'Event Hashtag',
            'dress_code': 'Dress Code',
            'is_published': 'Publish this event',
            'is_private': 'Make event private (require password)',
            'allow_guest_uploads': 'Allow guests to upload photos & videos',
            'require_media_approval': 'Review & approve guest media before publishing',
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.form_tag = False
        self.helper.layout = Layout(
            Fieldset('Event Details',
                Row(Column('event_type', css_class='col-md-4'), Column('title', css_class='col-md-8')),
                'host_names',
                'description',
                Row(Column('dress_code', css_class='col-md-6'), Column('event_hashtag', css_class='col-md-6')),
            ),
            Fieldset('Date & Time',
                Row(Column('event_date', css_class='col-md-3'), Column('event_time', css_class='col-md-3'),
                    Column('event_end_date', css_class='col-md-3'), Column('event_end_time', css_class='col-md-3')),
            ),
            Fieldset('Venue & GPS Navigation',
                'venue_name',
                'venue_address',
                'maps_url',
            ),
            Fieldset('Social Pages & Live Stream',
                Row(Column('instagram_url', css_class='col-md-4'),
                    Column('facebook_url', css_class='col-md-4'),
                    Column('youtube_url', css_class='col-md-4')),
            ),
            Fieldset('Media & Settings',
                'cover_image',
                Row(Column('is_published', css_class='col-md-6'), Column('is_private', css_class='col-md-6')),
                'private_password',
                Row(Column('allow_guest_uploads', css_class='col-md-6'), Column('require_media_approval', css_class='col-md-6')),
            ),
            Submit('submit', 'Save Event', css_class='btn btn-primary btn-lg mt-3'),
        )

    def clean(self):
        cleaned = super().clean()
        is_private = cleaned.get('is_private')
        password = cleaned.get('private_password')
        if is_private and not password:
            self.add_error('private_password', "Please set a password for your private event.")
        return cleaned


class MediaUploadForm(forms.ModelForm):
    """Upload multiple photos/videos to an event gallery."""

    files = forms.FileField(
        widget=MultipleFileInput(attrs={'accept': 'image/*,video/*'}),
        label='Select Files',
    )

    class Meta:
        model = EventMedia
        fields = ['caption', 'category', 'is_public']
        labels = {'is_public': 'Make this media publicly visible'}

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.layout = Layout(
            Field('files'),
            Row(Column('category', css_class='col-md-6'), Column('is_public', css_class='col-md-6')),
            'caption',
            Submit('submit', 'Upload Files', css_class='btn btn-primary mt-3'),
        )


class GuestMediaUploadForm(forms.Form):
    """Guest photo/video upload from public invitation page."""

    files = forms.FileField(
        widget=MultipleFileInput(attrs={'accept': 'image/*,video/*', 'class': 'form-control'}),
        label='Select Photos or Videos',
    )
    uploader_name = forms.CharField(
        max_length=100,
        required=False,
        widget=forms.TextInput(attrs={'placeholder': 'Your Name (optional)', 'class': 'form-control'}),
        label='Your Name',
    )
    category = forms.ChoiceField(
        choices=EventMedia.GALLERY_CATEGORIES,
        initial='candid',
        widget=forms.Select(attrs={'class': 'form-select'}),
        label='Category',
    )
    caption = forms.CharField(
        max_length=300,
        required=False,
        widget=forms.TextInput(attrs={'placeholder': 'Add a wish or message...', 'class': 'form-control'}),
        label='Wishes / Caption',
    )


class MediaEditForm(forms.ModelForm):
    """Edit caption, category, public status, and approval of media."""

    class Meta:
        model = EventMedia
        fields = ['caption', 'category', 'is_public', 'is_approved']
        widgets = {
            'caption': forms.TextInput(attrs={'class': 'form-control'}),
            'category': forms.Select(attrs={'class': 'form-select'}),
        }
