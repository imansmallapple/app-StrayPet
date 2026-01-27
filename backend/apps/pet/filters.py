# apps/pet/filters.py
import django_filters
import django_filters as df
from .models import Pet, Lost
from django.db import models
from django.db.models import Q


class PetFilter(df.FilterSet):
    name    = df.CharFilter(field_name="name", lookup_expr="icontains")
    species = df.CharFilter(field_name="species", lookup_expr="icontains")
    breed   = df.CharFilter(field_name="breed", lookup_expr="icontains")
    status  = df.CharFilter(field_name="status", lookup_expr="iexact")
    sex     = df.CharFilter(field_name="sex",     lookup_expr="iexact")
    size    = df.CharFilter(field_name="size",    lookup_expr="iexact")
    city    = df.CharFilter(method="filter_city")
    # 年龄段：用总月数范围过滤（前端映射成 age_min/age_max）
    age_min = df.NumberFilter(method="filter_age_min")
    age_max = df.NumberFilter(method="filter_age_max")
    
    # 宠物特性过滤
    vaccinated = df.BooleanFilter(field_name="vaccinated")
    sterilized = df.BooleanFilter(field_name="sterilized")
    dewormed = df.BooleanFilter(field_name="dewormed")
    child_friendly = df.BooleanFilter(field_name="child_friendly")
    trained = df.BooleanFilter(field_name="trained")
    loves_play = df.BooleanFilter(field_name="loves_play")
    loves_walks = df.BooleanFilter(field_name="loves_walks")
    good_with_dogs = df.BooleanFilter(field_name="good_with_dogs")
    good_with_cats = df.BooleanFilter(field_name="good_with_cats")
    affectionate = df.BooleanFilter(field_name="affectionate")
    needs_attention = df.BooleanFilter(field_name="needs_attention")

    def filter_city(self, qs, name, v):
        """Filter by city - search in both address and shelter address"""
        return qs.filter(
            Q(address__city__name__icontains=v) | Q(shelter__address__city__name__icontains=v)
        )

    def filter_age_min(self, qs, name, v):
        v = int(v); y, m = v // 12, v % 12
        return qs.filter(Q(age_years__gt=y) | (Q(age_years=y) & Q(age_months__gte=m)))

    def filter_age_max(self, qs, name, v):
        v = int(v); y, m = v // 12, v % 12
        return qs.filter(Q(age_years__lt=y) | (Q(age_years=y) & Q(age_months__lte=m)))
    
    class Meta:
        model = Pet
        fields = ["name", "species", "breed", "status", "size", "sex", "city", "vaccinated", "sterilized", "dewormed", 
                  "child_friendly", "trained", "loves_play", "loves_walks", "good_with_dogs", 
                  "good_with_cats", "affectionate", "needs_attention"]


class LostFilter(df.FilterSet):
    q = df.CharFilter(method='search', label='Search')
    pet_name = df.CharFilter(field_name='pet_name', lookup_expr='icontains')
    created_from = df.DateTimeFilter(field_name='created_at', lookup_expr='gte')
    created_to = df.DateTimeFilter(field_name='created_at', lookup_expr='lte')
    lost_from = df.DateTimeFilter(field_name='lost_time', lookup_expr='gte')
    lost_to = df.DateTimeFilter(field_name='lost_time', lookup_expr='lte')

    # 基于 Address 的过滤
    country = df.NumberFilter(field_name='address__country_id', lookup_expr='exact')
    region = df.NumberFilter(field_name='address__region_id', lookup_expr='exact')
    city = df.CharFilter(field_name='address__city__name', lookup_expr='icontains')

    class Meta:
        model = Lost
        fields = ['species', 'breed', 'color', 'sex', 'size', 'status', 'country', 'region', 'city', 'pet_name']

    def search(self, queryset, name, value):
        if not value:
            return queryset
        return queryset.filter(
            Q(pet_name__icontains=value) |
            Q(address__city__name__icontains=value) |
            Q(address__region__name__icontains=value) |
            Q(address__country__name__icontains=value) |
            Q(description__icontains=value) |
            Q(color__icontains=value) |
            Q(breed__icontains=value)
        )
