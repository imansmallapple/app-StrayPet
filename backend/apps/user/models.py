from django.db import models
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.core.cache import cache
from django.utils import timezone
from django.conf import settings
from django.core.validators import RegexValidator

phone_validator = RegexValidator(
    regex=r'^\+?[0-9\- ]{6,20}$',
    message='Phone format incorrect（e.g.：+48 123-456-789 or 13800138000）'
)

class UserProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='profile')
    phone = models.CharField(max_length=32, blank=True, validators=[phone_validator])
    
    # User avatar
    avatar = models.ImageField(
        upload_to='avatars/%Y/%m/%d/',
        null=True,
        blank=True,
        help_text='User avatar image'
    )
    
    # Holiday Family certification
    is_holiday_family_certified = models.BooleanField(default=False, help_text="用户是否通过了Holiday Family认证")
    
    # Pet adoption preferences
    preferred_species = models.CharField(max_length=50, blank=True, help_text="偏好的物种（如：dog, cat）")
    preferred_size = models.CharField(max_length=50, blank=True, help_text="偏好的大小（如：small, medium, large）")
    preferred_age_min = models.IntegerField(null=True, blank=True, help_text="偏好的最小年龄（月）")
    preferred_age_max = models.IntegerField(null=True, blank=True, help_text="偏好的最大年龄（月）")
    preferred_gender = models.CharField(max_length=20, blank=True, help_text="偏好的性别（male/female）")
    has_experience = models.BooleanField(default=False, help_text="是否有养宠经验")
    living_situation = models.CharField(max_length=100, blank=True, help_text="居住环境（如：apartment, house）")
    has_yard = models.BooleanField(default=False, help_text="是否有院子")
    other_pets = models.CharField(max_length=200, blank=True, help_text="家中其他宠物")
    additional_notes = models.TextField(blank=True, help_text="其他偏好说明")
    
    # Pet characteristics preferences
    prefer_vaccinated = models.BooleanField(default=False, help_text="偏好已接种疫苗的宠物")
    prefer_sterilized = models.BooleanField(default=False, help_text="偏好已绝育的宠物")
    prefer_dewormed = models.BooleanField(default=False, help_text="偏好已驱虫的宠物")
    prefer_child_friendly = models.BooleanField(default=False, help_text="偏好适合儿童的宠物")
    prefer_trained = models.BooleanField(default=False, help_text="偏好已训练的宠物")
    prefer_loves_play = models.BooleanField(default=False, help_text="偏好喜欢玩耍的宠物")
    prefer_loves_walks = models.BooleanField(default=False, help_text="偏好喜欢散步的宠物")
    prefer_good_with_dogs = models.BooleanField(default=False, help_text="偏好与其他狗相处友善的宠物")
    prefer_good_with_cats = models.BooleanField(default=False, help_text="偏好与猫相处友善的宠物")
    prefer_affectionate = models.BooleanField(default=False, help_text="偏好富有感情的宠物")
    prefer_needs_attention = models.BooleanField(default=False, help_text="偏好需要陪伴的宠物")

    def __str__(self):
        return f'Profile<{self.user.username}>'

class ViewStatistics(models.Model):
    object_id = models.PositiveIntegerField()
    content_type = models.ForeignKey(on_delete=models.CASCADE, to=ContentType)
    content_object = GenericForeignKey('content_type', 'object_id')
    count = models.PositiveIntegerField(default=0)
    date = models.DateField(auto_now_add=True)

    class Meta:
        verbose_name = 'View statistics'
        verbose_name_plural = 'View statistics'
        ordering = ['-date']
        indexes = [
            models.Index(
                fields=['content_type', 'object_id', 'date'],
                name='user_views_content_date_idx'
            )
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['content_type', 'object_id', 'date'],
                name='user_views_content_type_idx'
            )
        ]

    def __str__(self) -> str:
        return f'{self.content_type}{self.object_id}-{self.date}-{self.count}'

    @classmethod
    def increase(cls, request, obj):
        uid = request.uid
        obj_id = obj.id
        date = timezone.now().date()
        ct = ContentType.objects.get_for_model(obj.__class__)
        key = f'{uid}:{date}:{obj_id}'

        if not cache.get(key):
            cache.set(key, 1, 60 * 60 * 24)
            try:
                cls.objects.get(content_type=ct, object_id=obj_id, date=date)
            except cls.DoesNotExist:
                cls.objects.create(
                    content_type=ct,
                    object_id=obj_id,
                    count=1,
                    date=date
                )
            else:
                cls.objects.filter(
                    content_type=ct,
                    object_id=obj_id,
                    date=date
                ).update(count=models.F('count') + 1)

    @classmethod
    def get_view_count(cls, obj):
        ct = ContentType.objects.get_for_model(obj)
        obj_id = obj.id
        date = timezone.now().date()
        try:
            view_statistics = ViewStatistics.objects.get(
                content_type=ct,
                object_id=obj_id,
                date=date
            )
        except cls.DoesNotExist:
            return 0
        else:
            return cls.objects.filter(
                content_type=ct,
                object_id=obj_id
            ).aggregate(models.Sum('count'))['count__sum']


class Notification(models.Model):
    """用户通知模型 - 记录评论回复和其他通知"""
    NOTIFICATION_TYPES = (
        ('reply', '有人回复了我的评论'),
        ('mention', '有人提到了我'),
        ('friend_request', '好友申请'),
        ('system', '系统通知'),
        ('holiday_family_apply', 'Holiday Family 申请'),
        ('holiday_family_approve', 'Holiday Family 申请已批准'),
        ('holiday_family_reject', 'Holiday Family 申请已拒绝'),
    )
    
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=30, choices=NOTIFICATION_TYPES, default='reply')
    
    # 关联的 holiday family 申请
    holiday_family_application = models.ForeignKey(
        'holiday_family.HolidayFamilyApplication',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='notifications'
    )
    
    # 关联的评论
    comment = models.ForeignKey('comment.Comment', on_delete=models.CASCADE, null=True, blank=True)
    
    # 关联的好友关系
    friendship = models.ForeignKey('Friendship', on_delete=models.CASCADE, null=True, blank=True, related_name='notifications')
    
    # 触发通知的用户（谁回复了我或谁发送了好友申请）
    from_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True, related_name='sent_notifications')
    
    # 通知内容
    title = models.CharField(max_length=255, blank=True)
    content = models.TextField(blank=True)
    
    # 是否已读
    is_read = models.BooleanField(default=False)
    
    # 时间戳
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['user', 'is_read']),
        ]
    
    def __str__(self):
        return f'{self.user.username} - {self.get_notification_type_display()}'


class Friendship(models.Model):
    """好友关系模型"""
    from_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='friendships_initiated')
    to_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='friendships_received')
    
    # 状态：pending=待接受, accepted=已接受, blocked=已拒绝
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', '待接受'),
            ('accepted', '已接受'),
            ('blocked', '已拒绝'),
        ],
        default='pending'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('from_user', 'to_user')
        verbose_name = 'Friendship'
        verbose_name_plural = 'Friendships'
        indexes = [
            models.Index(fields=['from_user', 'status']),
            models.Index(fields=['to_user', 'status']),
        ]
    
    def __str__(self):
        return f'{self.from_user.username} -> {self.to_user.username} ({self.status})'


class PrivateMessage(models.Model):
    """私信模型"""
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sent_messages')
    recipient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='received_messages')
    
    content = models.TextField()
    is_read = models.BooleanField(default=False)
    is_system = models.BooleanField(default=False)  # 标记为系统消息
    
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = 'Private Message'
        verbose_name_plural = 'Private Messages'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['sender', 'recipient', '-created_at']),
            models.Index(fields=['recipient', 'is_read']),
        ]
    
    def __str__(self):
        return f'{self.sender.username} -> {self.recipient.username}: {self.content[:50]}'
