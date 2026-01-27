// Global App State Manager
// Following ArkTS strict typing rules

import { User } from '../models/User';
import { TokenManager } from '../services/TokenManager';

// AppStorage keys
export class AppStorageKeys {
  static readonly IS_LOGGED_IN: string = 'isLoggedIn';
  static readonly CURRENT_USER: string = 'currentUser';
  static readonly THEME_MODE: string = 'themeMode';
}

// Initialize global app state
export function initAppState(): void {
  // Initialize login state
  if (!AppStorage.has(AppStorageKeys.IS_LOGGED_IN)) {
    AppStorage.setOrCreate(AppStorageKeys.IS_LOGGED_IN, false);
  }

  // Initialize theme mode
  if (!AppStorage.has(AppStorageKeys.THEME_MODE)) {
    AppStorage.setOrCreate(AppStorageKeys.THEME_MODE, 'light');
  }
}

// Update login state
export function setLoggedIn(isLoggedIn: boolean, user?: User): void {
  AppStorage.setOrCreate(AppStorageKeys.IS_LOGGED_IN, isLoggedIn);
  if (user !== undefined) {
    AppStorage.setOrCreate(AppStorageKeys.CURRENT_USER, user);
  }
}

// Check if user is logged in
export function isUserLoggedIn(): boolean {
  const tokenManager = TokenManager.getInstance();
  return tokenManager.isLoggedIn();
}
