// Holiday Family Detail Page - View certified foster family details
import { router } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { HolidayFamilyService, HolidayFamilyApplication, HolidayFamilyResult, HolidayFamilyPhoto } from '../services/HolidayFamilyService';
import { ApiConfig } from '../services/ApiConfig';

interface RouterParams {
  familyId: number;
}

@Entry
@Component
struct HolidayFamilyDetailPage {
  @State family: HolidayFamilyApplication | null = null;
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State showImagePreview: boolean = false;
  @State previewImageUrl: string = '';

  private familyService: HolidayFamilyService = new HolidayFamilyService();
  private familyId: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as RouterParams;
    if (params && params.familyId) {
      this.familyId = params.familyId;
      this.loadFamilyDetail();
    }
  }

  async loadFamilyDetail(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    const result: HolidayFamilyResult = await this.familyService.getFamilyDetail(this.familyId);

    if (result.success && result.data !== null) {
      this.family = result.data;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  getAvatarColor(): string {
    const colors: string[] = ['#9C27B0', '#E91E63', '#2196F3', '#4CAF50', '#FF9800', '#00BCD4'];
    return colors[this.familyId % colors.length];
  }

  makePhoneCall(phoneNumber: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.call',
        uri: `tel:${phoneNumber}`
      };
      context.startAbility(want).then(() => {
        console.info('[HolidayFamilyDetail] Open dialer success');
      }).catch((err: Error) => {
        console.error('[HolidayFamilyDetail] Open dialer error:', JSON.stringify(err));
      });
    } catch (error) {
      console.error('[HolidayFamilyDetail] makePhoneCall exception:', JSON.stringify(error));
    }
  }

  sendEmail(email: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.sendToData',
        uri: `mailto:${email}`
      };
      context.startAbility(want).then(() => {
        console.info('[HolidayFamilyDetail] Open email success');
      }).catch((err: Error) => {
        console.error('[HolidayFamilyDetail] Open email error:', JSON.stringify(err));
      });
    } catch (error) {
      console.error('[HolidayFamilyDetail] sendEmail exception:', JSON.stringify(error));
    }
  }

  @Builder
  HeaderSection(): void {
    Stack() {
      // Background gradient
      Column()
        .width('100%')
        .height(220)
        .linearGradient({
          angle: 135,
          colors: [['#9C27B0', 0], ['#E91E63', 1]]
        })

      // Content overlay
      Column() {
        // Avatar - show image if available
        if (this.family !== null && this.family.avatar && this.family.avatar.length > 0) {
          Image('http://192.168.123.237:8000' + this.family.avatar)
            .width(100)
            .height(100)
            .borderRadius(50)
            .objectFit(ImageFit.Cover)
            .border({ width: 4, color: '#FFFFFF' })
            .shadow({ radius: 12, color: '#40000000', offsetX: 0, offsetY: 4 })
        } else {
          Column() {
            Text(this.family !== null ? this.family.full_name.charAt(0).toUpperCase() : '?')
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width(100)
          .height(100)
          .borderRadius(50)
          .backgroundColor(this.getAvatarColor())
          .justifyContent(FlexAlign.Center)
          .border({ width: 4, color: '#FFFFFF' })
          .shadow({ radius: 12, color: '#40000000', offsetX: 0, offsetY: 4 })
        }

        // Name with verified badge
        Row() {
          Text(this.family !== null ? this.family.full_name : '')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
            .fontSize(24)
            .fontColor(['#4CAF50'])
            .margin({ left: 8 })
        }
        .margin({ top: 16 })

        // Location
        Row() {
          SymbolGlyph($r('sys.symbol.paperplane'))
            .fontSize(16)
            .fontColor(['#FFFFFF'])
          Text(this.family !== null ? `${this.family.city}, ${this.family.state}` : '')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .margin({ left: 6 })
        }
        .margin({ top: 8 })
      }
      .width('100%')
      .padding({ top: 50, bottom: 24 })
    }
  }

  @Builder
  QuickActionsSection(): void {
    Row({ space: 16 }) {
      // Call button
      Column() {
        Column() {
          SymbolGlyph($r('sys.symbol.phone'))
            .fontSize(24)
            .fontColor(['#4CAF50'])
        }
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor('#E8F5E9')
        .justifyContent(FlexAlign.Center)

        Text('Call')
          .fontSize(12)
          .fontColor('#757575')
          .margin({ top: 8 })
      }
      .onClick(() => {
        if (this.family !== null && this.family.phone.length > 0) {
          this.makePhoneCall(this.family.phone);
        }
      })

      // Email button
      Column() {
        Column() {
          SymbolGlyph($r('sys.symbol.envelope'))
            .fontSize(24)
            .fontColor(['#2196F3'])
        }
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor('#E3F2FD')
        .justifyContent(FlexAlign.Center)

        Text('Email')
          .fontSize(12)
          .fontColor('#757575')
          .margin({ top: 8 })
      }
      .onClick(() => {
        if (this.family !== null && this.family.email.length > 0) {
          this.sendEmail(this.family.email);
        }
      })

      // Share button
      Column() {
        Column() {
          SymbolGlyph($r('sys.symbol.share'))
            .fontSize(24)
            .fontColor(['#FF9800'])
        }
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor('#FFF3E0')
        .justifyContent(FlexAlign.Center)

        Text('Share')
          .fontSize(12)
          .fontColor('#757575')
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 20, bottom: 20 })
    .backgroundColor('#FFFFFF')
    .margin({ top: -20 })
  }

  @Builder
  InfoRow(icon: Resource, label: string, value: string): void {
    Row() {
      Column() {
        SymbolGlyph(icon)
          .fontSize(18)
          .fontColor(['#9C27B0'])
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor('#F3E5F5')
      .justifyContent(FlexAlign.Center)

      Column() {
        Text(label)
          .fontSize(12)
          .fontColor('#757575')
        Text(value)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 14 })
      .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  @Builder
  PetTypeTag(label: string, isActive: boolean): void {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(isActive ? '#FFFFFF' : '#757575')
    }
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .backgroundColor(isActive ? '#9C27B0' : '#F5F5F5')
    .borderRadius(20)
    .margin({ right: 8, bottom: 8 })
  }

  @Builder
  AboutCard(): void {
    Column() {
      Text('About')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .margin({ bottom: 16 })

      Text(this.family !== null ? this.family.introduction : '')
        .fontSize(14)
        .fontColor('#424242')
        .lineHeight(22)
    }
    .width('100%')
    .padding(20)
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  AddressCard(): void {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.paperplane_fill'))
          .fontSize(20)
          .fontColor(['#9C27B0'])
        Text('Our Family Address')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ bottom: 16 })

      if (this.family !== null) {
        // Street address
        Row() {
          Column() {
            SymbolGlyph($r('sys.symbol.house'))
              .fontSize(16)
              .fontColor(['#757575'])
          }
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor('#F5F5F5')
          .justifyContent(FlexAlign.Center)

          Column() {
            Text('Street Address')
              .fontSize(11)
              .fontColor('#9E9E9E')
            Text(this.family.street_address)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#212121')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 12 })

        // City, State
        Row() {
          Column() {
            SymbolGlyph($r('sys.symbol.house'))
              .fontSize(16)
              .fontColor(['#757575'])
          }
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor('#F5F5F5')
          .justifyContent(FlexAlign.Center)

          Column() {
            Text('City & State')
              .fontSize(11)
              .fontColor('#9E9E9E')
            Text(`${this.family.city}, ${this.family.state}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#212121')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 12 })

        // Country, Postal Code
        Row() {
          Column() {
            SymbolGlyph($r('sys.symbol.flag'))
              .fontSize(16)
              .fontColor(['#757575'])
          }
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor('#F5F5F5')
          .justifyContent(FlexAlign.Center)

          Column() {
            Text('Country & Postal Code')
              .fontSize(11)
              .fontColor('#9E9E9E')
            Text(`${this.family.country}, ${this.family.postal_code}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#212121')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
          .layoutWeight(1)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  HomeEnvironmentCard(): void {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.house_fill'))
          .fontSize(20)
          .fontColor(['#4CAF50'])
        Text('Home Environment')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ bottom: 16 })

      if (this.family !== null) {
        // Pet capacity
        Row() {
          Column() {
            Text('🏠')
              .fontSize(18)
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#E8F5E9')
          .justifyContent(FlexAlign.Center)

          Column() {
            Text('Pet Capacity')
              .fontSize(11)
              .fontColor('#9E9E9E')
            Text(`Up to ${this.family.pet_count} pets at a time`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#212121')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 16 })

        // Accepted pet types
        Text('Accepted Pet Types')
          .fontSize(13)
          .fontColor('#757575')
          .margin({ bottom: 12 })

        Flex({ wrap: FlexWrap.Wrap }) {
          if (this.family.can_take_dogs) {
            this.EnvironmentTag('🐕 Dogs', true)
          }
          if (this.family.can_take_cats) {
            this.EnvironmentTag('🐱 Cats', true)
          }
          if (this.family.can_take_rabbits) {
            this.EnvironmentTag('🐰 Rabbits', true)
          }
          if (this.family.can_take_others.length > 0) {
            this.EnvironmentTag(`🐾 ${this.family.can_take_others}`, true)
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EnvironmentTag(label: string, isActive: boolean): void {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(isActive ? '#FFFFFF' : '#757575')
    }
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .backgroundColor(isActive ? '#4CAF50' : '#F5F5F5')
    .borderRadius(20)
    .margin({ right: 8, bottom: 8 })
  }

  @Builder
  FamilyPhotosCard(): void {
    if (this.family !== null && this.family.family_photos.length > 0) {
      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.picture_fill'))
            .fontSize(20)
            .fontColor(['#2196F3'])
          Text(`Family Environment Photos (${this.family.family_photos.length})`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ bottom: 16 })

        // Photos grid
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.family.family_photos, (photo: HolidayFamilyPhoto) => {
            Image('http://192.168.123.237:8000' + photo.photo)
              .width('47%')
              .aspectRatio(1)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)
              .margin({ right: '3%', bottom: 12 })
              .onClick(() => {
                this.previewImageUrl = 'http://192.168.123.237:8000' + photo.photo;
                this.showImagePreview = true;
              })
          })
        }
        .width('100%')
      }
      .width('100%')
      .padding(20)
      .margin({ left: 16, right: 16, bottom: 16 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  ContactCard(): void {
    Column() {
      Text('Contact Information')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .margin({ bottom: 16 })

      if (this.family !== null) {
        this.InfoRow($r('sys.symbol.envelope'), 'Email', this.family.email)
        this.InfoRow($r('sys.symbol.phone'), 'Phone', this.family.phone)
        this.InfoRow($r('sys.symbol.house'), 'Address',
          `${this.family.street_address}, ${this.family.city}, ${this.family.state} ${this.family.postal_code}`)
      }
    }
    .width('100%')
    .padding(20)
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  MotivationCard(): void {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.heart_fill'))
          .fontSize(20)
          .fontColor(['#E91E63'])
        Text('Why I Want to Foster')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ bottom: 16 })

      Text(this.family !== null ? this.family.motivation : '')
        .fontSize(14)
        .fontColor('#424242')
        .lineHeight(22)
    }
    .width('100%')
    .padding(20)
    .margin({ left: 16, right: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      // Navigation bar (positioned over header)
      Row() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor(['#FFFFFF'])
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#20FFFFFF')
        .justifyContent(FlexAlign.Center)
        .onClick(() => router.back())

        Blank()

        Text('Foster Family')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')

        Blank()

        Row().width(40)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .position({ x: 0, y: 0 })
      .zIndex(10)

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#9C27B0')
          Text('Loading...')
            .fontSize(14)
            .fontColor('#757575')
            .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        Column() {
          SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
            .fontSize(48)
            .fontColor(['#F44336'])
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#757575')
            .margin({ top: 16 })
          Button('Retry')
            .backgroundColor('#9C27B0')
            .margin({ top: 20 })
            .onClick(() => this.loadFamilyDetail())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.family !== null) {
        Scroll() {
          Column() {
            // Header
            this.HeaderSection()

            // Quick actions
            this.QuickActionsSection()

            // About section
            this.AboutCard()

            // Our Family Address section
            this.AddressCard()

            // Home Environment section
            this.HomeEnvironmentCard()

            // Family Photos section
            this.FamilyPhotosCard()

            // Motivation section
            this.MotivationCard()

            // Contact info
            this.ContactCard()

            // Contact button
            Button('Contact This Family')
              .width('90%')
              .height(52)
              .margin({ bottom: 32 })
              .backgroundColor('#9C27B0')
              .borderRadius(26)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .onClick(() => {
                if (this.family !== null && this.family.email.length > 0) {
                  this.sendEmail(this.family.email);
                }
              })
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }

      // Fullscreen image preview overlay
      if (this.showImagePreview) {
        Column() {
          // Image
          Column() {
            Image(this.previewImageUrl)
              .width('100%')
              .objectFit(ImageFit.Contain)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#E0000000')
        .position({ x: 0, y: 0 })
        .zIndex(100)
        .onClick(() => {
          this.showImagePreview = false;
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
