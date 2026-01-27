from django.core.management.base import BaseCommand
from apps.pet.models import Country, Region, City

# 你可以继续往这个 dict 里加其它国家/地区
PL_CITIES = {
    # key 用 Region 的名字（和 pycountry.subdivisions 的 name 一致）
    "Dolnośląskie": ["Wrocław", "Legnica", "Jelenia Góra", "Wałbrzych"],
    "Kujawsko-Pomorskie": ["Bydgoszcz", "Toruń", "Włocławek", "Grudziądz"],
    "Lubelskie": ["Lublin", "Chełm", "Zamość", "Biała Podlaska"],
    "Lubuskie": ["Zielona Góra", "Gorzów Wielkopolski"],
    "Łódzkie": ["Łódź", "Piotrków Trybunalski", "Pabianice"],
    "Małopolskie": ["Kraków", "Tarnów", "Nowy Sącz", "Oświęcim"],
    "Mazowieckie": ["Warszawa", "Płock", "Radom", "Siedlce", "Ostrołęka"],
    "Opolskie": ["Opole", "Kędzierzyn-Koźle"],
    "Podkarpackie": ["Rzeszów", "Przemyśl", "Tarnobrzeg", "Krosno"],
    "Podlaskie": ["Białystok", "Łomża", "Suwałki"],
    "Pomorskie": ["Gdańsk", "Gdynia", "Sopot", "Słupsk"],
    "Śląskie": ["Katowice", "Gliwice", "Bytom", "Częstochowa", "Sosnowiec"],
    "Świętokrzyskie": ["Kielce", "Ostrowiec Świętokrzyski"],
    "Warmińsko-Mazurskie": ["Olsztyn", "Elbląg"],
    "Wielkopolskie": ["Poznań", "Kalisz", "Konin", "Leszno", "Gniezno"],
    "Zachodniopomorskie": ["Szczecin", "Koszalin", "Świnoujście"],
}


class Command(BaseCommand):
    help = "Seed cities for selected countries/regions"

    def add_arguments(self, parser):
        parser.add_argument("--country", default="PL", help="ISO alpha-2 code, default PL")

    def handle(self, *args, **opts):
        code = opts["country"].upper()
        try:
            country = Country.objects.get(code=code)
        except Country.DoesNotExist:
            self.stderr.write(self.style.ERROR(f"Country {code} not found. Run seed_countries first."))
            return

        if code == "PL":
            mapping = PL_CITIES
        else:
            self.stderr.write(self.style.ERROR(f"No city seed mapping for {code}. Add it in seed_cities.py"))
            return

        created = 0
        for region_name, cities in mapping.items():
            try:
                region = Region.objects.get(country=country, name=region_name)
            except Region.DoesNotExist:
                self.stderr.write(self.style.WARNING(f"Region '{region_name}' not found; skipping"))
                continue
            for name in cities:
                obj, is_new = City.objects.get_or_create(region=region, name=name)
                created += int(is_new)

        self.stdout.write(self.style.SUCCESS(f"Seeded {created} city rows for country {code}"))
