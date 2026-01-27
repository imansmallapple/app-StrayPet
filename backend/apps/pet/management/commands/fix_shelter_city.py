"""
管理命令：修复收容所地址的城市关联
"""
from django.core.management.base import BaseCommand
from apps.pet.models import Shelter, Address, Country, Region, City

class Command(BaseCommand):
    help = '为收容所地址关联城市'

    def handle(self, *args, **options):
        self.stdout.write("=" * 80)
        self.stdout.write("🔧 修复收容所地址的城市关联")
        self.stdout.write("=" * 80)

        # Step 1: 确保有基础地理数据
        self.stdout.write("\n[1] 创建或获取地理数据...")
        
        poland, _ = Country.objects.get_or_create(code='PL', defaults={'name': 'Poland'})
        self.stdout.write(f"  ✅ Country: Poland")
        
        # 波兰主要城市和地区
        cities_data = {
            'Warsaw': 'Masovian',
            'Krakow': 'Lesser Poland',
            'Gdansk': 'Pomeranian',
            'Wroclaw': 'Lower Silesian',
            'Poznan': 'Greater Poland',
            'Lodz': 'Lodz',
        }
        
        cities_dict = {}
        for city_name, region_name in cities_data.items():
            region, _ = Region.objects.get_or_create(
                country=poland,
                name=region_name
            )
            city, _ = City.objects.get_or_create(
                region=region,
                name=city_name
            )
            cities_dict[city_name] = city
            self.stdout.write(f"  ✅ {region_name} - {city_name}")

        # Step 2: 为收容所地址添加城市
        self.stdout.write("\n[2] 为收容所地址添加城市...")
        
        shelters = Shelter.objects.all()
        updated = 0
        
        for idx, shelter in enumerate(shelters):
            if shelter.address:
                if not shelter.address.city_id:
                    # 从城市列表中循环选择一个城市
                    city = list(cities_dict.values())[idx % len(cities_dict)]
                    shelter.address.city = city
                    shelter.address.region = city.region
                    shelter.address.country = city.region.country
                    shelter.address.save()
                    updated += 1
                    self.stdout.write(f"  ✅ {shelter.name}: 关联到 {city.name}")
                else:
                    self.stdout.write(f"  ✓ {shelter.name}: 已有城市 ({shelter.address.city.name})")
            else:
                self.stdout.write(f"  ⚠️  {shelter.name}: 没有地址")

        self.stdout.write(f"\n✅ 更新完成: {updated} 个地址")
        self.stdout.write("=" * 80)
