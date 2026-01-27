// Token Manager Service
// Following ArkTS strict typing rules

import { preferences } from '@kit.ArkData';

export class TokenManager {
  private static instance: TokenManager | null = null;
  private accessToken: string = '';
  private refreshToken: string = '';
  private userId: number = 0;
  private username: string = '';
  private readonly PREF_NAME: string = 'stray_pet_auth';

  static getInstance(): TokenManager {
    if (TokenManager.instance === null) {
      TokenManager.instance = new TokenManager();
    }
    return TokenManager.instance;
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

  isLoggedIn(): boolean {
    return this.accessToken.length > 0;
  }

  setTokens(accessToken: string, refreshToken: string): void {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  setUserInfo(userId: number, username: string): void {
    this.userId = userId;
    this.username = username;
  }

  clearTokens(): void {
    this.accessToken = '';
    this.refreshToken = '';
    this.userId = 0;
    this.username = '';
  }

  async saveToPreferences(context: Context): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, this.PREF_NAME);
      await pref.put('accessToken', this.accessToken);
      await pref.put('refreshToken', this.refreshToken);
      await pref.put('userId', this.userId);
      await pref.put('username', this.username);
      await pref.flush();
    } catch (error) {
      console.error('TokenManager: Failed to save preferences', JSON.stringify(error));
    }
  }

  async loadFromPreferences(context: Context): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, this.PREF_NAME);
      const accessToken = await pref.get('accessToken', '');
      const refreshToken = await pref.get('refreshToken', '');
      const userId = await pref.get('userId', 0);
      const username = await pref.get('username', '');

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
    } catch (error) {
      console.error('TokenManager: Failed to load preferences', JSON.stringify(error));
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
}
