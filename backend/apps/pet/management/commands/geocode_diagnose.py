from django.core.management.base import BaseCommand
from django.conf import settings
import requests
import json


class Command(BaseCommand):
    help = "Diagnose geocoding by querying Mapbox and Nominatim directly and printing top candidates."

    def add_arguments(self, parser):
        parser.add_argument('--address', type=str, help='Free-form address string (used for Mapbox q and fallback)')
        parser.add_argument('--street', type=str, help='Structured street (e.g., Kopińska 12/16)')
        parser.add_argument('--city', type=str, help='Structured city (e.g., Warszawa)')
        parser.add_argument('--postal', type=str, help='Structured postal code (e.g., 02-321)')
        parser.add_argument('--country', type=str, help='Structured country (e.g., Poland)')
        parser.add_argument('--country_code', type=str, help='ISO2 country code (e.g., PL)')
        parser.add_argument('--limit', type=int, default=5, help='Max candidates to print from each provider')

    def handle(self, *args, **opts):
        addr = opts.get('address') or ''
        street = opts.get('street')
        city = opts.get('city')
        postal = opts.get('postal')
        country = opts.get('country')
        cc = opts.get('country_code')
        limit = int(opts.get('limit') or 5)

        if not (addr or street or city or postal or country):
            self.stderr.write('Provide --address or structured fields like --street/--city/--postal/--country')
            return

        self.stdout.write(self.style.NOTICE('=== Mapbox ==='))
        token = getattr(settings, 'MAPBOX_TOKEN', None) or getattr(settings, 'MAPBOX_ACCESS_TOKEN', None)
        if not token:
            self.stdout.write('MAPBOX_TOKEN not configured; skipping Mapbox')
        else:
            q = addr
            if not q:
                parts = [p for p in [street, city, postal, country] if p]
                q = ", ".join(parts)
            try:
                params = {
                    'access_token': token,
                    'limit': limit,
                    'autocomplete': 'false',
                    'types': 'address,poi',
                    'language': 'pl',
                }
                if cc:
                    params['country'] = str(cc).lower()
                url = f"https://api.mapbox.com/geocoding/v5/mapbox.places/{requests.utils.quote(q)}.json"
                self.stdout.write(f"GET {url}")
                self.stdout.write(f"params: {json.dumps(params, ensure_ascii=False)}")
                r = requests.get(url, params=params, timeout=10)
                self.stdout.write(f"status: {r.status_code}")
                if r.ok:
                    data = r.json() or {}
                    feats = data.get('features', [])[:limit]
                    if not feats:
                        self.stdout.write('No features returned')
                    for i, f in enumerate(feats, 1):
                        self.stdout.write(
                            f"#{i} relevance={f.get('relevance')} types={','.join(f.get('place_type', []))} center={f.get('center')}\n    name={f.get('place_name')}"
                        )
                else:
                    self.stdout.write(r.text[:500])
            except Exception as e:
                self.stdout.write(f"Mapbox error: {e}")

        self.stdout.write(self.style.NOTICE('\n=== Nominatim (OSM) ==='))
        try:
            url = 'https://nominatim.openstreetmap.org/search'
            headers = {'User-Agent': 'straypet/1.0 (geocode-diagnose)'}
            params = {
                'format': 'jsonv2',
                'limit': limit,
                'addressdetails': 1,
                'accept-language': 'pl',
            }
            if street or city or postal or country:
                if street:
                    params['street'] = street
                if city:
                    params['city'] = city
                if postal:
                    params['postalcode'] = postal
                if country:
                    params['country'] = country
            elif addr:
                params['q'] = addr
            self.stdout.write(f"GET {url}")
            self.stdout.write(f"params: {json.dumps(params, ensure_ascii=False)}")
            r2 = requests.get(url, params=params, headers=headers, timeout=12)
            self.stdout.write(f"status: {r2.status_code}")
            if r2.ok:
                arr = r2.json() or []
                if not arr:
                    self.stdout.write('No results')
                for i, it in enumerate(arr[:limit], 1):
                    self.stdout.write(
                        f"#{i} lat,lon=({it.get('lat')},{it.get('lon')}) type={it.get('type')} class={it.get('class')} importance={it.get('importance')}\n    name={it.get('display_name')}"
                    )
            else:
                self.stdout.write(r2.text[:500])
        except Exception as e:
            self.stdout.write(f"Nominatim error: {e}")
