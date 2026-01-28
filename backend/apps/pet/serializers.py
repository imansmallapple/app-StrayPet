from __future__ import annotations
# apps/pet/serializers.py
from rest_framework import serializers
import json
from .models import Pet, Adoption, DonationPhoto, Donation, Lost, Address, Country, Region, City, PetFavorite, Shelter, Ticket, HolidayFamily
from typing import TYPE_CHECKING
from common.utils import geocode_address
if TYPE_CHECKING:
    from apps.pet.models import Location


def _create_or_resolve_address(address_data: dict) -> Address:
    """
    Resolve or create Country/Region/City from provided strings or IDs and return an Address instance.
    address_data may contain: country, region, city, street, postal_code, building_number, latitude, longitude.
    """
    country = None
    region = None
    city = None

    if not address_data:
        raise ValueError("address_data is required")

    # Helper to normalize str
    def _norm(s):
        return str(s).strip() if s is not None else None

    cval = address_data.get('country')
    if cval is not None:
        if isinstance(cval, int):
            country = Country.objects.filter(pk=cval).first()
        else:
            cstr = _norm(cval)
            if len(cstr or '') == 2:
                country = Country.objects.filter(code__iexact=cstr).first()
            if not country:
                country = Country.objects.filter(name__iexact=cstr).first()
            if not country:
                # fallback: create with a guessed code
                code = ''.join([ch for ch in cstr if ch.isalpha()])[:2].upper() or 'XX'
                country, _ = Country.objects.get_or_create(code=code, defaults={'name': cstr or code})

    rval = address_data.get('region')
    if rval is not None:
        if isinstance(rval, int):
            region = Region.objects.filter(pk=rval).first()
        else:
            rstr = _norm(rval)
            if country:
                region = Region.objects.filter(country=country, name__iexact=rstr).first()
            if not region:
                region = Region.objects.filter(name__iexact=rstr).first()
            if not region and country:
                region, _ = Region.objects.get_or_create(country=country, name=rstr)

    ctyval = address_data.get('city')
    if ctyval is not None:
        if isinstance(ctyval, int):
            city = City.objects.filter(pk=ctyval).first()
        else:
            cstr = _norm(ctyval)
            if region:
                city = City.objects.filter(region=region, name__iexact=cstr).first()
            if not city:
                city = City.objects.filter(name__iexact=cstr).first()
            if not city and region:
                city, _ = City.objects.get_or_create(region=region, name=cstr)

    # If only city string provided and we didn't find a city, try find any city by name
    if not city and isinstance(address_data.get('city'), str):
        city = City.objects.filter(name__iexact=_norm(address_data.get('city'))).first()
        if city and not region:
            region = city.region
            country = city.region.country if city.region else country

    # Build Address kwargs
    addr_kwargs = {}
    if country:
        addr_kwargs['country'] = country
    if region:
        addr_kwargs['region'] = region
    if city:
        addr_kwargs['city'] = city
    if address_data.get('street'):
        addr_kwargs['street'] = _norm(address_data.get('street'))
    if address_data.get('building_number'):
        addr_kwargs['building_number'] = _norm(address_data.get('building_number'))
    if address_data.get('postal_code'):
        addr_kwargs['postal_code'] = _norm(address_data.get('postal_code'))
    
    # optional lat/lng
    import logging
    logger = logging.getLogger(__name__)
    logger.warning(f"Address data latitude: {address_data.get('latitude')}, type: {type(address_data.get('latitude'))}")
    logger.warning(f"Address data longitude: {address_data.get('longitude')}, type: {type(address_data.get('longitude'))}")
    
    if address_data.get('latitude') is not None:
        try:
            lat_val = float(address_data.get('latitude'))
            addr_kwargs['latitude'] = lat_val
            logger.warning(f"Set latitude to: {lat_val}")
        except Exception as e:
            logger.error(f"Failed to convert latitude: {e}")
            lat_val = None
    else:
        lat_val = None
    if address_data.get('longitude') is not None:
        try:
            lon_val = float(address_data.get('longitude'))
            addr_kwargs['longitude'] = lon_val
            logger.warning(f"Set longitude to: {lon_val}")
        except Exception as e:
            logger.error(f"Failed to convert longitude: {e}")
            lon_val = None
    else:
        lon_val = None
    
    logger.warning(f"Final addr_kwargs: {addr_kwargs}")

    # If coordinates were not provided, try geocoding from the textual address
    if (lat_val is None or lon_val is None):
        # Prefer resolved model names for city/region/country when available
        parts = []
        street = _norm(address_data.get('street')) if address_data.get('street') else None
        bnum = _norm(address_data.get('building_number')) if address_data.get('building_number') else None
        if street and bnum and bnum not in street:
            parts.append(f"{street} {bnum}")
        elif street:
            parts.append(street)
        elif bnum:
            parts.append(bnum)

        # add locality hierarchy (prefer resolved objects)
        if city:
            parts.append(city.name)
        elif address_data.get('city'):
            parts.append(_norm(address_data.get('city')))
        if region:
            parts.append(region.name)
        elif address_data.get('region'):
            parts.append(_norm(address_data.get('region')))
        if country:
            parts.append(country.name)
        elif address_data.get('country'):
            parts.append(_norm(address_data.get('country')))

        if address_data.get('postal_code'):
            parts.append(_norm(address_data.get('postal_code')))

        addr_str = ", ".join([p for p in parts if p])
        try:
            ctx = {
                'street': (f"{street} {bnum}" if street else bnum) if (street or bnum) else None,
                'city': city.name if city else None,
                'region': region.name if region else None,
                'country': country.name if country else None,
                'country_code': country.code if country else None,
                'postal_code': _norm(address_data.get('postal_code')) if address_data.get('postal_code') else None,
            }
            coords = geocode_address(addr_str, context=ctx) if addr_str else None
        except Exception:
            coords = None
        if coords:
            lon_val, lat_val = coords
            addr_kwargs['latitude'] = lat_val
            addr_kwargs['longitude'] = lon_val

    if lat_val is not None and lon_val is not None:
        try:
            # Store location as JSON with lon,lat
            addr_kwargs['location'] = {"type": "Point", "coordinates": [lon_val, lat_val]}
        except Exception:
            # don't fail the whole flow if Point creation fails
            pass

    addr = Address.objects.create(**addr_kwargs)
    logger.debug('Address created id=%s with kwargs=%r', getattr(addr, 'id', None), addr_kwargs)
    return addr


def _create_or_get_location(location_data: dict) -> "Location":
    """
    Create a Location instance from a simple payload. The data is expected to be plain strings or numbers.
    """
    if not location_data:
        raise ValueError('location_data is required')
    def _v(k):
        val = location_data.get(k)
        return None if val is None or str(val).strip() == '' else val

    lat = None
    lon = None
    if _v('latitude') is not None:
        try:
            lat = float(location_data.get('latitude'))
        except Exception:
            lat = None
    if _v('longitude') is not None:
        try:
            lon = float(location_data.get('longitude'))
        except Exception:
            lon = None

    kwargs = {
        'country_code': _v('country_code') or _v('country') or '',
        'country_name': _v('country') or _v('country_name') or '',
        'region': _v('region') or '',
        'city': _v('city') or '',
        'street': _v('street') or '',
        'postal_code': _v('postal_code') or '',
    }
    if lat is not None:
        kwargs['latitude'] = lat
    if lon is not None:
        kwargs['longitude'] = lon
    if lat is not None and lon is not None:
        try:
            kwargs['location'] = {"type": "Point", "coordinates": [lon, lat]}
        except Exception:
            pass

    from apps.pet.models import Location
    loc = Location.objects.create(**kwargs)
    return loc


import logging
logger = logging.getLogger(__name__)

class LostGeoSerializer(serializers.ModelSerializer):
    # Serialize geometry as JSON
    geometry = serializers.SerializerMethodField()

    def get_geometry(self, obj):
        if obj.address and obj.address.location:
            return obj.address.location
        return None

    class Meta:
        model = Lost
        fields = ("id", "status", "pet_name", "species", "breed", "color", "sex", "size", "reporter", "lost_time", "geometry")

class PetListSerializer(serializers.ModelSerializer):
    created_by = serializers.StringRelatedField(read_only=True)
    applications_count = serializers.IntegerField(read_only=True, default=0)  # 预留统计字段
    age_display = serializers.SerializerMethodField()
    address_display = serializers.SerializerMethodField()
    city = serializers.SerializerMethodField()  # 城市名称
    # provide numeric coordinates for frontend map (fallback: address -> location)
    address_lat = serializers.SerializerMethodField()
    address_lon = serializers.SerializerMethodField()
    cover = serializers.SerializerMethodField()  # 封面照片 URL
    photo = serializers.SerializerMethodField()  # 别名，同 cover
    photos = serializers.SerializerMethodField()  # 多张照片数组
    is_favorited = serializers.SerializerMethodField()
    favorites_count = serializers.IntegerField(source='favorites.count', read_only=True)
    # 收容所信息
    shelter_name = serializers.SerializerMethodField()
    shelter_address = serializers.SerializerMethodField()
    shelter_phone = serializers.SerializerMethodField()
    shelter_website = serializers.SerializerMethodField()
    shelter_id = serializers.SerializerMethodField()
    shelter_description = serializers.SerializerMethodField()

    class Meta:
        model = Pet
        fields = (
            "id", "name", "species", "breed", "sex",
            "age_years", "age_months", "age_display", "size",
            "description", "address_display", "city", "cover", 'photo', 'photos',
            "address_lat", "address_lon",
            "dewormed", "vaccinated", "microchipped", "child_friendly", "trained",
            "loves_play", "loves_walks", "good_with_dogs", "good_with_cats",
            "affectionate", "needs_attention", "sterilized", "contact_phone",
            "status", "created_by", "applications_count",
            "add_date", "pub_date",
            "is_favorited", "favorites_count",
            "shelter_id", "shelter_name", "shelter_address", "shelter_phone", "shelter_website", "shelter_description",
        )
        read_only_fields = ("status", "created_by", "applications_count", "add_date", "pub_date")

    def get_cover(self, obj: Pet) -> str:
        """返回封面照片的绝对 URL"""
        if not obj.cover:
            return ''
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(obj.cover.url)
        return obj.cover.url

    def get_photo(self, obj: Pet) -> str:
        """photo 字段是 cover 的别名"""
        return self.get_cover(obj)

    def get_photos(self, obj: Pet):
        """返回所有额外照片的 URL"""
        request = self.context.get('request')
        photo_objs = obj.photos.all()
        if not photo_objs:
            return []
        
        urls = []
        for photo in photo_objs:
            if photo.image:
                if request:
                    urls.append(request.build_absolute_uri(photo.image.url))
                else:
                    urls.append(photo.image.url)
        return urls

    def get_is_favorited(self, obj: Pet) -> bool:
        request = self.context.get('request')
        u = getattr(request, 'user', None)
        if not (u and u.is_authenticated):
            return False
        return PetFavorite.objects.filter(user=u, pet=obj).exists()

    def get_age_display(self, obj: Pet) -> str:
        y = obj.age_years or 0
        m = obj.age_months or 0
        if y and m:
            return f"{y}y {m}m"
        if y:
            return f"{y}y"
        if m:
            return f"{m}m"
        return "0m"

    def get_address_display(self, obj: Pet) -> str:
        # ✅ Prefer Location (if available) then Address
        if getattr(obj, 'location_id', None):
            loc = getattr(obj, 'location', None)
            parts = [
                loc.street,
                loc.city,
                loc.region,
                loc.country_name,
                loc.postal_code,
            ]
            return ", ".join([p for p in parts if p])

        if getattr(obj, 'address_id', None):
            a = getattr(obj, 'address', None)
            parts = [
                a.street, a.building_number,
                a.city.name if a.city_id else "",
                a.region.name if a.region_id else "",
                a.country.name if a.country_id else "",
                a.postal_code,
            ]
            return ", ".join([p for p in parts if p])

        return "-"

    def get_city(self, obj: Pet) -> str:
        """Extract city name from pet's shelter"""
        # 从宠物关联的收容所获取城市
        if obj.shelter and obj.shelter.address and obj.shelter.address.city:
            return obj.shelter.address.city.name or ''
        
        # 备选：如果宠物本身有地址也可以使用
        if obj.address and obj.address.city:
            return obj.address.city.name or ''
        
        return ''

    def get_address_lat(self, obj: Pet):
        if getattr(obj, 'location_id', None) and getattr(obj, 'location', None) and getattr(obj.location, 'latitude', None) is not None:
            return obj.location.latitude
        if getattr(obj, 'address_id', None) and getattr(obj, 'address', None) and getattr(obj.address, 'latitude', None) is not None:
            return obj.address.latitude
        return None

    def get_address_lon(self, obj: Pet):
        if getattr(obj, 'location_id', None) and getattr(obj, 'location', None) and getattr(obj.location, 'longitude', None) is not None:
            return obj.location.longitude
        if getattr(obj, 'address_id', None) and getattr(obj, 'address', None) and getattr(obj.address, 'longitude', None) is not None:
            return obj.address.longitude
        return None

    def get_shelter_name(self, obj: Pet) -> str:
        """获取关联的收容所名称"""
        # 优先从 Pet 的 shelter 字段获取
        if obj.shelter:
            return obj.shelter.name
        # 备选：从关联的 Donation 获取
        donation = getattr(obj, 'from_donor', None)
        if donation and donation.shelter:
            return donation.shelter.name
        return ""

    def get_shelter_address(self, obj: Pet) -> str:
        """获取关联的收容所地址"""
        shelter = obj.shelter if obj.shelter else (
            getattr(obj, 'from_donor', None) and getattr(obj, 'from_donor', None).shelter
        )
        if shelter and shelter.address:
            addr = shelter.address
            parts = [
                addr.street,
                addr.building_number,
                addr.city.name if addr.city_id else "",
                addr.region.name if addr.region_id else "",
                addr.country.name if addr.country_id else "",
                addr.postal_code,
            ]
            return ", ".join([p for p in parts if p])
        return ""

    def get_shelter_phone(self, obj: Pet) -> str:
        """获取关联的收容所电话"""
        shelter = obj.shelter if obj.shelter else (
            getattr(obj, 'from_donor', None) and getattr(obj, 'from_donor', None).shelter
        )
        if shelter:
            return shelter.phone or ""
        return ""

    def get_shelter_website(self, obj: Pet) -> str:
        """获取关联的收容所网站"""
        shelter = obj.shelter if obj.shelter else (
            getattr(obj, 'from_donor', None) and getattr(obj, 'from_donor', None).shelter
        )
        if shelter:
            return shelter.website or ""
        return ""

    def get_shelter_id(self, obj: Pet):
        """获取关联的收容所 ID"""
        shelter = obj.shelter if obj.shelter else (
            getattr(obj, 'from_donor', None) and getattr(obj, 'from_donor', None).shelter
        )
        if shelter:
            return shelter.id
        return None

    def get_shelter_description(self, obj: Pet) -> str:
        """获取关联的收容所描述"""
        shelter = obj.shelter if obj.shelter else (
            getattr(obj, 'from_donor', None) and getattr(obj, 'from_donor', None).shelter
        )
        if shelter:
            return shelter.description or ""
        return ""


class PetCreateUpdateSerializer(serializers.ModelSerializer):
    address_data = serializers.JSONField(write_only=True, required=False)
    
    class Meta:
        model = Pet
        fields = (
            "id", "name", "species", "breed", "sex", "age_years", "age_months",
            "description", "address", "address_data", "shelter", "cover", "status",
            "dewormed", "vaccinated", "microchipped", "child_friendly", "trained",
            "loves_play", "loves_walks", "good_with_dogs", "good_with_cats",
            "affectionate", "needs_attention", "sterilized", "contact_phone"
        )
        read_only_fields = ("status",)  # 创建默认 AVAILABLE；如需修改在视图层控制

    def _convert_bool_fields(self, data: dict) -> dict:
        """Convert string boolean values to actual booleans for FormData submissions"""
        bool_fields = [
            'dewormed', 'vaccinated', 'microchipped', 'child_friendly', 'trained',
            'loves_play', 'loves_walks', 'good_with_dogs', 'good_with_cats',
            'affectionate', 'needs_attention', 'sterilized'
        ]
        for field in bool_fields:
            if field in data:
                val = data[field]
                if isinstance(val, str):
                    data[field] = val.lower() in ('true', '1', 'yes', 'on')
        return data

    def to_internal_value(self, data):
        # Handle FormData: QueryDict may have values as lists, extract first element
        normalized_data = {}
        for key, value in data.items():
            if isinstance(value, list):
                normalized_data[key] = value[0] if value else None
            else:
                normalized_data[key] = value
        
        # Convert boolean string values from FormData
        normalized_data = self._convert_bool_fields(normalized_data)
        return super().to_internal_value(normalized_data)

    def _ensure_address_coords(self, address: Address):
        """自动为地址地理编码（如果坐标缺失）"""
        try:
            if not address:
                return
            
            # 检查是否需要地理编码
            lat_missing = getattr(address, 'latitude', None) is None
            lon_missing = getattr(address, 'longitude', None) is None
            
            # 如果坐标都存在，跳过
            if not (lat_missing or lon_missing):
                return
            
            # 构建地址字符串
            parts = [
                address.street or '',
                address.building_number or '',
                address.city.name if getattr(address, 'city_id', None) else '',
                address.region.name if getattr(address, 'region_id', None) else '',
                address.country.name if getattr(address, 'country_id', None) else '',
                address.postal_code or '',
            ]
            addr_str = ", ".join([p for p in parts if p])
            
            # 构建地理编码上下文
            ctx = {
                'street': (f"{address.street} {address.building_number}".strip()) if (address.street or address.building_number) else None,
                'city': address.city.name if getattr(address, 'city_id', None) else None,
                'region': address.region.name if getattr(address, 'region_id', None) else None,
                'country': address.country.name if getattr(address, 'country_id', None) else None,
                'country_code': getattr(getattr(address, 'country', None), 'code', None) if getattr(address, 'country_id', None) else None,
                'postal_code': address.postal_code or None,
            }
            
            # 执行地理编码
            coords = geocode_address(addr_str, context=ctx) if addr_str else None
            
            if coords:
                lon, lat = coords
                address.latitude = lat
                address.longitude = lon
                try:
                    address.location = {"type": "Point", "coordinates": [lon, lat]}
                except Exception:
                    pass
                address.save(update_fields=["latitude", "longitude", "location"])
                import logging
                logger = logging.getLogger(__name__)
                logger.info(f"✅ Address {address.id} geocoded: ({lat}, {lon})")
        except Exception as e:
            # 不阻断主流程，但记录错误
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"Failed to geocode address {getattr(address, 'id', '?')}: {e}")

    def create(self, validated_data):
        # Handle address_data if provided
        address_data = validated_data.pop('address_data', None)
        
        if address_data and not validated_data.get('address'):
            # Create address from address_data JSON
            if isinstance(address_data, str):
                try:
                    address_data = json.loads(address_data)
                except Exception:
                    address_data = None
            
            if address_data:
                try:
                    address = _create_or_resolve_address(address_data)
                    validated_data['address'] = address
                except Exception as e:
                    logger.exception('Failed to create Address from address_data')
        
        address = validated_data.get('address')
        self._ensure_address_coords(address)
        return super().create(validated_data)

    def update(self, instance, validated_data):
        # Handle address_data if provided
        address_data = validated_data.pop('address_data', None)
        
        if address_data and not validated_data.get('address'):
            if isinstance(address_data, str):
                try:
                    address_data = json.loads(address_data)
                except Exception:
                    address_data = None
            
            if address_data:
                try:
                    address = _create_or_resolve_address(address_data)
                    validated_data['address'] = address
                except Exception as e:
                    logger.exception('Failed to create Address from address_data')
        
        address = validated_data.get('address') or instance.address
        self._ensure_address_coords(address)
        return super().update(instance, validated_data)


class AdoptionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Adoption
        fields = ("id", "pet", "message", "status", "add_date", "pub_date")
        read_only_fields = ("status", "add_date", "pub_date")

    def validate(self, attrs):
        pet = attrs["pet"]
        if pet.status not in (Pet.Status.AVAILABLE, Pet.Status.PENDING):
            raise serializers.ValidationError("This pet is not available for adoption.")
        return attrs


class AdoptionDetailSerializer(serializers.ModelSerializer):
    pet = PetListSerializer(read_only=True)  # 你已有的列表/详情序列化器
    applicant = serializers.StringRelatedField(read_only=True)

    class Meta:
        model = Adoption
        fields = ("id", "pet", "applicant", "message", "status", "add_date", "pub_date")


class AdoptionReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Adoption
        fields = ("status",)


class DonationPhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = DonationPhoto
        fields = ["id", "image"]


class DonationCreateSerializer(serializers.ModelSerializer):
    photos = serializers.ListField(child=serializers.ImageField(), write_only=True, required=False)
    # 支持嵌套地址数据（参考 LostSerializer）
    address_data = serializers.JSONField(write_only=True, required=False)
    # 新增：前端可能发送更简单的 location_data（兼容 Mapbox/短 payload）
    location_data = serializers.JSONField(write_only=True, required=False)

    class Meta:
        model = Donation
        fields = ["name", "species", "breed", "sex", "age_years", "age_months",
                  "description", "address", "address_data", "location_data", "dewormed", "vaccinated", "microchipped",
                  "sterilized", "child_friendly", "trained", "loves_play", "loves_walks",
                  "good_with_dogs", "good_with_cats", "affectionate", "needs_attention",
                  "is_stray", "contact_phone", "photos"]

    def create(self, validated_data):
        photos = validated_data.pop("photos", [])
        address_data = validated_data.pop('address_data', None)
        location_data = validated_data.pop('location_data', None)
        # fallback: if frontend didn't send 'address_data' JSON but provided fields in request
        if not address_data:
            req = self.context.get('request')
            if req is not None:
                # form data might include top-level fields: country, region, city, street, postal_code
                logger.debug('Donation create request.data keys: %r', list(req.data.keys()))
                possible = {}
                for k in ('country', 'region', 'city', 'street', 'postal_code', 'latitude', 'longitude'):
                    v = req.data.get(k)
                    if v is not None and str(v).strip() != '':
                        possible[k] = v
                if possible:
                    address_data = possible
                    logger.debug('DonationCreateSerializer.create fallback using request.data fields for address_data: %r', address_data)
        address = None
        logger.debug('DonationCreateSerializer.create invoked; raw address_data: %r', address_data)
        if address_data:
            # Accept JSON string or dict
            if isinstance(address_data, str):
                try:
                    address_data = json.loads(address_data)
                except Exception:
                    address_data = None
            if address_data:
                try:
                    address = _create_or_resolve_address(address_data)
                    validated_data['address'] = address
                except Exception as e:
                    # Log address creation error and continue — the rest of fields still create Donation
                    logger.exception('Failed to create Address from address_data')
                    address = None
                    # Fallback: create minimal address record so location or street is persisted
                    try:
                        fallback_kwargs = {}
                        if address_data.get('street'):
                            fallback_kwargs['street'] = address_data.get('street')
                        if address_data.get('postal_code'):
                            fallback_kwargs['postal_code'] = address_data.get('postal_code')
                        if address_data.get('latitude') is not None:
                            try:
                                fallback_kwargs['latitude'] = float(address_data.get('latitude'))
                            except Exception:
                                pass
                        if address_data.get('longitude') is not None:
                            try:
                                fallback_kwargs['longitude'] = float(address_data.get('longitude'))
                            except Exception:
                                pass
                        if fallback_kwargs:
                            # if lat/lon present set location as JSON
                            lat_val = fallback_kwargs.get('latitude')
                            lon_val = fallback_kwargs.get('longitude')
                            if lat_val is not None and lon_val is not None:
                                try:
                                    fallback_kwargs['location'] = {"type": "Point", "coordinates": [lon_val, lat_val]}
                                except Exception:
                                    pass
                            address = Address.objects.create(**fallback_kwargs)
                            validated_data['address'] = address
                            logger.debug('Fallback minimal Address created id=%s with kwargs=%r', address.id, fallback_kwargs)
                    except Exception:
                        logger.exception('Fallback address creation failed')

        # If explicit location_data provided, create a Location and associate to donation
        loc_obj = None
        # Small fallback: if no location_data but address_data contains lat/lon, create a Location from that
        if not location_data and address_data and (address_data.get('latitude') is not None or address_data.get('longitude') is not None):
            # reuse latitude/longitude and other simple fields
            tmp = {}
            for k in ('country', 'region', 'city', 'street', 'postal_code', 'latitude', 'longitude', 'country_code'):
                if address_data.get(k) is not None:
                    tmp[k] = address_data.get(k)
            location_data = tmp

        if location_data:
            if isinstance(location_data, str):
                try:
                    location_data = json.loads(location_data)
                except Exception:
                    location_data = None
            if location_data:
                try:
                    # Create a Location row to persist geometry more simply
                    loc_obj = _create_or_get_location(location_data)
                    # Only attach to validated_data if Donation model actually has a 'location' field
                    try:
                        Donation._meta.get_field('location')
                        validated_data['location'] = loc_obj
                    except Exception:
                        # Donation model has no 'location' attribute — we'll assign after creation if supported
                        pass
                    logger.debug('Location created id=%s from location_data', getattr(loc_obj, 'id', None))
                except Exception:
                    logger.exception('Failed to create Location from location_data')

        # ensure donation creation and photo creation are an atomic operation
        from django.db import transaction
        with transaction.atomic():
            # Dump creation context for debug
            adid = getattr(validated_data.get('address'), 'id', None) if validated_data.get('address') else None
            lid = getattr(validated_data.get('location'), 'id', None) if validated_data.get('location') else None
            logger.debug('Creating Donation with validated_data address=%s location=%s', adid, lid)
            donation = Donation.objects.create(donor=self.context["request"].user, **validated_data)
            for img in photos[:8]:
                DonationPhoto.objects.create(donation=donation, image=img)
            # ensure donation.address is set (some DB backends may require instance to be assigned)
            if address and not donation.address:
                donation.address = address
                donation.save(update_fields=["address"]) 
            # ensure donation.location is set
            # ensure donation.location is set if the model supports the field
            if loc_obj:
                try:
                    Donation._meta.get_field('location')
                    if not getattr(donation, 'location', None):
                        donation.location = loc_obj
                        donation.save(update_fields=["location"]) 
                except Exception:
                    # Donation model doesn't support 'location' — ignore
                    pass
            logger.debug('Donation created id=%s; address=%s', donation.id, getattr(donation.address, 'id', None))
        return donation


class DonationDetailSerializer(serializers.ModelSerializer):
    photos = DonationPhotoSerializer(many=True, read_only=True)
    donor_name = serializers.CharField(source="donor.username", read_only=True)
    created_pet_id = serializers.IntegerField(source="created_pet.id", read_only=True)
    # expose location id and coordinates (read-only) via methods to safely handle when field doesn't exist
    location = serializers.SerializerMethodField(read_only=True)
    latitude = serializers.SerializerMethodField(read_only=True)
    longitude = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Donation
        fields = ["id", "donor", "donor_name", "name", "species", "breed", "sex", "age_years", "age_months",
              "description", "address", "location", "latitude", "longitude", "dewormed", "vaccinated", "microchipped", "is_stray", "contact_phone",
                  "status", "reviewer", "review_note", "created_pet_id", "photos", "add_date", "pub_date"]
        read_only_fields = ["status", "reviewer", "review_note", "created_pet_id", "add_date", "pub_date"]

    def get_location(self, obj: Donation):
            try:
                if not hasattr(obj, 'location'):
                    return None
                loc = getattr(obj, 'location')
                return getattr(loc, 'id', None)
            except Exception:
                return None

    def get_latitude(self, obj: Donation):
            try:
                if not hasattr(obj, 'location'):
                    return None
                return getattr(getattr(obj, 'location'), 'latitude', None)
            except Exception:
                return None

    def get_longitude(self, obj: Donation):
            try:
                if not hasattr(obj, 'location'):
                    return None
                return getattr(getattr(obj, 'location'), 'longitude', None)
            except Exception:
                return None

class LostSerializer(serializers.ModelSerializer):
    reporter_username = serializers.ReadOnlyField(source='reporter.username')
    # 返回地址的完整字符串
    country = serializers.SerializerMethodField(read_only=True)
    region = serializers.SerializerMethodField(read_only=True)
    city = serializers.SerializerMethodField(read_only=True)
    street = serializers.SerializerMethodField(read_only=True)
    postal_code = serializers.SerializerMethodField(read_only=True)
    latitude = serializers.SerializerMethodField(read_only=True)
    longitude = serializers.SerializerMethodField(read_only=True)
    photo_url = serializers.SerializerMethodField(read_only=True)

    # 接受 JSON 字符串或字典 - 使用 CharField 避免 JSONField 在 to_internal_value 前的处理
    address_data = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = Lost
        fields = [
            'id', 'pet_name', 'species', 'breed', 'color', 'sex', 'size',
            'address', 'address_data',  # ✅ 新增
            'country', 'region', 'city', 'street', 'postal_code', 'latitude', 'longitude',
            'lost_time', 'description', 'reward', 'photo', 'photo_url',
            'status', 'reporter', 'reporter_username',
            'contact_phone', 'contact_email',
            'created_at', 'updated_at',
        ]
        read_only_fields = ('reporter', 'created_at', 'updated_at')

    def to_internal_value(self, data):
        """处理 FormData: QueryDict 可能将值作为列表，提取第一个元素"""
        import logging
        logger = logging.getLogger(__name__)
        
        logger.warning(f"[LostSerializer.to_internal_value] Raw data type: {type(data)}")
        logger.warning(f"[LostSerializer.to_internal_value] Raw data keys: {list(data.keys())}")
        if 'address_data' in data:
            logger.warning(f"[LostSerializer.to_internal_value] address_data raw value: {data.get('address_data')}, type: {type(data.get('address_data'))}")
        
        normalized_data = {}
        for key, value in data.items():
            if isinstance(value, list):
                normalized_data[key] = value[0] if value else None
            else:
                normalized_data[key] = value
        
        logger.warning(f"[LostSerializer.to_internal_value] Normalized address_data: {normalized_data.get('address_data')}")
        
        result = super().to_internal_value(normalized_data)
        logger.warning(f"[LostSerializer.to_internal_value] Result keys: {result.keys()}")
        logger.warning(f"[LostSerializer.to_internal_value] Result address_data: {result.get('address_data')}")
        
        # Parse address_data JSON string if present
        if 'address_data' in result and result['address_data']:
            try:
                if isinstance(result['address_data'], str):
                    result['address_data'] = json.loads(result['address_data'])
                    logger.warning(f"[LostSerializer.to_internal_value] Parsed address_data: {result['address_data']}")
            except json.JSONDecodeError as e:
                logger.error(f"[LostSerializer.to_internal_value] Failed to parse address_data JSON: {e}")
                result['address_data'] = {}
        
        return result

    def get_country(self, obj):
        if obj.address and obj.address.country:
            return obj.address.country.name
        return None

    def get_region(self, obj):
        if obj.address and obj.address.region:
            return obj.address.region.name
        return None

    def get_city(self, obj):
        if obj.address and obj.address.city:
            return obj.address.city.name
        return None

    def get_street(self, obj):
        if obj.address and obj.address.street:
            return obj.address.street
        return None

    def get_postal_code(self, obj):
        if obj.address and obj.address.postal_code:
            return obj.address.postal_code
        return None

    def get_latitude(self, obj):
        if obj.address and obj.address.latitude is not None:
            return float(obj.address.latitude)
        return None

    def get_longitude(self, obj):
        if obj.address and obj.address.longitude is not None:
            return float(obj.address.longitude)
        return None

    def create(self, validated_data):
        import logging
        logger = logging.getLogger(__name__)
        
        logger.warning(f"[LostSerializer.create] validated_data keys: {validated_data.keys()}")
        logger.warning(f"[LostSerializer.create] full validated_data: {validated_data}")
        
        address_data = validated_data.pop('address_data', None)
        logger.warning(f"[LostSerializer.create] address_data: {address_data}, type: {type(address_data)}")
        
        if address_data:
            # Allow JSON string input in multipart/form-data
            if isinstance(address_data, str):
                try:
                    address_data = json.loads(address_data)
                    logger.warning(f"[LostSerializer.create] Parsed JSON address_data: {address_data}")
                except Exception as e:
                    logger.error(f"[LostSerializer.create] Failed to parse JSON: {e}")
                    address_data = None
            
            # Only process address_data if it has non-null/non-empty values
            if address_data:
                # Check if there's any meaningful data
                has_data = any(v for v in address_data.values() if v is not None and v != '' and v != 0)
                logger.warning(f"[LostSerializer.create] has_data: {has_data}, keys: {address_data.keys()}")
                
                if has_data:
                    try:
                        address = _create_or_resolve_address(address_data)
                        validated_data['address'] = address
                        logger.warning(f"[LostSerializer.create] Created address: {address.id}")
                    except Exception as e:
                        # Log error but don't fail the request
                        logger.error(f"[LostSerializer.create] Failed to create address from data {address_data}: {e}")
        
        return super().create(validated_data)

    def get_photo_url(self, obj):
        try:
            if obj.photo and hasattr(obj.photo, 'url'):
                request = self.context.get('request')
                url = obj.photo.url
                return request.build_absolute_uri(url) if request else url
        except Exception:
            pass
        return None


class ShelterListSerializer(serializers.ModelSerializer):
    """Serializer for shelter list view"""
    street = serializers.CharField(source='address.street', read_only=True, allow_null=True)
    building_number = serializers.CharField(source='address.building_number', read_only=True, allow_null=True)
    city = serializers.CharField(source='address.city.name', read_only=True, allow_null=True)
    region = serializers.CharField(source='address.region.name', read_only=True, allow_null=True)
    country = serializers.CharField(source='address.country.name', read_only=True, allow_null=True)
    postal_code = serializers.CharField(source='address.postal_code', read_only=True, allow_null=True)
    latitude = serializers.FloatField(source='address.latitude', read_only=True, allow_null=True)
    longitude = serializers.FloatField(source='address.longitude', read_only=True, allow_null=True)
    logo_url = serializers.SerializerMethodField(read_only=True)
    cover_url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Shelter
        fields = [
            'id', 'name', 'description', 'email', 'phone', 'website',
            'street', 'building_number', 'city', 'region', 'country', 'postal_code', 'latitude', 'longitude',
            'logo_url', 'cover_url',
            'capacity', 'current_animals', 'available_capacity', 'occupancy_rate',
            'is_verified', 'is_active', 'created_at', 'updated_at'
        ]

    def get_logo_url(self, obj):
        try:
            if obj.logo and hasattr(obj.logo, 'url'):
                request = self.context.get('request')
                url = obj.logo.url
                return request.build_absolute_uri(url) if request else url
        except Exception:
            pass
        return None

    def get_cover_url(self, obj):
        try:
            if obj.cover_image and hasattr(obj.cover_image, 'url'):
                request = self.context.get('request')
                url = obj.cover_image.url
                return request.build_absolute_uri(url) if request else url
        except Exception:
            pass
        return None


class ShelterDetailSerializer(serializers.ModelSerializer):
    """Serializer for shelter detail view"""
    city = serializers.CharField(source='address.city.name', read_only=True)
    region = serializers.CharField(source='address.region.name', read_only=True)
    country = serializers.CharField(source='address.country.name', read_only=True)
    street = serializers.CharField(source='address.street', read_only=True)
    building_number = serializers.CharField(source='address.building_number', read_only=True, allow_null=True)
    postal_code = serializers.CharField(source='address.postal_code', read_only=True)
    latitude = serializers.FloatField(source='address.latitude', read_only=True, allow_null=True)
    longitude = serializers.FloatField(source='address.longitude', read_only=True, allow_null=True)
    logo_url = serializers.SerializerMethodField(read_only=True)
    cover_url = serializers.SerializerMethodField(read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)

    class Meta:
        model = Shelter
        fields = [
            'id', 'name', 'description', 'email', 'phone', 'website',
            'address', 'street', 'building_number', 'city', 'region', 'country', 'postal_code', 'latitude', 'longitude',
            'logo_url', 'cover_url',
            'capacity', 'current_animals', 'available_capacity', 'occupancy_rate',
            'founded_year', 'is_verified', 'is_active',
            'facebook_url', 'instagram_url', 'twitter_url',
            'created_by', 'created_by_username',
            'created_at', 'updated_at'
        ]
        read_only_fields = ('created_by', 'created_at', 'updated_at')

    def get_logo_url(self, obj):
        try:
            if obj.logo and hasattr(obj.logo, 'url'):
                request = self.context.get('request')
                url = obj.logo.url
                return request.build_absolute_uri(url) if request else url
        except Exception:
            pass
        return None

    def get_cover_url(self, obj):
        try:
            if obj.cover_image and hasattr(obj.cover_image, 'url'):
                request = self.context.get('request')
                url = obj.cover_image.url
                return request.build_absolute_uri(url) if request else url
        except Exception:
            pass
        return None


class ShelterCreateUpdateSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating shelters"""
    address_data = serializers.DictField(write_only=True, required=False)

    class Meta:
        model = Shelter
        fields = [
            'id', 'name', 'description', 'email', 'phone', 'website',
            'address', 'address_data',
            'logo', 'cover_image',
            'capacity', 'current_animals',
            'founded_year', 'is_verified', 'is_active',
            'facebook_url', 'instagram_url', 'twitter_url',
        ]
        read_only_fields = ('id',)

    def create(self, validated_data):
        import logging
        logger = logging.getLogger(__name__)
        
        # Try to get address_data from validated_data first
        address_data = validated_data.pop('address_data', None)
        
        # If not in validated_data, try to get it from request.data
        if not address_data:
            request = self.context.get('request')
            if request and hasattr(request, 'data'):
                address_data_str = request.data.get('address_data')
                logger.warning(f"Got address_data from request.data: {address_data_str}")
                if address_data_str:
                    try:
                        address_data = json.loads(address_data_str)
                        logger.warning(f"Parsed address_data: {address_data}")
                    except Exception as e:
                        logger.error(f"Failed to parse address_data: {e}")
                        address_data = None
        
        logger.warning(f"Creating shelter with address_data: {address_data}")
        
        if address_data:
            if isinstance(address_data, str):
                try:
                    address_data = json.loads(address_data)
                    logger.warning(f"Parsed address_data from JSON: {address_data}")
                except Exception as e:
                    logger.error(f"Failed to parse address_data JSON: {e}")
                    address_data = None
            if address_data:
                # Don't catch exceptions - let them propagate
                logger.warning(f"Calling _create_or_resolve_address with: {address_data}")
                address = _create_or_resolve_address(address_data)
                logger.warning(f"Created address: {address}, ID: {address.id if address else None}")
                validated_data['address'] = address
        
        # Set created_by from request user
        request = self.context.get('request')
        if request and hasattr(request, 'user') and request.user.is_authenticated:
            validated_data['created_by'] = request.user
        
        return super().create(validated_data)

    def update(self, instance, validated_data):
        address_data = validated_data.pop('address_data', None)
        if address_data:
            if isinstance(address_data, str):
                try:
                    address_data = json.loads(address_data)
                except Exception:
                    address_data = None
            if address_data:
                address = _create_or_resolve_address(address_data)
                validated_data['address'] = address
        
        return super().update(instance, validated_data)

class TicketSerializer(serializers.ModelSerializer):
    """Serializer for Ticket model."""
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    assigned_to_username = serializers.CharField(source='assigned_to.username', read_only=True, required=False)
    
    class Meta:
        model = Ticket
        fields = [
            'id',
            'title',
            'description',
            'category',
            'status',
            'priority',
            'email',
            'phone',
            'created_by',
            'created_by_username',
            'assigned_to',
            'assigned_to_username',
            'created_at',
            'updated_at',
            'resolved_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'resolved_at', 'created_by', 'created_by_username', 'assigned_to_username']
    
    def create(self, validated_data):
        """Set created_by from request user."""
        request = self.context.get('request')
        if request and hasattr(request, 'user') and request.user.is_authenticated:
            validated_data['created_by'] = request.user
        return super().create(validated_data)


class HolidayFamilyApplicationSerializer(serializers.ModelSerializer):
    """Serializer for Holiday Family applications"""
    
    class Meta:
        model = HolidayFamily
        fields = [
            'id',
            'full_name',
            'email',
            'phone',
            'address',
            'city',
            'pet_count',
            'pet_types',
            'motivation',
            'terms_agreed',
            'status',
            'applied_at',
            'reviewed_at',
            'review_notes',
        ]
        read_only_fields = [
            'id',
            'status',
            'applied_at',
            'reviewed_at',
            'review_notes',
        ]
    
    def create(self, validated_data):
        """Create a new Holiday Family application"""
        user = self.context['request'].user
        
        # Check if user already has an application
        if HolidayFamily.objects.filter(user=user).exists():
            raise serializers.ValidationError("You have already submitted an application.")
        
        validated_data['user'] = user
        return super().create(validated_data)
