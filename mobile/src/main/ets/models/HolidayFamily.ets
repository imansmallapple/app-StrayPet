// Holiday Family models following ArkTS strict typing rules

export class HolidayFamilyApplication {
  id: number = 0;
  user_id: number = 0;
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
  terms_agreed: boolean = false;
  status: string = 'pending';
  rejection_reason: string = '';
  created_at: string = '';
  updated_at: string = '';

  constructor() {}

  getStatusDisplay(): string {
    const statusMap: Map<string, string> = new Map([
      ['pending', 'Pending Review'],
      ['approved', 'Approved'],
      ['rejected', 'Rejected']
    ]);
    const result = statusMap.get(this.status);
    return result !== undefined ? result : this.status;
  }

  getStatusColor(): ResourceColor {
    const colorMap: Map<string, ResourceColor> = new Map([
      ['pending', '#FF9800'],
      ['approved', '#4CAF50'],
      ['rejected', '#F44336']
    ]);
    const result = colorMap.get(this.status);
    return result !== undefined ? result : '#9E9E9E';
  }

  getAcceptedPetTypes(): string[] {
    const types: string[] = [];
    if (this.can_take_dogs) types.push('Dogs');
    if (this.can_take_cats) types.push('Cats');
    if (this.can_take_rabbits) types.push('Rabbits');
    if (this.can_take_others.length > 0) types.push(this.can_take_others);
    return types;
  }
}

export class HolidayFamilyRequest {
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
  terms_agreed: boolean = false;

  constructor() {}
}
