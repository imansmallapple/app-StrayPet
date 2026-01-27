from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User
from .models import UserProfile, ViewStatistics


# 在 User 管理中显示和编辑手机号
class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False
    verbose_name_plural = 'Profile'
    fk_name = 'user'


class UserAdmin(BaseUserAdmin):
    inlines = (UserProfileInline, )

    # 自定义列表显示字段
    list_display = ('username', 'email', 'first_name', 'last_name', 'phone', 'is_staff')

    # 通过 profile 取手机号
    def phone(self, obj):
        return getattr(obj.profile, 'phone', '')
    phone.short_description = 'Phone'
    phone.admin_order_field = 'profile__phone'

    # 支持搜索手机号
    search_fields = ('username', 'email', 'first_name', 'last_name', 'profile__phone')


# 取消默认 User 注册，再注册改写版
admin.site.unregister(User)
admin.site.register(User, UserAdmin)

# 保留你原本的 ViewStatistics 注册
@admin.register(ViewStatistics)
class ViewStatisticsAdmin(admin.ModelAdmin):
    list_display = ('content_type', 'object_id', 'date', 'count')
    list_filter = ('content_type', 'date')
    search_fields = ('object_id',)
