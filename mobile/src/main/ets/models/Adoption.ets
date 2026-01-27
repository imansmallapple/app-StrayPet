// Adoption and Donation models following ArkTS strict typing rules

import { Pet, UserBasic, Address, Shelter } from './Pet';

export class Adoption {
  id: number = 0;
  pet: Pet | null = null;
  pet_id: number = 0;
  applicant: UserBasic | null = null;
  applicant_id: number = 0;
  message: string = '';
  status: string = 'submitted';
  add_date: string = '';
  pub_date: string = '';

  constructor() {}

  getStatusDisplay(): string {
    const statusMap: Map<string, string> = new Map([
      ['submitted', 'Submitted'],
      ['processing', 'Processing'],
      ['approved', 'Approved'],
      ['rejected', 'Rejected'],
      ['closed', 'Closed']
    ]);
    const result = statusMap.get(this.status);
    return result !== undefined ? result : this.status;
  }

  getStatusColor(): ResourceColor {
    const colorMap: Map<string, ResourceColor> = new Map([
      ['submitted', '#2196F3'],
      ['processing', '#FF9800'],
      ['approved', '#4CAF50'],
      ['rejected', '#F44336'],
      ['closed', '#9E9E9E']
    ]);
    const result = colorMap.get(this.status);
    return result !== undefined ? result : '#9E9E9E';
  }
}

export class AdoptionRequest {
  pet_id: number = 0;
  message: string = '';

  constructor(pet_id: number = 0, message: string = '') {
    this.pet_id = pet_id;
    this.message = message;
  }
}

export class DonationPhoto {
  id: number = 0;
  image: string = '';
  add_date: string = '';

  constructor(id: number = 0, image: string = '', add_date: string = '') {
    this.id = id;
    this.image = image;
    this.add_date = add_date;
  }
}

export class Donation {
  id: number = 0;
  donor: UserBasic | null = null;
  donor_id: number = 0;
  name: string = '';
  species: string = '';
  breed: string = '';
  sex: string = 'male';
  age_years: number = 0;
  age_months: number = 0;
  description: string = '';
  address: Address | null = null;
  shelter: Shelter | null = null;
  contact_phone: string = '';

  // Health traits
  dewormed: boolean = false;
  vaccinated: boolean = false;
  microchipped: boolean = false;
  sterilized: boolean = false;
  child_friendly: boolean = false;
  trained: boolean = false;
  loves_play: boolean = false;
  loves_walks: boolean = false;
  good_with_dogs: boolean = false;
  good_with_cats: boolean = false;
  affectionate: boolean = false;
  needs_attention: boolean = false;
  is_stray: boolean = false;

  // Review
  status: string = 'submitted';
  review_note: string = '';
  photos: DonationPhoto[] = [];

  // Timestamps
  add_date: string = '';
  pub_date: string = '';

  constructor() {}

  getStatusDisplay(): string {
    const statusMap: Map<string, string> = new Map([
      ['submitted', 'Submitted'],
      ['reviewing', 'Reviewing'],
      ['approved', 'Approved'],
      ['rejected', 'Rejected'],
      ['closed', 'Closed']
    ]);
    const result = statusMap.get(this.status);
    return result !== undefined ? result : this.status;
  }
}

export class DonationRequest {
  name: string = '';
  species: string = '';
  breed: string = '';
  sex: string = 'male';
  age_years: number = 0;
  age_months: number = 0;
  description: string = '';
  contact_phone: string = '';
  dewormed: boolean = false;
  vaccinated: boolean = false;
  microchipped: boolean = false;
  sterilized: boolean = false;

  constructor() {}
}
