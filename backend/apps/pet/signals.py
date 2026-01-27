# apps/pet/signals.py
from django.db import transaction
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

from .models import Pet, Adoption, LostStatus, Lost

OPEN_STATUSES = {"submitted", "processing"}  # 未结案申请的状态集合


@receiver(post_save, sender=Adoption)
def set_pet_pending_on_create(sender, instance: Adoption, created, **kwargs):
    """
    规则 1：
    当用户提交申请时，如果宠物是 available，则把宠物状态改为 pending。
    无论是在 API 还是 Admin 创建都会触发。
    """
    if not created:
        return
    pet = instance.pet
    if pet.status == Pet.Status.AVAILABLE:
        pet.status = Pet.Status.PENDING
        pet.save(update_fields=["status", "pub_date"])


@receiver(pre_save, sender=Adoption)
def handle_status_transitions(sender, instance: Adoption, **kwargs):
    """
    规则 2 & 3：
    - 当申请被批准：宠物置为 adopted，并关闭同宠物其它未结案申请
    - 当申请被关闭/拒绝：若该宠物不再有未结案申请，则把宠物状态置回 available
    """
    # 新建时无 pk，不在这里处理（创建后的 pending 已在 post_save 处理）
    if not instance.pk:
        return

    # 取旧状态
    try:
        old_status = sender.objects.only("status").get(pk=instance.pk).status
    except sender.DoesNotExist:
        return
    new_status = instance.status
    if old_status == new_status:
        return

    pet = instance.pet

    # 2) 审批通过
    if new_status == "approved":
        with transaction.atomic():
            # 宠物标记为已领养
            if pet.status != Pet.Status.ADOPTED:
                pet.status = Pet.Status.ADOPTED
                pet.save(update_fields=["status", "pub_date"])
            # 关闭其它未结案申请
            sender.objects.filter(
                pet=pet, status__in=OPEN_STATUSES
            ).exclude(pk=instance.pk).update(status="closed")
        return

    # 3) 申请被关闭/拒绝：如果没有其它未结案申请，则把宠物置回 available
    if new_status in {"closed", "rejected"}:
        # 注意：这里用 exclude(pk=instance.pk) 是因为当前这条的状态已经要改成 closed/rejected
        open_exists = sender.objects.filter(
            pet=pet, status__in=OPEN_STATUSES
        ).exclude(pk=instance.pk).exists()

        if not open_exists and pet.status in (Pet.Status.PENDING, Pet.Status.AVAILABLE):
            pet.status = Pet.Status.AVAILABLE
            pet.save(update_fields=["status", "pub_date"])


def _safe_sex(value: str) -> str:
    choices = {c[0] for c in Pet.SEX_CHOICES}
    return value if value in choices else 'male'


@receiver(post_save, sender=Lost)
def sync_pet_with_lost(sender, instance: Lost, created, **kwargs):
    # 1) 确保有 Pet 记录
    pet = instance.pet
    if not pet:
        # 优先用“同名 + 同 reporter”的现有 Pet
        pet = Pet.objects.filter(name=instance.pet_name, created_by=instance.reporter).first()
    if not pet:
        # 没有就创建一个最小档案
        pet = Pet.objects.create(
            name=instance.pet_name or f"{instance.species} ({instance.color})",
            species=instance.species or "unknown",
            breed=instance.breed or "",
            sex=_safe_sex(instance.sex or "male"),
            description=instance.description or "",
            address=instance.address,
            status=Pet.Status.LOST,  # 立即标记为 LOST
            created_by=instance.reporter,
        )
        # 设置封面（可选）
        if instance.photo:
            pet.cover = instance.photo
            pet.save(update_fields=["cover", "pub_date"])
    else:
        # 同步基础信息并标记 LOST
        fields_to_update = []
        if pet.status != Pet.Status.LOST:
            pet.status = Pet.Status.LOST
            fields_to_update.append("status")
        for f in ("species", "breed", "description"):
            val = getattr(instance, f) or getattr(pet, f)
            if getattr(pet, f) != val:
                setattr(pet, f, val)
                fields_to_update.append(f)
        if instance.address_id and pet.address_id != instance.address_id:
            pet.address = instance.address
            fields_to_update.append("address")
        if instance.photo and not pet.cover:
            pet.cover = instance.photo
            fields_to_update.append("cover")
        if fields_to_update:
            pet.save(update_fields=list(set(fields_to_update)) + ["pub_date"])

    # 绑定回 Lost（表单里隐藏，不影响你的“只填名字”体验）
    if instance.pet_id != pet.id:
        Lost.objects.filter(pk=instance.pk).update(pet=pet)

    # 2) 若 Lost 已被标记为 FOUND/CLOSED，把 Pet 恢复为 AVAILABLE
    if instance.status in (LostStatus.FOUND, LostStatus.CLOSED) and pet.status == Pet.Status.LOST:
        pet.status = Pet.Status.AVAILABLE
        pet.save(update_fields=["status", "pub_date"])
