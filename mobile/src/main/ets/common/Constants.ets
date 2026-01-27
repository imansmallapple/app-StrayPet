// App Constants
// Following ArkTS strict typing rules

export class AppColors {
  // Primary colors
  static readonly PRIMARY: ResourceColor = '#FF6B35';
  static readonly PRIMARY_DARK: ResourceColor = '#E55A25';
  static readonly PRIMARY_LIGHT: ResourceColor = '#FFAB91';

  // Accent colors
  static readonly ACCENT: ResourceColor = '#FF4081';
  static readonly ACCENT_DARK: ResourceColor = '#F50057';

  // Status colors
  static readonly SUCCESS: ResourceColor = '#4CAF50';
  static readonly WARNING: ResourceColor = '#FF9800';
  static readonly ERROR: ResourceColor = '#F44336';
  static readonly INFO: ResourceColor = '#2196F3';

  // Neutral colors
  static readonly WHITE: ResourceColor = '#FFFFFF';
  static readonly BLACK: ResourceColor = '#000000';
  static readonly BACKGROUND: ResourceColor = '#FAFAFA';
  static readonly SURFACE: ResourceColor = '#FFFFFF';
  static readonly DIVIDER: ResourceColor = '#E0E0E0';

  // Text colors
  static readonly TEXT_PRIMARY: ResourceColor = '#212121';
  static readonly TEXT_SECONDARY: ResourceColor = '#757575';
  static readonly TEXT_DISABLED: ResourceColor = '#BDBDBD';
  static readonly TEXT_HINT: ResourceColor = '#9E9E9E';
}

export class AppSizes {
  // Font sizes
  static readonly FONT_HEADLINE: number = 24;
  static readonly FONT_TITLE: number = 20;
  static readonly FONT_SUBTITLE: number = 16;
  static readonly FONT_BODY: number = 14;
  static readonly FONT_CAPTION: number = 12;

  // Spacing
  static readonly SPACING_XS: number = 4;
  static readonly SPACING_SM: number = 8;
  static readonly SPACING_MD: number = 16;
  static readonly SPACING_LG: number = 24;
  static readonly SPACING_XL: number = 32;

  // Border radius
  static readonly RADIUS_SM: number = 4;
  static readonly RADIUS_MD: number = 8;
  static readonly RADIUS_LG: number = 12;
  static readonly RADIUS_XL: number = 24;
  static readonly RADIUS_FULL: number = 100;
}

export class AppStrings {
  // App info
  static readonly APP_NAME: string = 'StrayPet';
  static readonly APP_TAGLINE: string = 'Find your perfect companion';

  // Common actions
  static readonly ACTION_SAVE: string = 'Save';
  static readonly ACTION_CANCEL: string = 'Cancel';
  static readonly ACTION_DELETE: string = 'Delete';
  static readonly ACTION_EDIT: string = 'Edit';
  static readonly ACTION_SUBMIT: string = 'Submit';
  static readonly ACTION_RETRY: string = 'Retry';

  // Common messages
  static readonly MSG_LOADING: string = 'Loading...';
  static readonly MSG_NO_DATA: string = 'No data available';
  static readonly MSG_ERROR: string = 'Something went wrong';
  static readonly MSG_SUCCESS: string = 'Operation successful';
}
