# apps/pet/models.py
from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from django.db import models
from django.contrib.auth import get_user_model
from django.utils.safestring import mark_safe
from smart_selects.db_fields import ChainedForeignKey

User = get_user_model()


class Pet(models.Model):
    SEX_CHOICES = (
        ("male", "Boy"),
        ("female", "Girl"),
    )

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"  # 草稿，仅发布者可见
        AVAILABLE = "available", "Available"  # 可申请/公开
        PENDING = "pending", "Pending"  # 处理中（比如有申请）
        ADOPTED = "adopted", "Adopted"  # 已被领养/转让
        ARCHIVED = "archived", "Archived"  # 下架/归档
        LOST = "lost", "Lost"

    name = models.CharField("Pet Name", max_length=80)
    species = models.CharField("Species", max_length=40)  # cat/dog/…
    breed = models.CharField("Breed", max_length=80, blank=True, default="")

    sex = models.CharField(
        "Sex",
        max_length=10,
        choices=SEX_CHOICES,
        default="male"
    )

    age_years = models.PositiveIntegerField("Age (years)", default=0)
    age_months = models.PositiveIntegerField("Age (months)", default=0)
    size = models.CharField("Size", max_length=20, blank=True, default="")  # small/medium/large/xlarge
    description = models.CharField("Description", max_length=300, blank=True, default="")
    
    # Health and traits
    dewormed = models.BooleanField("Dewormed", default=False)
    vaccinated = models.BooleanField("Vaccinated", default=False)
    microchipped = models.BooleanField("Microchipped", default=False)
    child_friendly = models.BooleanField("Child Friendly", default=False)
    trained = models.BooleanField("House Trained", default=False)
    loves_play = models.BooleanField("Loves to Play", default=False)
    loves_walks = models.BooleanField("Loves Walks", default=False)
    good_with_dogs = models.BooleanField("Good with Dogs", default=False)
    good_with_cats = models.BooleanField("Good with Cats", default=False)
    affectionate = models.BooleanField("Affectionate", default=False)
    needs_attention = models.BooleanField("Needs Attention", default=False)
    sterilized = models.BooleanField("Sterilized/Neutered", default=False)
    contact_phone = models.CharField("Contact Phone", max_length=30, blank=True, default="")
    
    address = models.ForeignKey(
        "pet.Address", on_delete=models.SET_NULL, null=True, blank=True, related_name="pets", verbose_name="Address"
    )
    shelter = models.ForeignKey(
        "pet.Shelter", on_delete=models.SET_NULL, null=True, blank=True, related_name="pets", verbose_name="Shelter"
    )
    cover = models.ImageField("Cover", upload_to="pets/", blank=True, null=True)

    status = models.CharField(
        "Status", max_length=20, choices=Status.choices,
        default=Status.AVAILABLE, db_index=True
    )
    created_by = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="pets", verbose_name="Owner"
    )

    add_date = models.DateTimeField("Created At", auto_now_add=True)
    pub_date = models.DateTimeField("Updated At", auto_now=True)

    class Meta:
        verbose_name = "Pet"
        verbose_name_plural = "Pets"
        ordering = ["-pub_date"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["species", "breed"]),
            models.Index(fields=["created_by"]),
        ]

    def __str__(self):
        return f"{self.name} ({self.species})"


# simple use case:
# when user submit application, if pet available, status change into pending
# when application approved, pet status change into adopted and close all other unclosed applications from this pet
# when application close or refused, if there is no other application, pet status change back to available
class Adoption(models.Model):
    STATUS_CHOICES = (
        ("submitted", "Submitted"),
        ("processing", "Processing"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
        ("closed", "Closed"),
    )

    pet = models.ForeignKey(Pet, on_delete=models.CASCADE, related_name="applications")
    applicant = models.ForeignKey(User, on_delete=models.CASCADE, related_name="pet_adoption")
    message = models.TextField("Message to Owner", blank=True, default="")
    status = models.CharField("Status", max_length=20, choices=STATUS_CHOICES, default="submitted", db_index=True)

    add_date = models.DateTimeField("Created At", auto_now_add=True)
    pub_date = models.DateTimeField("Updated At", auto_now=True)

    def clean(self):
        super().clean()
        if self.pet and self.pet.status == Pet.Status.LOST:
            raise ValidationError({"pet": "This pet is reported LOST and cannot be adopted."})

    class Meta:
        verbose_name = "Adoption"
        verbose_name_plural = "Adoptions"
        ordering = ["-pub_date"]
        indexes = [models.Index(fields=["pet", "status"]), models.Index(fields=["applicant", "status"])]

    def __str__(self):
        return f"{self.applicant} -> {self.pet} ({self.status})"


# todo: Reviewer默认设置为当前
class Donation(models.Model):
    STATUS_CHOICES = (
        ("submitted", "Submitted"),
        ("reviewing", "Reviewing"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
        ("closed", "Closed"),  # ← 新增
    )

    donor = models.ForeignKey(User, on_delete=models.CASCADE, related_name="pet_donor")

    # 基础信息（用于生成 Pet）
    name = models.CharField("Pet Name", max_length=80)
    species = models.CharField("Species", max_length=40)  # cat/dog/…
    breed = models.CharField("Breed", max_length=80, blank=True, default="")
    sex = models.CharField("Sex", max_length=10, choices=(("male", "Boy"), ("female", "Girl")), default="male")
    age_years = models.PositiveIntegerField("Age (years)", default=0)
    age_months = models.PositiveIntegerField("Age (months)", default=0)
    description = models.TextField("Description", blank=True, default="")
    address = models.ForeignKey(
        "pet.Address", on_delete=models.SET_NULL, null=True, blank=True, related_name="donations",
        verbose_name="Address"
    )
    # 健康与背景（可选）
    dewormed = models.BooleanField("Dewormed", default=False)
    vaccinated = models.BooleanField("Vaccinated", default=False)
    microchipped = models.BooleanField("Microchipped", default=False)
    sterilized = models.BooleanField("Sterilized/Neutered", default=False)
    child_friendly = models.BooleanField("Child Friendly", default=False)
    trained = models.BooleanField("House Trained", default=False)
    loves_play = models.BooleanField("Loves to Play", default=False)
    loves_walks = models.BooleanField("Loves Walks", default=False)
    good_with_dogs = models.BooleanField("Good with Dogs", default=False)
    good_with_cats = models.BooleanField("Good with Cats", default=False)
    affectionate = models.BooleanField("Affectionate", default=False)
    needs_attention = models.BooleanField("Needs Attention", default=False)
    is_stray = models.BooleanField("Found as Stray", default=False)
    contact_phone = models.CharField("Contact Phone", max_length=30, blank=True, default="")

    # 关联的收容所
    shelter = models.ForeignKey(
        "pet.Shelter", on_delete=models.SET_NULL, null=True, blank=True,
        related_name="donations", verbose_name="Associated Shelter"
    )

    # 审核流
    status = models.CharField("Status", max_length=20, choices=STATUS_CHOICES, default="submitted", db_index=True)
    reviewer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True,
                                 related_name="donation_reviewed")
    review_note = models.CharField("Review Note", max_length=200, blank=True, default="")

    # 审核通过后关联生成的 Pet
    created_pet = models.OneToOneField(Pet, on_delete=models.SET_NULL, null=True, blank=True,
                                       related_name="from_donor")

    add_date = models.DateTimeField("Created At", auto_now_add=True)
    pub_date = models.DateTimeField("Updated At", auto_now=True)

    class Meta:
        verbose_name = "Donation"
        verbose_name_plural = "Donations"
        ordering = ["-pub_date"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["donor"]),
        ]

    def __str__(self):
        return f"{self.donor} -> {self.name} ({self.species}) [{self.status}]"

    # —— 审核通过时自动创建 Pet，并将第一张图设为封面 ——
    def approve(self, reviewer, note=""):
        from django.db import transaction
        with transaction.atomic():
            if self.created_pet:
                return self.created_pet  # 避免重复创建

            if self.status not in ("submitted", "reviewing", "approved"):
                raise ValueError("Current status can't process")

            pet = Pet.objects.create(
                name=self.name, species=self.species, breed=self.breed, sex=self.sex,
                age_years=self.age_years, age_months=self.age_months,
                description=self.description,
                address=self.address,
                dewormed=self.dewormed,
                vaccinated=self.vaccinated,
                microchipped=self.microchipped,
                sterilized=self.sterilized,
                child_friendly=self.child_friendly,
                trained=self.trained,
                loves_play=self.loves_play,
                loves_walks=self.loves_walks,
                good_with_dogs=self.good_with_dogs,
                good_with_cats=self.good_with_cats,
                affectionate=self.affectionate,
                needs_attention=self.needs_attention,
                contact_phone=self.contact_phone,
                status=Pet.Status.AVAILABLE,
                created_by=self.donor,  # 或 reviewer/机构账号
            )
            
            # 复制所有照片到 PetPhoto
            donation_photos = self.photos.order_by("id").all()
            for idx, donation_photo in enumerate(donation_photos):
                if not donation_photo.image:
                    continue
                    
                try:
                    # 读取照片数据
                    donation_photo.image.open("rb")
                    data = donation_photo.image.read()
                    donation_photo.image.close()
                    
                    # 生成新文件名
                    orig_name = donation_photo.image.name.split("/")[-1]
                    
                    # 第一张设为封面
                    if idx == 0:
                        target_path = f"pets/{pet.id}_{orig_name}"
                        saved_path = default_storage.save(target_path, ContentFile(data))
                        pet.cover.name = saved_path
                        pet.save(update_fields=["cover"])
                    
                    # 创建 PetPhoto（包括第一张，这样在 photos 数组中也能看到所有照片）
                    pet_photo = PetPhoto.objects.create(
                        pet=pet,
                        order=idx,
                    )
                    photo_target_path = f"pets/photos/{pet.id}_{idx}_{orig_name}"
                    pet_photo.image.save(photo_target_path, ContentFile(data), save=True)
                    
                except Exception as e:
                    # 出错也不阻断主流程
                    import logging
                    logging.error(f"Failed to copy photo {idx} for pet {pet.id}: {e}")
                    continue

            self.created_pet = pet
            self.status = "approved"
            self.reviewer = reviewer
            self.review_note = note
            self.save(update_fields=["created_pet", "status", "reviewer", "review_note", "pub_date"])
            return pet


class PetPhoto(models.Model):
    """ Pet 的额外照片（多图） """
    pet = models.ForeignKey(Pet, on_delete=models.CASCADE, related_name="photos", verbose_name="Pet")
    image = models.ImageField("Photo", upload_to="pets/photos/")
    order = models.PositiveIntegerField("Display Order", default=0)  # 用于排序
    add_date = models.DateTimeField("Created At", auto_now_add=True)

    class Meta:
        verbose_name = "Pet Photo"
        verbose_name_plural = "Pet Photos"
        ordering = ["order", "id"]

    def __str__(self):
        return f"Photo for {self.pet.name}"


class DonationPhoto(models.Model):
    """ 多图上传；第一张作为 Pet 封面 """
    donation = models.ForeignKey(Donation, on_delete=models.CASCADE, related_name="photos")
    image = models.ImageField(upload_to="donations/")
    add_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["id"]

    def preview(self):
        if self.image and hasattr(self.image, "url"):
            return mark_safe(f'<img src="{self.image.url}" width="120" style="border-radius:8px;" />')
        return "(no image)"

    preview.short_description = "Preview"


# Address related models
class Country(models.Model):
    code = models.CharField(max_length=2, unique=True)  # ISO 3166-1 alpha-2, 如 "PL"
    name = models.CharField(max_length=64)

    class Meta:
        ordering = ["name"]
        verbose_name = "Country"
        verbose_name_plural = "Countries"

    def __str__(self): return self.name


class Region(models.Model):  # 省/州
    country = models.ForeignKey(Country, on_delete=models.CASCADE, related_name="regions")
    code = models.CharField(max_length=10)  # ISO 3166-2 (可选)
    name = models.CharField(max_length=64)

    class Meta:
        unique_together = ("country", "name")
        ordering = ["name"]
        verbose_name = "Region"
        verbose_name_plural = "Regions"
        indexes = [models.Index(fields=["country", "name"])]

    def __str__(self): return self.name


class City(models.Model):
    region = models.ForeignKey(Region, on_delete=models.CASCADE, related_name="cities")
    name = models.CharField(max_length=64)

    class Meta:
        unique_together = ("region", "name")
        ordering = ["name"]
        verbose_name = "City"
        verbose_name_plural = "Cities"
        indexes = [models.Index(fields=["region", "name"])]

    def __str__(self): return self.name


class Address(models.Model):
    country = models.ForeignKey(
        Country, on_delete=models.PROTECT, verbose_name="Country",
        null=True, blank=True  # ← 允许空（第一次迁移更顺滑）
    )
    region = ChainedForeignKey(
        Region, on_delete=models.PROTECT, verbose_name="Region",
        chained_field="country", chained_model_field="country",
        show_all=False, auto_choose=True, sort=True,
        null=True, blank=True  # ← 允许空
    )
    city = ChainedForeignKey(
        City, on_delete=models.PROTECT, verbose_name="City",
        chained_field="region", chained_model_field="region",
        show_all=False, auto_choose=False, sort=True,
        null=True, blank=True  # ← 允许空
    )
    street = models.CharField("Street", max_length=128, blank=True, default="")
    building_number = models.CharField("Building No.", max_length=16, blank=True, default="")
    postal_code = models.CharField("Postal Code", max_length=20, blank=True, default="")
    latitude = models.DecimalField("Lat", max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField("Lng", max_digits=9, decimal_places=6, null=True, blank=True)
  # ✅ 新增：地理点（WGS84，经纬度）
    location  = models.JSONField(default=dict, null=True, blank=True)

    class Meta:
        ordering = ["country", "region", "city", "street"]
        verbose_name = "Address"
        verbose_name_plural = "Addresses"
        indexes = [
            models.Index(fields=["country", "region", "city"]),
            models.Index(fields=["postal_code"]),
        ]

    def __str__(self):
        parts = [
            self.street, self.building_number,
            self.city.name if self.city_id else "",
            self.region.name if self.region_id else "",
            self.country.name if self.country_id else "",
            self.postal_code,
        ]
        return ", ".join([p for p in parts if p]) or "Address"


class LostStatus(models.TextChoices):
    OPEN = "open", "Open"  # 待寻找
    FOUND = "found", "Found"  # 已找到
    CLOSED = "closed", "Closed"  # 关闭/无效


def lost_upload_to(instance, filename):
    return f"lost/{instance.id or 'new'}/{filename}"


# todo: 需要新增宠物状态 Lost
# Lost的宠物不可以收养
class Lost(models.Model):
    pet = models.ForeignKey('Pet', null=True, blank=True,
                            on_delete=models.SET_NULL, related_name='lost_reports')
    pet_name = models.CharField("Pet Name", max_length=80, blank=True, default="")

    species = models.CharField(max_length=50, help_text="cat/dog/…")
    breed = models.CharField(max_length=100, blank=True, default="")
    color = models.CharField(max_length=100, blank=True, default="")
    sex = models.CharField("Sex", max_length=10, choices=(("male", "Boy"), ("female", "Girl")), default="male")
    size = models.CharField(max_length=20, blank=True, default="")  # small/medium/large

    # 与 Donation 一致，使用 Address 外键（Country→Region→City 级联在 Address 中完成）
    address = models.ForeignKey(
        "pet.Address", on_delete=models.SET_NULL, null=True, blank=True,
        related_name="losts", verbose_name="Address"
    )

    lost_time = models.DateTimeField(help_text="Lost time (local)")
    description = models.TextField(blank=True, default="")
    reward = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    photo = models.ImageField(upload_to=lost_upload_to, null=True, blank=True)

    status = models.CharField(max_length=20, choices=LostStatus.choices, default=LostStatus.OPEN)
    reporter = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='lost_reports')
    contact_phone = models.CharField(max_length=50, blank=True, default="")
    contact_email = models.EmailField(blank=True, default="")

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = "Lost"
        verbose_name_plural = "Losts"

    def __str__(self):
        base = self.pet_name or f"{self.species} ({self.color})"
        if self.address_id:
            parts = [
                self.address.city.name if self.address and self.address.city_id else "",
                self.address.region.name if self.address and self.address.region_id else "",
                self.address.country.name if self.address and self.address.country_id else "",
            ]
            loc = ", ".join([p for p in parts if p])
            return f"[{self.get_status_display()}] {base}" + (f" @ {loc}" if loc else "")
        return f"[{self.get_status_display()}] {base}"


class Shelter(models.Model):
    """Animal shelter organization"""
    name = models.CharField("Shelter Name", max_length=150, unique=True)
    description = models.TextField("Description", blank=True, default="")
    
    # Contact information
    email = models.EmailField("Email", blank=True, default="")
    phone = models.CharField("Phone", max_length=30, blank=True, default="")
    website = models.URLField("Website", blank=True, default="")
    
    # Address
    address = models.ForeignKey(
        "pet.Address", on_delete=models.SET_NULL, null=True, blank=True,
        related_name="shelters", verbose_name="Address"
    )
    
    # Images
    logo = models.ImageField("Logo", upload_to="shelters/logos/", blank=True, null=True)
    cover_image = models.ImageField("Cover Image", upload_to="shelters/covers/", blank=True, null=True)
    
    # Capacity and statistics
    capacity = models.PositiveIntegerField("Capacity", default=0, help_text="Maximum number of animals")
    current_animals = models.PositiveIntegerField("Current Animals", default=0)
    
    # Operation details
    founded_year = models.PositiveIntegerField("Founded Year", null=True, blank=True)
    is_verified = models.BooleanField("Verified", default=False, help_text="Verified by admin")
    is_active = models.BooleanField("Active", default=True)
    
    # Social media
    facebook_url = models.URLField("Facebook", blank=True, default="")
    instagram_url = models.URLField("Instagram", blank=True, default="")
    twitter_url = models.URLField("Twitter/X", blank=True, default="")
    
    # Management
    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="created_shelters", verbose_name="Created By"
    )
    
    created_at = models.DateTimeField("Created At", auto_now_add=True)
    updated_at = models.DateTimeField("Updated At", auto_now=True)

    class Meta:
        verbose_name = "Shelter"
        verbose_name_plural = "Shelters"
        ordering = ["-is_verified", "name"]
        indexes = [
            models.Index(fields=["is_active", "is_verified"]),
            models.Index(fields=["name"]),
        ]

    def __str__(self):
        return self.name
    
    @property
    def available_capacity(self):
        """Calculate available capacity"""
        if self.capacity > 0:
            return max(0, self.capacity - self.current_animals)
        return 0
    
    @property
    def occupancy_rate(self):
        """Calculate occupancy rate as percentage"""
        if self.capacity > 0:
            return (self.current_animals / self.capacity) * 100
        return 0


class PetFavorite(models.Model):
    """User favorites a pet (bookmark). Unique per (user, pet)."""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="pet_favorites")
    pet = models.ForeignKey(Pet, on_delete=models.CASCADE, related_name="favorites")
    add_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "pet")
        indexes = [models.Index(fields=["user", "pet"])]
        verbose_name = "Pet Favorite"
        verbose_name_plural = "Pet Favorites"

    def __str__(self):
        return f"{self.user} ❤ {self.pet}"

class Ticket(models.Model):
    """Support ticket for admin use."""
    
    class Status(models.TextChoices):
        OPEN = "open", "Open"
        IN_PROGRESS = "in_progress", "In Progress"
        CLOSED = "closed", "Closed"
        RESOLVED = "resolved", "Resolved"
    
    class Priority(models.TextChoices):
        LOW = "low", "Low"
        MEDIUM = "medium", "Medium"
        HIGH = "high", "High"
        URGENT = "urgent", "Urgent"
    
    class Category(models.TextChoices):
        GENERAL = "general", "General Inquiry"
        PET_HEALTH = "pet_health", "Pet Health"
        ADOPTION = "adoption", "Adoption Issue"
        LOST_FOUND = "lost_found", "Lost/Found Pet"
        SHELTER = "shelter", "Shelter Issue"
        TECHNICAL = "technical", "Technical Issue"
        FEEDBACK = "feedback", "Feedback"
        OTHER = "other", "Other"
    
    title = models.CharField("Title", max_length=255, db_index=True)
    description = models.TextField("Description", blank=True, default="")
    category = models.CharField(
        "Category",
        max_length=50,
        choices=Category.choices,
        default=Category.GENERAL
    )
    status = models.CharField(
        "Status",
        max_length=20,
        choices=Status.choices,
        default=Status.OPEN,
        db_index=True
    )
    priority = models.CharField(
        "Priority",
        max_length=20,
        choices=Priority.choices,
        default=Priority.MEDIUM
    )
    
    # Contact information
    email = models.EmailField("Email", blank=True, default="")
    phone = models.CharField("Phone", max_length=30, blank=True, default="")
    
    # Audit fields
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="tickets_created"
    )
    assigned_to = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="tickets_assigned",
        help_text="Admin assigned to this ticket"
    )
    
    created_at = models.DateTimeField("Created At", auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField("Updated At", auto_now=True)
    resolved_at = models.DateTimeField("Resolved At", null=True, blank=True)
    
    class Meta:
        verbose_name = "Ticket"
        verbose_name_plural = "Tickets"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status", "-created_at"]),
            models.Index(fields=["priority", "-created_at"]),
            models.Index(fields=["category"]),
            models.Index(fields=["created_by"]),
            models.Index(fields=["assigned_to"]),
        ]
    
    def __str__(self):
        return f"[{self.get_priority_display()}] {self.title} ({self.get_status_display()})"


class HolidayFamily(models.Model):
    """Model for Holiday Family applications"""
    
    STATUS_CHOICES = [
        ("pending", "Pending Review"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
    ]
    
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="holiday_family_application"
    )
    
    # Personal Information
    full_name = models.CharField("Full Name", max_length=150)
    email = models.EmailField("Email")
    phone = models.CharField("Phone Number", max_length=20)
    address = models.CharField("Address", max_length=255)
    city = models.CharField("City", max_length=100)
    
    # Pet Experience
    pet_count = models.PositiveIntegerField("Number of Current Pets", default=0)
    pet_types = models.CharField("Types of Pets", max_length=255, help_text="e.g., 2 dogs, 1 cat")
    
    # Motivation
    motivation = models.TextField("Why do you want to be a Holiday Family?")
    terms_agreed = models.BooleanField("Terms and Conditions Agreed", default=False)
    
    # Status and Review
    status = models.CharField(
        "Application Status",
        max_length=20,
        choices=STATUS_CHOICES,
        default="pending"
    )
    
    applied_at = models.DateTimeField("Applied At", auto_now_add=True, db_index=True)
    reviewed_at = models.DateTimeField("Reviewed At", null=True, blank=True)
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="holiday_family_reviewed"
    )
    review_notes = models.TextField("Review Notes", blank=True)
    
    class Meta:
        verbose_name = "Holiday Family"
        verbose_name_plural = "Holiday Families"
        ordering = ["-applied_at"]
        indexes = [
            models.Index(fields=["status", "-applied_at"]),
            models.Index(fields=["user"]),
        ]
    
    def __str__(self):
        return f"{self.full_name} - {self.get_status_display()}"