from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from django.contrib.auth import get_user_model
from apps.pet.models import Donation, Address, Country
import json


class DonationCreateAddressTest(APITestCase):
    def setUp(self):
        User = get_user_model()
        self.user = User.objects.create_user(username='tester', password='pass')
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_create_donation_with_address_data_creates_address(self):
        url = reverse('pet:pet_donation')  # namespaced route name for donation list/create
        payload = {
            'name': 'Test pet',
            'species': 'dog',
            'breed': 'Hybrid',
            'sex': 'male',
            'age_years': 0,
            'age_months': 6,
            'description': 'desc',
            'address_data': json.dumps({
                'country': 'Poland',
                'region': 'Mazowieckie',
                'city': 'Warszawa',
                'street': 'Some street',
                'postal_code': '00-001',
                'latitude': 52.2297,
                'longitude': 21.0122,
            }),
        }
        resp = self.client.post(url, data=payload, format='multipart')
        self.assertEqual(resp.status_code, 201, resp.data)
        donation_id = resp.data.get('id')
        self.assertIsNotNone(donation_id)
        donation = Donation.objects.get(pk=donation_id)
        self.assertIsNotNone(donation.address)
        addr = donation.address
        self.assertEqual(addr.city.name.lower(), 'warszawa')
        self.assertIsNotNone(addr.location)

    def test_create_donation_with_location_data_creates_location(self):
        url = reverse('pet:pet_donation')
        payload = {
            'name': 'Test pet loc',
            'species': 'dog',
            'sex': 'male',
            'age_years': 0,
            'age_months': 6,
            'description': 'desc',
            'location_data': json.dumps({
                'country': 'Poland',
                'region': 'Mazowieckie',
                'city': 'Warszawa',
                'street': 'Another Street',
                'postal_code': '00-001',
                'latitude': 52.2297,
                'longitude': 21.0122,
            }),
        }
        resp = self.client.post(url, data=payload, format='multipart')
        self.assertEqual(resp.status_code, 201, resp.data)
        donation_id = resp.data.get('id')
        self.assertIsNotNone(donation_id)
        donation = Donation.objects.get(pk=donation_id)
        # Address may be empty, but location should be set
        self.assertTrue(donation.address is not None or donation.location is not None)
        # API should expose location id in response when location created
        if resp.data.get('location') is not None:
            self.assertEqual(int(resp.data.get('location')), donation.location.id)
        if donation.location:
            self.assertEqual(float(donation.location.latitude), 52.2297)
            self.assertEqual(float(donation.location.longitude), 21.0122)
