// Holiday Family Page
import { router } from '@kit.ArkUI';
import { TokenManager } from '../services/TokenManager';
import { UserService, UserResult } from '../services/UserService';
import { HolidayFamilyService, HolidayFamilyApplication, HolidayFamilyResult, HolidayFamilyListResult } from '../services/HolidayFamilyService';
import { ApiConfig } from '../services/ApiConfig';

// Tab type
type PageTab = 'families' | 'myProfile';

@Entry
@Component
struct HolidayFamilyPage {
  @State isLoggedIn: boolean = false;
  @State isLoading: boolean = true;
  @State isCertified: boolean = false;
  @State userId: number = 0;
  @State application: HolidayFamilyApplication | null = null;
  @State familyList: HolidayFamilyApplication[] = [];
  @State currentTab: PageTab = 'families';

  private userService: UserService = new UserService();
  private holidayFamilyService: HolidayFamilyService = new HolidayFamilyService();

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    this.isLoggedIn = TokenManager.getInstance().isLoggedIn();

    // Load family list (public)
    await this.loadFamilyList();

    if (this.isLoggedIn) {
      // Get user info to check certification status
      const userResult: UserResult = await this.userService.getCurrentUser();
      if (userResult.success && userResult.data !== null) {
        this.userId = userResult.data.id;
        if (userResult.data.profile !== null && userResult.data.profile.is_holiday_family_certified) {
          this.isCertified = true;
          // Load holiday family application details
          await this.loadApplicationDetails();
        }
      }
    }

    this.isLoading = false;
  }

  async loadFamilyList(): Promise<void> {
    const result: HolidayFamilyListResult = await this.holidayFamilyService.getApprovedList();
    if (result.success) {
      this.familyList = result.data;
    }
  }

  async loadApplicationDetails(): Promise<void> {
    if (this.userId > 0) {
      const result: HolidayFamilyResult = await this.holidayFamilyService.getMyApplication(this.userId);
      if (result.success && result.data !== null) {
        this.application = result.data;
      }
    }
  }

  getPetTypes(): string {
    if (this.application === null) return '';
    const types: string[] = [];
    if (this.application.can_take_dogs) types.push('Dogs');
    if (this.application.can_take_cats) types.push('Cats');
    if (this.application.can_take_rabbits) types.push('Rabbits');
    if (this.application.can_take_others.length > 0) types.push(this.application.can_take_others);
    return types.join(', ');
  }

  getFamilyPetTypes(family: HolidayFamilyApplication): string {
    const types: string[] = [];
    if (family.can_take_dogs) types.push('🐕');
    if (family.can_take_cats) types.push('🐱');
    if (family.can_take_rabbits) types.push('🐰');
    return types.length > 0 ? types.join(' ') : '🐾';
  }

  // Getter for safe application access in builders
  getApp(): HolidayFamilyApplication {
    return this.application as HolidayFamilyApplication;
  }

  build() {
    Column() {
      // Header
      Row() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor(['#424242'])
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { router.back(); })

        Text('Holiday Foster')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#9C27B0')
          .margin({ left: 8 })

        Blank()

        // Apply button in header for non-certified users
        if (!this.isCertified) {
          Button('Apply')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#9C27B0')
            .borderRadius(16)
            .height(32)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              if (!this.isLoggedIn) {
                router.pushUrl({ url: 'pages/LoginPage' });
              } else {
                router.pushUrl({ url: 'pages/HolidayFamilyApplyPage' });
              }
            })
        }
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 12, bottom: 12 })

      // Tab bar for certified users
      if (this.isCertified) {
        Row() {
          this.TabButton('Foster Families', 'families')
          this.TabButton('My Profile', 'myProfile')
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .justifyContent(FlexAlign.Start)
      }

      if (this.isLoading) {
        // Loading state
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#9C27B0')
          Text('Loading...')
            .fontSize(14)
            .fontColor('#757575')
            .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.isCertified && this.currentTab === 'myProfile' && this.application !== null) {
        // Certified user profile
        this.CertifiedContent()
      } else {
        // Family list and features
        this.FamilyListContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  TabButton(label: string, tab: PageTab): void {
    Column() {
      Text(label)
        .fontSize(14)
        .fontWeight(this.currentTab === tab ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTab === tab ? '#9C27B0' : '#757575')
        .padding({ top: 12, bottom: 10 })

      if (this.currentTab === tab) {
        Row()
          .width(40)
          .height(3)
          .borderRadius(2)
          .backgroundColor('#9C27B0')
      }
    }
    .margin({ right: 24 })
    .onClick(() => { this.currentTab = tab; })
  }

  @Builder
  FamilyListContent(): void {
    Scroll() {
      Column() {
        // Hero Banner (compact)
        Column() {
          Row() {
            Column() {
              Text('Holiday Foster Program')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')

              Text('Give pets a warm home during holidays')
                .fontSize(13)
                .fontColor('#FFFFFF')
                .opacity(0.9)
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            SymbolGlyph($r('sys.symbol.heart_fill'))
              .fontSize(48)
              .fontColor(['#FFFFFF'])
              .opacity(0.3)
          }
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#9C27B0')

        // Program Features - Horizontal scroll with improved cards
        Text('Why Foster?')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .width('100%')
          .padding({ left: 16, top: 20, bottom: 12 })

        Scroll() {
          Row({ space: 12 }) {
            this.FeatureCardNew($r('sys.symbol.house_fill'), 'Temporary Home', 'Short-term care', '#E91E63')
            this.FeatureCardNew($r('sys.symbol.heart_fill'), 'Save Lives', 'Help overcrowded shelters', '#F44336')
            this.FeatureCardNew($r('sys.symbol.person_2_fill'), 'Family Fun', 'Bond with loved ones', '#9C27B0')
            this.FeatureCardNew($r('sys.symbol.star_fill'), 'Community', 'Join caring families', '#FF9800')
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        // Certified Families Section
        Row() {
          Text('Certified Families')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')

          Blank()

          Text(`${this.familyList.length} families`)
            .fontSize(13)
            .fontColor('#9C27B0')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 24, bottom: 12 })

        if (this.familyList.length === 0) {
          // Empty state
          Column() {
            SymbolGlyph($r('sys.symbol.person_3_fill'))
              .fontSize(64)
              .fontColor(['#E0E0E0'])
            Text('No certified families yet')
              .fontSize(14)
              .fontColor('#9E9E9E')
              .margin({ top: 12 })
            Text('Be the first to join!')
              .fontSize(13)
              .fontColor('#9C27B0')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding(40)
        } else {
          // Family cards
          ForEach(this.familyList, (family: HolidayFamilyApplication) => {
            this.FamilyCard(family)
          })
        }

        // Bottom spacer
        Row().height(20)
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  FeatureCardNew(icon: Resource, title: string, description: string, color: string): void {
    Stack() {
      // Background
      Column()
        .width(130)
        .height(140)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({ radius: 8, color: '#14000000', offsetX: 0, offsetY: 4 })

      // Content
      Column() {
        // Icon circle
        Row() {
          SymbolGlyph(icon)
            .fontSize(24)
            .fontColor([color])
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor('#F5F5F5')
        .justifyContent(FlexAlign.Center)

        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .margin({ top: 12 })

        Text(description)
          .fontSize(11)
          .fontColor('#757575')
          .margin({ top: 4 })
          .maxLines(2)
      }
      .width(130)
      .height(140)
      .padding(12)
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  FamilyCard(family: HolidayFamilyApplication): void {
    Column() {
      Row() {
        // Avatar - show image if available, otherwise initial
        if (family.avatar && family.avatar.length > 0) {
          Image('http://192.168.123.237:8000' + family.avatar)
            .width(56)
            .height(56)
            .borderRadius(28)
            .objectFit(ImageFit.Cover)
            .border({ width: 2, color: '#4CAF50' })
        } else {
          Column() {
            Text(family.full_name.charAt(0).toUpperCase())
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width(56)
          .height(56)
          .borderRadius(28)
          .backgroundColor('#9C27B0')
          .justifyContent(FlexAlign.Center)
        }

        // Info
        Column() {
          Row() {
            Text(family.full_name)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')

            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(16)
              .fontColor(['#4CAF50'])
              .margin({ left: 6 })
          }

          // Location info
          Row() {
            SymbolGlyph($r('sys.symbol.paperplane'))
              .fontSize(12)
              .fontColor(['#757575'])
            Text(`${family.city}, ${family.country}`)
              .fontSize(12)
              .fontColor('#757575')
              .margin({ left: 4 })
          }
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 14 })
        .layoutWeight(1)

        // Arrow
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor(['#BDBDBD'])
      }
      .width('100%')

      // Divider
      Divider()
        .color('#F0F0F0')
        .margin({ top: 12, bottom: 12 })

      // Pet info row
      Row() {
        // Accepts pets section
        Column() {
          Text('Accepts')
            .fontSize(11)
            .fontColor('#9E9E9E')
            .margin({ bottom: 6 })

          Row({ space: 6 }) {
            if (family.can_take_dogs) {
              Row() {
                Text('🐕')
                  .fontSize(14)
              }
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#E8F5E9')
              .borderRadius(8)
            }
            if (family.can_take_cats) {
              Row() {
                Text('🐱')
                  .fontSize(14)
              }
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#FFF3E0')
              .borderRadius(8)
            }
            if (family.can_take_rabbits) {
              Row() {
                Text('🐰')
                  .fontSize(14)
              }
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#E3F2FD')
              .borderRadius(8)
            }
            if (family.can_take_others.length > 0) {
              Row() {
                Text('🐾')
                  .fontSize(14)
              }
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#F3E5F5')
              .borderRadius(8)
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .margin({ left: 16, right: 16, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      router.pushUrl({
        url: 'pages/HolidayFamilyDetailPage',
        params: { familyId: family.id }
      });
    })
  }

  @Builder
  CertifiedContent(): void {
    Scroll() {
      Column() {
        // Certified Banner
        Column() {
          Row() {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(40)
              .fontColor(['#FFFFFF'])
            Text('Certified Foster Family')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .margin({ left: 12 })
          }
          .margin({ bottom: 8 })

          Text(this.getApp().full_name)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 8 })

          Text(`Member since ${this.formatDate(this.getApp().created_at)}`)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .opacity(0.9)
            .margin({ top: 4 })
        }
        .width('100%')
        .padding({ top: 32, bottom: 32, left: 20, right: 20 })
        .backgroundColor('#4CAF50')
        .alignItems(HorizontalAlign.Center)

        // Stats Cards
        Row() {
          this.StatCard('Capacity', `${this.getApp().pet_count} pets`)
          this.StatCard('Pet Types', this.getPetTypes())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
        .justifyContent(FlexAlign.SpaceBetween)

        // Contact Information Card
        Column() {
          Text('Contact Information')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .width('100%')
            .margin({ bottom: 12 })

          this.InfoRow($r('sys.symbol.envelope_fill'), 'Email', this.getApp().email)
          this.InfoRow($r('sys.symbol.phone_fill'), 'Phone', this.getApp().phone)
        }
        .width('100%')
        .padding(16)
        .margin({ top: 16, left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // Address Card
        Column() {
          Text('Location')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .width('100%')
            .margin({ bottom: 12 })

          this.InfoRow($r('sys.symbol.doc_text_fill'), 'Address', this.getApp().street_address)
          this.InfoRow($r('sys.symbol.house_fill'), 'City', `${this.getApp().city}, ${this.getApp().state}`)
          this.InfoRow($r('sys.symbol.paperplane_fill'), 'Country', this.getApp().country)
        }
        .width('100%')
        .padding(16)
        .margin({ top: 12, left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // Introduction Card
        Column() {
          Text('About Me')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .width('100%')
            .margin({ bottom: 12 })

          Text(this.getApp().introduction)
            .fontSize(14)
            .fontColor('#424242')
            .lineHeight(22)
        }
        .width('100%')
        .padding(16)
        .margin({ top: 12, left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)

        // Motivation Card
        Column() {
          Text('Why I Foster')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .width('100%')
            .margin({ bottom: 12 })

          Text(this.getApp().motivation)
            .fontSize(14)
            .fontColor('#424242')
            .lineHeight(22)
        }
        .width('100%')
        .padding(16)
        .margin({ top: 12, left: 16, right: 16, bottom: 32 })
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  StatCard(label: string, value: string): void {
    Column() {
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#9C27B0')
        .textAlign(TextAlign.Center)
      Text(label)
        .fontSize(12)
        .fontColor('#757575')
        .margin({ top: 4 })
    }
    .width('48%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  InfoRow(icon: Resource, label: string, value: string): void {
    Row() {
      SymbolGlyph(icon)
        .fontSize(18)
        .fontColor(['#9C27B0'])
        .margin({ right: 12 })
      Column() {
        Text(label)
          .fontSize(12)
          .fontColor('#757575')
        Text(value)
          .fontSize(14)
          .fontColor('#212121')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  formatDate(dateString: string): string {
    if (dateString.length === 0) return '';
    try {
      const date = new Date(dateString);
      return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
    } catch (e) {
      return dateString;
    }
  }
}
