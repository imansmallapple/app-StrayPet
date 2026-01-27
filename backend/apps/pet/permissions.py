# apps/pet/permissions.py
from rest_framework.permissions import BasePermission, SAFE_METHODS


class IsOwnerOrAdmin(BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        u = request.user
        return bool(u and u.is_authenticated and (u.is_staff or obj.created_by_id == u.id))


class IsAdopterOrOwnerOrAdmin(BasePermission):
    """
    - 读：申请人 / 宠物发布者 / 管理员
    - 写：管理员 或 宠物发布者；申请人只能撤销（置 closed）
    """
    def has_object_permission(self, request, view, obj):
        u = request.user
        if not u or not u.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return u.is_staff or obj.applicant_id == u.id or obj.pet.created_by_id == u.id
        return u.is_staff or obj.pet.created_by_id == u.id or obj.applicant_id == u.id
