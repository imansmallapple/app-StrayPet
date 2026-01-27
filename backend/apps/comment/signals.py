"""
评论相关信号处理器 - 自动创建通知
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from .models import Comment
from apps.user.models import Notification

User = get_user_model()


@receiver(post_save, sender=Comment)
def create_notification_on_reply(sender, instance, created, **kwargs):
    """
    当创建新评论时，检查是否是回复，如果是则创建通知
    """
    if not created:
        return
    
    # 如果这条评论有父评论，说明是回复
    if instance.parent:
        parent_comment = instance.parent
        # 通知被回复的用户（除非是回复自己）
        if parent_comment.owner != instance.owner:
            # 创建通知
            Notification.objects.create(
                user=parent_comment.owner,
                notification_type='reply',
                comment=instance,
                from_user=instance.owner,
                title=f'{instance.owner.username} 回复了你的评论',
                content=instance.content[:100]  # 前100个字符
            )
