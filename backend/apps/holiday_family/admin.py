from django.contrib import admin
from django.utils.html import format_html
from .models import HolidayFamilyApplication, HolidayFamilyPhoto


class HolidayFamilyPhotoInline(admin.TabularInline):
    model = HolidayFamilyPhoto
    extra = 0
    fields = ['photo']
    readonly_fields = ['photo']


@admin.register(HolidayFamilyApplication)
class HolidayFamilyApplicationAdmin(admin.ModelAdmin):
    list_display = ['full_name', 'email', 'phone', 'city', 'status_badge', 'created_at']
    list_filter = ['status', 'can_take_dogs', 'can_take_cats', 'can_take_rabbits', 'created_at']
    search_fields = ['full_name', 'email', 'city', 'country']
    readonly_fields = ['created_at', 'updated_at']
    inlines = [HolidayFamilyPhotoInline]
    
    fieldsets = (
        ('Personal Information', {
            'fields': ('full_name', 'email', 'phone')
        }),
        ('Address', {
            'fields': ('country', 'state', 'city', 'street_address', 'postal_code')
        }),
        ('Pet Information', {
            'fields': ('pet_count', 'can_take_dogs', 'can_take_cats', 'can_take_rabbits', 'can_take_others')
        }),
        ('Application Details', {
            'fields': ('motivation', 'introduction')
        }),
        ('Documents', {
            'fields': ('id_document',)
        }),
        ('Agreement', {
            'fields': ('terms_agreed',)
        }),
        ('Status & Dates', {
            'fields': ('status', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def status_badge(self, obj):
        colors = {
            'pending': '#FFA500',
            'approved': '#008000',
            'rejected': '#FF0000',
        }
        color = colors.get(obj.status, '#808080')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px;">{}</span>',
            color,
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'
    
    def has_delete_permission(self, request, obj=None):
        # 只有超级用户可以删除
        return request.user.is_superuser


@admin.register(HolidayFamilyPhoto)
class HolidayFamilyPhotoAdmin(admin.ModelAdmin):
    list_display = ['application', 'photo_preview', 'uploaded_at']
    list_filter = ['uploaded_at']
    search_fields = ['application__full_name']
    readonly_fields = ['photo_preview', 'uploaded_at']
    
    def photo_preview(self, obj):
        if obj.photo:
            return format_html(
                '<img src="{}" style="max-width: 200px; max-height: 200px;" />',
                obj.photo.url
            )
        return 'No photo'
    photo_preview.short_description = 'Preview'
