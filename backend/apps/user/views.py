import random
import string
import io
import base64
import uuid
from datetime import date
from django.core.cache import cache
from django.contrib.auth import get_user_model, logout
from django.contrib.auth.models import User
from django.db.models import Q
from rest_framework import viewsets, mixins, filters, permissions, authentication, status, generics
from rest_framework.generics import GenericAPIView
from rest_framework.response import Response
from common import pagination
from rest_framework.decorators import action
from apps.user.serializer import RegisterSerializer, SendEmailCodeSerializer, VerifyEmailCodeSerializer, \
    UserInfoSerializer, UpdateEmailSerializer, ChangePasswordSerializer, UploadImageSerializer, \
    PasswordResetRequestSerializer, PasswordResetConfirmSerializer, UserMeSerializer, UserListSerializer, \
    UserDetailSerializer, NotificationSerializer, FriendshipSerializer, PrivateMessageSerializer
from apps.user.models import Notification, Friendship, PrivateMessage
from rest_framework_simplejwt.authentication import JWTAuthentication
from common.utils import generate_catcha_image
from django.core.files.storage import default_storage
from django.core.mail import send_mail
from rest_framework.permissions import AllowAny
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.authentication import SessionAuthentication
User = get_user_model()

    
class RegisterViewSet(mixins.CreateModelMixin, viewsets.GenericViewSet):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]
    authentication_classes = []
    http_method_names = ['get', 'post', 'head', 'options']  # 允许 GET
    
    def list(self, request, *args, **kwargs):
        return Response({"detail": "Use POST to register a new user."})

class SendEmailCodeGenericAPIView(GenericAPIView):
    serializer_class = SendEmailCodeSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        code = ''.join(random.sample(string.ascii_letters + string.digits, 4))
        email = serializer.validated_data['email']
        cache.get_or_set(email, code, 60 * 5)

        from django.core.mail import send_mail
        send_mail(
            subject='Email code sent, please check your mail box!',
            message=f'Your verification code is {code}',
            from_email='admin@qq.com',
            recipient_list=[email],
            fail_silently=False,
        )
        return Response({'msg': 'Sent success!'})


class VerifyEmailCodeGenericAPIView(GenericAPIView):
    serializer_class = VerifyEmailCodeSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        cache.delete(serializer.data['email'])
        return Response({'msg': 'Verification success!'})


class UserViewSet(mixins.ListModelMixin,
                  mixins.RetrieveModelMixin,
                  viewsets.GenericViewSet):
    """
    /user/
      ├── /user/register/     注册
      ├── /user/me/           当前用户信息
      └── /user/profiles/     所有用户（管理员）
    """
    queryset = User.objects.all().select_related('profile')
    authentication_classes = [JWTAuthentication]
    serializer_class = UserDetailSerializer
    permission_classes = [permissions.IsAdminUser] 
    # 仅管理员可以访问列表
    def get_permissions(self):
        if self.action in ['list']:
            return [permissions.IsAdminUser()]
        elif self.action in ['me', 'partial_update', 'update']:
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    # 普通 list: /user/profiles/
    def list(self, request, *args, **kwargs):
        """管理员查看所有用户资料"""
        serializer = self.get_serializer(self.get_queryset(), many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get', 'patch'], url_path='me')
    def me(self, request):
        """
        GET /user/me/      → 当前用户资料
        PATCH /user/me/    → 修改当前用户资料
        """
        user = request.user
        if request.method == 'GET':
            serializer = self.get_serializer(user)
            return Response(serializer.data)
        elif request.method == 'PATCH':
            serializer = self.get_serializer(user, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)

    @action(
        detail=False,
        methods=['get', 'patch'],
        url_path='detail',
        permission_classes=[permissions.IsAuthenticated],
        authentication_classes=[JWTAuthentication]
    )
    def detail(self, request):
        """
        GET  /user/detail/?fields=id,username,email,phone
        PATCH /user/detail/ { "username": "...", "phone": "..." }
        """
        user = request.user

        # 从 query 中取动态字段
        fields_param  = request.query_params.get('fields')
        exclude_param = request.query_params.get('exclude')
        fields  = [s.strip() for s in fields_param.split(',')] if fields_param else None
        exclude = [s.strip() for s in exclude_param.split(',')] if exclude_param else None

        if request.method == 'GET':
            ser = UserDetailSerializer(user, context={'request': request}, fields=fields, exclude=exclude)
            return Response(ser.data)

        # PATCH：只允许基础信息字段
        ser = UserDetailSerializer(
            user,
            data=request.data,
            partial=True,
            context={'request': request}
        )
        ser.is_valid(raise_exception=True)
        ser.save()
        return Response(ser.data)


class UserListViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    """
    GET /user/list/   All user basic information
    """
    queryset = User.objects.all().select_related('profile')
    serializer_class = UserListSerializer
    permission_classes = [permissions.IsAdminUser]   # 或视需求改成 IsAuthenticated
    
    def get_view_name(self):
        if getattr(self, 'action', None) == 'list':
            return 'User list'   # 你想要的标题
        return super().get_view_name()


class UserInfoViewSet(mixins.RetrieveModelMixin,
                      viewsets.GenericViewSet):
    queryset = User.objects.all().select_related('profile')
    serializer_class = UserInfoSerializer
    authentication_classes = [authentication.SessionAuthentication, JWTAuthentication]
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        # 允许查询任何用户的公开信息
        return super().get_queryset()

    def get_serializer_class(self):
        if self.action == 'update_email':
            return UpdateEmailSerializer
        elif self.action == 'change_password':
            return ChangePasswordSerializer
        return super().get_serializer_class()

    @action(detail=False, methods=['get'], url_path='certified')
    def certified(self, request):
        """
        GET /user/userinfo/certified/  获取所有认证过的 Holiday Family 用户
        """
        certified_users = User.objects.filter(
            profile__is_holiday_family_certified=True
        ).select_related('profile')
        serializer = self.get_serializer(certified_users, many=True)
        return Response(serializer.data)

    @action(methods=['post'], detail=True)
    def update_email(self, request, pk=None):
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data)
        serializer.is_valid(raise_exception=True)
        instance.email = serializer.validated_data['email']
        instance.save()
        return Response({'msg': 'Email update succeed!'})

    @action(methods=['post'], detail=True)
    def change_password(self, request, pk=None):
        """
        Only the authenticated user can change their own password
        POST /user/userinfo/{id}/change_password/
        Body: { "old_password": "...", "password": "..." }
        """
        instance = self.get_object()
        
        # Check if the user is authenticated and can only change their own password
        if not request.user.is_authenticated:
            return Response(
                {'detail': 'Authentication required'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        if request.user.id != instance.id:
            return Response(
                {'detail': 'You can only change your own password'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = self.get_serializer(instance, data=request.data)
        serializer.is_valid(raise_exception=True)
        instance.set_password(serializer.validated_data['password'])
        instance.save()

        if authentication.SessionAuthentication in self.authentication_classes:
            logout(request)
        return Response({'msg': 'Change password succeed!'})


class CaptchaGenericAPIView(GenericAPIView):
    permission_classes = [AllowAny]          
    authentication_classes = []  
    
    def get(self, request, *args, **kwargs):
        image, text = generate_catcha_image()
        uid = uuid.uuid4().hex
        cache.set(uid, text, 60 * 5)

        buf = io.BytesIO()
        image.save(buf, format='PNG')  # 大写也行
        b64 = base64.b64encode(buf.getvalue()).decode('ascii')  # ← 只 decode，不要再 encode

        return Response({
            "uid": uid,
            "image": f"data:image/png;base64,{b64}"  # ← 关键：加 data URL 前缀
        })


class UploadImageGenericAPIView(GenericAPIView):
    serializer_class = UploadImageSerializer
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [
        authentication.SessionAuthentication,
        JWTAuthentication
    ]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        file = serializer.validated_data['image']
        name = default_storage.save(file.name, file)
        url = request.build_absolute_uri(default_storage.url(name))

        return Response({
            'code': 'ok',
            'url': url,
            'text': file.name
        })

class PasswordResetRequestAPIView(GenericAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []      # ← important: no SessionAuth (no CSRF)
    serializer_class = PasswordResetRequestSerializer

    def post(self, request):
        s = self.get_serializer(data=request.data)
        s.is_valid(raise_exception=True)
        email = s.validated_data["email"]
        code = ''.join(random.sample(string.ascii_letters + string.digits, 4))
        cache.set(email, code, 300)
        send_mail("Password reset code", f"Your code is {code}", "admin@gmail.com", [email])
        return Response({"msg": "If the email exists, a reset code has been sent."})

class PasswordResetConfirmAPIView(GenericAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    serializer_class = PasswordResetConfirmSerializer

    def post(self, request):
        s = self.get_serializer(data=request.data)
        s.is_valid(raise_exception=True)
        user = s.validated_data["user"]
        user.set_password(s.validated_data["new_password"])
        user.save()
        cache.delete(s.validated_data["email"])
        return Response({"msg": "Password has been reset."})
    
class UserMeView(generics.RetrieveUpdateAPIView):
    # ★ 明确只用 JWT 认证（避免默认 SessionAuth 导致匿名 -> 403）
    serializer_class = UserMeSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get_object(self):
        return self.request.user
    

class UserOpsViewSet(mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    """
    提供以下路由（空前缀）：
    - GET  /user/<id>/              → 按 id 查看单个用户
    - GET  /user/<id>/detail/       → 按 id 查看单个用户的详细信息
    - GET  /user/me/                → 当前登录用户（简要）
    - GET  /user/detail/            → 当前用户详细（支持 fields/exclude）
    - PATCH /user/detail/           → 修改当前用户基础信息（username/email/first/last/phone）
    """
    queryset = User.objects.all().select_related('profile')
    serializer_class = UserDetailSerializer
    authentication_classes = [JWTAuthentication, SessionAuthentication]

    def get_permissions(self):
        # retrieve: 任何认证用户都可以查看其他用户的公开信息
        # detail_by_id: 需要管理员权限
        if self.action == 'detail_by_id':
            return [permissions.IsAdminUser()]
        # retrieve 和其他action都需要认证
        return [permissions.IsAuthenticated()]

    # 当前用户——简要
    @action(detail=False, methods=['get', 'patch'])
    def me(self, request):
        if request.method == 'GET':
            ser = UserMeSerializer(request.user, context={'request': request})
            return Response(ser.data)
        elif request.method == 'PATCH':
            ser = UserMeSerializer(request.user, data=request.data, partial=True, context={'request': request})
            ser.is_valid(raise_exception=True)
            ser.save()
            return Response(ser.data)
        ser = UserMeSerializer(request.user, context={'request': request})
        return Response(ser.data)

    # 当前用户——详细（GET 可裁剪字段，PATCH 可修改基础信息）
    @action(detail=False, methods=['get', 'patch'], url_path='detail', url_name='my-detail')
    def my_detail(self, request):
        user = request.user
        fields_q  = request.query_params.get('fields')
        exclude_q = request.query_params.get('exclude')
        fields  = [s.strip() for s in fields_q.split(',')] if fields_q else None
        exclude = [s.strip() for s in exclude_q.split(',')] if exclude_q else None

        if request.method == 'GET':
            ser = UserDetailSerializer(user, context={'request': request},
                                       fields=fields, exclude=exclude)
            return Response(ser.data)

        ser = UserDetailSerializer(user, data=request.data, partial=True,
                                   context={'request': request})
        ser.is_valid(raise_exception=True)
        ser.save()
        return Response(ser.data)

    # 指定 id —— 详细
    @action(detail=True, methods=['get'], url_path='detail', url_name='detail-by-id')
    def detail_by_id(self, request, pk=None):
        obj = self.get_object()  # 按 pk 取用户
        ser = UserDetailSerializer(obj, context={'request': request})
        return Response(ser.data)


class NotificationViewSet(viewsets.ModelViewSet):
    """用户通知 API - 获取当前用户的所有通知"""
    serializer_class = NotificationSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]  # 需要认证
    http_method_names = ['get', 'post', 'patch', 'delete', 'head', 'options']
    pagination_class = pagination.PageNumberPagination
    
    def initial(self, request, *args, **kwargs):
        import logging
        logger = logging.getLogger('django')
        logger.warning(f"[NotificationViewSet] 请求: {request.method} {request.path}")
        logger.warning(f"[NotificationViewSet] Authorization header: {request.META.get('HTTP_AUTHORIZATION', 'MISSING')[:50] if request.META.get('HTTP_AUTHORIZATION') else 'MISSING'}")
        logger.warning(f"[NotificationViewSet] User before auth: {request.user}")
        super().initial(request, *args, **kwargs)
        logger.warning(f"[NotificationViewSet] User after auth: {request.user}")
    
    def get_queryset(self):
        # 只返回当前用户的通知
        # 如果request.user是匿名用户，返回空
        if not self.request.user or not self.request.user.is_authenticated:
            return Notification.objects.none()
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')
    
    def get_object(self):
        # 确保用户只能访问自己的通知
        obj = super().get_object()
        if not self.request.user.is_authenticated or obj.user != self.request.user:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('You do not have permission to access this notification.')
        return obj
    
    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """获取未读通知数"""
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return Response({'unread_count': count})
    
    @action(detail=False, methods=['get'])
    def unread(self, request):
        """获取所有未读通知"""
        notifications = Notification.objects.filter(user=request.user, is_read=False)
        serializer = self.get_serializer(notifications, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def mark_all_as_read(self, request):
        """标记所有通知为已读"""
        from django.utils import timezone
        Notification.objects.filter(user=request.user, is_read=False).update(
            is_read=True,
            read_at=timezone.now()
        )
        return Response({'message': 'All notifications marked as read'})
    
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """标记单个通知为已读"""
        from django.utils import timezone
        notification = self.get_object()
        notification.is_read = True
        notification.read_at = timezone.now()
        notification.save()
        return Response({'message': 'Notification marked as read'})

class AvatarViewSet(viewsets.ViewSet):
    """
    User avatar management
    - GET  /user/avatars/{user_id}/          - Get user avatar
    - GET  /user/avatars/{user_id}/default/  - Get default avatar (initials)
    - POST /user/avatars/upload/              - Upload custom avatar
    - DELETE /user/avatars/delete/            - Delete custom avatar (revert to default)
    """
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [JWTAuthentication]

    @action(detail=False, methods=['post'], url_path='upload', url_name='upload-avatar')
    def upload_avatar(self, request):
        """Upload a custom avatar for current user"""
        if 'avatar' not in request.FILES:
            return Response(
                {'error': 'No avatar file provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        avatar_file = request.FILES['avatar']
        user = request.user
        
        # Validate file size (max 5MB)
        if avatar_file.size > 5 * 1024 * 1024:
            return Response(
                {'error': 'Avatar file too large (max 5MB)'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate file type
        valid_extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp']
        file_ext = avatar_file.name.split('.')[-1].lower()
        if file_ext not in valid_extensions:
            return Response(
                {'error': f'Invalid file type. Allowed: {", ".join(valid_extensions)}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Save avatar
            user.profile.avatar = avatar_file
            user.profile.save()
            
            serializer = UserMeSerializer(user)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {'error': f'Failed to upload avatar: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'], url_path='delete', url_name='delete-avatar')
    def delete_avatar(self, request):
        """Delete custom avatar and revert to default"""
        user = request.user
        
        try:
            # Delete the custom avatar file
            if user.profile.avatar:
                user.profile.avatar.delete()
                user.profile.avatar = None
                user.profile.save()
            
            return Response(
                {'message': 'Avatar deleted, reverting to default'},
                status=status.HTTP_200_OK
            )
        except Exception as e:
            return Response(
                {'error': f'Failed to delete avatar: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'], url_path='reset', url_name='reset-avatar')
    def reset_to_default(self, request):
        """Reset to default avatar"""
        user = request.user
        
        try:
            from .avatar_utils import generate_default_avatar
            
            # Delete existing custom avatar
            if user.profile.avatar:
                user.profile.avatar.delete()
            
            # Generate and save default avatar
            default_avatar = generate_default_avatar(user.username)
            user.profile.avatar.save(
                f'{user.username}_avatar.png',
                default_avatar,
                save=True
            )
            
            serializer = UserMeSerializer(user)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {'error': f'Failed to reset avatar: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class FriendshipViewSet(viewsets.ModelViewSet):
    """好友管理 API"""
    serializer_class = FriendshipSerializer
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [JWTAuthentication]
    
    def get_queryset(self):
        user = self.request.user
        # 返回与当前用户相关的所有好友关系
        return Friendship.objects.filter(
            Q(from_user=user) | Q(to_user=user)
        )
    
    @action(detail=False, methods=['post'])
    def add_friend(self, request):
        """添加好友"""
        user_id = request.data.get('user_id')
        if not user_id:
            return Response({'error': '缺少user_id参数'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            target_user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'error': '用户不存在'}, status=status.HTTP_404_NOT_FOUND)
        
        if target_user == request.user:
            return Response({'error': '不能添加自己为好友'}, status=status.HTTP_400_BAD_REQUEST)
        
        # 检查是否已存在好友关系
        friendship = Friendship.objects.filter(
            Q(from_user=request.user, to_user=target_user) |
            Q(from_user=target_user, to_user=request.user)
        ).first()
        
        if friendship:
            serializer = self.get_serializer(friendship)
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        # 创建新的好友请求
        friendship = Friendship.objects.create(
            from_user=request.user,
            to_user=target_user,
            status='pending'
        )
        # Signal会自动创建通知，无需在这里重复创建
        
        serializer = self.get_serializer(friendship)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        """接受好友请求"""
        from apps.user.models import PrivateMessage, Notification
        
        friendship = self.get_object()
        if friendship.to_user != request.user:
            return Response({'error': '只有接收者能接受好友请求'}, status=status.HTTP_403_FORBIDDEN)
        
        friendship.status = 'accepted'
        friendship.save()
        
        # 将相关的好友请求通知标记为已读
        Notification.objects.filter(
            friendship=friendship,
            notification_type='friend_request'
        ).update(is_read=True)
        
        # 创建系统消息：为两边创建相同内容的系统消息
        message_content = 'We are now friends, you can start chatting!'
        
        # 为发送者创建一条
        PrivateMessage.objects.create(
            sender=friendship.from_user,
            recipient=request.user,
            content=message_content,
            is_system=True
        )
        
        # 为接收者创建一条（内容相同）
        PrivateMessage.objects.create(
            sender=request.user,
            recipient=friendship.from_user,
            content=message_content,
            is_system=True
        )
        
        serializer = self.get_serializer(friendship)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """拒绝好友请求"""
        from apps.user.models import Notification
        
        friendship = self.get_object()
        if friendship.to_user != request.user:
            return Response({'error': '只有接收者能拒绝好友请求'}, status=status.HTTP_403_FORBIDDEN)
        
        friendship.status = 'blocked'
        friendship.save()
        
        # 将相关的好友请求通知标记为已读
        Notification.objects.filter(
            friendship=friendship,
            notification_type='friend_request'
        ).update(is_read=True)
        
        serializer = self.get_serializer(friendship)
        return Response(serializer.data)
    
    def destroy(self, request, pk=None):
        """删除好友"""
        friendship = self.get_object()
        
        # 检查当前用户是否与此好友有关系
        if friendship.from_user != request.user and friendship.to_user != request.user:
            return Response({'error': '你无权删除此好友关系'}, status=status.HTTP_403_FORBIDDEN)
        
        # 删除好友关系
        friendship.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    @action(detail=False, methods=['get'])
    def check_friendship(self, request):
        """检查与某用户的好友关系"""
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response({'error': '缺少user_id参数'}, status=status.HTTP_400_BAD_REQUEST)
        
        friendship = Friendship.objects.filter(
            Q(from_user=request.user, to_user_id=user_id) |
            Q(from_user_id=user_id, to_user=request.user)
        ).first()
        
        if not friendship:
            return Response({'status': None})
        
        serializer = self.get_serializer(friendship)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def list_friends(self, request):
        """获取当前用户的所有好友列表"""
        # 获取所有状态为'accepted'的好友关系
        friendships = Friendship.objects.filter(
            (Q(from_user=request.user) | Q(to_user=request.user)) &
            Q(status='accepted')
        )
        
        # 提取好友用户对象
        friends = []
        for friendship in friendships:
            friend = friendship.to_user if friendship.from_user == request.user else friendship.from_user
            avatar_url = None
            
            # 获取 userprofile 和 avatar (使用 related_name 'profile')
            if hasattr(friend, 'profile') and friend.profile.avatar:
                avatar_url = friend.profile.avatar.url
                # 转换相对路径为绝对URL
                if avatar_url.startswith('/'):
                    avatar_url = request.build_absolute_uri(avatar_url)
            
            friends.append({
                'id': friend.id,
                'friendship_id': friendship.id,  # 添加friendship_id用于删除好友
                'username': friend.username,
                'email': friend.email,
                'avatar': avatar_url,
            })
        
        # 分页
        page = request.query_params.get('page', 1)
        page_size = int(request.query_params.get('page_size', 20))
        from django.core.paginator import Paginator
        paginator = Paginator(friends, page_size)
        page_obj = paginator.get_page(page)
        
        return Response({
            'count': len(friends),
            'results': page_obj.object_list,
            'page_size': page_size,
            'total_pages': paginator.num_pages,
        })

    @action(detail=False, methods=['get'])
    def search_users(self, request):
        """搜索用户（用于添加好友）"""
        query = request.query_params.get('q', '').strip()
        if not query:
            return Response({'error': '缺少搜索关键词'}, status=status.HTTP_400_BAD_REQUEST)
        
        if len(query) < 2:
            return Response({'error': '搜索关键词至少需要2个字符'}, status=status.HTTP_400_BAD_REQUEST)
        
        # 搜索用户名或email包含关键词的用户，排除当前用户
        users = User.objects.filter(
            Q(username__icontains=query) | Q(email__icontains=query)
        ).exclude(id=request.user.id)[:20]  # 限制最多返回20条
        
        results = []
        for user in users:
            avatar_url = None
            if hasattr(user, 'profile') and user.profile and user.profile.avatar:
                avatar_url = user.profile.avatar.url
                if avatar_url.startswith('/'):
                    avatar_url = request.build_absolute_uri(avatar_url)
            
            # 检查好友关系
            friendship = Friendship.objects.filter(
                Q(from_user=request.user, to_user=user) |
                Q(from_user=user, to_user=request.user)
            ).first()
            
            friendship_status = None
            friendship_id = None
            is_sent_by_me = False
            if friendship:
                friendship_status = friendship.status
                friendship_id = friendship.id
                is_sent_by_me = friendship.from_user == request.user
            
            results.append({
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'avatar': avatar_url,
                'friendship_status': friendship_status,
                'friendship_id': friendship_id,
                'is_sent_by_me': is_sent_by_me,
            })
        
        return Response({
            'count': len(results),
            'results': results,
        })


class PrivateMessageViewSet(viewsets.ModelViewSet):
    """私信管理 API"""
    serializer_class = PrivateMessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [JWTAuthentication]
    http_method_names = ['get', 'post', 'patch', 'delete', 'head', 'options']
    
    def get_queryset(self):
        user = self.request.user
        # 返回当前用户收到或发送的所有消息
        return PrivateMessage.objects.filter(
            Q(sender=user) | Q(recipient=user)
        ).order_by('-created_at')
    
    def create(self, request, *args, **kwargs):
        """发送私信"""
        recipient_id = request.data.get('recipient_id')
        content = request.data.get('content')
        
        if not recipient_id or not content:
            return Response({'error': '缺少recipient_id或content'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            recipient = User.objects.get(id=recipient_id)
        except User.DoesNotExist:
            return Response({'error': '接收者不存在'}, status=status.HTTP_404_NOT_FOUND)
        
        # 检查是否为好友或者检查非好友消息数量
        friendship = Friendship.objects.filter(
            Q(from_user=request.user, to_user=recipient, status='accepted') |
            Q(from_user=recipient, to_user=request.user, status='accepted')
        ).first()
        
        if not friendship:
            # 非好友关系，检查消息数量限制
            message_count = PrivateMessage.objects.filter(
                sender=request.user,
                recipient=recipient,
                created_at__date=date.today()
            ).count()
            
            if message_count >= 3:
                return Response(
                    {'error': '今日给陌生人的消息已达上限(3条)'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        message = PrivateMessage.objects.create(
            sender=request.user,
            recipient=recipient,
            content=content
        )
        serializer = self.get_serializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=False, methods=['get'])
    def conversation(self, request):
        """获取与某用户的对话"""
        from django.utils import timezone
        
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response({'error': '缺少user_id参数'}, status=status.HTTP_400_BAD_REQUEST)
        
        messages = PrivateMessage.objects.filter(
            Q(sender=request.user, recipient_id=user_id) |
            Q(sender_id=user_id, recipient=request.user)
        ).order_by('created_at')  # 按升序排列，最新的消息在最后
        
        # 自动将对方发给我的未读消息标记为已读
        PrivateMessage.objects.filter(
            sender_id=user_id,
            recipient=request.user,
            is_read=False
        ).update(is_read=True, read_at=timezone.now())
        
        serializer = self.get_serializer(messages, many=True, context={'request': request})
        return Response({
            'results': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """标记消息为已读"""
        message = self.get_object()
        if message.recipient != request.user:
            return Response({'error': '只有接收者能标记消息为已读'}, status=status.HTTP_403_FORBIDDEN)
        
        from django.utils import timezone
        message.is_read = True
        message.read_at = timezone.now()
        message.save()
        serializer = self.get_serializer(message)
        return Response(serializer.data)


from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt


@csrf_exempt
@require_http_methods(["GET", "OPTIONS"])
def test_notifications_view(request):
    """测试通知 API - 使用纯 Django View，跳过所有 DRF 权限检查"""
    if request.method == 'OPTIONS':
        response = JsonResponse({'message': 'OK'})
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
        return response
    
    return JsonResponse({
        'message': 'Test endpoint works with pure Django View!',
        'path': request.path,
        'auth_header': request.META.get('HTTP_AUTHORIZATION', 'NO HEADER'),
        'timestamp': str(__import__('django.utils.timezone', fromlist=['now']).now())
    })


@csrf_exempt
@require_http_methods(["GET", "OPTIONS"])
def notifications_view(request):
    """通知列表 API - 使用纯 Django View"""
    import logging
    logger = logging.getLogger('django')
    logger.warning(f"[notifications_view] 被调用！Method: {request.method}")
    
    if request.method == 'OPTIONS':
        response = JsonResponse({'message': 'OK'})
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
        response['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
        return response
    
    # 验证 token
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    logger.warning(f"[notifications_view] Authorization header: {auth_header[:50] if auth_header else 'MISSING'}")
    
    if not auth_header.startswith('Bearer '):
        logger.warning(f"[notifications_view] 返回 401 - 无 Bearer token")
        return JsonResponse({'error': 'No auth'}, status=401)
    
    token = auth_header[7:]
    try:
        from rest_framework_simplejwt.tokens import AccessToken
        validated_token = AccessToken(token)
        user_id = validated_token['user_id']
        logger.warning(f"[notifications_view] 验证 token 成功，user_id={user_id}")
        from django.contrib.auth import get_user_model
        User = get_user_model()
        user = User.objects.get(id=user_id)
        logger.warning(f"[notifications_view] 找到用户: {user.username}")
    except Exception as e:
        logger.error(f"[notifications_view] Token 验证失败: {str(e)}", exc_info=True)
        return JsonResponse({'error': f'Invalid token: {str(e)}'}, status=401)
    
    # 获取通知
    from apps.user.models import Notification
    from apps.user.serializer import NotificationSerializer
    from django.core.paginator import Paginator
    
    # 分页处理
    page = request.GET.get('page', 1)
    page_size = request.GET.get('page_size', 10)
    
    all_notifications = Notification.objects.filter(user=user).order_by('-created_at')
    paginator = Paginator(all_notifications, page_size)
    
    try:
        page_obj = paginator.page(page)
    except:
        page_obj = paginator.page(1)
    
    # 使用序列化器
    serializer = NotificationSerializer(page_obj.object_list, many=True)
    
    data = {
        'count': paginator.count,
        'next': f'/user/notifications/?page={page_obj.next_page_number()}&page_size={page_size}' if page_obj.has_next() else None,
        'previous': f'/user/notifications/?page={page_obj.previous_page_number()}&page_size={page_size}' if page_obj.has_previous() else None,
        'results': serializer.data
    }
    
    return JsonResponse(data)


class TestNotificationsView(APIView):
    """测试通知 API - 最简单的实现，用于诊断问题"""
    authentication_classes = []
    permission_classes = [permissions.AllowAny]  # 明确设置为 AllowAny
    
    def get(self, request):
        return Response({
            'message': 'Test endpoint works!',
            'path': request.path,
            'auth_header': request.META.get('HTTP_AUTHORIZATION', 'NO HEADER'),
            'timestamp': str(__import__('django.utils.timezone', fromlist=['now']).now())
        })


class NotificationsListView(APIView):
    """通知列表 API - 获取当前用户的所有通知"""
    authentication_classes = []
    permission_classes = [permissions.AllowAny]  # 明确设置为 AllowAny
    
    def get(self, request):
        import logging
        logger = logging.getLogger(__name__)
        logger.info("=== NotificationsListView.get() called ===")
        logger.info(f"Authorization header: {request.META.get('HTTP_AUTHORIZATION', 'MISSING')}")
        
        try:
            # 手动验证 JWT token
            auth_header = request.META.get('HTTP_AUTHORIZATION', '')
            
            if not auth_header.startswith('Bearer '):
                logger.warning("No valid Authorization header")
                return Response(
                    {'error': 'Authentication credentials were not provided.'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            token = auth_header[7:]
            from rest_framework_simplejwt.tokens import AccessToken
            try:
                validated_token = AccessToken(token)
                user_id = validated_token['user_id']
                from django.contrib.auth import get_user_model
                User = get_user_model()
                user = User.objects.get(id=user_id)
                logger.info(f"Token validated for user: {user.username}")
            except Exception as e:
                logger.error(f"Token validation failed: {str(e)}")
                return Response(
                    {'error': f'Invalid token: {str(e)}'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # 获取当前用户的通知，按创建时间倒序
            notifications = Notification.objects.filter(user=user).order_by('-created_at')
            logger.info(f"Found {notifications.count()} notifications for user {user.username}")
            
            # 分页处理
            page = request.query_params.get('page', 1)
            page_size = request.query_params.get('page_size', 10)
            
            from django.core.paginator import Paginator
            paginator = Paginator(notifications, int(page_size))
            
            try:
                page_obj = paginator.page(int(page))
            except Exception:
                page_obj = paginator.page(1)
            
            serializer = NotificationSerializer(page_obj.object_list, many=True)
            
            return Response({
                'count': paginator.count,
                'next': f'?page={page_obj.next_page_number()}' if page_obj.has_next() else None,
                'previous': f'?page={page_obj.previous_page_number()}' if page_obj.has_previous() else None,
                'results': serializer.data,
            })
        except Notification.DoesNotExist:
            return Response({
                'count': 0,
                'next': None,
                'previous': None,
                'results': [],
            })
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f'Error in NotificationsListView: {str(e)}', exc_info=True)
            return Response(
                {'error': f'Internal server error: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
