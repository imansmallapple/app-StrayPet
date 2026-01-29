// Holiday Family Service
// Following ArkTS strict typing rules

import { HttpClient, HttpResponse } from './HttpClient';
import { ApiConfig, ApiEndpoints } from './ApiConfig';

// Holiday Family Application Model
export class HolidayFamilyApplication {
  id: number = 0;
  user: number | null = null;
  full_name: string = '';
  email: string = '';
  phone: string = '';
  country: string = '';
  state: string = '';
  city: string = '';
  street_address: string = '';
  postal_code: string = '';
  pet_count: number = 0;
  can_take_dogs: boolean = false;
  can_take_cats: boolean = false;
  can_take_rabbits: boolean = false;
  can_take_others: string = '';
  motivation: string = '';
  introduction: string = '';
  family_photos: HolidayFamilyPhoto[] = [];
  status: string = 'pending';
  rejection_reason: string = '';
  created_at: string = '';
  updated_at: string = '';
  avatar: string = '';  // User avatar URL
}

export class HolidayFamilyPhoto {
  id: number = 0;
  photo: string = '';
  uploaded_at: string = '';
}

export class HolidayFamilyResult {
  success: boolean = false;
  data: HolidayFamilyApplication | null = null;
  errorMessage: string = '';

  constructor(success: boolean = false, data: HolidayFamilyApplication | null = null, errorMessage: string = '') {
    this.success = success;
    this.data = data;
    this.errorMessage = errorMessage;
  }
}

export class HolidayFamilyListResult {
  success: boolean = false;
  data: HolidayFamilyApplication[] = [];
  count: number = 0;
  errorMessage: string = '';

  constructor() {}
}

export class HolidayFamilyService {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = HttpClient.getInstance();
  }

  // Get all approved holiday family applications (public list)
  async getApprovedList(): Promise<HolidayFamilyListResult> {
    const result = new HolidayFamilyListResult();
    const url = ApiConfig.buildUrl(`${ApiEndpoints.HOLIDAY_FAMILY}approved/`);
    console.info('[HolidayFamilyService] Getting approved list:', url);

    try {
      const response: HttpResponse = await this.httpClient.get(url, false);
      console.info('[HolidayFamilyService] List Response:', response.success, response.code);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.count = Number(parsed['count']) || 0;
        const resultsData = parsed['results'];
        if (Array.isArray(resultsData)) {
          result.data = resultsData.map((item: Object) => {
            return this.parseApplicationObject(item as Record<string, Object>);
          });
        }
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to load list';
      console.error('[HolidayFamilyService] List Exception:', result.errorMessage);
    }

    return result;
  }

  // Get single family detail by ID (public)
  async getFamilyDetail(familyId: number): Promise<HolidayFamilyResult> {
    const result = new HolidayFamilyResult();
    const url = ApiConfig.buildUrl(`${ApiEndpoints.HOLIDAY_FAMILY}${familyId}/`);
    console.info('[HolidayFamilyService] Getting family detail:', url);

    try {
      const response: HttpResponse = await this.httpClient.get(url, false);
      console.info('[HolidayFamilyService] Detail Response:', response.success, response.code);

      if (response.success) {
        result.data = this.parseApplication(response.data);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to load family detail';
      console.error('[HolidayFamilyService] Detail Exception:', result.errorMessage);
    }

    return result;
  }

  // Get current user's approved holiday family application
  async getMyApplication(userId: number): Promise<HolidayFamilyResult> {
    const result = new HolidayFamilyResult();
    const url = ApiConfig.buildUrl(`${ApiEndpoints.HOLIDAY_FAMILY}user-application/${userId}/`);
    console.info('[HolidayFamilyService] Getting user application:', url);

    try {
      const response: HttpResponse = await this.httpClient.get(url, true);
      console.info('[HolidayFamilyService] Response:', response.success, response.code);

      if (response.success) {
        result.data = this.parseApplication(response.data);
        result.success = true;
      } else {
        // 404 means no approved application found
        if (response.code === 404) {
          result.errorMessage = 'No approved application found';
        } else {
          result.errorMessage = this.parseErrorMessage(response.data);
        }
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to load application';
      console.error('[HolidayFamilyService] Exception:', result.errorMessage);
    }

    return result;
  }

  private parseApplication(jsonData: string): HolidayFamilyApplication {
    const parsed = JSON.parse(jsonData) as Record<string, Object>;
    return this.parseApplicationObject(parsed);
  }

  private parseApplicationObject(parsed: Record<string, Object>): HolidayFamilyApplication {
    const application = new HolidayFamilyApplication();

    try {
      application.id = Number(parsed['id']) || 0;
      application.user = parsed['user'] !== null ? Number(parsed['user']) : null;
      application.full_name = String(parsed['full_name'] || '');
      application.email = String(parsed['email'] || '');
      application.phone = String(parsed['phone'] || '');
      application.country = String(parsed['country'] || '');
      application.state = String(parsed['state'] || '');
      application.city = String(parsed['city'] || '');
      application.street_address = String(parsed['street_address'] || '');
      application.postal_code = String(parsed['postal_code'] || '');
      application.pet_count = Number(parsed['pet_count']) || 0;
      application.can_take_dogs = Boolean(parsed['can_take_dogs']);
      application.can_take_cats = Boolean(parsed['can_take_cats']);
      application.can_take_rabbits = Boolean(parsed['can_take_rabbits']);
      application.can_take_others = String(parsed['can_take_others'] || '');
      application.motivation = String(parsed['motivation'] || '');
      application.introduction = String(parsed['introduction'] || '');
      application.status = String(parsed['status'] || 'pending');
      application.rejection_reason = String(parsed['rejection_reason'] || '');
      application.created_at = String(parsed['created_at'] || '');
      application.updated_at = String(parsed['updated_at'] || '');
      application.avatar = String(parsed['avatar'] || '');

      // Parse photos - API returns array of URL strings
      const photosData = parsed['family_photos'];
      if (Array.isArray(photosData)) {
        application.family_photos = photosData.map((photoItem: Object, index: number) => {
          const photo = new HolidayFamilyPhoto();
          // Check if it's a string (URL) or an object
          if (typeof photoItem === 'string') {
            photo.id = index + 1;
            photo.photo = String(photoItem);
            photo.uploaded_at = '';
          } else {
            const photoObj = photoItem as Record<string, Object>;
            photo.id = Number(photoObj['id']) || index + 1;
            photo.photo = String(photoObj['photo'] || '');
            photo.uploaded_at = String(photoObj['uploaded_at'] || '');
          }
          return photo;
        });
      }
    } catch (e) {
      console.error('[HolidayFamilyService] Parse error:', JSON.stringify(e));
    }

    return application;
  }

  private parseErrorMessage(jsonData: string): string {
    try {
      const parsed = JSON.parse(jsonData) as Record<string, Object>;
      if (parsed['error'] !== undefined) {
        return String(parsed['error']);
      }
      if (parsed['detail'] !== undefined) {
        return String(parsed['detail']);
      }
    } catch (e) {
      // Ignore parse error
    }
    return 'Request failed';
  }
}
