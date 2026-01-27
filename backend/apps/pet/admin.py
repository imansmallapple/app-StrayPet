# apps/pet/admin.py
from django.contrib import admin, messages
from django.utils.html import format_html
from .models import Pet, Adoption, DonationPhoto, Donation, Country, Region, City, Address, Lost, PetPhoto, Shelter, Ticket, HolidayFamily
from django import forms

class AddressAdminForm(forms.ModelForm):
    class Meta:
        model = Address
        fields = "__all__"


class PetPhotoInline(admin.TabularInline):
    model = PetPhoto
    extra = 1
    fields = ("image", "order")


@admin.register(Pet)
class PetAdmin(admin.ModelAdmin):
    list_display = ("id", "thumb", "name", "species", "breed", "status", "formatted_address", "created_by", "add_date")
    readonly_fields = ("preview",)
    list_filter = ("status", "species", "add_date")
    search_fields = ("name", "species", "breed", "description", "address")
    autocomplete_fields = ("created_by",)
    inlines = [PetPhotoInline]
    fields = (
        "name", "species", "breed", "sex", "age_years", "age_months", "description",
        "address", "cover", "status", "created_by"
    )

    def addr(self, obj):
        # 若你引入了 Address 外键
        if hasattr(obj, "address") and obj.address:
            return str(obj.address)
        # 兼容老数据
        return getattr(obj, "location", "") or "—"

    addr.short_description = "Location / Address"

    def thumb(self, obj):
        if obj.cover:
            return format_html(
                '<img src="{}" style="height:60px;width:60px;object-fit:cover;border-radius:6px;" />',
                obj.cover.url
            )
        return "—"

    thumb.short_description = "Photo"

    def formatted_address(self, obj):
        if not obj.address:
            return "-"
        parts = [
            obj.address.street,
            obj.address.building_number,
            obj.address.city.name if obj.address.city_id else "",
            obj.address.region.name if obj.address.region_id else "",
            obj.address.country.name if obj.address.country_id else "",
            obj.address.postal_code,
        ]
        # 用 <br> 换行
        lines = [p for p in parts if p]
        return format_html("<br>".join(lines))

    formatted_address.short_description = "Address"

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        formfield = super().formfield_for_foreignkey(db_field, request, **kwargs)
        if db_field.name in ("country", "region", "city"):
            w = formfield.widget
            w.can_add_related = False
            w.can_change_related = False
            w.can_delete_related = False
            w.can_view_related = False
        return formfield

    def preview(self, obj):
        url = obj.cover.url if obj and obj.cover else ""
        # 无图时也渲染一个隐藏的 img，方便 JS 直接改它的 src
        display = "block" if url else "none"
        return format_html(
            '<img id="cover-preview" src="{}" style="max-height:240px;border-radius:8px;display:{};" />',
            url, display
        )

    preview.short_description = "Preview"

    class Media:
        # 静态文件路径相对于 STATIC_URL
        js = ("pet/preview.js",)


@admin.register(Adoption)
class AdoptionApplicationAdmin(admin.ModelAdmin):
    list_display = ("id", "pet", "applicant", "status", "add_date")
    list_filter = ("status", "add_date")
    search_fields = ("message", "pet__name", "applicant__username")
    autocomplete_fields = ("pet", "applicant")


class DonationPhotoInline(admin.TabularInline):
    model = DonationPhoto
    extra = 0
    readonly_fields = ("preview",)
    fields = ("preview", "image")


@admin.register(Donation)
class DonationAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "species", "sex", "donor", "status", "created_pet", "add_date")
    list_filter = ("status", "species", "sex", "add_date")
    search_fields = ("name", "species", "breed", "donor__username")
    inlines = [DonationPhotoInline]
    readonly_fields = ("created_pet",)  # Create temp pet to avoid polluting pet pool
    exclude = ("reviewer",)
    actions = ["approve_and_create_pet", "close_donation"]
    autocomplete_fields = ()
    fields = (
        # 你的 Donation 基本字段...
        "name", "species", "breed", "sex", "age_years", "age_months", "description",
        "address",  # ← 新增：结构化地址（点击进入地址创建/选择页）
        "status", "created_pet", "donor"
    )

    def save_model(self, request, obj, form, change):
        # 如果当前用户是管理员（is_staff），并且 reviewer 还没填，则写入
        if request.user.is_staff and not obj.reviewer:
            obj.reviewer = request.user
        # 检测“状态是否从 非approved -> approved”
        to_approved = False
        if change:
            prev = Donation.objects.get(pk=obj.pk)
            to_approved = (prev.status != "approved" and obj.status == "approved")

        super().save_model(request, obj, form, change)

        # 触发创建 Pet（仅当尚未创建过）
        if to_approved and not obj.created_pet:
            obj.approve(reviewer=request.user, note="Approved in admin (edit form)")

    def has_change_permission(self, request, obj=None):
        if obj and obj.status == "closed":
            return False  # 关闭后彻底不可编辑
        return super().has_change_permission(request, obj)


@admin.action(description="Review pass and create pet")
def approve_and_create_pet(modeladmin, request, queryset):
    ok, fail = 0, 0
    for d in queryset:
        try:
            d.approve(reviewer=request.user, note="Approved in admin")
            ok += 1
        except Exception as e:
            fail += 1
    messages.info(request, f"Finish: Pass {ok} time(s); Fail {fail} time(s)")


@admin.action(description="Close donation (lock editing)")
def close_donation(modeladmin, request, queryset):
    updated = queryset.exclude(status="closed").update(status="closed")
    messages.info(request, f"Closed {updated} item(s).")


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    form = AddressAdminForm
    list_display = ("__str__", "postal_code", "location")
    list_select_related = ("city", "region", "country")
    # ⭐ 必须有 search_fields，供其他 Admin 的 autocomplete 使用
    search_fields = (
        "street", "building_number", "postal_code",
        "city__name", "region__name", "country__name",
    )


@admin.register(Lost)
class LostAdmin(admin.ModelAdmin):
    list_display = (
        'id', 'thumb', 'pet_name', 'species', 'breed', 'color', 'status',
        'city_name', 'region_name', 'country_name',
        'reporter', 'created_at'
    )
    list_filter = ('status', 'species', 'address__region', 'address__country', 'created_at')
    search_fields = (
        'pet_name', 'breed', 'color',
        'address__city__name', 'address__region__name', 'address__country__name',
        'reporter__username', 'reporter__email'
    )
    exclude = ('pet',)
    autocomplete_fields = ('address', 'reporter')
    readonly_fields = ('created_at', 'updated_at')
    date_hierarchy = 'created_at'

    def thumb(self, obj):
        if obj.photo:
            return format_html('<img src="{}" style="height:45px;border-radius:6px;" />', obj.photo.url)
        return '—'

    thumb.short_description = "Photo"

    def country_name(self, obj):
        return obj.address.country.name if obj.address_id and obj.address.country_id else ""

    country_name.short_description = "Country"

    def region_name(self, obj):
        return obj.address.region.name if obj.address_id and obj.address.region_id else ""

    region_name.short_description = "Region"

    def city_name(self, obj):
        return obj.address.city.name if obj.address_id and obj.address.city_id else ""

    city_name.short_description = "City"


@admin.register(Shelter)
class ShelterAdmin(admin.ModelAdmin):
    list_display = (
        'id', 'logo_thumb', 'name', 'city_name', 'region_name', 'country_name',
        'capacity', 'current_animals', 'occupancy_display', 'is_verified', 'is_active', 'created_at'
    )
    list_filter = ('is_verified', 'is_active', 'address__country', 'address__region', 'created_at')
    search_fields = (
        'name', 'description', 'email', 'phone',
        'address__city__name', 'address__region__name', 'address__country__name'
    )
    autocomplete_fields = ('address', 'created_by')
    readonly_fields = ('created_at', 'updated_at', 'available_capacity', 'occupancy_rate')
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'description', 'logo', 'cover_image')
        }),
        ('Contact Information', {
            'fields': ('email', 'phone', 'website', 'address')
        }),
        ('Capacity & Statistics', {
            'fields': ('capacity', 'current_animals', 'available_capacity', 'occupancy_rate')
        }),
        ('Operation Details', {
            'fields': ('founded_year', 'is_verified', 'is_active')
        }),
        ('Social Media', {
            'fields': ('facebook_url', 'instagram_url', 'twitter_url'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def logo_thumb(self, obj):
        if obj.logo:
            return format_html('<img src="{}" style="height:45px;width:45px;object-fit:cover;border-radius:50%;" />', obj.logo.url)
        return '—'
    logo_thumb.short_description = "Logo"

    def country_name(self, obj):
        return obj.address.country.name if obj.address_id and obj.address.country_id else "—"
    country_name.short_description = "Country"

    def region_name(self, obj):
        return obj.address.region.name if obj.address_id and obj.address.region_id else "—"
    region_name.short_description = "Region"

    def city_name(self, obj):
        return obj.address.city.name if obj.address_id and obj.address.city_id else "—"
    city_name.short_description = "City"
    
    def occupancy_display(self, obj):
        if obj.capacity > 0:
            rate = obj.occupancy_rate
            color = '#28a745' if rate < 70 else '#ffc107' if rate < 90 else '#dc3545'
            return format_html(
                '<span style="color:{};">{:.1f}%</span>',
                color, rate
            )
        return '—'
    occupancy_display.short_description = "Occupancy"


@admin.register(Ticket)
class TicketAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "get_priority_display", "get_status_display", "get_category_display", "created_by", "assigned_to", "created_at")
    list_filter = ("status", "priority", "category", "created_at")
    search_fields = ("title", "description", "email", "phone")
    readonly_fields = ("created_at", "updated_at", "resolved_at", "created_by")
    autocomplete_fields = ("assigned_to",)
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'description', 'category')
        }),
        ('Contact Information', {
            'fields': ('email', 'phone', 'created_by')
        }),
        ('Status & Priority', {
            'fields': ('status', 'priority', 'assigned_to')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'resolved_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_priority_display(self, obj):
        colors = {
            'low': '#28a745',
            'medium': '#ffc107',
            'high': '#fd7e14',
            'urgent': '#dc3545',
        }
        color = colors.get(obj.priority, '#6c757d')
        return format_html(
            '<span style="color:{}; font-weight:bold;">{}</span>',
            color, obj.get_priority_display()
        )
    get_priority_display.short_description = "Priority"
    
    def get_status_display_colored(self, obj):
        colors = {
            'open': '#007bff',
            'in_progress': '#ffc107',
            'closed': '#6c757d',
            'resolved': '#28a745',
        }
        color = colors.get(obj.status, '#6c757d')
        return format_html(
            '<span style="color:white; background-color:{}; padding:3px 8px; border-radius:3px;">{}</span>',
            color, obj.get_status_display()
        )
    get_status_display_colored.short_description = "Status"

@admin.register(HolidayFamily)
class HolidayFamilyAdmin(admin.ModelAdmin):
    list_display = ('id', 'full_name', 'email', 'city', 'status_badge', 'applied_at', 'reviewed_by')
    list_filter = ('status', 'applied_at', 'pet_count')
    search_fields = ('full_name', 'email', 'city', 'phone', 'motivation')
    readonly_fields = ('user', 'applied_at', 'reviewed_at', 'status_badge_detail')
    autocomplete_fields = ('reviewed_by',)
    
    fieldsets = (
        ('Applicant Info', {
            'fields': ('user', 'full_name', 'email', 'phone')
        }),
        ('Location', {
            'fields': ('address', 'city')
        }),
        ('Pet Experience', {
            'fields': ('pet_count', 'pet_types')
        }),
        ('Motivation', {
            'fields': ('motivation',)
        }),
        ('Application Status', {
            'fields': ('status', 'terms_agreed', 'applied_at', 'reviewed_at', 'reviewed_by', 'review_notes')
        }),
    )
    
    def status_badge(self, obj):
        colors = {
            'pending': '#ffc107',
            'approved': '#28a745',
            'rejected': '#dc3545',
        }
        color = colors.get(obj.status, '#6c757d')
        return format_html(
            '<span style="background-color:{}; color:white; padding:4px 8px; border-radius:3px; font-weight:bold;">{}</span>',
            color, obj.get_status_display()
        )
    status_badge.short_description = 'Status'
    
    def status_badge_detail(self, obj):
        return self.status_badge(obj)
    status_badge_detail.short_description = 'Status'
    
    def get_readonly_fields(self, request, obj=None):
        if obj:  # Editing an existing object
            return self.readonly_fields + ['full_name', 'email', 'phone', 'address', 'city', 'pet_count', 'pet_types', 'motivation', 'terms_agreed']
        return self.readonly_fields