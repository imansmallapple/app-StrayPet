// API Configuration
// Following ArkTS strict typing rules

// API Endpoints class - following ArkTS no object literal rule
export class ApiEndpoints {
  // User endpoints
  static readonly TOKEN: string = 'user/token/';
  static readonly TOKEN_REFRESH: string = 'user/token/refresh/';
  static readonly REGISTER: string = 'user/register/';
  static readonly USER_INFO: string = 'user/userinfo/';
  static readonly USER_LIST: string = 'user/list/';
  static readonly NOTIFICATIONS: string = 'user/notifications/';

  // Pet endpoints
  static readonly PETS: string = 'pet/';
  static readonly PET_DETAIL: string = 'pet/{id}/';
  static readonly PET_FAVORITE: string = 'pet/{id}/favorite/';

  // Adoption endpoints
  static readonly ADOPTIONS: string = 'pet/adoption/';
  static readonly ADOPTION_DETAIL: string = 'pet/adoption/{id}/';

  // Lost endpoints
  static readonly LOST: string = 'pet/lost/';
  static readonly LOST_DETAIL: string = 'pet/lost/{id}/';

  // Donation endpoints
  static readonly DONATIONS: string = 'pet/donation/';
  static readonly DONATION_DETAIL: string = 'pet/donation/{id}/';

  // Shelter endpoints
  static readonly SHELTERS: string = 'pet/shelter/';
  static readonly SHELTER_DETAIL: string = 'pet/shelter/{id}/';

  // Holiday Family endpoints
  static readonly HOLIDAY_FAMILY: string = 'pet/holiday-family/';
  static readonly HOLIDAY_FAMILY_DETAIL: string = 'pet/holiday-family/{id}/';
}

export class ApiConfig {
  // Base URL - change this to your backend server address
  // Use your computer's actual IP address for device/emulator access
  static readonly BASE_URL: string = 'http://192.168.123.237:8000/';

  // Request timeout in milliseconds
  static readonly TIMEOUT: number = 30000;

  // Build full URL
  static buildUrl(endpoint: string, params?: Map<string, string>): string {
    let url = ApiConfig.BASE_URL + endpoint;
    if (params !== undefined) {
      params.forEach((value: string, key: string) => {
        url = url.replace(`{${key}}`, value);
      });
    }
    return url;
  }

  // Build URL with query parameters
  static buildUrlWithQuery(endpoint: string, queryParams?: Map<string, string>): string {
    let url = ApiConfig.BASE_URL + endpoint;
    if (queryParams !== undefined && queryParams.size > 0) {
      const queryParts: string[] = [];
      queryParams.forEach((value: string, key: string) => {
        queryParts.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`);
      });
      url = url + '?' + queryParts.join('&');
    }
    return url;
  }
}
