// Lost Pet API Service
// Following ArkTS strict typing rules

import { HttpClient } from './HttpClient';
import { ApiConfig, ApiEndpoints } from './ApiConfig';
import { Lost, LostRequest, Address, UserBasic } from '../models/index';

export class LostListResult {
  success: boolean = false;
  losts: Lost[] = [];
  count: number = 0;
  errorMessage: string = '';

  constructor() {}
}

export class LostDetailResult {
  success: boolean = false;
  lost: Lost | null = null;
  errorMessage: string = '';

  constructor() {}
}

export class LostFilter {
  species: string = '';
  status: string = '';
  search: string = '';
  page: number = 1;

  constructor() {}

  toQueryParams(): Map<string, string> {
    const params = new Map<string, string>();
    if (this.species.length > 0) params.set('species', this.species);
    if (this.status.length > 0) params.set('status', this.status);
    if (this.search.length > 0) params.set('search', this.search);
    params.set('page', this.page.toString());
    return params;
  }
}

export class LostService {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = HttpClient.getInstance();
  }

  async getLosts(filter: LostFilter): Promise<LostListResult> {
    const result = new LostListResult();
    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.LOST, filter.toQueryParams());

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const lost = this.parseLost(item);
            result.losts.push(lost);
          });
        }

        result.count = Number(parsed['count']) || 0;
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get lost pets';
    }

    return result;
  }

  async getLostDetail(lostId: number): Promise<LostDetailResult> {
    const result = new LostDetailResult();
    const params = new Map<string, string>();
    params.set('id', lostId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.LOST_DETAIL, params);

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.lost = this.parseLost(parsed);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get lost pet detail';
    }

    return result;
  }

  async reportLost(request: LostRequest): Promise<LostDetailResult> {
    const result = new LostDetailResult();
    const url = ApiConfig.buildUrl(ApiEndpoints.LOST);

    try {
      const response = await this.httpClient.post(url, JSON.stringify(request), true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.lost = this.parseLost(parsed);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to report lost pet';
    }

    return result;
  }

  async updateStatus(lostId: number, status: string): Promise<LostDetailResult> {
    const result = new LostDetailResult();
    const params = new Map<string, string>();
    params.set('id', lostId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.LOST_DETAIL, params);

    try {
      const response = await this.httpClient.patch(url, JSON.stringify({ status: status }), true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.lost = this.parseLost(parsed);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to update status';
    }

    return result;
  }

  private parseLost(data: Record<string, Object>): Lost {
    const lost = new Lost();
    lost.id = Number(data['id']) || 0;
    lost.pet_id = Number(data['pet']) || 0;
    lost.pet_name = String(data['pet_name'] || '');
    lost.species = String(data['species'] || '');
    lost.breed = String(data['breed'] || '');
    lost.color = String(data['color'] || '');
    lost.sex = String(data['sex'] || 'male');
    lost.size = String(data['size'] || '');
    lost.lost_time = String(data['lost_time'] || '');
    lost.description = String(data['description'] || '');
    lost.reward = Number(data['reward']) || 0;
    lost.photo = String(data['photo'] || data['photo_url'] || '');
    lost.status = String(data['status'] || 'open');
    lost.contact_phone = String(data['contact_phone'] || '');
    lost.contact_email = String(data['contact_email'] || '');
    lost.created_at = String(data['created_at'] || '');
    lost.updated_at = String(data['updated_at'] || '');

    // Parse address - API returns flat fields for address data
    const address = new Address();
    address.country = String(data['country'] || '');
    address.region = String(data['region'] || '');
    address.city = String(data['city'] || '');
    address.street = String(data['street'] || '');
    address.postal_code = String(data['postal_code'] || '');
    // Latitude and longitude are returned as top-level fields
    address.latitude = Number(data['latitude']) || 0;
    address.longitude = Number(data['longitude']) || 0;
    
    // Only set address if we have meaningful data
    if (address.latitude !== 0 || address.longitude !== 0 || 
        address.city.length > 0 || address.country.length > 0) {
      lost.address = address;
    }

    // Parse reporter
    const reporterData = data['reporter'] as Record<string, Object> | null;
    if (reporterData !== null && reporterData !== undefined) {
      lost.reporter = new UserBasic(
        Number(reporterData['id']) || 0,
        String(reporterData['username'] || ''),
        String(reporterData['email'] || ''),
        String(reporterData['avatar'] || '')
      );
    }

    return lost;
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
