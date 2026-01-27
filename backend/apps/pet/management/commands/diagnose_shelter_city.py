"""
管理命令：诊断收容所城市关联
"""
from django.core.management.base import BaseCommand
from apps.pet.models import Shelter, Pet
from apps.pet.serializers import PetListSerializer

class Command(BaseCommand):
    help = '诊断收容所和地址的城市关联情况'

    def handle(self, *args, **options):
        self.stdout.write("=" * 80)
        self.stdout.write("🔍 诊断收容所地址和城市关联")
        self.stdout.write("=" * 80)

        # 检查收容所
        self.stdout.write("\n[1] 检查收容所...")
        shelters = Shelter.objects.all()
        self.stdout.write(f"总收容所数: {shelters.count()}")

        for shelter in shelters[:5]:
            self.stdout.write(f"\n  📦 {shelter.name}")
            self.stdout.write(f"     - ID: {shelter.id}")
            self.stdout.write(f"     - address_id: {shelter.address_id}")
            
            if shelter.address:
                addr = shelter.address
                self.stdout.write(f"     - Address: {addr.street} {addr.building_number}")
                self.stdout.write(f"     - city_id: {addr.city_id}")
                if addr.city:
                    self.stdout.write(f"     - city.name: {addr.city.name} ✅")
                else:
                    self.stdout.write(f"     - ❌ address 没有 city")
            else:
                self.stdout.write(f"     - ❌ 没有地址")

        # 检查宠物
        self.stdout.write("\n\n[2] 检查宠物及其序列化...")
        pets = Pet.objects.all()[:5]

        for pet in pets:
            self.stdout.write(f"\n  🐾 {pet.name}")
            self.stdout.write(f"     - ID: {pet.id}")
            self.stdout.write(f"     - shelter_id: {pet.shelter_id}")
            
            if pet.shelter:
                self.stdout.write(f"     - shelter: {pet.shelter.name}")
                if pet.shelter.address:
                    if pet.shelter.address.city:
                        self.stdout.write(f"       - city: {pet.shelter.address.city.name} ✅")
                    else:
                        self.stdout.write(f"       - ❌ address 没有 city")
                else:
                    self.stdout.write(f"       - ❌ shelter 没有 address")
            else:
                self.stdout.write(f"     - ❌ 没有 shelter")
            
            # 序列化测试
            serializer = PetListSerializer(pet)
            city_value = serializer.data.get('city', 'MISSING')
            status = "✅" if city_value else "❌"
            self.stdout.write(f"     - 序列化 city: '{city_value}' {status}")

        self.stdout.write("\n" + "=" * 80)
