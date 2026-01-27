"""
Management command to add test photos to pets for testing the carousel feature.
"""
from django.core.management.base import BaseCommand
from django.core.files.base import ContentFile
from apps.pet.models import Pet, PetPhoto
import os


class Command(BaseCommand):
    help = 'Add test photos to pets by duplicating their cover image'

    def add_arguments(self, parser):
        parser.add_argument(
            '--pet-id',
            type=int,
            help='Pet ID to add photos to (if not specified, adds to all pets with covers)',
        )
        parser.add_argument(
            '--count',
            type=int,
            default=2,
            help='Number of photos to add per pet (default: 2)',
        )

    def handle(self, *args, **options):
        pet_id = options.get('pet_id')
        count = options.get('count', 2)

        if pet_id:
            pets = Pet.objects.filter(id=pet_id, cover__isnull=False)
        else:
            pets = Pet.objects.filter(cover__isnull=False)

        if not pets.exists():
            self.stdout.write(self.style.ERROR('No pets found with cover images'))
            return

        for pet in pets:
            # Skip if already has photos
            if pet.photos.exists():
                self.stdout.write(
                    self.style.WARNING(f'Pet "{pet.name}" already has {pet.photos.count()} photos, skipping')
                )
                continue

            try:
                # Read the cover image
                pet.cover.open('rb')
                image_data = pet.cover.read()
                pet.cover.close()

                # Get the original filename
                original_name = os.path.basename(pet.cover.name)
                name_parts = os.path.splitext(original_name)
                base_name = name_parts[0]
                extension = name_parts[1]

                # Create multiple photos
                for i in range(count):
                    new_name = f"{base_name}_copy_{i+1}{extension}"
                    photo = PetPhoto.objects.create(
                        pet=pet,
                        order=i,
                    )
                    photo.image.save(new_name, ContentFile(image_data), save=True)
                    self.stdout.write(
                        self.style.SUCCESS(f'✓ Added photo {i+1} to pet "{pet.name}"')
                    )

            except Exception as e:
                self.stdout.write(
                    self.style.ERROR(f'✗ Failed to add photos to pet "{pet.name}": {str(e)}')
                )
                continue

        self.stdout.write(self.style.SUCCESS(f'\nDone! Added photos to {pets.count()} pet(s)'))
