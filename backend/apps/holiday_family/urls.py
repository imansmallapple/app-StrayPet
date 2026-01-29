from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import HolidayFamilyApplicationViewSet, ApprovedFamiliesListView

router = DefaultRouter()
router.register(r'', HolidayFamilyApplicationViewSet, basename='holiday-family')

urlpatterns = [
    path('approved/', ApprovedFamiliesListView.as_view(), name='approved-families'),
    path('', include(router.urls)),
]
