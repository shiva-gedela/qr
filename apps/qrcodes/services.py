"""
apps/qrcodes/services.py

Core QR generation engine & PDF invitation card generator.
Uses:
 - python-qrcode + Pillow (RGBA manipulation, high error correction, custom logo embedding)
 - ReportLab (printable vector-styled invitation cards with custom QR insertion)
"""

import io
import os
from PIL import Image, ImageDraw, ImageOps
import qrcode
from qrcode.constants import ERROR_CORRECT_H

from django.core.files.base import ContentFile
from django.conf import settings
from django.urls import reverse

from reportlab.lib.pagesizes import letter, A4
from reportlab.lib import colors
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader


def create_qr_image_buffer(target_url, fill_color='#000000', back_color='#FFFFFF', logo_file=None, box_size=12, border=4):
    """
    Generate a PIL-based QR code image in memory and return a BytesIO buffer.
    
    Uses ERROR_CORRECT_H (High, ~30% recovery) to guarantee seamless scanning
    even when a custom logo or badge is placed at the center.
    """
    qr = qrcode.QRCode(
        version=None,
        error_correction=ERROR_CORRECT_H,
        box_size=box_size,
        border=border,
    )
    qr.add_data(target_url)
    qr.make(fit=True)

    # Base QR image with colors
    qr_img = qr.make_image(fill_color=fill_color, back_color=back_color).convert('RGBA')
    qr_width, qr_height = qr_img.size

    # Embed center logo if provided
    if logo_file:
        try:
            # Handle Django FieldFile, UploadedFile, or file path
            if hasattr(logo_file, 'file'):
                logo_file.seek(0)
                logo_src = Image.open(logo_file)
            elif isinstance(logo_file, str):
                logo_src = Image.open(logo_file)
            else:
                logo_file.seek(0)
                logo_src = Image.open(logo_file)

            logo = logo_src.convert('RGBA')

            # Calculate safe size (max 22% of QR dimensions to protect error correction)
            max_size = int(qr_width * 0.22)
            logo.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
            lw, lh = logo.size

            # Create circular/rounded white background plate for contrast
            padding = 10
            plate_size = (lw + padding * 2, lh + padding * 2)
            plate = Image.new('RGBA', plate_size, (255, 255, 255, 255))

            # Draw smooth rounded border around the plate
            draw = ImageDraw.Draw(plate)
            draw.rounded_rectangle([(0, 0), (plate_size[0] - 1, plate_size[1] - 1)], radius=12, outline=fill_color, width=2)

            # Paste the logo into the center of the plate
            plate.paste(logo, (padding, padding), mask=logo)

            # Paste plate onto QR code center
            pos_x = (qr_width - plate_size[0]) // 2
            pos_y = (qr_height - plate_size[1]) // 2
            qr_img.paste(plate, (pos_x, pos_y), mask=plate)
        except Exception as e:
            # Fallback gracefully to standard QR if logo has issues
            pass

    buf = io.BytesIO()
    qr_img.save(buf, format='PNG', quality=95)
    buf.seek(0)
    return buf


def generate_or_update_event_qr(event, fill_color=None, back_color=None, logo_file=None, base_url=None):
    """
    Get or create QRCode model instance for an Event and refresh its image.
    Ensures QR code points to the permanent event public URL.
    """
    from .models import QRCode

    if not base_url:
        base_url = getattr(settings, 'SITE_URL', 'http://127.0.0.1:8000').rstrip('/')

    target_url = f"{base_url}/events/e/{event.slug}/"

    qr, created = QRCode.objects.get_or_create(
        event=event,
        defaults={
            'qr_type': 'event',
            'target_url': target_url,
            'fill_color': fill_color or '#000000',
            'back_color': back_color or '#FFFFFF',
        }
    )

    # Apply updates if provided
    updated = False
    if fill_color and qr.fill_color != fill_color:
        qr.fill_color = fill_color
        updated = True
    if back_color and qr.back_color != back_color:
        qr.back_color = back_color
        updated = True
    if qr.target_url != target_url:
        qr.target_url = target_url
        updated = True
    if logo_file:
        qr.logo = logo_file
        updated = True

    # Generate image buffer
    effective_logo = logo_file or (qr.logo if qr.logo else None)
    buf = create_qr_image_buffer(
        target_url=target_url,
        fill_color=qr.fill_color,
        back_color=qr.back_color,
        logo_file=effective_logo,
    )

    filename = f"qr_{event.slug}.png"
    qr.qr_image.save(filename, ContentFile(buf.getvalue()), save=False)
    qr.save()
    return qr


def generate_event_qr_pdf(qr_instance):
    """
    Generate an elegant printable invitation card PDF featuring the custom QR code.
    Designed for print (A4 / Portrait), events invitations, or table cards.
    """
    event = qr_instance.event
    buf = io.BytesIO()

    # Setup canvas (A4 size: 595.27 x 841.89 points)
    c = canvas.Canvas(buf, pagesize=A4)
    page_w, page_h = A4

    # Theme colors based on event type or fill color
    primary_color = colors.HexColor(qr_instance.fill_color) if qr_instance.fill_color != '#000000' else colors.HexColor('#6c3483')
    gold_color = colors.HexColor('#d4ac0d')
    dark_gray = colors.HexColor('#2c3e50')
    light_bg = colors.HexColor('#fcfaf7')

    # Draw full page light background
    c.setFillColor(light_bg)
    c.rect(0, 0, page_w, page_h, fill=1, stroke=0)

    # Double decorative border
    c.setStrokeColor(primary_color)
    c.setLineWidth(3)
    c.rect(25, 25, page_w - 50, page_h - 50)

    c.setStrokeColor(gold_color)
    c.setLineWidth(1)
    c.rect(32, 32, page_w - 64, page_h - 64)

    # Header Banner
    banner_height = 110
    c.setFillColor(primary_color)
    c.rect(32, page_h - 32 - banner_height, page_w - 64, banner_height, fill=1, stroke=0)

    # Header Texts
    c.setFillColor(gold_color)
    c.setFont("Helvetica-Bold", 14)
    event_type_str = f"★ {event.get_event_type_display().upper()} INVITATION ★" if event else "★ SPECIAL INVITATION ★"
    c.drawCentredString(page_w / 2, page_h - 65, event_type_str)

    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 24)
    title = event.title if event else "You are Cordially Invited"
    # Truncate if overly long
    if len(title) > 42:
        title = title[:40] + "..."
    c.drawCentredString(page_w / 2, page_h - 100, title)

    c.setFillColor(colors.HexColor('#f1f1f1'))
    c.setFont("Helvetica-Oblique", 13)
    hosts_text = f"Hosted by {event.host_names}" if (event and event.host_names) else ""
    c.drawCentredString(page_w / 2, page_h - 124, hosts_text)

    # Decorative separator
    c.setStrokeColor(gold_color)
    c.setLineWidth(1.5)
    c.line(page_w / 2 - 120, page_h - 155, page_w / 2 + 120, page_h - 155)

    # Date, Time & Venue Block
    current_y = page_h - 185
    c.setFillColor(dark_gray)
    c.setFont("Helvetica-Bold", 16)
    if event and event.event_date:
        date_str = event.event_date.strftime("%A, %d %B %Y")
        c.drawCentredString(page_w / 2, current_y, f"Date: {date_str}")
        current_y -= 22

    if event and event.event_time:
        c.setFont("Helvetica", 14)
        time_str = event.event_time.strftime("%I:%M %p")
        c.drawCentredString(page_w / 2, current_y, f"Time: {time_str}")
        current_y -= 22

    if event and event.venue_name:
        c.setFont("Helvetica-Bold", 14)
        c.drawCentredString(page_w / 2, current_y, f"Venue: {event.venue_name}")
        current_y -= 18
        if event.venue_address:
            c.setFont("Helvetica", 11)
            c.setFillColor(colors.HexColor('#555555'))
            # Wrap address if needed
            addr = event.venue_address.replace('\n', ' ')
            if len(addr) > 65:
                addr = addr[:62] + '...'
            c.drawCentredString(page_w / 2, current_y, addr)
            current_y -= 25

    # Center QR Code box
    qr_box_size = 260
    qr_x = (page_w - qr_box_size) / 2
    qr_y = current_y - qr_box_size - 10

    # White card behind QR
    c.setFillColor(colors.white)
    c.setStrokeColor(colors.HexColor('#dddddd'))
    c.setLineWidth(1)
    c.roundRect(qr_x - 15, qr_y - 15, qr_box_size + 30, qr_box_size + 30, 16, fill=1, stroke=1)

    # Draw QR code image
    if qr_instance.qr_image:
        try:
            qr_path = qr_instance.qr_image.path
            img_reader = ImageReader(qr_path)
            c.drawImage(img_reader, qr_x, qr_y, width=qr_box_size, height=qr_box_size, preserveAspectRatio=True)
        except Exception:
            # Re-generate into memory if file is not on disk yet
            mem_buf = create_qr_image_buffer(
                target_url=qr_instance.target_url,
                fill_color=qr_instance.fill_color,
                back_color=qr_instance.back_color,
                logo_file=qr_instance.logo if qr_instance.logo else None,
            )
            img_reader = ImageReader(mem_buf)
            c.drawImage(img_reader, qr_x, qr_y, width=qr_box_size, height=qr_box_size, preserveAspectRatio=True)

    # Scan Call to Action
    c.setFillColor(primary_color)
    c.setFont("Helvetica-Bold", 15)
    c.drawCentredString(page_w / 2, qr_y - 36, "Scan with your Smartphone Camera")

    c.setFillColor(colors.HexColor('#666666'))
    c.setFont("Helvetica", 11)
    c.drawCentredString(page_w / 2, qr_y - 54, "Access event invitation, Google Maps GPS navigation, gallery & social pages")

    if event and event.event_hashtag:
        c.setFillColor(colors.HexColor('#d97706'))
        c.setFont("Helvetica-Bold", 11)
        c.drawCentredString(page_w / 2, qr_y - 70, f"Share your moments: {event.event_hashtag}")

    # Direct URL
    c.setFillColor(colors.HexColor('#0d6efd'))
    c.setFont("Helvetica-Bold", 11)
    c.drawCentredString(page_w / 2, qr_y - 88, qr_instance.target_url)

    # Footer note
    c.setFillColor(colors.HexColor('#888888'))
    c.setFont("Helvetica", 9)
    c.drawCentredString(page_w / 2, 45, "Created with EventConnect QR • Beautiful Digital Invitations")

    c.showPage()
    c.save()
    buf.seek(0)
    return buf


def generate_or_update_business_qr(business, fill_color=None, back_color=None, logo_file=None, base_url=None):
    """
    Get or create QRCode model instance for a Business Profile and refresh its image.
    Ensures QR code points to the permanent business public profile URL.
    """
    from .models import QRCode

    if not base_url:
        base_url = getattr(settings, 'SITE_URL', 'http://127.0.0.1:8000').rstrip('/')

    target_url = f"{base_url}/b/{business.slug}/"

    qr, created = QRCode.objects.get_or_create(
        business=business,
        defaults={
            'qr_type': 'business',
            'target_url': target_url,
            'fill_color': fill_color or '#1a365d',
            'back_color': back_color or '#FFFFFF',
        }
    )

    if fill_color and qr.fill_color != fill_color:
        qr.fill_color = fill_color
    if back_color and qr.back_color != back_color:
        qr.back_color = back_color
    if qr.target_url != target_url:
        qr.target_url = target_url
    if logo_file:
        qr.logo = logo_file

    effective_logo = logo_file or (qr.logo if qr.logo else None) or (business.logo if business.logo else None)
    buf = create_qr_image_buffer(
        target_url=target_url,
        fill_color=qr.fill_color,
        back_color=qr.back_color,
        logo_file=effective_logo,
    )

    filename = f"qr_biz_{business.slug}.png"
    qr.qr_image.save(filename, ContentFile(buf.getvalue()), save=False)
    qr.save()
    return qr


def generate_business_qr_pdf(qr_instance):
    """
    Generate an elegant printable tabletop display card / standee PDF for a Business.
    Suitable for retail checkout counters, dining tables, desks, and storefronts.
    """
    business = qr_instance.business
    buf = io.BytesIO()

    c = canvas.Canvas(buf, pagesize=A4)
    page_w, page_h = A4

    brand_color = colors.HexColor(qr_instance.fill_color) if qr_instance.fill_color != '#000000' else colors.HexColor('#1a365d')
    accent_color = colors.HexColor('#d4ac0d')
    dark_gray = colors.HexColor('#2d3748')
    light_bg = colors.HexColor('#f8fafc')

    # Background
    c.setFillColor(light_bg)
    c.rect(0, 0, page_w, page_h, fill=1, stroke=0)

    # Frame
    c.setStrokeColor(brand_color)
    c.setLineWidth(3)
    c.rect(25, 25, page_w - 50, page_h - 50)

    # Header Card
    header_h = 130
    c.setFillColor(brand_color)
    c.rect(25, page_h - 25 - header_h, page_w - 50, header_h, fill=1, stroke=0)

    # Business Name & Tagline
    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 24)
    name_str = business.name if business else "Our Digital Profile"
    if len(name_str) > 35:
        name_str = name_str[:32] + "..."
    c.drawCentredString(page_w / 2, page_h - 75, name_str)

    c.setFillColor(accent_color)
    c.setFont("Helvetica-Bold", 12)
    cat_str = business.get_category_display().upper() if business else "BUSINESS PROFILE"
    c.drawCentredString(page_w / 2, page_h - 100, f"★  {cat_str}  ★")

    if business and business.tagline:
        c.setFillColor(colors.HexColor('#e2e8f0'))
        c.setFont("Helvetica-Oblique", 11)
        tag_str = business.tagline[:55]
        c.drawCentredString(page_w / 2, page_h - 122, tag_str)

    # Centered QR Box
    qr_box_size = 270
    qr_x = (page_w - qr_box_size) / 2
    qr_y = page_h - header_h - 35 - qr_box_size

    # White card frame
    c.setFillColor(colors.white)
    c.setStrokeColor(colors.HexColor('#cbd5e1'))
    c.setLineWidth(1.5)
    c.roundRect(qr_x - 15, qr_y - 15, qr_box_size + 30, qr_box_size + 30, 16, fill=1, stroke=1)

    # Draw QR
    if qr_instance.qr_image:
        try:
            img_reader = ImageReader(qr_instance.qr_image.path)
            c.drawImage(img_reader, qr_x, qr_y, width=qr_box_size, height=qr_box_size, preserveAspectRatio=True)
        except Exception:
            mem_buf = create_qr_image_buffer(
                target_url=qr_instance.target_url,
                fill_color=qr_instance.fill_color,
                back_color=qr_instance.back_color,
                logo_file=qr_instance.logo or (business.logo if business else None),
            )
            img_reader = ImageReader(mem_buf)
            c.drawImage(img_reader, qr_x, qr_y, width=qr_box_size, height=qr_box_size, preserveAspectRatio=True)

    # Call to action
    c.setFillColor(brand_color)
    c.setFont("Helvetica-Bold", 16)
    c.drawCentredString(page_w / 2, qr_y - 42, "Scan to Connect & View Our Catalog")

    c.setFillColor(dark_gray)
    c.setFont("Helvetica", 11)
    c.drawCentredString(page_w / 2, qr_y - 62, "Call, WhatsApp, Get Directions, and Browse Products & Services")

    # Contact Details Section
    cur_y = qr_y - 100
    c.setFillColor(colors.HexColor('#f1f5f9'))
    c.setStrokeColor(colors.HexColor('#e2e8f0'))
    c.roundRect(45, cur_y - 50, page_w - 90, 75, 10, fill=1, stroke=1)

    c.setFillColor(dark_gray)
    c.setFont("Helvetica-Bold", 12)
    contact_parts = []
    if business and business.phone:
        contact_parts.append(f"Phone: {business.phone}")
    if business and business.whatsapp:
        contact_parts.append(f"WhatsApp: {business.whatsapp}")
    if contact_parts:
        c.drawCentredString(page_w / 2, cur_y + 5, "  •  ".join(contact_parts))

    c.setFont("Helvetica", 10)
    c.setFillColor(colors.HexColor('#475569'))
    addr_line = business.full_address if (business and business.full_address) else ""
    if len(addr_line) > 75:
        addr_line = addr_line[:72] + "..."
    if addr_line:
        c.drawCentredString(page_w / 2, cur_y - 14, addr_line)

    c.setFillColor(colors.HexColor('#2563eb'))
    c.setFont("Helvetica-Bold", 11)
    c.drawCentredString(page_w / 2, cur_y - 34, qr_instance.target_url)

    # Footer
    c.setFillColor(colors.HexColor('#94a3b8'))
    c.setFont("Helvetica", 9)
    c.drawCentredString(page_w / 2, 45, "Powered by EventConnect QR Digital Business Profiles")

    c.showPage()
    c.save()
    buf.seek(0)
    return buf
