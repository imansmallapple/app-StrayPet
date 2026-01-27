from django.core.management.base import BaseCommand
from django.db import transaction
from django.contrib.gis.geos import Point
from apps.pet.models import Address
from common.utils import geocode_address
from django.db.models import Q


class Command(BaseCommand):
    help = "Geocode Address rows missing latitude/longitude and save results."

    def add_arguments(self, parser):
        parser.add_argument('--limit', type=int, default=500, help='Max rows to process')
        parser.add_argument('--dry-run', action='store_true', help='Only print, do not write changes')
        parser.add_argument('--recalc', action='store_true', help='Recalculate even if coordinates already exist')
        parser.add_argument('--filter', dest='filter_substr', type=str, help='Only process addresses containing this substring (street/city/region/country/postal/postfix)')

    def handle(self, *args, **options):
        limit = options['limit']
        dry = options['dry_run']
        recalc = options['recalc']
        filt = options.get('filter_substr')

        if recalc:
            qs = Address.objects.all()
        else:
            qs = Address.objects.filter(Q(latitude__isnull=True) | Q(longitude__isnull=True))

        if filt:
            qs = qs.filter(
                Q(street__icontains=filt) |
                Q(building_number__icontains=filt) |
                Q(postal_code__icontains=filt) |
                Q(city__name__icontains=filt) |
                Q(region__name__icontains=filt) |
                Q(country__name__icontains=filt)
            )

        qs = qs.order_by('id')[:limit]
        total = qs.count()
        self.stdout.write(self.style.NOTICE(f'Processing {total} address rows (limit={limit})'))
        updated = 0

        for addr in qs:
            parts = [
                addr.street or '',
                addr.building_number or '',
                getattr(addr.city, 'name', '') if getattr(addr, 'city_id', None) else '',
                getattr(addr.region, 'name', '') if getattr(addr, 'region_id', None) else '',
                getattr(addr.country, 'name', '') if getattr(addr, 'country_id', None) else '',
                addr.postal_code or '',
            ]
            s = ', '.join([p for p in parts if p])
            if not s:
                continue
            ctx = {
                'street': (f"{addr.street} {addr.building_number}".strip()) if (addr.street or addr.building_number) else None,
                'city': getattr(addr.city, 'name', None) if getattr(addr, 'city_id', None) else None,
                'region': getattr(addr.region, 'name', None) if getattr(addr, 'region_id', None) else None,
                'country': getattr(addr.country, 'name', None) if getattr(addr, 'country_id', None) else None,
                'country_code': getattr(getattr(addr, 'country', None), 'code', None) if getattr(addr, 'country_id', None) else None,
                'postal_code': addr.postal_code or None,
            }
            coords = geocode_address(s, context=ctx)
            if not coords:
                continue
            lon, lat = coords
            if dry:
                self.stdout.write(f'[dry-run] id={addr.id} -> {lat},{lon} ({s})')
                updated += 1
                continue
            with transaction.atomic():
                addr.latitude = lat
                addr.longitude = lon
                try:
                    addr.location = Point(lon, lat)
                except Exception:
                    pass
                addr.save(update_fields=['latitude', 'longitude', 'location'])
                updated += 1
        self.stdout.write(self.style.SUCCESS(f'Done. Updated {updated} rows.'))
