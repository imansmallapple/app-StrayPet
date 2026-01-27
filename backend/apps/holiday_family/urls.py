from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import HolidayFamilyApplicationViewSet

router = DefaultRouter()
router.register(r'', HolidayFamilyApplicationViewSet, basename='holiday-family')

urlpatterns = [
    path('', include(router.urls)),
]
