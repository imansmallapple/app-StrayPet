// User related models following ArkTS strict typing rules

export class UserProfile {
  id: number = 0;
  phone: string = '';
  avatar: string = '';
  is_holiday_family_certified: boolean = false;
  preferred_species: string = '';
  preferred_size: string = '';
  preferred_gender: string = '';
  has_experience: boolean = false;
  living_situation: string = '';
  has_yard: boolean = false;
  other_pets: string = '';
  additional_notes: string = '';

  constructor() {}
}

export class User {
  id: number = 0;
  username: string = '';
  email: string = '';
  first_name: string = '';
  last_name: string = '';
  is_active: boolean = true;
  is_staff: boolean = false;
  date_joined: string = '';
  profile: UserProfile | null = null;

  constructor() {}

  getDisplayName(): string {
    if (this.first_name.length > 0 || this.last_name.length > 0) {
      return `${this.first_name} ${this.last_name}`.trim();
    }
    return this.username;
  }

  getAvatar(): string {
    if (this.profile !== null && this.profile.avatar.length > 0) {
      return this.profile.avatar;
    }
    return '';
  }
}

export class TokenResponse {
  access: string = '';
  refresh: string = '';

  constructor(access: string = '', refresh: string = '') {
    this.access = access;
    this.refresh = refresh;
  }
}

export class LoginRequest {
  username: string = '';
  password: string = '';
  captcha: string = '';
  uid: string = '';

  constructor(username: string = '', password: string = '', captcha: string = '', uid: string = '') {
    this.username = username;
    this.password = password;
    this.captcha = captcha;
    this.uid = uid;
  }
}

export class RegisterRequest {
  username: string = '';
  email: string = '';
  password: string = '';
  password2: string = '';

  constructor(username: string = '', email: string = '', password: string = '', password2: string = '') {
    this.username = username;
    this.email = email;
    this.password = password;
    this.password2 = password2;
  }
}

export class Notification {
  id: number = 0;
  notification_type: string = '';
  message: string = '';
  is_read: boolean = false;
  created_at: string = '';

  constructor() {}

  getTypeDisplay(): string {
    const typeMap: Map<string, string> = new Map([
      ['reply', 'Comment Reply'],
      ['mention', 'Mention'],
      ['friend_request', 'Friend Request'],
      ['system', 'System'],
      ['holiday_family_apply', 'Holiday Family Application'],
      ['holiday_family_approve', 'Application Approved'],
      ['holiday_family_reject', 'Application Rejected']
    ]);
    const result = typeMap.get(this.notification_type);
    return result !== undefined ? result : this.notification_type;
  }
}
