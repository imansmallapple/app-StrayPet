# apps/user/signals.py
import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.conf import settings
from .models import UserProfile, Friendship, Notification
from .avatar_utils import generate_default_avatar

logger = logging.getLogger(__name__)

@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_profile(sender, instance, created, **kwargs):
    if created:
        profile, _ = UserProfile.objects.get_or_create(user=instance)
        # Generate and save default avatar if not already set
        if not profile.avatar:
            default_avatar = generate_default_avatar(instance.username)
            profile.avatar.save(f'{instance.username}_avatar.png', default_avatar, save=True)


@receiver(post_save, sender=Friendship)
def create_friend_request_notification(sender, instance, created, **kwargs):
    """当创建好友申请时，为接收方生成通知"""
    try:
        if created and instance.status == 'pending':
            logger.info(f'Creating notification for friend request from {instance.from_user.username} to {instance.to_user.username}')
            # 为接收方创建通知
            notification = Notification.objects.create(
                user=instance.to_user,
                notification_type='friend_request',
                title=f'{instance.from_user.username} sent a friend request',
                content=f'{instance.from_user.username} wants to add you as a friend',
                from_user=instance.from_user,
                friendship=instance,
                is_read=False
            )
            logger.info(f'Notification created successfully: {notification.id}')
    except Exception as e:
        logger.error(f'Error creating friend request notification: {str(e)}', exc_info=True)
