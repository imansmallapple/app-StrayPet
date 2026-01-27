// Lost pet models following ArkTS strict typing rules

import { Address, UserBasic } from './Pet';

export class Lost {
  id: number = 0;
  pet_id: number = 0;
  pet_name: string = '';
  species: string = '';
  breed: string = '';
  color: string = '';
  sex: string = 'male';
  size: string = '';
  address: Address | null = null;
  lost_time: string = '';
  description: string = '';
  reward: number = 0;
  photo: string = '';
  status: string = 'open';
  reporter: UserBasic | null = null;
  contact_phone: string = '';
  contact_email: string = '';
  created_at: string = '';
  updated_at: string = '';

  constructor() {}

  getStatusDisplay(): string {
    const statusMap: Map<string, string> = new Map([
      ['open', 'Looking'],
      ['found', 'Found'],
      ['closed', 'Closed']
    ]);
    const result = statusMap.get(this.status);
    return result !== undefined ? result : this.status;
  }

  getStatusColor(): ResourceColor {
    const colorMap: Map<string, ResourceColor> = new Map([
      ['open', '#F44336'],
      ['found', '#4CAF50'],
      ['closed', '#9E9E9E']
    ]);
    const result = colorMap.get(this.status);
    return result !== undefined ? result : '#9E9E9E';
  }

  getSexDisplay(): string {
    return this.sex === 'male' ? 'Boy' : 'Girl';
  }
}

export class LostRequest {
  pet_name: string = '';
  species: string = '';
  breed: string = '';
  color: string = '';
  sex: string = 'male';
  size: string = '';
  lost_time: string = '';
  description: string = '';
  reward: number = 0;
  contact_phone: string = '';
  contact_email: string = '';

  constructor() {}
}
