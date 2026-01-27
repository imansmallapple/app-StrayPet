// Pet API Service
// Following ArkTS strict typing rules

import { HttpClient } from './HttpClient';
import { ApiConfig, ApiEndpoints } from './ApiConfig';
import { Pet, PetPhoto, Address, UserBasic, Shelter } from '../models/index';

export class PetListResult {
  success: boolean = false;
  pets: Pet[] = [];
  count: number = 0;
  next: string = '';
  previous: string = '';
  errorMessage: string = '';

  constructor() {}
}

export class PetDetailResult {
  success: boolean = false;
  pet: Pet | null = null;
  errorMessage: string = '';

  constructor() {}
}

export class PetFavoriteResult {
  success: boolean = false;
  is_favorited: boolean = false;
  errorMessage: string = '';

  constructor() {}
}

export class PetFilter {
  species: string = '';
  breed: string = '';
  sex: string = '';
  size: string = '';
  status: string = 'available';
  search: string = '';
  page: number = 1;
  page_size: number = 20;

  constructor() {}

  toQueryParams(): Map<string, string> {
    const params = new Map<string, string>();
    if (this.species.length > 0) params.set('species', this.species);
    if (this.breed.length > 0) params.set('breed', this.breed);
    if (this.sex.length > 0) params.set('sex', this.sex);
    if (this.size.length > 0) params.set('size', this.size);
    if (this.status.length > 0) params.set('status', this.status);
    if (this.search.length > 0) params.set('search', this.search);
    params.set('page', this.page.toString());
    params.set('page_size', this.page_size.toString());
    return params;
  }
}

export class PetService {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = HttpClient.getInstance();
  }

  async getPets(filter: PetFilter): Promise<PetListResult> {
    const result = new PetListResult();
    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.PETS, filter.toQueryParams());

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const pet = this.parsePet(item);
            result.pets.push(pet);
          });
        }

        result.count = Number(parsed['count']) || 0;
        result.next = String(parsed['next'] || '');
        result.previous = String(parsed['previous'] || '');
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get pets';
    }

    return result;
  }

  async getPetDetail(petId: number): Promise<PetDetailResult> {
    const result = new PetDetailResult();
    const params = new Map<string, string>();
    params.set('id', petId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.PET_DETAIL, params);

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.pet = this.parsePet(parsed);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get pet detail';
    }

    return result;
  }

  async toggleFavorite(petId: number): Promise<PetFavoriteResult> {
    const result = new PetFavoriteResult();
    const params = new Map<string, string>();
    params.set('id', petId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.PET_FAVORITE, params);

    try {
      const response = await this.httpClient.post(url, '{}', true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.is_favorited = Boolean(parsed['is_favorited']);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to toggle favorite';
    }

    return result;
  }

  async getMyFavorites(page: number = 1): Promise<PetListResult> {
    const result = new PetListResult();
    const queryParams = new Map<string, string>();
    queryParams.set('page', page.toString());
    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.PETS + 'favorites/', queryParams);

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const pet = this.parsePet(item);
            result.pets.push(pet);
          });
        }

        result.count = Number(parsed['count']) || 0;
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get favorites';
    }

    return result;
  }

  private parsePet(data: Record<string, Object>): Pet {
    const pet = new Pet();

    pet.id = Number(data['id']) || 0;
    pet.name = String(data['name'] || '');
    pet.species = String(data['species'] || '');
    pet.breed = String(data['breed'] || '');
    pet.sex = String(data['sex'] || 'male');
    pet.age_years = Number(data['age_years']) || 0;
    pet.age_months = Number(data['age_months']) || 0;
    pet.size = String(data['size'] || '');
    pet.description = String(data['description'] || '');
    pet.cover = String(data['cover'] || '');
    pet.status = String(data['status'] || 'available');
    pet.contact_phone = String(data['contact_phone'] || '');

    // Health traits
    pet.dewormed = Boolean(data['dewormed']);
    pet.vaccinated = Boolean(data['vaccinated']);
    pet.microchipped = Boolean(data['microchipped']);
    pet.child_friendly = Boolean(data['child_friendly']);
    pet.trained = Boolean(data['trained']);
    pet.loves_play = Boolean(data['loves_play']);
    pet.loves_walks = Boolean(data['loves_walks']);
    pet.good_with_dogs = Boolean(data['good_with_dogs']);
    pet.good_with_cats = Boolean(data['good_with_cats']);
    pet.affectionate = Boolean(data['affectionate']);
    pet.needs_attention = Boolean(data['needs_attention']);
    pet.sterilized = Boolean(data['sterilized']);

    // UI helpers
    pet.is_favorited = Boolean(data['is_favorited']);
    pet.favorite_count = Number(data['favorite_count']) || 0;

    // Timestamps
    pet.add_date = String(data['add_date'] || '');
    pet.pub_date = String(data['pub_date'] || '');

    // Parse address
    const addressData = data['address'] as Record<string, Object> | null;
    if (addressData !== null && addressData !== undefined) {
      pet.address = this.parseAddress(addressData);
    }

    // Parse shelter
    const shelterData = data['shelter'] as Record<string, Object> | null;
    if (shelterData !== null && shelterData !== undefined) {
      pet.shelter = this.parseShelter(shelterData);
    }

    // Parse created_by
    const createdByData = data['created_by'] as Record<string, Object> | null;
    if (createdByData !== null && createdByData !== undefined) {
      pet.created_by = this.parseUserBasic(createdByData);
    }

    // Parse photos
    const photosData = data['photos'] as Array<Record<string, Object>> | null;
    if (Array.isArray(photosData)) {
      photosData.forEach((photoData: Record<string, Object>) => {
        const photo = new PetPhoto();
        photo.id = Number(photoData['id']) || 0;
        photo.image = String(photoData['image'] || '');
        photo.order = Number(photoData['order']) || 0;
        photo.add_date = String(photoData['add_date'] || '');
        pet.photos.push(photo);
      });
    }

    return pet;
  }

  private parseAddress(data: Record<string, Object>): Address {
    const address = new Address();
    address.id = Number(data['id']) || 0;
    address.country = String(data['country_name'] || data['country'] || '');
    address.country_id = Number(data['country_id'] || data['country']) || 0;
    address.region = String(data['region_name'] || data['region'] || '');
    address.region_id = Number(data['region_id'] || data['region']) || 0;
    address.city = String(data['city_name'] || data['city'] || '');
    address.city_id = Number(data['city_id'] || data['city']) || 0;
    address.street = String(data['street'] || '');
    address.building_number = String(data['building_number'] || '');
    address.postal_code = String(data['postal_code'] || '');
    address.latitude = Number(data['latitude']) || 0;
    address.longitude = Number(data['longitude']) || 0;
    return address;
  }

  private parseShelter(data: Record<string, Object>): Shelter {
    const shelter = new Shelter();
    shelter.id = Number(data['id']) || 0;
    shelter.name = String(data['name'] || '');
    shelter.description = String(data['description'] || '');
    shelter.email = String(data['email'] || '');
    shelter.phone = String(data['phone'] || '');
    shelter.website = String(data['website'] || '');
    shelter.logo = String(data['logo'] || '');
    shelter.cover_image = String(data['cover_image'] || '');
    shelter.capacity = Number(data['capacity']) || 0;
    shelter.current_animals = Number(data['current_animals']) || 0;
    shelter.is_verified = Boolean(data['is_verified']);
    shelter.is_active = Boolean(data['is_active']);
    return shelter;
  }

  private parseUserBasic(data: Record<string, Object>): UserBasic {
    return new UserBasic(
      Number(data['id']) || 0,
      String(data['username'] || ''),
      String(data['email'] || ''),
      String(data['avatar'] || '')
    );
  }

  private parseErrorMessage(jsonString: string): string {
    try {
      const parsed = JSON.parse(jsonString) as Record<string, Object>;
      if (parsed['detail'] !== undefined) {
        return String(parsed['detail']);
      }
    } catch (error) {
      return jsonString;
    }
    return 'Unknown error';
  }
}
