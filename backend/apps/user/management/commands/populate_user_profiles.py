"""
Management command to populate user profiles with sample data and avatars.
Run with: python manage.py populate_user_profiles
"""
import random
import os
import requests
from io import BytesIO
from django.core.management.base import BaseCommand
from django.core.files.base import ContentFile
from django.contrib.auth import get_user_model
from apps.user.models import UserProfile

User = get_user_model()

# Sample data for profiles
FIRST_NAMES = ['Alex', 'Jordan', 'Taylor', 'Morgan', 'Casey', 'Riley', 'Jamie', 'Drew', 'Avery', 'Quinn']
LAST_NAMES = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez']
PHONE_PREFIXES = ['+1', '+86', '+44', '+49', '+33']
LIVING_SITUATIONS = ['apartment', 'house', 'condo', 'townhouse', 'studio']
OTHER_PETS_OPTIONS = ['', 'One cat', 'Two dogs', 'A hamster', 'Three cats', 'One dog and two cats', 'Fish tank']
ADDITIONAL_NOTES_OPTIONS = [
    'I work from home so I can spend lots of time with my pet.',
    'Looking for a calm companion.',
    'Active lifestyle, love outdoor activities.',
    'First time pet owner but very excited!',
    'Experienced with rescue animals.',
    'Have a big backyard, perfect for dogs.',
    'Live in a quiet neighborhood.',
    'Looking for a playful friend for my kids.',
    '',
]
SPECIES_OPTIONS = ['dog', 'cat', '']
SIZE_OPTIONS = ['small', 'medium', 'large', '']
GENDER_OPTIONS = ['male', 'female', '']

# Avatar URLs from UI Avatars service (generates avatars based on initials)
def get_avatar_url(name):
    """Generate avatar URL using UI Avatars service"""
    colors = ['FF6B35', '4CAF50', '2196F3', '9C27B0', 'FF9800', 'E91E63', '00BCD4', '795548']
    bg_color = random.choice(colors)
    return f"https://ui-avatars.com/api/?name={name}&size=256&background={bg_color}&color=fff&bold=true"


class Command(BaseCommand):
    help = 'Populate user profiles with sample data and avatars'

    def add_arguments(self, parser):
        parser.add_argument(
            '--no-avatar',
            action='store_true',
            help='Skip downloading avatars',
        )

    def handle(self, *args, **options):
        skip_avatar = options.get('no_avatar', False)
        
        users = User.objects.all()
        updated_count = 0
        
        for user in users:
            # Get or create profile
            profile, created = UserProfile.objects.get_or_create(user=user)
            
            # Generate random data
            first_name = random.choice(FIRST_NAMES)
            last_name = random.choice(LAST_NAMES)
            
            # Update user's first and last name if empty
            if not user.first_name:
                user.first_name = first_name
            if not user.last_name:
                user.last_name = last_name
            user.save()
            
            # Update profile fields
            if not profile.phone:
                prefix = random.choice(PHONE_PREFIXES)
                number = ''.join([str(random.randint(0, 9)) for _ in range(10)])
                profile.phone = f"{prefix} {number[:3]}-{number[3:6]}-{number[6:]}"
            
            if not profile.living_situation:
                profile.living_situation = random.choice(LIVING_SITUATIONS)
            
            profile.has_yard = random.choice([True, False])
            profile.has_experience = random.choice([True, False])
            
            if not profile.other_pets:
                profile.other_pets = random.choice(OTHER_PETS_OPTIONS)
            
            if not profile.additional_notes:
                profile.additional_notes = random.choice(ADDITIONAL_NOTES_OPTIONS)
            
            # Pet preferences
            profile.preferred_species = random.choice(SPECIES_OPTIONS)
            profile.preferred_size = random.choice(SIZE_OPTIONS)
            profile.preferred_gender = random.choice(GENDER_OPTIONS)
            profile.preferred_age_min = random.choice([None, 1, 6, 12])
            profile.preferred_age_max = random.choice([None, 24, 60, 120])
            
            # Boolean preferences
            profile.prefer_vaccinated = random.choice([True, False])
            profile.prefer_sterilized = random.choice([True, False])
            profile.prefer_dewormed = random.choice([True, False])
            profile.prefer_child_friendly = random.choice([True, False])
            profile.prefer_trained = random.choice([True, False])
            profile.prefer_loves_play = random.choice([True, False])
            profile.prefer_loves_walks = random.choice([True, False])
            profile.prefer_good_with_dogs = random.choice([True, False])
            profile.prefer_good_with_cats = random.choice([True, False])
            profile.prefer_affectionate = random.choice([True, False])
            profile.prefer_needs_attention = random.choice([True, False])
            
            # Holiday family certification (random, 30% chance)
            profile.is_holiday_family_certified = random.random() < 0.3
            
            # Download and save avatar
            if not skip_avatar and not profile.avatar:
                try:
                    display_name = f"{user.first_name}+{user.last_name}"
                    avatar_url = get_avatar_url(display_name)
                    
                    response = requests.get(avatar_url, timeout=10)
                    if response.status_code == 200:
                        filename = f"avatar_{user.username}.png"
                        profile.avatar.save(filename, ContentFile(response.content), save=False)
                        self.stdout.write(f"  Downloaded avatar for {user.username}")
                except Exception as e:
                    self.stdout.write(self.style.WARNING(f"  Failed to download avatar for {user.username}: {e}"))
            
            profile.save()
            updated_count += 1
            self.stdout.write(self.style.SUCCESS(f"Updated profile for: {user.username}"))
        
        self.stdout.write(self.style.SUCCESS(f"\nSuccessfully updated {updated_count} user profiles!"))
