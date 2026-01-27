// Shelter API Service
// Following ArkTS strict typing rules

import { HttpClient } from './HttpClient';
import { ApiConfig, ApiEndpoints } from './ApiConfig';
import { Shelter, Address } from '../models/index';

export class ShelterListResult {
  success: boolean = false;
  shelters: Shelter[] = [];
  count: number = 0;
  next: string = '';
  previous: string = '';
  errorMessage: string = '';

  constructor() {}
}

export class ShelterDetailResult {
  success: boolean = false;
  shelter: Shelter | null = null;
  errorMessage: string = '';

  constructor() {}
}

export class ShelterFilter {
  search: string = '';
  is_verified: string = '';
  page: number = 1;
  page_size: number = 20;

  constructor() {}

  toQueryParams(): Map<string, string> {
    const params = new Map<string, string>();
    if (this.search.length > 0) params.set('search', this.search);
    if (this.is_verified.length > 0) params.set('is_verified', this.is_verified);
    params.set('page', this.page.toString());
    params.set('page_size', this.page_size.toString());
    return params;
  }
}

export class ShelterService {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = HttpClient.getInstance();
  }

  async getShelters(filter: ShelterFilter): Promise<ShelterListResult> {
    const result = new ShelterListResult();
    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.SHELTERS, filter.toQueryParams());

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const shelter = this.parseShelter(item);
            result.shelters.push(shelter);
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
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get shelters';
    }

    return result;
  }

  async getShelterDetail(shelterId: number): Promise<ShelterDetailResult> {
    const result = new ShelterDetailResult();
    const params = new Map<string, string>();
    params.set('id', shelterId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.SHELTER_DETAIL, params);

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.shelter = this.parseShelter(parsed);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get shelter detail';
    }

    return result;
  }

  private parseShelter(data: Record<string, Object>): Shelter {
    const shelter = new Shelter();
    shelter.id = Number(data['id']) || 0;
    shelter.name = String(data['name'] || '');
    shelter.description = String(data['description'] || '');
    shelter.email = String(data['email'] || '');
    shelter.phone = String(data['phone'] || '');
    shelter.website = String(data['website'] || '');
    // Handle null values properly - null should become empty string
    const logoVal = data['logo'] || data['logo_url'];
    shelter.logo = (logoVal !== null && logoVal !== undefined) ? String(logoVal) : '';
    const coverVal = data['cover_image'] || data['cover_url'];
    shelter.cover_image = (coverVal !== null && coverVal !== undefined) ? String(coverVal) : '';
    shelter.capacity = Number(data['capacity']) || 0;
    shelter.current_animals = Number(data['current_animals']) || 0;
    shelter.is_verified = Boolean(data['is_verified']);
    shelter.is_active = Boolean(data['is_active']);

    // Parse address - API returns flat fields
    const address = new Address();
    address.country = String(data['country'] || '');
    address.region = String(data['region'] || '');
    address.city = String(data['city'] || '');
    address.street = String(data['street'] || '');
    address.building_number = String(data['building_number'] || '');
    address.postal_code = String(data['postal_code'] || '');
    address.latitude = Number(data['latitude']) || 0;
    address.longitude = Number(data['longitude']) || 0;
    
    // Only set address if we have meaningful data
    if (address.latitude !== 0 || address.longitude !== 0 || 
        address.city.length > 0 || address.country.length > 0) {
      shelter.address = address;
    }

    return shelter;
  }

  private parseAddress(data: Record<string, Object>): Address {
    const address = new Address();
    address.id = Number(data['id']) || 0;
    address.country = String(data['country'] || '');
    address.country_id = Number(data['country_id']) || 0;
    address.region = String(data['region'] || '');
    address.region_id = Number(data['region_id']) || 0;
    address.city = String(data['city'] || '');
    address.city_id = Number(data['city_id']) || 0;
    address.street = String(data['street'] || '');
    address.building_number = String(data['building_number'] || '');
    address.postal_code = String(data['postal_code'] || '');
    address.latitude = Number(data['latitude']) || 0;
    address.longitude = Number(data['longitude']) || 0;
    return address;
  }

  private parseErrorMessage(responseData: string): string {
    try {
      const parsed = JSON.parse(responseData) as Record<string, Object>;
      if (parsed['detail'] !== undefined) {
        return String(parsed['detail']);
      }
      return 'Request failed';
    } catch (e) {
      return responseData || 'Request failed';
    }
  }
}
