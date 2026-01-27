"""
修改同城市lost pet的地址坐标，使它们不重叠
为了测试地图上的分城市分组功能
"""
from django.core.management.base import BaseCommand
from apps.pet.models import Lost, Address
from decimal import Decimal
import random


class Command(BaseCommand):
    help = 'Diversify lost pet coordinates by city to avoid overlap on map'

    # Wroclaw areas with unique street addresses
    WROCLAW_AREAS = [
        {"lat": Decimal("51.1079"), "lng": Decimal("17.0385"), "street": "Stary Rynek 45"},
        {"lat": Decimal("51.1500"), "lng": Decimal("17.0450"), "street": "Al. Niepodległości 120"},
        {"lat": Decimal("51.0800"), "lng": Decimal("17.0250"), "street": "ul. Karłowicza 78"},
        {"lat": Decimal("51.1100"), "lng": Decimal("17.1000"), "street": "ul. Twardowskiego 56"},
        {"lat": Decimal("51.1100"), "lng": Decimal("16.9700"), "street": "ul. Generała Dąbrowskiego 23"},
        {"lat": Decimal("51.0900"), "lng": Decimal("17.0700"), "street": "Plac Grunwaldzki 12"},
        {"lat": Decimal("51.1300"), "lng": Decimal("16.9800"), "street": "ul. Bolesława Śmiałego 89"},
        {"lat": Decimal("51.0950"), "lng": Decimal("16.9600"), "street": "ul. Jana Długosza 34"},
    ]

    # Gdansk areas with unique street addresses
    GDANSK_AREAS = [
        {"lat": Decimal("54.3520"), "lng": Decimal("18.6466"), "street": "Długi Targ 28"},
        {"lat": Decimal("54.4000"), "lng": Decimal("18.6500"), "street": "ul. Kartuska 156"},
        {"lat": Decimal("54.3200"), "lng": Decimal("18.6400"), "street": "ul. Piastowska 91"},
        {"lat": Decimal("54.3500"), "lng": Decimal("18.7000"), "street": "ul. Energetyków 67"},
        {"lat": Decimal("54.3500"), "lng": Decimal("18.5900"), "street": "ul. Derdowskiego 44"},
    ]

    # Warsaw areas with unique street addresses
    WARSAW_AREAS = [
        {"lat": Decimal("52.2297"), "lng": Decimal("21.0122"), "street": "Plac Zamkowy 10"},
        {"lat": Decimal("52.2500"), "lng": Decimal("21.0200"), "street": "ul. Puławska 245"},
        {"lat": Decimal("52.2000"), "lng": Decimal("21.0100"), "street": "Al. Ujazdowskie 18"},
        {"lat": Decimal("52.2300"), "lng": Decimal("21.0800"), "street": "ul. Wiatraczna 73"},
        {"lat": Decimal("52.2300"), "lng": Decimal("20.9700"), "street": "ul. Słodowca 55"},
    ]

    # Krakow areas with unique street addresses
    KRAKOW_AREAS = [
        {"lat": Decimal("50.0616"), "lng": Decimal("19.9375"), "street": "Rynek Główny 3"},
        {"lat": Decimal("50.0700"), "lng": Decimal("19.9400"), "street": "ul. Floriańska 79"},
        {"lat": Decimal("50.0550"), "lng": Decimal("19.9500"), "street": "ul. Grodzka 42"},
        {"lat": Decimal("50.0480"), "lng": Decimal("19.9300"), "street": "ul. Szewska 15"},
    ]

    # Poznan areas with unique street addresses
    POZNAN_AREAS = [
        {"lat": Decimal("52.4069"), "lng": Decimal("16.9288"), "street": "Stary Rynek 88"},
        {"lat": Decimal("52.4079"), "lng": Decimal("16.9219"), "street": "ul. Święty Marcin 150"},
        {"lat": Decimal("52.4059"), "lng": Decimal("16.9307"), "street": "ul. Paderewskiego 57"},
        {"lat": Decimal("52.4086"), "lng": Decimal("16.9320"), "street": "Al. Marcinkowskiego 101"},
    ]

    # Szczecin areas with unique street addresses
    SZCZECIN_AREAS = [
        {"lat": Decimal("53.4384"), "lng": Decimal("14.5502"), "street": "Al. Papieża Jana Pawła II 30"},
        {"lat": Decimal("53.4316"), "lng": Decimal("14.5541"), "street": "ul. Niepodległości 72"},
        {"lat": Decimal("53.4273"), "lng": Decimal("14.5507"), "street": "ul. Bosaka 21"},
        {"lat": Decimal("53.4400"), "lng": Decimal("14.5600"), "street": "ul. 3 Maja 48"},
    ]

    # Lodz areas with unique street addresses
    LODZ_AREAS = [
        {"lat": Decimal("51.7708"), "lng": Decimal("19.4511"), "street": "ul. Piotrkowska 119"},
        {"lat": Decimal("51.7609"), "lng": Decimal("19.4561"), "street": "ul. Przędzalniana 62"},
        {"lat": Decimal("51.7575"), "lng": Decimal("19.4479"), "street": "Plac Wolności 9"},
        {"lat": Decimal("51.7650"), "lng": Decimal("19.4600"), "street": "ul. Zachodnia 85"},
    ]

    # Katowice areas with unique street addresses
    KATOWICE_AREAS = [
        {"lat": Decimal("50.2722"), "lng": Decimal("19.0316"), "street": "ul. 3 Maja 15"},
        {"lat": Decimal("50.2574"), "lng": Decimal("19.0186"), "street": "ul. Mariacka 57"},
        {"lat": Decimal("50.2600"), "lng": Decimal("19.0250"), "street": "Rynek 33"},
    ]

    CITY_AREAS = {
        "Wrocław": WROCLAW_AREAS,
        "Gdańsk": GDANSK_AREAS,
        "Warszawa": WARSAW_AREAS,
        "Kraków": KRAKOW_AREAS,
        "Poznań": POZNAN_AREAS,
        "Szczecin": SZCZECIN_AREAS,
        "Łódź": LODZ_AREAS,
        "Katowice": KATOWICE_AREAS,
    }

    def handle(self, *args, **options):
        """Group lost pets by city and assign different coordinates"""
        
        self.stdout.write("🗺️ Diversifying lost pet coordinates by city...\n")
        
        # Get all lost pets grouped by city
        lost_pets = Lost.objects.all().select_related('address', 'address__city')
        
        if not lost_pets.exists():
            self.stdout.write(self.style.ERROR("❌ No lost pets found!"))
            return
        
        # Group by city
        by_city = {}
        for lost in lost_pets:
            city = lost.address.city.name if lost.address and lost.address.city else "Unknown"
            if city not in by_city:
                by_city[city] = []
            by_city[city].append(lost)
        
        total_updated = 0
        
        for city_name, lost_list in by_city.items():
            self.stdout.write(f"\n📍 Processing city: {city_name} ({len(lost_list)} pets)")
            
            # Get the areas for this city (or use random variations)
            areas = self.CITY_AREAS.get(city_name, None)
            
            if not areas and len(lost_list) > 1:
                # If no predefined areas, create variations from first pet's coordinates
                first_lost = lost_list[0]
                if first_lost.address and first_lost.address.latitude and first_lost.address.longitude:
                    base_lat = float(first_lost.address.latitude)
                    base_lng = float(first_lost.address.longitude)
                    areas = []
                    for i in range(len(lost_list)):
                        # Add small random variations (±0.01 degrees ≈ 1km)
                        lat = Decimal(str(base_lat + random.uniform(-0.01, 0.01)))
                        lng = Decimal(str(base_lng + random.uniform(-0.01, 0.01)))
                        areas.append({"lat": lat, "lng": lng, "street": f"Location {i+1}"})
                else:
                    self.stdout.write(self.style.WARNING(f"   ⚠️ First pet has no coordinates, skipping"))
                    continue
            
            if not areas:
                self.stdout.write(self.style.WARNING(f"   ⚠️ No predefined areas for {city_name}, skipping"))
                continue
            
            # Assign different coordinates to each pet in this city
            for idx, lost in enumerate(lost_list):
                area_idx = idx % len(areas)
                area = areas[area_idx]
                
                if not lost.address:
                    self.stdout.write(self.style.WARNING(f"   ⚠️ {lost.pet_name} has no address, creating one"))
                    # Create address if needed
                    lost.address = Address.objects.create(
                        city_id=lost_list[0].address.city_id if lost_list[0].address else None,
                        latitude=area["lat"],
                        longitude=area["lng"],
                        street=area["street"]
                    )
                else:
                    # Update existing address
                    lost.address.latitude = area["lat"]
                    lost.address.longitude = area["lng"]
                    lost.address.street = area["street"]
                    lost.address.save()
                
                lost.save()
                total_updated += 1
                
                self.stdout.write(f"   ✅ {lost.pet_name}: [{area['lat']}, {area['lng']}] {area['street']}")
        
        self.stdout.write(self.style.SUCCESS(f"\n✨ Updated {total_updated} lost pets total"))
        self.stdout.write(self.style.SUCCESS("✅ Done!"))
