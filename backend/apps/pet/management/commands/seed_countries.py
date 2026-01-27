# apps/pet/management/__init__.py  ← 空文件
# apps/pet/management/commands/__init__.py ← 空文件
# apps/pet/management/commands/seed_countries.py
from django.core.management.base import BaseCommand
import pycountry
from apps.pet.models import Country, Region  # 现在都在一个 models.py 里


class Command(BaseCommand):
    help = "Seed ISO countries and regions (ISO-3166)"

    def handle(self, *args, **kwargs):
        # Countries
        for c in pycountry.countries:
            Country.objects.get_or_create(code=c.alpha_2, defaults={"name": c.name})

        # Regions (ISO-3166-2 subdivisions)
        for sub in pycountry.subdivisions:
            try:
                country = Country.objects.get(code=sub.country_code)
            except Country.DoesNotExist:
                continue
            Region.objects.update_or_create(
                country=country,
                name=sub.name,  # 只用 name 和 country 保证唯一
                defaults={"code": sub.code},
            )

        self.stdout.write(self.style.SUCCESS("Seeded countries & regions"))
