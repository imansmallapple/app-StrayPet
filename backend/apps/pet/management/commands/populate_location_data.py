# management/commands/populate_location_data.py
"""
Populate location coordinates (latitude/longitude) for Lost pets and Shelters.
This allows them to be displayed on the map.

Usage:
    python manage.py populate_location_data
"""

from django.core.management.base import BaseCommand
from apps.pet.models import Lost, Shelter, Address
import random


class Command(BaseCommand):
    help = 'Populate location coordinates for Lost pets and Shelters'

    # Sample coordinates for major cities (lat, lng, city_name)
    SAMPLE_LOCATIONS = [
        # Beijing area
        (39.9042, 116.4074, 'Beijing'),
        (39.9219, 116.4437, 'Beijing Chaoyang'),
        (39.9628, 116.3456, 'Beijing Haidian'),
        (39.8673, 116.4979, 'Beijing Daxing'),
        # Shanghai area
        (31.2304, 121.4737, 'Shanghai'),
        (31.2397, 121.4998, 'Shanghai Pudong'),
        (31.2063, 121.4855, 'Shanghai Xuhui'),
        # Guangzhou area
        (23.1291, 113.2644, 'Guangzhou'),
        (23.1579, 113.2754, 'Guangzhou Tianhe'),
        # Shenzhen area
        (22.5431, 114.0579, 'Shenzhen'),
        (22.5329, 113.9436, 'Shenzhen Nanshan'),
        # Hangzhou area
        (30.2741, 120.1551, 'Hangzhou'),
        (30.2592, 120.2192, 'Hangzhou Xihu'),
        # Chengdu area
        (30.5728, 104.0668, 'Chengdu'),
        (30.6598, 104.0633, 'Chengdu Jinniu'),
    ]

    def add_random_offset(self, lat: float, lng: float) -> tuple:
        """Add small random offset to coordinates to spread markers"""
        lat_offset = random.uniform(-0.02, 0.02)
        lng_offset = random.uniform(-0.02, 0.02)
        return (lat + lat_offset, lng + lng_offset)

    def get_or_create_address_with_location(self, lat: float, lng: float) -> Address:
        """Create a new address with location data"""
        # Add small offset to avoid overlapping markers
        lat, lng = self.add_random_offset(lat, lng)
        
        address = Address.objects.create(
            street=f'Street {random.randint(1, 100)}',
            building_number=str(random.randint(1, 50)),
            latitude=round(lat, 6),
            longitude=round(lng, 6)
        )
        return address

    def handle(self, *args, **options):
        self.stdout.write('Populating location data for Lost pets and Shelters...')

        # Update Lost pets
        lost_pets = Lost.objects.all()
        updated_lost = 0
        
        for lost in lost_pets:
            # Pick a random location
            base_lat, base_lng, city = random.choice(self.SAMPLE_LOCATIONS)
            
            if lost.address is None:
                # Create new address with location
                lost.address = self.get_or_create_address_with_location(base_lat, base_lng)
                lost.save()
                updated_lost += 1
            elif lost.address.latitude is None or lost.address.latitude == 0:
                # Update existing address with location
                lat, lng = self.add_random_offset(base_lat, base_lng)
                lost.address.latitude = round(lat, 6)
                lost.address.longitude = round(lng, 6)
                lost.address.save()
                updated_lost += 1

        self.stdout.write(f'  Updated {updated_lost} Lost pets with location data')

        # Update Shelters
        shelters = Shelter.objects.all()
        updated_shelters = 0
        
        for shelter in shelters:
            # Pick a random location
            base_lat, base_lng, city = random.choice(self.SAMPLE_LOCATIONS)
            
            if shelter.address is None:
                # Create new address with location
                shelter.address = self.get_or_create_address_with_location(base_lat, base_lng)
                shelter.save()
                updated_shelters += 1
            elif shelter.address.latitude is None or shelter.address.latitude == 0:
                # Update existing address with location
                lat, lng = self.add_random_offset(base_lat, base_lng)
                shelter.address.latitude = round(lat, 6)
                shelter.address.longitude = round(lng, 6)
                shelter.address.save()
                updated_shelters += 1

        self.stdout.write(f'  Updated {updated_shelters} Shelters with location data')
        
        self.stdout.write(self.style.SUCCESS(
            f'Done! Total: {updated_lost} Lost pets, {updated_shelters} Shelters'
        ))
