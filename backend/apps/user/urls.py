from django.urls import path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    TokenVerifyView,
)
from collections import OrderedDict
from rest_framework.reverse import reverse
from . import views
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
app_name = 'user'

# 用户路由
router = DefaultRouter()
router.register(r'', views.UserViewSet, basename='user-list')

# 通知路由在 user_router 中注册

class UserDefaultRouter(DefaultRouter):
    permission_classes = [AllowAny]
    authentication_classes = []

    def __init__(self, root_name='User', root_description='The default basic root view for user router'):
        super().__init__()
        self._root_name = root_name
        self._root_desc = root_description

    def get_api_root_view(self, **kwargs):
        view = super().get_api_root_view(**kwargs)
        view.cls.__name__ = self._root_name
        view.cls.__doc__  = self._root_desc

        # original_get = view.cls().get  # 缓存原 get

        # def patched_get(self, request, *args, **kw):
        #     resp = original_get(self, request, *args, **kw)
        #     if isinstance(resp.data, dict):
        #         # 追加当前用户接口链接（需要已注册 basename='user-ops'）
        #         extra = OrderedDict()
        #         extra['detail'] = reverse('user:user-ops-detail', request=request)
        #         extra['me']     = reverse('user:user-ops-me',     request=request)
        #         # 把 extra 合并到现有 Root JSON 的末尾
        #         resp.data.update(extra)
        #     return resp

        # view.cls.get = patched_get
        return view
    
class UserRootAPIView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get_view_name(self):         # 页眉
        return 'User'
    def get_view_description(self, html=False):   # 副标题
        return 'The default basic root view for user router'

    def get(self, request):
        base = request.build_absolute_uri('/user/')
        data = OrderedDict([
            ('register', reverse('user:register-list',   request=request)),
            ('list',     reverse('user:user-list-list',  request=request)),
            # ↓ 这两行是你要的“模板链接”
            ('userinfo', f'{base}<id>/'),
            # ('detail',   f'{base}<id>/detail/'),
            # # 也顺便把“当前用户”的两个接口列出来（可选）
            # ('me',       reverse('user:user-me',         request=request)
            #              if 'user:user-me' in request.resolver_match.namespaces
            #              else reverse('user:user-me',    request=request)),
            # ('my_detail', reverse('user:user-my-detail', request=request)),
        ])
        return Response(data)
    
user_router = DefaultRouter()
user_router.register('register', views.RegisterViewSet, basename='register')
user_router.register('userinfo', views.UserInfoViewSet, basename='userinfo')
user_router.register('list',      views.UserListViewSet,basename='user-list')
user_router.register('avatars',   views.AvatarViewSet, basename='avatar')
user_router.register('friendships', views.FriendshipViewSet, basename='friendship')
user_router.register('messages',    views.PrivateMessageViewSet, basename='message')
user_router.register('notifications', views.NotificationViewSet, basename='notification')
# ⚠️ 注意：UserOpsViewSet 的空前缀会生成 catch-all 模式 `^(?P<pk>[^/.]+)/$`
# 所以需要将所有特殊路径（如 notifications）放在它之前
user_router.register('',         views.UserOpsViewSet,  basename='user')
urlpatterns = [
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    path(
        'send_email_code/',
        views.SendEmailCodeGenericAPIView.as_view(),
        name='send_email_code'
    ),
    path(
        'verify_email_code/',
        views.VerifyEmailCodeGenericAPIView.as_view(),
        name='verify_email_code'
    ),
    path(
        'captcha/',
        views.CaptchaGenericAPIView.as_view(),
        name='captcha'
    ),
    path(
        'upload_image/',
        views.UploadImageGenericAPIView.as_view(),
        name='upload_image'
    ),
    path(
        'password/reset/confirm/',
        views.PasswordResetConfirmAPIView.as_view(),
        name='pwd_reset_confirm'
    ),
    path(
        'password/reset/request/',
        views.PasswordResetRequestAPIView.as_view(),
        name='pwd_reset_request'
    ),
    path(
        'me/',
        views.UserMeView.as_view(),
        name='user-me'
    ),
    # 测试端点 - 纯 Django View
    path(
        'test-notifications/',
        views.test_notifications_view,
        name='test-notifications'
    ),
    path(
        '',
        UserRootAPIView.as_view(),
        name='api-root'
    ),
    # Router URLs 必须在最后（包括 NotificationViewSet）
    *user_router.urls,
]
