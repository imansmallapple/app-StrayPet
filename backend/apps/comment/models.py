from django.db import models
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.contrib.auth import get_user_model

User = get_user_model()


class Comment(models.Model):
    owner = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="author")
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE, verbose_name="content type")
    object_id = models.PositiveIntegerField(verbose_name="object id")
    content_object = GenericForeignKey('content_type', 'object_id')
    content = models.TextField(verbose_name="content")
    add_date = models.DateTimeField("add date", auto_now_add=True)
    pub_date = models.DateTimeField("pub date", auto_now=True)
    parent = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        verbose_name="parent comment"
    )

    class Meta:
        verbose_name = "comment"
        verbose_name_plural = "comments"
        ordering = ["-pub_date"]

    def __str__(self):
        return self.content
