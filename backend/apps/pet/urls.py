# apps/pet/urls.py
from rest_framework.routers import DefaultRouter
from .views import PetViewSet, AdoptionViewSet, LostViewSet, DonationViewSet, ShelterViewSet, TicketViewSet
from django.urls import path, include
from apps.pet.views import LostGeoViewSet, HolidayFamilyViewSet

router = DefaultRouter()
router.register(r'', PetViewSet, basename='pet')
router.register(r'adoption', AdoptionViewSet, basename='pet-application')
router.register(r'lost', LostViewSet, basename='lost')
router.register(r'donation', DonationViewSet, basename='donation')
router.register(r"lost_geo", LostGeoViewSet, basename="lost-geo")
router.register(r'shelter', ShelterViewSet, basename='shelter')
router.register(r'ticket', TicketViewSet, basename='ticket')
router.register(r'holiday-family', HolidayFamilyViewSet, basename='holiday-family')

urlpatterns = [
	# Explicit lost routes to ensure /pet/lost/ resolves
	path(
		'lost/',
		LostViewSet.as_view({'get': 'list', 'post': 'create'}),
		name='pet_lost'
	),
	path(
		'lost/<int:pk>/',
		LostViewSet.as_view({'get': 'retrieve', 'patch': 'partial_update', 'delete': 'destroy'}),
		name='pet_lost_detail'
	),
	# Explicit donation routes to ensure /pet/donation/ resolves
	path(
		'donation/',
		DonationViewSet.as_view({'get': 'list', 'post': 'create'}),
		name='pet_donation'
	),
	path(
		'donation/<int:pk>/',
		DonationViewSet.as_view({'get': 'retrieve', 'patch': 'partial_update', 'delete': 'destroy'}),
		name='pet_donation_detail'
	),
	# Explicit shelter routes
	path(
		'shelter/',
		ShelterViewSet.as_view({'get': 'list', 'post': 'create'}),
		name='shelter_list'
	),
	path(
		'shelter/<int:pk>/',
		ShelterViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}),
		name='shelter_detail'
	),
	# Router-generated routes
	*router.urls
]
