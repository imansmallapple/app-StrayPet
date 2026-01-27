// Adoption API Service
// Following ArkTS strict typing rules

import { HttpClient } from './HttpClient';
import { ApiConfig, ApiEndpoints } from './ApiConfig';
import { Adoption, AdoptionRequest } from '../models/index';

export class AdoptionListResult {
  success: boolean = false;
  adoptions: Adoption[] = [];
  count: number = 0;
  errorMessage: string = '';

  constructor() {}
}

export class AdoptionDetailResult {
  success: boolean = false;
  adoption: Adoption | null = null;
  errorMessage: string = '';

  constructor() {}
}

export class AdoptionService {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = HttpClient.getInstance();
  }

  async getMyAdoptions(page: number = 1): Promise<AdoptionListResult> {
    const result = new AdoptionListResult();
    const queryParams = new Map<string, string>();
    queryParams.set('page', page.toString());

    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.ADOPTIONS, queryParams);

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const adoption = this.parseAdoption(item);
            result.adoptions.push(adoption);
          });
        }

        result.count = Number(parsed['count']) || 0;
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get adoptions';
    }

    return result;
  }

  async createAdoption(request: AdoptionRequest): Promise<AdoptionDetailResult> {
    const result = new AdoptionDetailResult();
    const url = ApiConfig.buildUrl(ApiEndpoints.ADOPTIONS);

    try {
      const response = await this.httpClient.post(url, JSON.stringify({
        pet: request.pet_id,
        message: request.message
      }), true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.adoption = this.parseAdoption(parsed);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to create adoption';
    }

    return result;
  }

  async cancelAdoption(adoptionId: number): Promise<AdoptionDetailResult> {
    const result = new AdoptionDetailResult();
    const params = new Map<string, string>();
    params.set('id', adoptionId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.ADOPTION_DETAIL, params);

    try {
      const response = await this.httpClient.patch(url, JSON.stringify({
        status: 'closed'
      }), true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.adoption = this.parseAdoption(parsed);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to cancel adoption';
    }

    return result;
  }

  private parseAdoption(data: Record<string, Object>): Adoption {
    const adoption = new Adoption();
    adoption.id = Number(data['id']) || 0;
    adoption.pet_id = Number(data['pet']) || 0;
    adoption.applicant_id = Number(data['applicant']) || 0;
    adoption.message = String(data['message'] || '');
    adoption.status = String(data['status'] || 'submitted');
    adoption.add_date = String(data['add_date'] || '');
    adoption.pub_date = String(data['pub_date'] || '');
    return adoption;
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
