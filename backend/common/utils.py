import string
import random
from PIL import Image, ImageDraw, ImageFont
import logging
from typing import Optional, Tuple, Dict, Any
import requests
from django.conf import settings
from django.core.cache import cache


def random_string(length=4):
    if not isinstance(length, int):
        raise TypeError('length must be int')

    chars = string.ascii_letters + string.digits
    return ''.join(random.sample(chars, length))


def generate_catcha_image(width=80, height=30, font_size=27, font_path='', length=4):
    image = Image.new('RGB', (width, height), color=(255, 255, 255))
    draw = ImageDraw.Draw(image)
    from django.conf import settings
    if not font_path:
        font_path = "static/fonts/Arial.ttf"
    font = ImageFont.truetype(font_path, font_size)
    random_str = random_string(length)
    x, y = 1, 0
    for i in range(length):
        color = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
        draw.text((x, y), random_str[i], font=font, fill=color)
        x += font_size * 0.7
    for _ in range(random.randint(0, 7)):
        color = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
        draw.point((random.randint(0, width), random.randint(0, height)), fill=color)

    for _ in range(random.randint(0, 4)):
        color = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
        draw.line(
            (random.randint(0, width), random.randint(0, height), random.randint(0, width), random.randint(0, height)),
            fill=color)
    print(random_str)
    return image, random_str


if __name__ == '__main__':
    generate_catcha_image()


# ============== Geocoding helpers ==============
logger = logging.getLogger(__name__)

def _cache_get(key: str):
    try:
        return cache.get(key)
    except Exception:
        return None

def _cache_set(key: str, value, timeout: int = 24*3600):
    try:
        cache.set(key, value, timeout=timeout)
    except Exception:
        pass

def _mk_cache_key(prefix: str, payload: Dict[str, Any]) -> str:
    try:
        import hashlib, json as _json
        s = prefix + _json.dumps(payload, sort_keys=True, ensure_ascii=False)
        return 'gc:' + hashlib.md5(s.encode('utf-8')).hexdigest()
    except Exception:
        return prefix

def geocode_address(address: str, *, context: Optional[Dict[str, Any]] = None) -> Optional[Tuple[float, float]]:
    """
    Geocode a free-form address string to (lon, lat).
    Prefers Mapbox when MAPBOX_TOKEN is configured; falls back to OSM Nominatim.
    context may include: street, city, region, country, country_code, postal_code.
    Caches results for 24 hours.
    """
    if not address or not isinstance(address, str):
        return None
    addr = address.strip()
    if not addr:
        return None

    context = context or {}
    cache_key = _mk_cache_key("geocode", {"addr": addr, **{k: v for k, v in context.items() if v}})
    cached = _cache_get(cache_key)
    if cached:
        return cached

    # When structured context is available, build a normalized address string
    def _normalize_street(s: str) -> str:
        s = str(s).strip()
        # strip any trailing apartment/room info after a comma
        if ',' in s:
            s = s.split(',')[0].strip()
        # reorder patterns like "12/16 Kopińska" -> "Kopińska 12/16"
        try:
            import re
            m = re.match(r"^(\d+[\w\/-]*)\s+(.+)$", s)
            if m:
                return f"{m.group(2).strip()} {m.group(1).strip()}"
        except Exception:
            pass
        return s

    if context:
        street = context.get('street')
        city = context.get('city')
        postal = context.get('postal_code') or context.get('postal')
        country = context.get('country')
        parts = []
        if street:
            parts.append(_normalize_street(street))
        if city:
            parts.append(str(city).strip())
        if postal:
            parts.append(str(postal).strip())
        if country:
            parts.append(str(country).strip())
        if parts:
            addr = ", ".join([p for p in parts if p])

    # Try Mapbox Geocoding API
    token = getattr(settings, 'MAPBOX_TOKEN', None) or getattr(settings, 'MAPBOX_ACCESS_TOKEN', None)
    if token:
        try:
            params = {
                "access_token": token,
                "limit": 1,
                "autocomplete": "false",
                "types": "address,poi",
                "language": "pl",
            }
            if context.get('country_code'):
                params['country'] = str(context['country_code']).lower()
            url = f"https://api.mapbox.com/geocoding/v5/mapbox.places/{requests.utils.quote(addr)}.json"
            resp = requests.get(url, params=params, timeout=6)
            if resp.ok:
                data = resp.json()
                feats = (data or {}).get('features', [])
                if feats:
                    feat0 = feats[0]
                    # 要求足够相关且类型为 address/poi 才接受（略微放宽阈值以适配复杂门牌）
                    if feat0.get('relevance', 0) >= 0.7 and any(t in ('address','poi') for t in feat0.get('place_type', [])):
                        center = feat0.get('center')
                        if isinstance(center, list) and len(center) >= 2:
                            lon, lat = float(center[0]), float(center[1])
                            _cache_set(cache_key, (lon, lat))
                            return lon, lat
            # 额外尝试将 “12/16” 简化为 “12”，并确保街道名在前
            if context.get('street'):
                s = _normalize_street(context['street'])
                simple_s = s
                if '/' in s:
                    # reduce 12/16 -> 12
                    try:
                        simple_s = s.replace('/', ' ').split()[-1]
                    except Exception:
                        simple_s = s.split('/')[0]
                # build alt address with city/postal
                alt_addr = simple_s
                if context.get('city'):
                    alt_addr += f", {context['city']}"
                if context.get('postal_code'):
                    alt_addr += f", {context['postal_code']}"
                params2 = dict(params)
                url2 = f"https://api.mapbox.com/geocoding/v5/mapbox.places/{requests.utils.quote(alt_addr)}.json"
                resp2 = requests.get(url2, params=params2, timeout=6)
                if resp2.ok:
                    data2 = resp2.json()
                    feats2 = (data2 or {}).get('features', [])
                    if feats2:
                        f0 = feats2[0]
                        if f0.get('relevance', 0) >= 0.7 and any(t in ('address','poi') for t in f0.get('place_type', [])):
                            center = f0.get('center')
                            if isinstance(center, list) and len(center) >= 2:
                                lon, lat = float(center[0]), float(center[1])
                                _cache_set(cache_key, (lon, lat))
                                return lon, lat
        except Exception as e:
            logger.debug('Mapbox geocoding failed: %s', e)

    # Fallback to OSM Nominatim
    try:
        url = "https://nominatim.openstreetmap.org/search"
        headers = {"User-Agent": "straypet/1.0 (geocoder)"}
        params: Dict[str, Any] = {"format": "jsonv2", "limit": 1, "addressdetails": 1, "accept-language": "pl"}
        # 尽量使用结构化查询提升精度
        if any(context.get(k) for k in ('street','city','country','postal_code')):
            if context.get('street'):
                params['street'] = context['street']
            if context.get('city'):
                params['city'] = context['city']
            if context.get('postal_code'):
                params['postalcode'] = context['postal_code']
            if context.get('country'):
                params['country'] = context['country']
        else:
            params['q'] = addr
        resp = requests.get(url, params=params, headers=headers, timeout=8)
        if resp.ok:
            arr = resp.json() or []
            if arr:
                lat = float(arr[0].get('lat'))
                lon = float(arr[0].get('lon'))
                _cache_set(cache_key, (lon, lat))
                return lon, lat
    except Exception as e:
        logger.debug('Nominatim geocoding failed: %s', e)

    return None
