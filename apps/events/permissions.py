from .models import EventStaff


def can_access_event(user, event):
    return user.is_authenticated and (
        event.owner_id == user.pk or EventStaff.objects.filter(event=event, user=user).exists()
    )


def can_manage_guests(user, event):
    return user.is_authenticated and (
        event.owner_id == user.pk
        or EventStaff.objects.filter(event=event, user=user, role='manager').exists()
    )
