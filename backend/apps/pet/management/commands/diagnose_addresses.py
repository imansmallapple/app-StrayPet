#!/usr/bin/env python
"""管理命令：诊断地址"""
import sys
from django.core.management.base import BaseCommand
from apps.pet.models import Pet, Shelter, Address, City

class Command(BaseCommand):
    help = '诊断宠物和地址关联情况'

    def handle(self, *args, **options):
        # 统计信息
        self.stdout.write("=== 数据库统计 ===")
        self.stdout.write(f"总宠物数: {Pet.objects.count()}")
        self.stdout.write(f"有地址的宠物: {Pet.objects.filter(address__isnull=False).count()}")
        self.stdout.write(f"无地址的宠物: {Pet.objects.filter(address__isnull=True).count()}")
        self.stdout.write(f"总收容所数: {Shelter.objects.count()}")
        self.stdout.write(f"有地址的收容所: {Shelter.objects.filter(address__isnull=False).count()}")
        self.stdout.write(f"总城市数: {City.objects.count()}")

        self.stdout.write("\n=== 检查前5个宠物 ===")
        for pet in Pet.objects.all()[:5]:
            self.stdout.write(f"\n{pet.name} (ID: {pet.id})")
            self.stdout.write(f"  - 宠物地址: {pet.address_id}")
            self.stdout.write(f"  - 宠物收容所: {pet.shelter_id}")
            
            if pet.address:
                self.stdout.write(f"  - 城市 ID: {pet.address.city_id}")
                self.stdout.write(f"  - 城市对象: {pet.address.city}")
                self.stdout.write(f"  - 城市名: {pet.address.city.name if pet.address.city else 'None'}")
            else:
                self.stdout.write(f"  - ❌ 没有地址")

        self.stdout.write("\n=== 查看收容所地址 ===")
        for shelter in Shelter.objects.filter(address__isnull=False)[:3]:
            self.stdout.write(f"\n{shelter.name}")
            self.stdout.write(f"  - 地址: {shelter.address}")
            if shelter.address and shelter.address.city:
                self.stdout.write(f"  - 城市: {shelter.address.city.name}")
            else:
                self.stdout.write(f"  - ❌ 没有城市")
