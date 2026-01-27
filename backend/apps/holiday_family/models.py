from django.db import models
from django.conf import settings
from django.core.validators import FileExtensionValidator


class HolidayFamilyApplication(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )

    # 关联用户
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='holiday_family_applications', null=True, blank=True)

    # Personal Information
    full_name = models.CharField(max_length=255)
    email = models.EmailField()
    phone = models.CharField(max_length=20)

    # Address Information
    country = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    city = models.CharField(max_length=100)
    street_address = models.CharField(max_length=255)
    postal_code = models.CharField(max_length=20, blank=True)

    # Pet Information
    pet_count = models.IntegerField()
    can_take_dogs = models.BooleanField(default=False)
    can_take_cats = models.BooleanField(default=False)
    can_take_rabbits = models.BooleanField(default=False)
    can_take_others = models.CharField(max_length=255, blank=True)

    # Story & Introduction
    motivation = models.TextField()
    introduction = models.TextField()

    # Documents
    id_document = models.FileField(
        upload_to='holiday_family/id_documents/',
        validators=[FileExtensionValidator(allowed_extensions=['pdf', 'jpg', 'jpeg', 'png'])]
    )

    # Agreement
    terms_agreed = models.BooleanField(default=False)

    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    rejection_reason = models.TextField(blank=True, null=True, help_text="拒绝的原因")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.full_name} - {self.status}"

    class Meta:
        ordering = ['-created_at']


class HolidayFamilyPhoto(models.Model):
    application = models.ForeignKey(
        HolidayFamilyApplication,
        on_delete=models.CASCADE,
        related_name='family_photos'
    )
    photo = models.ImageField(upload_to='holiday_family/family_photos/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Photo for {self.application.full_name}"
