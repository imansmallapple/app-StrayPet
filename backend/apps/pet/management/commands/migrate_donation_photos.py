"""
Management command to migrate donation photos to existing pets created from donations.
"""
from django.core.management.base import BaseCommand
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from apps.pet.models import Pet, PetPhoto, Donation


class Command(BaseCommand):
    help = 'Migrate donation photos to existing pets created from donations'

    def add_arguments(self, parser):
        parser.add_argument(
            '--pet-id',
            type=int,
            help='Specific pet ID to migrate photos for',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be done without actually doing it',
        )

    def handle(self, *args, **options):
        pet_id = options.get('pet_id')
        dry_run = options.get('dry_run', False)

        # Find donations with created_pet
        if pet_id:
            donations = Donation.objects.filter(created_pet_id=pet_id, created_pet__isnull=False)
        else:
            donations = Donation.objects.filter(created_pet__isnull=False)

        if not donations.exists():
            self.stdout.write(self.style.WARNING('No donations with created pets found'))
            return

        total_processed = 0
        total_photos_added = 0

        for donation in donations:
            pet = donation.created_pet
            
            # Skip if pet already has photos
            existing_count = pet.photos.count()
            donation_photos_count = donation.photos.count()
            
            if existing_count >= donation_photos_count:
                self.stdout.write(
                    self.style.WARNING(
                        f'Pet "{pet.name}" (ID: {pet.id}) already has {existing_count} photos, skipping'
                    )
                )
                continue

            self.stdout.write(f'\nProcessing Pet "{pet.name}" (ID: {pet.id}) from Donation ID: {donation.id}')
            self.stdout.write(f'  Donation has {donation_photos_count} photos, Pet has {existing_count} photos')

            if dry_run:
                self.stdout.write(self.style.WARNING(f'  [DRY RUN] Would add {donation_photos_count} photos'))
                continue

            # Delete existing PetPhotos to avoid duplicates
            if existing_count > 0:
                pet.photos.all().delete()
                self.stdout.write(f'  Deleted {existing_count} existing photos')

            # Copy all donation photos to PetPhoto
            donation_photos = donation.photos.order_by("id").all()
            for idx, donation_photo in enumerate(donation_photos):
                if not donation_photo.image:
                    continue

                try:
                    # Read photo data
                    donation_photo.image.open("rb")
                    data = donation_photo.image.read()
                    donation_photo.image.close()

                    # Generate new filename
                    orig_name = donation_photo.image.name.split("/")[-1]

                    # First photo as cover (update if needed)
                    if idx == 0 and not pet.cover:
                        target_path = f"pets/{pet.id}_{orig_name}"
                        saved_path = default_storage.save(target_path, ContentFile(data))
                        pet.cover.name = saved_path
                        pet.save(update_fields=["cover"])
                        self.stdout.write(self.style.SUCCESS(f'  ✓ Set cover photo'))

                    # Create PetPhoto
                    pet_photo = PetPhoto.objects.create(
                        pet=pet,
                        order=idx,
                    )
                    photo_target_path = f"pets/photos/{pet.id}_{idx}_{orig_name}"
                    pet_photo.image.save(photo_target_path, ContentFile(data), save=True)
                    total_photos_added += 1
                    self.stdout.write(self.style.SUCCESS(f'  ✓ Added photo {idx + 1}/{donation_photos_count}'))

                except Exception as e:
                    self.stdout.write(
                        self.style.ERROR(f'  ✗ Failed to copy photo {idx}: {str(e)}')
                    )
                    continue

            total_processed += 1

        if dry_run:
            self.stdout.write(self.style.SUCCESS(f'\n[DRY RUN] Would process {donations.count()} pet(s)'))
        else:
            self.stdout.write(
                self.style.SUCCESS(
                    f'\n✓ Done! Processed {total_processed} pet(s), added {total_photos_added} photos'
                )
            )
