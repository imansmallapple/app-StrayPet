// Export all models

export { Pet, PetPhoto, Address, UserBasic, Shelter } from './Pet';
export { User, UserProfile, TokenResponse, LoginRequest, RegisterRequest, UpdateProfileRequest, Notification } from './User';
export { Adoption, AdoptionRequest, Donation, DonationPhoto, DonationRequest } from './Adoption';
export { Lost, LostRequest } from './Lost';
export { HolidayFamilyApplication, HolidayFamilyRequest } from './HolidayFamily';

// Common response wrapper
export class ApiResponse<T> {
  count: number = 0;
  next: string = '';
  previous: string = '';
  results: T[] = [];

  constructor() {}
}

// Error response
export class ApiError {
  detail: string = '';
  code: string = '';

  constructor(detail: string = '', code: string = '') {
    this.detail = detail;
    this.code = code;
  }
}
