"""
URL configuration for server project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from apps.pet.views import LostGeoViewSet 
from rest_framework.routers import DefaultRouter
from django.http import FileResponse
import os

router = DefaultRouter()
router.register(r"pet/lost_geo", LostGeoViewSet, basename="lost-geo")

def serve_media_with_cache_control(request, path):
    """Serve media files with no-cache headers to prevent image caching"""
    full_path = os.path.join(settings.MEDIA_ROOT, path)
    if not os.path.isfile(full_path):
        from django.http import Http404
        raise Http404(f"File not found: {path}")
    
    response = FileResponse(open(full_path, 'rb'))
    response['Cache-Control'] = 'no-cache, no-store, must-revalidate, max-age=0'
    response['Pragma'] = 'no-cache'
    response['Expires'] = '0'
    response['ETag'] = None  # 移除ETag以强制重新验证
    response['Last-Modified'] = None
    return response

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('api.urls')),
    path('blog/', include('apps.blog.urls')),
    path('holiday-family/', include('apps.holiday_family.urls')),
    # path('user/', include('apps.user.urls')),  # Already included in api.urls as api/user/
    # path("pet/", include("apps.pet.urls")),
    path('api-auth/', include('rest_framework.urls', namespace='rest_framework')),
    path("chaining/", include("smart_selects.urls")),
    *static(settings.STATIC_URL, document_root=settings.STATIC_ROOT),
]

if settings.DEBUG:
    # 为媒体文件添加缓存控制头，防止浏览器缓存导致头像更新不显示
    urlpatterns += [
        path('media/<path:path>', serve_media_with_cache_control),
    ]
