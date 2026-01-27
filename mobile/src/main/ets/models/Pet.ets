// Pet related models following ArkTS strict typing rules

export class PetPhoto {
  id: number = 0;
  image: string = '';
  order: number = 0;
  add_date: string = '';

  constructor(id: number = 0, image: string = '', order: number = 0, add_date: string = '') {
    this.id = id;
    this.image = image;
    this.order = order;
    this.add_date = add_date;
  }
}

export class Address {
  id: number = 0;
  country: string = '';
  country_id: number = 0;
  region: string = '';
  region_id: number = 0;
  city: string = '';
  city_id: number = 0;
  street: string = '';
  building_number: string = '';
  postal_code: string = '';
  latitude: number = 0;
  longitude: number = 0;

  constructor() {}

  getFullAddress(): string {
    const parts: string[] = [];
    if (this.street.length > 0) {
      parts.push(this.street);
    }
    if (this.building_number.length > 0) {
      parts.push(this.building_number);
    }
    if (this.city.length > 0) {
      parts.push(this.city);
    }
    if (this.region.length > 0) {
      parts.push(this.region);
    }
    if (this.country.length > 0) {
      parts.push(this.country);
    }
    return parts.join(', ');
  }
}

export class UserBasic {
  id: number = 0;
  username: string = '';
  email: string = '';
  avatar: string = '';

  constructor(id: number = 0, username: string = '', email: string = '', avatar: string = '') {
    this.id = id;
    this.username = username;
    this.email = email;
    this.avatar = avatar;
  }
}

export class Shelter {
  id: number = 0;
  name: string = '';
  description: string = '';
  email: string = '';
  phone: string = '';
  website: string = '';
  logo: string = '';
  cover_image: string = '';
  capacity: number = 0;
  current_animals: number = 0;
  is_verified: boolean = false;
  is_active: boolean = true;
  address: Address | null = null;

  constructor() {}
}

export class Pet {
  id: number = 0;
  name: string = '';
  species: string = '';
  breed: string = '';
  sex: string = 'male';
  age_years: number = 0;
  age_months: number = 0;
  size: string = '';
  description: string = '';
  cover: string = '';
  status: string = 'available';
  contact_phone: string = '';

  // Health and traits
  dewormed: boolean = false;
  vaccinated: boolean = false;
  microchipped: boolean = false;
  child_friendly: boolean = false;
  trained: boolean = false;
  loves_play: boolean = false;
  loves_walks: boolean = false;
  good_with_dogs: boolean = false;
  good_with_cats: boolean = false;
  affectionate: boolean = false;
  needs_attention: boolean = false;
  sterilized: boolean = false;

  // Relations
  address: Address | null = null;
  shelter: Shelter | null = null;
  created_by: UserBasic | null = null;
  photos: PetPhoto[] = [];

  // Timestamps
  add_date: string = '';
  pub_date: string = '';

  // UI helpers
  is_favorited: boolean = false;
  favorite_count: number = 0;

  constructor() {}

  getAgeString(): string {
    if (this.age_years > 0 && this.age_months > 0) {
      return `${this.age_years}y ${this.age_months}m`;
    } else if (this.age_years > 0) {
      return `${this.age_years} years`;
    } else if (this.age_months > 0) {
      return `${this.age_months} months`;
    }
    return 'Unknown';
  }

  getSexDisplay(): string {
    return this.sex === 'male' ? 'Boy' : 'Girl';
  }

  getStatusDisplay(): string {
    const statusMap: Map<string, string> = new Map([
      ['draft', 'Draft'],
      ['available', 'Available'],
      ['pending', 'Pending'],
      ['adopted', 'Adopted'],
      ['archived', 'Archived'],
      ['lost', 'Lost']
    ]);
    const result = statusMap.get(this.status);
    return result !== undefined ? result : this.status;
  }

  getTraits(): string[] {
    const traits: string[] = [];
    if (this.vaccinated) traits.push('Vaccinated');
    if (this.dewormed) traits.push('Dewormed');
    if (this.microchipped) traits.push('Microchipped');
    if (this.sterilized) traits.push('Sterilized');
    if (this.trained) traits.push('Trained');
    if (this.child_friendly) traits.push('Child Friendly');
    if (this.good_with_dogs) traits.push('Good with Dogs');
    if (this.good_with_cats) traits.push('Good with Cats');
    if (this.loves_play) traits.push('Playful');
    if (this.loves_walks) traits.push('Loves Walks');
    if (this.affectionate) traits.push('Affectionate');
    if (this.needs_attention) traits.push('Needs Attention');
    return traits;
  }
}
