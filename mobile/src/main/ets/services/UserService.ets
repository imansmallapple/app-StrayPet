// User API Service
// Following ArkTS strict typing rules

import { HttpClient } from './HttpClient';
import { ApiConfig, ApiEndpoints } from './ApiConfig';
import { TokenManager } from './TokenManager';
import { User, TokenResponse, LoginRequest, RegisterRequest, Notification, ApiResponse } from '../models/index';

export class UserResult {
  success: boolean = false;
  data: User | null = null;
  errorMessage: string = '';

  constructor(success: boolean = false, data: User | null = null, errorMessage: string = '') {
    this.success = success;
    this.data = data;
    this.errorMessage = errorMessage;
  }
}

export class LoginResult {
  success: boolean = false;
  tokens: TokenResponse | null = null;
  errorMessage: string = '';

  constructor(success: boolean = false, tokens: TokenResponse | null = null, errorMessage: string = '') {
    this.success = success;
    this.tokens = tokens;
    this.errorMessage = errorMessage;
  }
}

export class NotificationsResult {
  success: boolean = false;
  notifications: Notification[] = [];
  count: number = 0;
  errorMessage: string = '';

  constructor() {}
}

export class UserService {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = HttpClient.getInstance();
  }

  async login(request: LoginRequest): Promise<LoginResult> {
    const result = new LoginResult();
    const url = ApiConfig.buildUrl(ApiEndpoints.TOKEN);

    try {
      const response = await this.httpClient.post(url, JSON.stringify({
        username: request.username,
        password: request.password,
        captcha: request.captcha,
        uid: request.uid
      }), false);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, string>;
        const tokens = new TokenResponse();
        tokens.access = parsed['access'] as string || '';
        tokens.refresh = parsed['refresh'] as string || '';

        TokenManager.getInstance().setTokens(tokens.access, tokens.refresh);
        result.success = true;
        result.tokens = tokens;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Login failed';
    }

    return result;
  }

  async register(request: RegisterRequest): Promise<UserResult> {
    const result = new UserResult();
    const url = ApiConfig.buildUrl(ApiEndpoints.REGISTER);

    try {
      const response = await this.httpClient.post(url, JSON.stringify({
        username: request.username,
        email: request.email,
        password: request.password,
        password2: request.password2
      }), false);

      if (response.success) {
        const user = this.parseUser(response.data);
        result.success = true;
        result.data = user;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Registration failed';
    }

    return result;
  }

  async refreshToken(): Promise<boolean> {
    const refreshToken = TokenManager.getInstance().getRefreshToken();
    if (refreshToken.length === 0) {
      return false;
    }

    const url = ApiConfig.buildUrl(ApiEndpoints.TOKEN_REFRESH);
    try {
      const response = await this.httpClient.post(url, JSON.stringify({
        refresh: refreshToken
      }), false);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, string>;
        const newAccess = parsed['access'] as string || '';
        TokenManager.getInstance().setTokens(newAccess, refreshToken);
        return true;
      }
    } catch (error) {
      console.error('Token refresh failed', JSON.stringify(error));
    }

    return false;
  }

  async getCurrentUser(): Promise<UserResult> {
    const result = new UserResult();
    const url = ApiConfig.buildUrl(ApiEndpoints.USER_INFO) + 'me/';

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const user = this.parseUser(response.data);
        result.success = true;
        result.data = user;

        if (user !== null) {
          TokenManager.getInstance().setUserInfo(user.id, user.username);
        }
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get user info';
    }

    return result;
  }

  async getNotifications(page: number = 1): Promise<NotificationsResult> {
    const result = new NotificationsResult();
    const queryParams = new Map<string, string>();
    queryParams.set('page', page.toString());

    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.NOTIFICATIONS, queryParams);

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const notification = new Notification();
            notification.id = Number(item['id']) || 0;
            notification.notification_type = String(item['notification_type']) || '';
            notification.message = String(item['message']) || '';
            notification.is_read = Boolean(item['is_read']);
            notification.created_at = String(item['created_at']) || '';
            result.notifications.push(notification);
          });
        }

        result.count = Number(parsed['count']) || 0;
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get notifications';
    }

    return result;
  }

  async logout(context: Context): Promise<void> {
    await TokenManager.getInstance().clearPreferences(context);
  }

  private parseUser(jsonString: string): User {
    const user = new User();
    try {
      const parsed = JSON.parse(jsonString) as Record<string, Object>;
      user.id = Number(parsed['id']) || 0;
      user.username = String(parsed['username']) || '';
      user.email = String(parsed['email']) || '';
      user.first_name = String(parsed['first_name']) || '';
      user.last_name = String(parsed['last_name']) || '';
      user.is_active = Boolean(parsed['is_active']);
      user.is_staff = Boolean(parsed['is_staff']);
      user.date_joined = String(parsed['date_joined']) || '';
    } catch (error) {
      console.error('Failed to parse user', JSON.stringify(error));
    }
    return user;
  }

  private parseErrorMessage(jsonString: string): string {
    try {
      const parsed = JSON.parse(jsonString) as Record<string, Object>;
      if (parsed['detail'] !== undefined) {
        return String(parsed['detail']);
      }
      // Try to get first error message from any field
      const keys = Object.keys(parsed);
      if (keys.length > 0) {
        const firstValue = parsed[keys[0]];
        if (Array.isArray(firstValue) && firstValue.length > 0) {
          return String(firstValue[0]);
        }
        return String(firstValue);
      }
    } catch (error) {
      return jsonString;
    }
    return 'Unknown error';
  }
}
