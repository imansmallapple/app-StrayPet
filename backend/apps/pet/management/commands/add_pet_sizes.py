"""
管理命令：为所有宠物添加 size 值
"""
from django.core.management.base import BaseCommand
from apps.pet.models import Pet

class Command(BaseCommand):
    help = '为所有没有 size 的宠物添加默认 size 值'

    def handle(self, *args, **options):
        self.stdout.write("=" * 80)
        self.stdout.write("🔧 为宠物添加 Size 值")
        self.stdout.write("=" * 80)

        # 获取所有 size 为空的宠物
        pets_without_size = Pet.objects.filter(size='')
        total = pets_without_size.count()
        
        if total == 0:
            self.stdout.write("✅ 所有宠物都已有 Size 值")
            return

        self.stdout.write(f"\n找到 {total} 个宠物需要添加 Size")

        # Size 分配策略：根据物种和品种分配
        # 可以修改这个逻辑来满足实际需求
        small_breeds = ['chihuahua', 'poodle', 'dachshund', 'pug', 'shih tzu', 'maltese', 'yorkie']
        large_breeds = ['german shepherd', 'retriever', 'husky', 'boxer', 'doberman', 'rottweiler', 'labrador']
        
        updated = 0
        for pet in pets_without_size:
            # 根据品种分配 size
            if pet.breed:
                breed_lower = pet.breed.lower()
                if any(small_breed in breed_lower for small_breed in small_breeds):
                    pet.size = 'Small'
                elif any(large_breed in breed_lower for large_breed in large_breeds):
                    pet.size = 'Large'
                else:
                    pet.size = 'Medium'
            else:
                # 如果没有品种，按物种分配
                if pet.species == 'cat':
                    pet.size = 'Small'
                elif pet.species == 'dog':
                    pet.size = 'Medium'
                else:
                    pet.size = 'Medium'
            
            pet.save(update_fields=['size'])
            updated += 1
            self.stdout.write(f"✅ {pet.name}: {pet.size}")

        self.stdout.write(f"\n✅ 成功更新 {updated} 个宠物的 Size")
        self.stdout.write("=" * 80)
