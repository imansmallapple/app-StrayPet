# apps/pet/management/commands/seed_pets.py
import random
import os
import shutil
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.conf import settings
from apps.pet.models import Pet

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed database with sample pet data'

    def add_arguments(self, parser):
        parser.add_argument(
            '--update-images',
            action='store_true',
            help='Update images for existing pets without cover',
        )

    def handle(self, *args, **options):
        # 获取或创建一个用户
        user, created = User.objects.get_or_create(
            username='admin',
            defaults={'email': 'admin@example.com', 'is_staff': True, 'is_superuser': True}
        )
        if created:
            user.set_password('admin123')
            user.save()
            self.stdout.write(self.style.SUCCESS(f'Created admin user'))

        # 宠物数据
        pets_data = [
            # 狗
            {'name': 'Max', 'species': 'dog', 'breed': 'Golden Retriever', 'sex': 'male', 'age_years': 2, 'age_months': 6, 'size': 'large', 'description': 'Friendly and energetic golden retriever, loves to play fetch!'},
            {'name': 'Bella', 'species': 'dog', 'breed': 'Labrador', 'sex': 'female', 'age_years': 1, 'age_months': 8, 'size': 'large', 'description': 'Sweet and gentle lab looking for a loving home.'},
            {'name': 'Rocky', 'species': 'dog', 'breed': 'German Shepherd', 'sex': 'male', 'age_years': 3, 'age_months': 0, 'size': 'large', 'description': 'Loyal and protective, great with kids.'},
            {'name': 'Luna', 'species': 'dog', 'breed': 'Husky', 'sex': 'female', 'age_years': 2, 'age_months': 3, 'size': 'medium', 'description': 'Beautiful blue eyes, very playful and active.'},
            {'name': 'Charlie', 'species': 'dog', 'breed': 'Beagle', 'sex': 'male', 'age_years': 4, 'age_months': 2, 'size': 'medium', 'description': 'Curious and friendly beagle, loves walks.'},
            {'name': 'Daisy', 'species': 'dog', 'breed': 'Poodle', 'sex': 'female', 'age_years': 1, 'age_months': 5, 'size': 'small', 'description': 'Intelligent and hypoallergenic, perfect for apartments.'},
            {'name': 'Cooper', 'species': 'dog', 'breed': 'Bulldog', 'sex': 'male', 'age_years': 5, 'age_months': 0, 'size': 'medium', 'description': 'Calm and loving bulldog, great companion.'},
            {'name': 'Sadie', 'species': 'dog', 'breed': 'Corgi', 'sex': 'female', 'age_years': 2, 'age_months': 9, 'size': 'small', 'description': 'Adorable corgi with lots of personality!'},
            
            # 猫
            {'name': 'Whiskers', 'species': 'cat', 'breed': 'Persian', 'sex': 'male', 'age_years': 3, 'age_months': 4, 'size': 'medium', 'description': 'Fluffy and calm Persian cat, loves to cuddle.'},
            {'name': 'Mittens', 'species': 'cat', 'breed': 'Siamese', 'sex': 'female', 'age_years': 2, 'age_months': 0, 'size': 'small', 'description': 'Vocal and affectionate Siamese beauty.'},
            {'name': 'Shadow', 'species': 'cat', 'breed': 'British Shorthair', 'sex': 'male', 'age_years': 4, 'age_months': 6, 'size': 'medium', 'description': 'Independent but loving, great for busy owners.'},
            {'name': 'Cleo', 'species': 'cat', 'breed': 'Maine Coon', 'sex': 'female', 'age_years': 1, 'age_months': 10, 'size': 'large', 'description': 'Gentle giant with a playful personality.'},
            {'name': 'Tiger', 'species': 'cat', 'breed': 'Tabby', 'sex': 'male', 'age_years': 2, 'age_months': 2, 'size': 'medium', 'description': 'Striped tabby with lots of energy and love.'},
            {'name': 'Snowball', 'species': 'cat', 'breed': 'Ragdoll', 'sex': 'female', 'age_years': 3, 'age_months': 1, 'size': 'medium', 'description': 'Pure white beauty, very docile and sweet.'},
            
            # 兔子
            {'name': 'Bunny', 'species': 'rabbit', 'breed': 'Holland Lop', 'sex': 'female', 'age_years': 1, 'age_months': 3, 'size': 'small', 'description': 'Adorable lop-eared bunny, loves veggies!'},
            {'name': 'Thumper', 'species': 'rabbit', 'breed': 'Dutch Rabbit', 'sex': 'male', 'age_years': 2, 'age_months': 0, 'size': 'small', 'description': 'Active and curious, great with children.'},
            {'name': 'Cotton', 'species': 'rabbit', 'breed': 'Angora', 'sex': 'female', 'age_years': 1, 'age_months': 8, 'size': 'small', 'description': 'Fluffy angora rabbit, needs regular grooming.'},
            
            # 鸟
            {'name': 'Tweety', 'species': 'bird', 'breed': 'Canary', 'sex': 'male', 'age_years': 1, 'age_months': 0, 'size': 'small', 'description': 'Beautiful yellow canary with a lovely song.'},
            {'name': 'Polly', 'species': 'bird', 'breed': 'Parrot', 'sex': 'female', 'age_years': 5, 'age_months': 6, 'size': 'medium', 'description': 'Colorful parrot that can talk and do tricks!'},
            {'name': 'Sky', 'species': 'bird', 'breed': 'Budgie', 'sex': 'male', 'age_years': 0, 'age_months': 8, 'size': 'small', 'description': 'Cheerful blue budgie, loves to chirp.'},
            
            # 其他
            {'name': 'Shelly', 'species': 'other', 'breed': 'Turtle', 'sex': 'female', 'age_years': 10, 'age_months': 0, 'size': 'small', 'description': 'Calm and low-maintenance pet turtle.'},
            {'name': 'Hammy', 'species': 'other', 'breed': 'Hamster', 'sex': 'male', 'age_years': 0, 'age_months': 6, 'size': 'small', 'description': 'Cute hamster, loves running on the wheel!'},
            {'name': 'Goldie', 'species': 'other', 'breed': 'Goldfish', 'sex': 'female', 'age_years': 1, 'age_months': 2, 'size': 'small', 'description': 'Beautiful orange goldfish, easy to care for.'},
        ]

        # 可用的示例图片
        sample_images = [
            'pets/neko.jpg',
            'pets/pet1.png',
            'pets/pet2.png',
            'pets/pet3.png',
            'pets/VCG211221459334.jpg',
            'pets/furkids-com-tw-QsFCDa-G4a8-unsplash.jpg',
        ]

        created_count = 0
        for pet_data in pets_data:
            # 随机设置一些属性
            pet_data['vaccinated'] = random.choice([True, False])
            pet_data['dewormed'] = random.choice([True, False])
            pet_data['microchipped'] = random.choice([True, False])
            pet_data['child_friendly'] = random.choice([True, False])
            pet_data['trained'] = random.choice([True, False])
            pet_data['sterilized'] = random.choice([True, False])
            pet_data['good_with_dogs'] = random.choice([True, False])
            pet_data['good_with_cats'] = random.choice([True, False])
            pet_data['loves_play'] = random.choice([True, False])
            pet_data['loves_walks'] = random.choice([True, False])
            pet_data['affectionate'] = random.choice([True, False])
            pet_data['needs_attention'] = random.choice([True, False])
            
            pet, created = Pet.objects.get_or_create(
                name=pet_data['name'],
                species=pet_data['species'],
                defaults={
                    **pet_data,
                    'created_by': user,
                    'status': Pet.Status.AVAILABLE,
                }
            )
            if created:
                created_count += 1
                self.stdout.write(f'Created pet: {pet.name} ({pet.species})')

        self.stdout.write(self.style.SUCCESS(f'Successfully created {created_count} pets!'))
        self.stdout.write(self.style.SUCCESS(f'Total pets in database: {Pet.objects.count()}'))

        # 为没有图片的宠物添加图片
        if options.get('update_images') or created_count > 0:
            self.update_pet_images(sample_images)

    def update_pet_images(self, sample_images):
        """为没有cover的宠物分配图片"""
        pets_without_cover = Pet.objects.filter(cover='') | Pet.objects.filter(cover__isnull=True)
        updated_count = 0
        
        for pet in pets_without_cover:
            # 根据物种选择合适的图片
            image_path = random.choice(sample_images)
            pet.cover = image_path
            pet.save(update_fields=['cover'])
            updated_count += 1
            self.stdout.write(f'Added image to: {pet.name} -> {image_path}')
        
        self.stdout.write(self.style.SUCCESS(f'Updated images for {updated_count} pets!'))
