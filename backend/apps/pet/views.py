# apps/pet/views.py
from django.db import transaction
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import viewsets, permissions, decorators, status
from rest_framework.decorators import action
from rest_framework.filters import OrderingFilter
from rest_framework.permissions import IsAdminUser, AllowAny, SAFE_METHODS
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from .models import Pet, Adoption, Lost, Donation, PetFavorite, Shelter, Ticket, HolidayFamily
from django.core.exceptions import FieldDoesNotExist
from .serializers import PetListSerializer, PetCreateUpdateSerializer, AdoptionCreateSerializer, \
    AdoptionDetailSerializer, AdoptionReviewSerializer, LostSerializer, DonationCreateSerializer,\
    DonationDetailSerializer, DonationCreateSerializer, DonationDetailSerializer, \
    ShelterListSerializer, ShelterDetailSerializer, ShelterCreateUpdateSerializer, TicketSerializer
from .permissions import IsOwnerOrAdmin, IsAdopterOrOwnerOrAdmin
from .filters import PetFilter, LostFilter
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.parsers import MultiPartParser, FormParser
from .serializers import LostGeoSerializer, HolidayFamilyApplicationSerializer
from rest_framework.permissions import IsAuthenticatedOrReadOnly
from rest_framework import viewsets, permissions
from django.utils import timezone
from django.contrib.auth.models import User
import logging
logger = logging.getLogger(__name__)


class PetViewSet(viewsets.ModelViewSet):
    # Build a safe select_related list based on actual model relations so we don't crash
    _pet_related = ["created_by", "address", "address__city", "address__region", "address__country", "shelter", "shelter__address", "shelter__address__city", "location"]
    _valid_related = []
    for _f in _pet_related:
        root = _f.split("__")[0]
        try:
            fld = Pet._meta.get_field(root)
            if getattr(fld, "is_relation", False):
                _valid_related.append(_f)
        except FieldDoesNotExist:
            pass
    queryset = Pet.objects.select_related(*_valid_related).order_by("-pub_date")
    filterset_class = PetFilter
    search_fields = ["name", "species", "breed", "description", "address"]
    ordering_fields = ["add_date", "pub_date", "age_months", "name"]
    permission_classes = [IsAuthenticatedOrReadOnly]

    @action(detail=True, methods=['post'])
    def mark_lost(self, request, pk=None):
        pet = self.get_object()
        pet.status = Pet.Status.LOST
        pet.save(update_fields=['status', 'pub_date'])
        return Response({'status': 'lost'}, status=status.HTTP_200_OK)

    def get_serializer_class(self):
        return PetListSerializer if self.action in ("list", "retrieve") else PetCreateUpdateSerializer

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [permissions.AllowAny()]
        if self.action in ("create",):
            return [permissions.IsAuthenticated()]
        return super().get_permissions()

    # 公共列表：只展示 AVAILABLE/PENDING
    def list(self, request, *args, **kwargs):
        try:
            qs = self.filter_queryset(
                self.get_queryset().filter(status__in=[Pet.Status.AVAILABLE, Pet.Status.PENDING])
            )
            page = self.paginate_queryset(qs)
            ser = PetListSerializer(page, many=True, context={"request": request})
            return self.get_paginated_response(ser.data)
        except Exception as exc:
            logger.exception('PetViewSet.list encountered error')
            # Return JSON error and avoid unhandled exception bubbling (helps with CORS during dev)
            return Response({"detail": "Internal Server Error", "error": str(exc)}, status=500)

    # 非公开详情限制访问（DRAFT/ARCHIVED 仅作者/管理员可见）
    def retrieve(self, request, *args, **kwargs):
        obj = self.get_object()
        if obj.status in (Pet.Status.DRAFT, Pet.Status.ARCHIVED):
            u = request.user
            if not (u.is_authenticated and (u.is_staff or u.id == obj.created_by_id)):
                raise PermissionDenied("This pet is not public.")
        try:
            ser = PetListSerializer(obj, context={"request": request})
            return Response(ser.data)
        except Exception:
            logger.exception('PetViewSet.retrieve serialization failed')
            return Response({"detail": "Internal Server Error"}, status=500)

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user, status=Pet.Status.AVAILABLE)

    # 可选：快速标记状态（仅作者/管理员）
    @decorators.action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def set_status(self, request, pk=None):
        obj = self.get_object()
        u = request.user
        if not (u.is_staff or u.id == obj.created_by_id):
            raise PermissionDenied("Only owner or admin can change status.")
        status_val = request.data.get("status")
        allowed = {s for s, _ in Pet.Status.choices}
        if status_val not in allowed:
            return Response({"detail": f"status must be one of {sorted(allowed)}"}, status=400)
        obj.status = status_val
        obj.save(update_fields=["status", "pub_date"])
        return Response({"ok": True, "status": obj.status})

    @decorators.action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def apply(self, request, pk=None):
        pet = self.get_object()
        ser = AdoptionCreateSerializer(
            data={"pet": pet.id, "message": request.data.get("message", "")},
            context={"request": request}
        )
        ser.is_valid(raise_exception=True)
        app = ser.save(applicant=request.user)
        # 有申请则把宠物置为 pending
        if pet.status == Pet.Status.AVAILABLE:
            pet.status = Pet.Status.PENDING
            pet.save(update_fields=["status", "pub_date"])
        return Response({"ok": True, "application_id": app.id})

    # —— Favorites —— #
    @decorators.action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def favorite(self, request, pk=None):
        pet = self.get_object()
        fav, created = PetFavorite.objects.get_or_create(user=request.user, pet=pet)
        return Response({"favorited": True, "created": created, "count": pet.favorites.count()})

    @decorators.action(detail=True, methods=["delete"], permission_classes=[permissions.IsAuthenticated])
    def unfavorite(self, request, pk=None):
        pet = self.get_object()
        PetFavorite.objects.filter(user=request.user, pet=pet).delete()
        return Response({"favorited": False, "count": pet.favorites.count()})

    @decorators.action(detail=False, methods=["get"], permission_classes=[permissions.IsAuthenticated])
    def favorites(self, request):
        qs = Pet.objects.filter(favorites__user=request.user).order_by("-favorites__add_date")
        page = self.paginate_queryset(qs)
        ser = PetListSerializer(page, many=True, context={"request": request})
        return self.get_paginated_response(ser.data)

    @decorators.action(detail=False, methods=["get"], permission_classes=[permissions.IsAuthenticated])
    def my_pets(self, request):
        """Get all pets created by current user"""
        qs = Pet.objects.filter(created_by=request.user).order_by("-add_date")
        page = self.paginate_queryset(qs)
        ser = PetListSerializer(page, many=True, context={"request": request})
        return self.get_paginated_response(ser.data)


class AdoptionViewSet(viewsets.ModelViewSet):
    queryset = Adoption.objects.select_related("pet", "applicant", "pet__created_by").order_by("-pub_date")
    permission_classes = [IsAdopterOrOwnerOrAdmin]
    search_fields = ["message", "pet__name", "applicant__username"]
    ordering_fields = ["add_date", "pub_date", "status"]

    def get_serializer_class(self):
        if self.action in ("update", "partial_update"):
            return AdoptionReviewSerializer
        return AdoptionDetailSerializer

    def get_permissions(self):
        if self.action in ("list", "retrieve", "create"):
            return [permissions.IsAuthenticated()]
        return super().get_permissions()

    # 我的申请 / 发布者看自己宠物的申请；管理员看全部
    def list(self, request, *args, **kwargs):
        u = request.user
        qs = self.filter_queryset(self.get_queryset())
        if not u.is_staff:
            pet_id = request.query_params.get("pet")
            if pet_id:
                qs = qs.filter(pet__created_by=u, pet_id=pet_id)  # 发布者看某只宠物
            else:
                qs = qs.filter(applicant=u)  # 普通用户看自己的
        page = self.paginate_queryset(qs)
        ser = AdoptionDetailSerializer(page, many=True, context={"request": request})
        return self.get_paginated_response(ser.data)

    @transaction.atomic
    def partial_update(self, request, *args, **kwargs):
        """
        审核/撤销：
        - 管理员或宠物发布者：processing/approved/rejected/closed
        - 申请人：closed（撤销）
        审核通过：宠物置 ADOPTED，并关闭其它未结案申请
        """
        obj = self.get_object()
        u = request.user
        next_status = request.data.get("status")
        if not next_status:
            return Response({"detail": "status is required"}, status=400)

        owner_allowed = {"processing", "approved", "rejected", "closed"}
        applicant_allowed = {"closed"}

        is_owner_or_admin = (u.is_staff or obj.pet.created_by_id == u.id)
        is_applicant = (obj.applicant_id == u.id)

        if is_owner_or_admin and next_status in owner_allowed:
            obj.status = next_status
            obj.save(update_fields=["status", "pub_date"])
        elif is_applicant and next_status in applicant_allowed:
            obj.status = next_status
            obj.save(update_fields=["status", "pub_date"])
        else:
            raise PermissionDenied("Not allowed to change status.")

        pet = obj.pet
        if obj.status == "approved":
            pet.status = Pet.Status.ADOPTED
            pet.save(update_fields=["status", "pub_date"])
            Adoption.objects.filter(
                pet=pet, status__in=["submitted", "processing"]
            ).exclude(id=obj.id).update(status="closed")
        else:
            open_exists = Adoption.objects.filter(
                pet=pet, status__in=["submitted", "processing"]
            ).exists()
            if not open_exists and pet.status in (Pet.Status.PENDING, Pet.Status.AVAILABLE):
                pet.status = Pet.Status.AVAILABLE
                pet.save(update_fields=["status", "pub_date"])

        ser = AdoptionDetailSerializer(obj, context={"request": request})
        return Response(ser.data)

    @action(detail=True, methods=["post"], permission_classes=[IsAdminUser])
    def approve(self, request, pk=None):
        donation = self.get_object()
        pet = donation.approve(reviewer=request.user, note=request.data.get("note", ""))
        return Response({"detail": "approved", "pet_id": pet.id})


class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.reporter_id == request.user.id or request.user.is_staff


class LostViewSet(viewsets.ModelViewSet):
    serializer_class = LostSerializer
    # Allow anyone to read, authenticated users and owners to write
    permission_classes = [permissions.AllowAny]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_class = LostFilter
    ordering_fields = ['created_at', 'lost_time']
    ordering = ['-created_at']

    # Optional JWT authentication for write operations
    authentication_classes = [JWTAuthentication]
    def get_authenticators(self):
        if self.request and self.request.method in SAFE_METHODS:
            return []
        return super().get_authenticators()

    # ✅ 允许 multipart/form-data 与 application/x-www-form-urlencoded
    parser_classes = [MultiPartParser, FormParser]

    def list(self, request, *args, **kwargs):
        logger.info(f"Lost list request params: {request.query_params.dict()}")
        return super().list(request, *args, **kwargs)

    def perform_create(self, serializer):
        # If user is authenticated, set them as reporter, otherwise create anonymous entry
        if self.request.user and self.request.user.is_authenticated:
            serializer.save(reporter=self.request.user)
        else:
            # For anonymous submissions, we need to create/get an anonymous user
            from django.contrib.auth import get_user_model
            User = get_user_model()
            anonymous_user, _ = User.objects.get_or_create(
                username='anonymous',
                defaults={'email': 'anonymous@straypet.local'}
            )
            serializer.save(reporter=anonymous_user)

    def get_queryset(self):
        return (
            Lost.objects
            .select_related(
                'address',  # Lost -> Address
                'address__country',  # Address -> Country
                'address__region',  # Address -> Region
                'address__city',  # Address -> City
                'reporter',  # Lost -> User
                'pet',  # 若保留了内部 pet 外键
            )
            .all()
        )


class DonationViewSet(viewsets.ModelViewSet):
    # Build a safe select_related list for Donation (avoid FieldError when 'location' missing)
    _donation_related = [
        'address', 'address__country', 'address__region', 'address__city',
        'location', 'donor', 'created_pet',
    ]
    _valid_donation_related = []
    for _f in _donation_related:
        root = _f.split('__')[0]
        try:
            fld = Donation._meta.get_field(root)
            if getattr(fld, 'is_relation', False):
                _valid_donation_related.append(_f)
        except FieldDoesNotExist:
            pass
    queryset = Donation.objects.select_related(*_valid_donation_related).all()
    # 不再在这里固定 serializer_class，完全交给 get_serializer_class 决定
    permission_classes = [permissions.AllowAny]
    authentication_classes = [JWTAuthentication]
    parser_classes = [MultiPartParser, FormParser]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    ordering_fields = ['add_date', 'pub_date']
    ordering = ['-pub_date']

    def get_permissions(self):
        # 创建/修改/删除 需要登录
        if self.action in ("create", "update", "partial_update", "destroy"):
            return [permissions.IsAuthenticated()]
        # 列表/详情允许匿名
        if self.action in ("list", "retrieve"):
            return [permissions.AllowAny()]
        return super().get_permissions()

    def get_serializer_class(self):
        # list / retrieve 用详情版
        if self.action in ("list", "retrieve"):
            return DonationDetailSerializer
        # create / update 用带自定义 create() 的版本
        return DonationCreateSerializer

    def create(self, request, *args, **kwargs):
        """
        创建时用 DonationCreateSerializer 的 create()，
        然后用 DonationDetailSerializer 再序列化一次返回完整数据。
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        donation = serializer.save()
        logger.debug(
            "DonationViewSet.create: created donation id=%s address_id=%s location_id=%s",
            donation.id,
            getattr(getattr(donation, 'address', None), "id", None),
            getattr(getattr(donation, 'location', None), "id", None),
        )

        detail_ser = DonationDetailSerializer(donation, context={"request": request})
        return Response(detail_ser.data, status=201)


class LostGeoViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Lost.objects.select_related("address", "pet", "reporter").all()
    serializer_class = LostGeoSerializer
    # bbox_filter_field = "address__location" 
    # InBBoxFilter removed - using standard filtering


class ShelterViewSet(viewsets.ModelViewSet):
    """ViewSet for Shelter CRUD operations"""
    permission_classes = [IsAuthenticatedOrReadOnly]
    authentication_classes = [JWTAuthentication]
    parser_classes = [MultiPartParser, FormParser]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    ordering_fields = ['name', 'created_at', 'capacity', 'current_animals']
    ordering = ['name']
    
    def get_queryset(self):
        # Build select_related list based on actual fields
        _shelter_related = ['address', 'address__country', 'address__region', 'address__city', 'created_by']
        _valid_related = []
        for _f in _shelter_related:
            root = _f.split('__')[0]
            try:
                fld = Shelter._meta.get_field(root)
                if getattr(fld, 'is_relation', False):
                    _valid_related.append(_f)
            except FieldDoesNotExist:
                pass
        
        qs = Shelter.objects.select_related(*_valid_related)
        
        # Filter by active status by default
        if self.action == 'list':
            # Allow filtering by is_active parameter
            is_active = self.request.query_params.get('is_active')
            if is_active is None:
                qs = qs.filter(is_active=True)
            elif is_active.lower() in ('true', '1'):
                qs = qs.filter(is_active=True)
            elif is_active.lower() in ('false', '0'):
                qs = qs.filter(is_active=False)
        
        return qs
    
    def get_serializer_class(self):
        if self.action == 'list':
            return ShelterListSerializer
        elif self.action == 'retrieve':
            return ShelterDetailSerializer
        else:
            return ShelterCreateUpdateSerializer
    
    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [AllowAny()]
        elif self.action == 'create':
            return [permissions.IsAuthenticated()]
        elif self.action in ('update', 'partial_update', 'destroy'):
            # Only admin or creator can update/delete
            return [permissions.IsAuthenticated(), IsOwnerOrAdmin()]
        return super().get_permissions()
    
    def list(self, request, *args, **kwargs):
        try:
            qs = self.filter_queryset(self.get_queryset())
            page = self.paginate_queryset(qs)
            serializer = self.get_serializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
        except Exception as exc:
            logger.exception('ShelterViewSet.list encountered error')
            return Response({'detail': 'Internal Server Error', 'error': str(exc)}, status=500)
    
    def retrieve(self, request, *args, **kwargs):
        try:
            obj = self.get_object()
            serializer = self.get_serializer(obj, context={'request': request})
            return Response(serializer.data)
        except Exception as exc:
            logger.exception('ShelterViewSet.retrieve encountered error')
            return Response({'detail': 'Internal Server Error', 'error': str(exc)}, status=500)


class TicketViewSet(viewsets.ModelViewSet):
    """ViewSet for managing support tickets."""
    queryset = Ticket.objects.select_related('created_by', 'assigned_to').order_by('-created_at')
    serializer_class = TicketSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_fields = ['status', 'priority', 'category']
    ordering_fields = ['created_at', 'priority', 'status']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Filter tickets: admins see all, regular users see their own."""
        user = self.request.user
        if user.is_staff:
            return self.queryset
        return self.queryset.filter(created_by=user)
    
    def get_permissions(self):
        """Admin can do anything, users can only create and view their own."""
        if self.action == 'create':
            return [permissions.IsAuthenticated()]
        elif self.action in ('list', 'retrieve'):
            return [permissions.IsAuthenticated()]
        elif self.action in ('update', 'partial_update', 'destroy'):
            return [permissions.IsAuthenticated(), IsAdminUser()]
        return super().get_permissions()
    
    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def my_tickets(self, request):
        """Get current user's tickets."""
        tickets = self.queryset.filter(created_by=request.user)
        page = self.paginate_queryset(tickets)
        if page is not None:
            serializer = self.get_serializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(tickets, many=True, context={'request': request})
        return Response(serializer.data)

class HolidayFamilyViewSet(viewsets.ModelViewSet):
    """ViewSet for Holiday Family applications"""
    
    queryset = HolidayFamily.objects.all()
    serializer_class = HolidayFamilyApplicationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Users can only see their own application, admins can see all"""
        if self.request.user.is_staff:
            return HolidayFamily.objects.all()
        return HolidayFamily.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['get'], url_path='my-application')
    def my_application(self, request):
        """Get current user's Holiday Family application"""
        try:
            application = HolidayFamily.objects.get(user=request.user)
            serializer = self.get_serializer(application)
            return Response(serializer.data)
        except HolidayFamily.DoesNotExist:
            return Response(
                {"detail": "No application found"},
                status=status.HTTP_404_NOT_FOUND
            )
    
    def create(self, request, *args, **kwargs):
        """Create a new Holiday Family application with notification"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Send notification to admin users
        try:
            self._notify_admins(serializer.instance)
        except Exception as e:
            # Log the error but don't fail the request
            logger.error(f"Error sending admin notification: {e}")
        
        headers = self.get_success_headers(serializer.data)
        return Response(
            {
                "detail": "Application submitted successfully",
                "data": serializer.data
            },
            status=status.HTTP_201_CREATED,
            headers=headers
        )
    
    def _notify_admins(self, application):
        """Send notification to all admin users about new application"""
        from apps.common.models import Notification
        
        admin_users = User.objects.filter(is_staff=True)
        
        for admin in admin_users:
            try:
                Notification.objects.create(
                    user=admin,
                    title="New Holiday Family Application",
                    message=f"New application from {application.full_name} ({application.email})",
                    notification_type="info",
                    link=f"/admin/pet/holidayfamily/{application.id}/change/"
                )
            except Exception as e:
                logger.error(f"Failed to create notification for admin {admin.id}: {e}")