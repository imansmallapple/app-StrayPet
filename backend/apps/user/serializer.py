import logging
from django.contrib.auth import get_user_model
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.hashers import make_password, check_password
from rest_framework.validators import UniqueValidator

logger = logging.getLogger(__name__)
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework.permissions import AllowAny
from django.core.cache import cache
from .models import Notification, Friendship, PrivateMessage

User = get_user_model()


def get_token_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


class VerifyEmailCodeSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True, label='Email')
    code = serializers.CharField(
        required=True,
        label='Verification Code',
        max_length=4,
        min_length=4,
        write_only=True
    )

    def validate(self, attrs):
        attrs = super().validate(attrs)
        from django.core.cache import cache
        item_code = cache.get(attrs['email'])
        if not item_code:
            raise serializers.ValidationError('Verification code expired!')
        # 大小写不敏感比较验证码
        if item_code.lower() != attrs['code'].lower():
            raise serializers.ValidationError('Code wrong!')
        # 验证码验证成功后，删除它以防止重复使用
        cache.delete(attrs['email'])
        return attrs
    
class UserMeSerializer(serializers.ModelSerializer):
    phone = serializers.CharField(source='profile.phone', allow_blank=True, required=False, default='')
    avatar = serializers.ImageField(source='profile.avatar', allow_null=True, required=False)
    is_holiday_family_certified = serializers.BooleanField(source='profile.is_holiday_family_certified', required=False, default=False)
    preferred_species = serializers.CharField(source='profile.preferred_species', allow_blank=True, required=False, default='')
    preferred_size = serializers.CharField(source='profile.preferred_size', allow_blank=True, required=False, default='')
    preferred_age_min = serializers.IntegerField(source='profile.preferred_age_min', allow_null=True, required=False)
    preferred_age_max = serializers.IntegerField(source='profile.preferred_age_max', allow_null=True, required=False)
    preferred_gender = serializers.CharField(source='profile.preferred_gender', allow_blank=True, required=False, default='')
    has_experience = serializers.BooleanField(source='profile.has_experience', required=False, default=False)
    living_situation = serializers.CharField(source='profile.living_situation', allow_blank=True, required=False, default='')
    has_yard = serializers.BooleanField(source='profile.has_yard', required=False, default=False)
    other_pets = serializers.CharField(source='profile.other_pets', allow_blank=True, required=False, default='')
    additional_notes = serializers.CharField(source='profile.additional_notes', allow_blank=True, required=False, default='')
    
    # Preference fields - both readable and writable
    prefer_vaccinated = serializers.BooleanField(source='profile.prefer_vaccinated', required=False, default=False)
    prefer_sterilized = serializers.BooleanField(source='profile.prefer_sterilized', required=False, default=False)
    prefer_dewormed = serializers.BooleanField(source='profile.prefer_dewormed', required=False, default=False)
    prefer_child_friendly = serializers.BooleanField(source='profile.prefer_child_friendly', required=False, default=False)
    prefer_trained = serializers.BooleanField(source='profile.prefer_trained', required=False, default=False)
    prefer_loves_play = serializers.BooleanField(source='profile.prefer_loves_play', required=False, default=False)
    prefer_loves_walks = serializers.BooleanField(source='profile.prefer_loves_walks', required=False, default=False)
    prefer_good_with_dogs = serializers.BooleanField(source='profile.prefer_good_with_dogs', required=False, default=False)
    prefer_good_with_cats = serializers.BooleanField(source='profile.prefer_good_with_cats', required=False, default=False)
    prefer_affectionate = serializers.BooleanField(source='profile.prefer_affectionate', required=False, default=False)
    prefer_needs_attention = serializers.BooleanField(source='profile.prefer_needs_attention', required=False, default=False)
    

    class Meta:
        model = User
        fields = ("id", "username", "email", "first_name", "last_name", "phone", "avatar", "is_holiday_family_certified",
                  "preferred_species", "preferred_size", "preferred_age_min", "preferred_age_max",
                  "preferred_gender", "has_experience", "living_situation", "has_yard", 
                  "other_pets", "additional_notes",
                  "prefer_vaccinated", "prefer_sterilized", "prefer_dewormed", "prefer_child_friendly",
                  "prefer_trained", "prefer_loves_play", "prefer_loves_walks", "prefer_good_with_dogs",
                  "prefer_good_with_cats", "prefer_affectionate", "prefer_needs_attention",
                  "is_staff")
        extra_kwargs = {
            "username": {"required": False},
            "email": {"required": False},
            "first_name": {"required": False},
            "last_name": {"required": False},
        }

    def to_internal_value(self, data):
        # DRF automatically handles nested source fields via source='profile.field_name'
        # Just call parent implementation
        return super().to_internal_value(data)

    def update(self, instance, validated_data):
        profile_data = validated_data.pop('profile', {})

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        # 确保profile存在
        profile = getattr(instance, 'profile', None)
        if not profile:
            from .models import UserProfile
            profile = UserProfile.objects.create(user=instance)
        
        if profile_data:
            for attr, value in profile_data.items():
                setattr(profile, attr, value)
            profile.save()

        return instance
    
    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Convert relative avatar URL to absolute URL
        if data.get('avatar') and not data['avatar'].startswith('http'):
            request = self.context.get('request')
            if request:
                data['avatar'] = request.build_absolute_uri(data['avatar'])
        return data

class RegisterSerializer(VerifyEmailCodeSerializer, serializers.ModelSerializer):
    # password = serializers.CharField(write_only=True)
    password1 = serializers.CharField(write_only=True, style={'input_type': 'password'})
    # get user object
    tokens = serializers.SerializerMethodField()
    email = serializers.EmailField(required=True, label='email',
                                   validators=[UniqueValidator(queryset=User.objects.all(),
                                                               message='Email already exists!')
                                               ])

    class Meta:
        model = User
        fields = ('username', 'password', 'password1', 'email', 'tokens', 'code')
        extra_kwargs = {
            # 'email': {
            #     'validators': [
            #         UniqueValidator(queryset=User.objects.all(), message='Email already exists!')
            #     ]
            # },
            'password': {
                'write_only': True,
                'style': {'input_type': 'password'}
            },
            'password1': {
                'write_only': True,
                'style': {'input_type': 'password'}
            },
        }

    def validate(self, attrs):
        print(attrs)
        if attrs['password'] != attrs['password1']:
            raise serializers.ValidationError('Repeat password incorrect!')
        attrs = super().validate(attrs)
        attrs['password'] = make_password(attrs['password'])
        del attrs['password1']
        del attrs['code']
        return attrs

    def validate_password(self, password):
        validate_password(password)
        return password

    def get_tokens(self, obj):
        return get_token_for_user(obj)


class SendEmailCodeSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True, label='Email')


class UserInfoSerializer(serializers.ModelSerializer):
    avatar = serializers.ImageField(source='profile.avatar', allow_null=True, required=False)
    phone = serializers.CharField(source='profile.phone', allow_blank=True, required=False)
    is_holiday_family_certified = serializers.BooleanField(source='profile.is_holiday_family_certified', required=False, default=False)
    
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'avatar', 'phone', 'first_name', 'last_name', 'is_holiday_family_certified')
    
    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Convert relative avatar URL to absolute URL
        if data.get('avatar') and not data['avatar'].startswith('http'):
            request = self.context.get('request')
            if request:
                data['avatar'] = request.build_absolute_uri(data['avatar'])
        return data


class UpdateEmailSerializer(VerifyEmailCodeSerializer, serializers.ModelSerializer):
    email = serializers.EmailField(required=True, label='Email', validators=[
        UniqueValidator(queryset=User.objects.all(), message='Email already exists!')
    ])

    class Meta:
        model = User
        fields = ('id', 'email', 'code')

        def validate(self, attrs):
            attrs = super().validate(attrs)
            del attrs['code']
            return attrs


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()
    permission_classes = [AllowAny]
    authentication_classes = []  
    def validate(self, attrs):
        # 不暴露用户是否存在；如果要提示不存在，可在此查表并返回 ValidationError
        attrs["user_exists"] = User.objects.filter(email=attrs["email"]).exists()
        return attrs

class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=4, min_length=4, write_only=True)
    new_password = serializers.CharField(write_only=True, style={'input_type': 'password'})
    re_new_password = serializers.CharField(write_only=True, style={'input_type': 'password'})
    permission_classes = [AllowAny]
    authentication_classes = [] 
    
    def validate(self, attrs):
        if attrs["new_password"] != attrs["re_new_password"]:
            raise serializers.ValidationError("Repeat password incorrect!")
        validate_password(attrs["new_password"])  # 走 Django 密码强度校验

        real = cache.get(attrs["email"])
        if not real:
            raise serializers.ValidationError("Verification code expired!")
        if real != attrs["code"]:
            raise serializers.ValidationError("Code wrong!")

        try:
            attrs["user"] = User.objects.get(email=attrs["email"])
        except User.DoesNotExist:
            # 保持一致性：不暴露是否存在
            raise serializers.ValidationError("Invalid email or code.")
        return attrs

class ChangePasswordSerializer(serializers.ModelSerializer):
    old_password = serializers.CharField(
        required=True,
        label='Old Password',
        write_only=True,
        style={'input_type': 'password'}
    )

    class Meta:
        model = User
        fields = ('id', 'old_password', 'password')
        extra_kwargs = {
            'password': {
                'write_only': True,
                'style': {'input_type': 'password'}
            },
        }

    def validate_old_password(self, old_password):
        if not self.instance.check_password(old_password):
            raise serializers.ValidationError('Old password incorrect!')
        return old_password

    def validate(self, attrs):
        attrs = super().validate(attrs)
        del attrs['old_password']
        return attrs


class CaptchaSerializer(serializers.Serializer):
    captcha = serializers.CharField(
        label="Verification code",
        max_length=4,
        min_length=4,
        write_only=True,
        required=True
    )
    uid = serializers.CharField(
        label='Verification code id',
        max_length=100,
        min_length=10,
        write_only=True,
        required=True
    )

    def validate(self, attrs):
        from django.core.cache import cache
        import logging
        
        logger = logging.getLogger(__name__)
        uid = attrs.get('uid')
        captcha_input = attrs.get('captcha')
        
        # 检查缓存中是否存在验证码
        cached_captcha = cache.get(uid)
        
        logger.info(f"[CaptchaValidator] uid={uid}, input={captcha_input}, cached={bool(cached_captcha)}")

        if not cached_captcha:
            logger.warning(f"[CaptchaValidator] Verification code expired for uid={uid}")
            raise serializers.ValidationError({
                "captcha": ["Verification code expired or invalid!"]
            })

        # 大小写不敏感的比对
        if cached_captcha.lower() != captcha_input.lower():
            logger.warning(f"[CaptchaValidator] Captcha mismatch: expected={cached_captcha}, got={captcha_input}")
            raise serializers.ValidationError({
                "captcha": ["Verification code is incorrect!"]
            })
        
        logger.info(f"[CaptchaValidator] Verification code validated successfully for uid={uid}")
        cache.delete(uid)
        return super().validate(attrs)


class LoginSerializer(CaptchaSerializer, TokenObtainPairSerializer):
    pass


class UploadImageSerializer(serializers.Serializer):
    image = serializers.ImageField(label="Image", required=True)

    def validate(self, attrs):
        if attrs['image'].size > 2 * 1024 * 1024:
            raise serializers.ValidationError("Image size can't bigger than 2M")
        return super().validate(attrs)


# apps/user/serializers.py
from django.contrib.auth.models import User
from rest_framework import serializers

class UserListSerializer(serializers.ModelSerializer):
    phone = serializers.CharField(source='profile.phone', allow_blank=True, required=False)
    avatar = serializers.ImageField(source='profile.avatar', allow_null=True, required=False)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'phone', 'avatar')
    
    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Convert relative avatar URL to absolute URL
        if data.get('avatar') and not data['avatar'].startswith('http'):
            request = self.context.get('request')
            if request:
                data['avatar'] = request.build_absolute_uri(data['avatar'])
        return data


class DynamicFieldsModelSerializer(serializers.ModelSerializer):
    """
    允许通过 kwargs['fields'] / kwargs['exclude'] 动态裁剪字段
    """
    def __init__(self, *args, **kwargs):
        fields = kwargs.pop('fields', None)
        exclude = kwargs.pop('exclude', None)
        super().__init__(*args, **kwargs)
        if fields is not None:
            allowed = set(fields)
            for f in list(self.fields.keys()):
                if f not in allowed:
                    self.fields.pop(f)
        if exclude is not None:
            for f in exclude:
                self.fields.pop(f, None)

class UserDetailSerializer(DynamicFieldsModelSerializer):
    # 把 phone 映射到 profile.phone
    phone = serializers.CharField(source='profile.phone', allow_blank=True, required=False)
    avatar = serializers.ImageField(source='profile.avatar', allow_null=True, required=False)
    is_holiday_family_certified = serializers.BooleanField(source='profile.is_holiday_family_certified', required=False, default=False)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name',
                  'phone', 'avatar', 'is_staff', 'date_joined', 'last_login', 'is_holiday_family_certified')
        extra_kwargs = {
            'username': {'required': False},
            'email': {'required': False},
            'first_name': {'required': False, 'allow_blank': True},
            'last_name': {'required': False, 'allow_blank': True},
        }

    # 唯一性校验
    def validate_username(self, v):
        if not v:
            return v
        user = self.instance or self.context.get('request').user
        if User.objects.exclude(pk=user.pk).filter(username=v).exists():
            raise serializers.ValidationError('该用户名已被占用')
        return v

    def validate_email(self, v):
        if not v:
            return v
        user = self.instance or self.context.get('request').user
        if User.objects.exclude(pk=user.pk).filter(email=v).exists():
            raise serializers.ValidationError('该邮箱已被占用')
        return v

    def update(self, instance, validated_data):
        profile_data = validated_data.pop('profile', {})
        # 更新 User 字段
        for attr in ['username', 'first_name', 'last_name', 'email']:
            if attr in validated_data:
                setattr(instance, attr, validated_data[attr])
        instance.save()
        # 更新 phone 和 avatar
        if profile_data:
            profile = getattr(instance, 'profile', None)
            if profile is None:
                from .models import UserProfile
                profile = UserProfile.objects.create(user=instance)
            for attr, value in profile_data.items():
                setattr(profile, attr, value)
            profile.full_clean()
            profile.save()
        return instance

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Convert relative avatar URL to absolute URL
        if data.get('avatar') and not data['avatar'].startswith('http'):
            request = self.context.get('request')
            if request:
                data['avatar'] = request.build_absolute_uri(data['avatar'])
        return data


class NotificationSerializer(serializers.ModelSerializer):
    """通知序列化器"""
    from_user = serializers.SerializerMethodField()
    comment_content = serializers.SerializerMethodField()
    friendship_id = serializers.SerializerMethodField()
    holiday_family_application_id = serializers.SerializerMethodField()
    content = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = ['id', 'notification_type', 'title', 'content', 'from_user', 'comment_content', 'friendship_id', 'holiday_family_application_id', 'is_read', 'created_at', 'read_at']
        read_only_fields = ['id', 'created_at', 'read_at']
    
    def get_from_user(self, obj):
        if obj.from_user:
            return {
                'id': obj.from_user.id,
                'username': obj.from_user.username
            }
        return None
    
    def get_friendship_id(self, obj):
        if obj.friendship:
            return obj.friendship.id
        return None
    
    def get_holiday_family_application_id(self, obj):
        if obj.holiday_family_application:
            return obj.holiday_family_application.id
        return None
    
    def get_comment_content(self, obj):
        if obj.comment:
            return obj.comment.content
        return None
    
    def get_content(self, obj):
        """将中文内容翻译为英文"""
        content = obj.content or ''
        
        # 翻译常见的中文短语
        translations = {
            '想要加你为好友': 'wants to add you as a friend',
            '想要加你为好友': 'wants to add you as a friend',
            '回复了你': 'replied to you',
            '提到了你': 'mentioned you',
        }
        
        # 进行翻译
        result = content
        for chinese, english in translations.items():
            result = result.replace(chinese, english)
        
        return result


class FriendshipSerializer(serializers.ModelSerializer):
    """好友关系序列化器"""
    from_user = serializers.SerializerMethodField()
    to_user = serializers.SerializerMethodField()
    
    class Meta:
        model = Friendship
        fields = ['id', 'from_user', 'to_user', 'status', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_from_user(self, obj):
        return {
            'id': obj.from_user.id,
            'username': obj.from_user.username
        }
    
    def get_to_user(self, obj):
        return {
            'id': obj.to_user.id,
            'username': obj.to_user.username
        }


class PrivateMessageSerializer(serializers.ModelSerializer):
    """私信序列化器"""
    sender = serializers.SerializerMethodField()
    recipient = serializers.SerializerMethodField()
    
    class Meta:
        model = PrivateMessage
        fields = ['id', 'sender', 'recipient', 'content', 'is_read', 'is_system', 'created_at', 'read_at']
        read_only_fields = ['id', 'created_at', 'read_at', 'is_read', 'is_system']
    
    def get_sender(self, obj):
        avatar_url = None
        if obj.sender.profile and obj.sender.profile.avatar:
            avatar_url = obj.sender.profile.avatar.url
            request = self.context.get('request')
            if request:
                avatar_url = request.build_absolute_uri(avatar_url)
        
        return {
            'id': obj.sender.id,
            'username': obj.sender.username,
            'avatar': avatar_url
        }
    
    def get_recipient(self, obj):
        avatar_url = None
        if obj.recipient.profile and obj.recipient.profile.avatar:
            avatar_url = obj.recipient.profile.avatar.url
            request = self.context.get('request')
            if request:
                avatar_url = request.build_absolute_uri(avatar_url)
        
        return {
            'id': obj.recipient.id,
            'username': obj.recipient.username,
            'avatar': avatar_url
        }
