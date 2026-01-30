// Token Manager Service
// Following ArkTS strict typing rules

import { preferences } from '@kit.ArkData';
import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';

export class TokenManager {
  private static instance: TokenManager | null = null;
  private accessToken: string = '';
  private refreshToken: string = '';
  private userId: number = 0;
  private username: string = '';
  private isStaff: boolean = false;
  private readonly PREF_NAME: string = 'stray_pet_auth';
  private isRefreshing: boolean = false;
  private context: Context | null = null;
  private isInitialized: boolean = false;
  private initPromise: Promise<void> | null = null;
  private initStarted: boolean = false;

  static getInstance(): TokenManager {
    if (TokenManager.instance === null) {
      TokenManager.instance = new TokenManager();
    }
    return TokenManager.instance;
  }

  // 等待初始化完成
  async waitForInit(): Promise<void> {
    // 如果已经初始化完成，直接返回
    if (this.isInitialized) {
      console.info('[TokenManager] waitForInit: already initialized');
      return;
    }
    
    // 最多等待 3 秒让初始化开始
    let waited = 0;
    while (!this.initStarted && waited < 3000) {
      console.info('[TokenManager] waitForInit: waiting for init to start, waited:', waited);
      await new Promise<void>((resolve) => setTimeout(resolve, 100));
      waited += 100;
    }
    
    // 如果有 initPromise，等待它完成
    if (this.initPromise !== null) {
      console.info('[TokenManager] waitForInit: waiting for initPromise');
      await this.initPromise;
      return;
    }
    
    // 如果初始化还没开始，再等一会儿看看是否完成
    while (!this.isInitialized && waited < 5000) {
      await new Promise<void>((resolve) => setTimeout(resolve, 100));
      waited += 100;
    }
    console.info('[TokenManager] waitForInit: done, isInitialized:', this.isInitialized);
  }

  getIsInitialized(): boolean {
    return this.isInitialized;
  }

  getAccessToken(): string {
    return this.accessToken;
  }

  getRefreshToken(): string {
    return this.refreshToken;
  }

  getUserId(): number {
    return this.userId;
  }

  getUsername(): string {
    return this.username;
  }

  getIsStaff(): boolean {
    return this.isStaff;
  }

  isLoggedIn(): boolean {
    return this.accessToken.length > 0;
  }

  setTokens(accessToken: string, refreshToken: string): void {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  setUserInfo(userId: number, username: string, isStaff: boolean = false): void {
    this.userId = userId;
    this.username = username;
    this.isStaff = isStaff;
  }

  clearTokens(): void {
    this.accessToken = '';
    this.refreshToken = '';
    this.userId = 0;
    this.username = '';
    this.isStaff = false;
  }

  async saveToPreferences(context: Context): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, this.PREF_NAME);
      await pref.put('accessToken', this.accessToken);
      await pref.put('refreshToken', this.refreshToken);
      await pref.put('userId', this.userId);
      await pref.put('username', this.username);
      await pref.put('isStaff', this.isStaff);
      await pref.flush();
    } catch (error) {
      console.error('TokenManager: Failed to save preferences', JSON.stringify(error));
    }
  }

  async loadFromPreferences(context: Context): Promise<void> {
    console.info('[TokenManager] loadFromPreferences: starting');
    this.initStarted = true;
    this.initPromise = this.doLoadFromPreferences(context);
    await this.initPromise;
    console.info('[TokenManager] loadFromPreferences: done');
  }

  private async doLoadFromPreferences(context: Context): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, this.PREF_NAME);
      const accessToken = await pref.get('accessToken', '');
      const refreshToken = await pref.get('refreshToken', '');
      const userId = await pref.get('userId', 0);
      const username = await pref.get('username', '');
      const isStaff = await pref.get('isStaff', false);

      if (typeof accessToken === 'string') {
        this.accessToken = accessToken;
      }
      if (typeof refreshToken === 'string') {
        this.refreshToken = refreshToken;
      }
      if (typeof userId === 'number') {
        this.userId = userId;
      }
      if (typeof username === 'string') {
        this.username = username;
      }
      if (typeof isStaff === 'boolean') {
        this.isStaff = isStaff;
      }
      console.info('[TokenManager] Loaded from preferences, token length:', this.accessToken.length);
    } catch (error) {
      console.error('TokenManager: Failed to load preferences', JSON.stringify(error));
    } finally {
      this.isInitialized = true;
    }
  }

  async clearPreferences(context: Context): Promise<void> {
    try {
      await preferences.deletePreferences(context, this.PREF_NAME);
      this.clearTokens();
    } catch (error) {
      console.error('TokenManager: Failed to clear preferences', JSON.stringify(error));
    }
  }

  setContext(context: Context): void {
    this.context = context;
  }

  // Refresh access token using refresh token
  async refreshAccessToken(): Promise<boolean> {
    if (this.isRefreshing) {
      // Already refreshing, wait a bit and check again
      return false;
    }

    if (this.refreshToken.length === 0) {
      console.error('TokenManager: No refresh token available');
      return false;
    }

    this.isRefreshing = true;
    console.info('TokenManager: Refreshing access token...');

    try {
      const httpRequest = http.createHttp();
      const url = `${ApiConfig.BASE_URL}user/token/refresh/`;
      const body = JSON.stringify({ refresh: this.refreshToken });

      const result = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        extraData: body,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      httpRequest.destroy();

      if (result.responseCode === 200) {
        const data = JSON.parse(result.result as string) as Record<string, string>;
        const newAccessToken = data['access'] ?? '';
        const newRefreshToken = data['refresh'] ?? this.refreshToken;

        if (newAccessToken.length > 0) {
          this.accessToken = newAccessToken;
          this.refreshToken = newRefreshToken;

          // Save to preferences if context is available
          if (this.context !== null) {
            await this.saveToPreferences(this.context);
          }

          console.info('TokenManager: Token refreshed successfully');
          this.isRefreshing = false;
          return true;
        }
      } else {
        console.error('TokenManager: Token refresh failed with code', result.responseCode);
        // If refresh fails, clear tokens (user needs to login again)
        this.clearTokens();
        if (this.context !== null) {
          await this.clearPreferences(this.context);
        }
      }
    } catch (error) {
      console.error('TokenManager: Token refresh error', JSON.stringify(error));
    }

    this.isRefreshing = false;
    return false;
  }
}
