"""
apps/core/management/commands/seed_data.py

Management command to seed the database with sample users, events and media.
Run with: python manage.py seed_data

Usage:
    python manage.py seed_data
    python manage.py seed_data --clear    (clears existing sample data first)
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import date, time, timedelta
import random

User = get_user_model()


class Command(BaseCommand):
    help = 'Seeds the database with sample data for testing EventConnect QR'

    def add_arguments(self, parser):
        parser.add_argument('--clear', action='store_true', help='Clear sample data first')

    def handle(self, *args, **options):
        from apps.events.models import Event

        if options['clear']:
            self.stdout.write('Clearing sample data...')
            User.objects.filter(email__endswith='@sample.eventconnect.com').delete()
            self.stdout.write(self.style.WARNING('Sample data cleared.'))

        self.stdout.write('Creating sample users...')

        # Create superadmin
        if not User.objects.filter(email='admin@eventconnect.com').exists():
            admin = User.objects.create_superuser(
                username='admin',
                email='admin@eventconnect.com',
                password='Admin@1234',
                first_name='Admin',
                last_name='User',
            )
            admin.email_verified = True
            admin.save()
            self.stdout.write(self.style.SUCCESS(f'  Created superuser: admin@eventconnect.com / Admin@1234'))

        # Create sample users
        sample_users = [
            {'first_name': 'Ravi', 'last_name': 'Kumar', 'email': 'ravi@sample.eventconnect.com'},
            {'first_name': 'Priya', 'last_name': 'Sharma', 'email': 'priya@sample.eventconnect.com'},
            {'first_name': 'Arjun', 'last_name': 'Nair', 'email': 'arjun@sample.eventconnect.com'},
        ]

        created_users = []
        for data in sample_users:
            if not User.objects.filter(email=data['email']).exists():
                u = User.objects.create_user(
                    username=data['email'].split('@')[0],
                    email=data['email'],
                    password='Test@1234',
                    first_name=data['first_name'],
                    last_name=data['last_name'],
                    email_verified=True,
                    phone='+91 98765 00' + str(random.randint(100, 999)),
                )
                created_users.append(u)
                self.stdout.write(self.style.SUCCESS(f"  Created user: {data['email']} / Test@1234"))
            else:
                created_users.append(User.objects.get(email=data['email']))

        # Create sample events
        self.stdout.write('Creating sample events...')

        sample_events = [
            {
                'owner': created_users[0],
                'event_type': 'wedding',
                'title': 'Ram & Priya Wedding',
                'host_names': 'Ram Kumar & Priya Sharma',
                'description': 'Join us for the most beautiful day of our lives as we celebrate our union in the presence of our loved ones. The ceremony will be followed by an elegant dinner reception.',
                'event_date': date.today() + timedelta(days=30),
                'event_time': time(11, 0),
                'venue_name': 'The Grand Palace Banquet Hall',
                'venue_address': '123 MG Road, Bangalore, Karnataka 560001',
                'maps_url': 'https://maps.google.com/?q=MG+Road+Bangalore',
                'is_published': True,
            },
            {
                'owner': created_users[1],
                'event_type': 'birthday',
                'title': "Aryan's 1st Birthday Celebration",
                'host_names': 'Mr. & Mrs. Sharma',
                'description': "Little Aryan turns 1! Come celebrate this magical milestone with us. Fun activities, cake cutting and lots of joy await!",
                'event_date': date.today() + timedelta(days=15),
                'event_time': time(16, 0),
                'venue_name': 'Sunshine Garden Resort',
                'venue_address': '45 Park Street, Chennai, Tamil Nadu 600001',
                'maps_url': 'https://maps.google.com/?q=Park+Street+Chennai',
                'is_published': True,
            },
            {
                'owner': created_users[2],
                'event_type': 'engagement',
                'title': 'Arjun & Meena Engagement',
                'host_names': 'Arjun Nair & Meena Pillai',
                'description': 'We are overjoyed to invite you to our engagement ceremony. Please join us as we take this beautiful step together.',
                'event_date': date.today() + timedelta(days=45),
                'event_time': time(18, 30),
                'venue_name': 'Coconut Grove Convention Center',
                'venue_address': '78 Marine Drive, Kochi, Kerala 682001',
                'maps_url': 'https://maps.google.com/?q=Marine+Drive+Kochi',
                'is_published': False,
            },
        ]

        for data in sample_events:
            owner = data.pop('owner')
            event = Event.objects.filter(title=data['title'], owner=owner).first()
            if not event:
                event = Event.objects.create(owner=owner, **data)
                self.stdout.write(self.style.SUCCESS(f"  Created event: {event.title} (slug: {event.slug})"))

            # Generate or customize QR Code for the event
            try:
                from apps.qrcodes.services import generate_or_update_event_qr
                color_map = {
                    'wedding': ('#6c3483', '#fdf8f0'),
                    'birthday': ('#922b21', '#fffdf9'),
                    'engagement': ('#0d6efd', '#ffffff'),
                }
                fill, back = color_map.get(event.event_type, ('#000000', '#ffffff'))
                qr = generate_or_update_event_qr(event, fill_color=fill, back_color=back)
                self.stdout.write(self.style.SUCCESS(f"    -> Generated QR [{qr.fill_color}] for {event.title}"))
            except Exception as e:
                self.stdout.write(self.style.WARNING(f"    -> QR generation notice: {e}"))

        # Seed sample photos and gallery items
        self.stdout.write('Creating sample gallery photos...')
        from apps.events.models import EventMedia
        from PIL import Image, ImageDraw
        import io
        from django.core.files.base import ContentFile

        wedding_event = Event.objects.filter(event_type='wedding').first()
        if wedding_event and not wedding_event.media.exists():
            sample_photos = [
                ('ceremony', 'Sacred Mandap & Varmala Ceremony', (108, 52, 131), True),
                ('reception', 'Grand Evening Stage & Lighting', (41, 128, 185), True),
                ('decor', 'Exquisite Floral Entrance Arch', (39, 174, 96), True),
                ('candid', 'Joyful Moments with Family & Friends', (211, 84, 0), True),
                ('food', 'Royal Feast & Dessert Spread', (142, 68, 173), True),
                ('guests', 'Congratulations from Rohit & Family', (44, 62, 80), False),  # Pending approval!
            ]

            for cat, caption, rgb_color, approved in sample_photos:
                # Generate sample 800x600 photo
                img = Image.new('RGB', (800, 600), rgb_color)
                draw = ImageDraw.Draw(img)
                # Draw white frame & label
                draw.rectangle([(20, 20), (780, 580)], outline=(255, 255, 255), width=4)
                draw.rectangle([(40, 480), (760, 560)], fill=(0, 0, 0, 180))
                draw.text((60, 500), f"[{cat.upper()}] {caption}", fill=(255, 255, 255))

                buf = io.BytesIO()
                img.save(buf, format='JPEG', quality=85)
                buf.seek(0)

                filename = f"sample_{cat}.jpg"
                media = EventMedia(
                    event=wedding_event,
                    uploaded_by=wedding_event.owner if approved else None,
                    media_type='image',
                    caption=caption,
                    category=cat,
                    is_approved=approved,
                    is_public=True,
                    file_size=len(buf.getvalue()),
                )
                media.file.save(filename, ContentFile(buf.getvalue()), save=True)
                status_txt = "Approved" if approved else "Pending Approval"
                self.stdout.write(self.style.SUCCESS(f"    -> Added photo: {caption} ({status_txt})"))

        # Seed sample business profiles & products/services
        self.stdout.write('Creating sample business profiles...')
        from apps.business.models import Business, BusinessService
        from apps.qrcodes.services import generate_or_update_business_qr

        sample_businesses = [
            {
                'owner': created_users[0] if created_users else User.objects.first(),
                'name': 'Royal Moments Photography & Studio',
                'tagline': 'Capturing your timeless weddings & celebration memories',
                'category': 'photography',
                'description': 'Award-winning wedding & cinematic event photography studio based in Bengaluru. With over 8+ years of experience and 300+ weddings documented, we specialize in candid moments, 4K cinematic films, and drone coverage that tells your true love story.',
                'phone': '+91 98765 12340',
                'whatsapp': '+91 98765 12340',
                'email': 'hello@royalmoments.example.com',
                'website': 'https://royalmoments.example.com',
                'instagram': 'https://instagram.com/royalmoments_studio',
                'facebook': 'https://facebook.com/royalmomentsstudio',
                'address': 'Plot 42, 100 Feet Road, Indiranagar',
                'city': 'Bengaluru',
                'state': 'Karnataka',
                'pincode': '560038',
                'maps_url': 'https://maps.google.com/?q=Indiranagar+Bengaluru',
                'working_hours': "Monday - Saturday: 10:00 AM - 8:00 PM\nSunday: By Prior Appointment",
                'is_active': True,
                'services': [
                    {
                        'name': 'Royal Wedding Photography Package',
                        'description': 'Complete 2-day coverage including 2 candid photographers, 2 traditional videographers, and 4K highlight teaser.',
                        'price': 75000.00,
                        'price_type': 'fixed',
                        'order': 1,
                    },
                    {
                        'name': 'Pre-Wedding Cinematic Shoot',
                        'description': 'One full day outdoor shoot with 2 costume changes, 30 edited portraits, and a 2-minute 4K cinematic film.',
                        'price': 25000.00,
                        'price_type': 'starting',
                        'order': 2,
                    },
                    {
                        'name': 'Live Drone Aerial Video Coverage',
                        'description': 'Licensed drone pilot for stunning 4K aerial views of your venue, procession, and outdoor reception.',
                        'price': 15000.00,
                        'price_type': 'hourly',
                        'order': 3,
                    },
                    {
                        'name': 'Custom Luxury Matte Photo Album',
                        'description': '50 thick metallic-finish pages with velvet box cover and lifelong binding warranty.',
                        'price': 12000.00,
                        'price_type': 'fixed',
                        'order': 4,
                    },
                ]
            },
            {
                'owner': created_users[1] if len(created_users) > 1 else User.objects.first(),
                'name': 'Spice Symphony Gourmet Caterers',
                'tagline': 'Exquisite culinary experiences for weddings & grand celebrations',
                'category': 'food',
                'description': 'Premium catering company delivering unforgettable dining experiences. From authentic traditional thalis to international fusion counters and live cocktail bars.',
                'phone': '+91 98765 67890',
                'whatsapp': '+91 98765 67890',
                'email': 'catering@spicesymphony.example.com',
                'website': 'https://spicesymphony.example.com',
                'instagram': 'https://instagram.com/spicesymphony_caterers',
                'address': '24, Jubilee Hills Road No. 36',
                'city': 'Hyderabad',
                'state': 'Telangana',
                'pincode': '500033',
                'maps_url': 'https://maps.google.com/?q=Jubilee+Hills+Hyderabad',
                'working_hours': "Monday - Sunday: 9:00 AM - 9:00 PM",
                'is_active': True,
                'services': [
                    {
                        'name': 'Grand Royal Buffet (Veg & Non-Veg)',
                        'description': 'Over 45 dishes across appetizers, main course, live breads, and dessert bar.',
                        'price': 950.00,
                        'price_type': 'starting',
                        'order': 1,
                    },
                    {
                        'name': 'Live Street Chaat & Fusion Counter',
                        'description': 'Interactive live stations: Delhi Pani Puri, Lucknowi Kebabs, and Mumbai Pav Bhaji.',
                        'price': 18000.00,
                        'price_type': 'starting',
                        'order': 2,
                    },
                    {
                        'name': 'Artisanal Dessert & Mocktail Lounge',
                        'description': 'Nitrogen ice cream station, Belgian chocolate fountains, and curated fruit mocktails.',
                        'price': 22000.00,
                        'price_type': 'fixed',
                        'order': 3,
                    },
                ]
            }
        ]

        for b_data in sample_businesses:
            services_data = b_data.pop('services')
            owner = b_data.pop('owner')
            biz, created = Business.objects.get_or_create(
                name=b_data['name'],
                owner=owner,
                defaults=b_data
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f"  Created business: {biz.name}"))
                generate_or_update_business_qr(biz)
                for s in services_data:
                    BusinessService.objects.create(business=biz, **s)
                self.stdout.write(self.style.SUCCESS(f"    -> Added {len(services_data)} products/services"))
            else:
                self.stdout.write(f"  Business already exists: {biz.name}")

        # Seed subscription plans and sample payments
        self.stdout.write('Creating subscription plans and transactions...')
        from apps.subscriptions.services import seed_default_plans, verify_and_activate_payment
        from apps.subscriptions.models import SubscriptionPlan, Subscription, Payment, AuditLog

        plans = seed_default_plans()
        self.stdout.write(self.style.SUCCESS(f"  Seeded {len(plans)} subscription plans."))

        # Assign Wedding Package to Ravi
        wedding_plan = SubscriptionPlan.objects.filter(code='wedding_package').first()
        if wedding_plan and created_users:
            ravi = created_users[0]
            ravi.is_premium = True
            ravi.save(update_fields=['is_premium'])
            sub, _ = Subscription.objects.update_or_create(
                user=ravi,
                defaults={
                    'plan': wedding_plan,
                    'status': 'active',
                    'start_date': timezone.now() - timedelta(days=15),
                    'end_date': timezone.now() + timedelta(days=350),
                }
            )
            # Create sample payment
            inv = Payment.generate_invoice_number()
            Payment.objects.get_or_create(
                razorpay_order_id='order_mock_seed_wedding_01',
                defaults={
                    'user': ravi,
                    'subscription': sub,
                    'plan': wedding_plan,
                    'invoice_number': inv,
                    'amount': wedding_plan.price,
                    'currency': 'INR',
                    'razorpay_payment_id': 'pay_mock_seed_wedding_01',
                    'razorpay_signature': 'sig_mock_wedding_01',
                    'status': 'captured',
                }
            )
            AuditLog.objects.create(
                user=ravi,
                action='PAYMENT_SUCCESS',
                resource_type='Payment',
                resource_id=inv,
                details=f"Seeded payment of ₹{wedding_plan.price} for {wedding_plan.name}"
            )
            self.stdout.write(self.style.SUCCESS(f"  Provisioned {wedding_plan.name} for Ravi (Invoice: {inv})"))

        # Assign Business Annual to Priya
        biz_plan = SubscriptionPlan.objects.filter(code='business_annual').first()
        if biz_plan and len(created_users) > 1:
            priya = created_users[1]
            priya.is_premium = True
            priya.save(update_fields=['is_premium'])
            sub2, _ = Subscription.objects.update_or_create(
                user=priya,
                defaults={
                    'plan': biz_plan,
                    'status': 'active',
                    'start_date': timezone.now() - timedelta(days=5),
                    'end_date': timezone.now() + timedelta(days=360),
                }
            )
            inv2 = Payment.generate_invoice_number()
            Payment.objects.get_or_create(
                razorpay_order_id='order_mock_seed_biz_02',
                defaults={
                    'user': priya,
                    'subscription': sub2,
                    'plan': biz_plan,
                    'invoice_number': inv2,
                    'amount': biz_plan.price,
                    'currency': 'INR',
                    'razorpay_payment_id': 'pay_mock_seed_biz_02',
                    'razorpay_signature': 'sig_mock_biz_02',
                    'status': 'captured',
                }
            )
            AuditLog.objects.create(
                user=priya,
                action='PAYMENT_SUCCESS',
                resource_type='Payment',
                resource_id=inv2,
                details=f"Seeded payment of ₹{biz_plan.price} for {biz_plan.name}"
            )
            self.stdout.write(self.style.SUCCESS(f"  Provisioned {biz_plan.name} for Priya (Invoice: {inv2})"))

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write(self.style.SUCCESS('Sample data seeded successfully!'))
        self.stdout.write('')
        self.stdout.write('Login credentials:')
        self.stdout.write('  Admin:  admin@eventconnect.com  /  Admin@1234')
        self.stdout.write('  User 1: ravi@sample.eventconnect.com  /  Test@1234')
        self.stdout.write('  User 2: priya@sample.eventconnect.com  /  Test@1234')
        self.stdout.write(self.style.SUCCESS('=' * 60))
