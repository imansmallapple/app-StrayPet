// Shelter Detail Page - Full shelter information with dynamic map
import { router } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { Shelter } from '../models/Pet';
import { ShelterService, ShelterDetailResult } from '../services/ShelterService';
import { MapView, MapMarker } from '../components/MapView';
import { MapConfig } from '../services/ApiConfig';

interface RouterParams {
  shelterId: number;
}

// Tab type for switching views
type ShelterTab = 'info' | 'map';

@Entry
@Component
struct ShelterDetailPage {
  @State shelter: Shelter | null = null;
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State currentTab: ShelterTab = 'info';  // 默认显示信息页

  private shelterService: ShelterService = new ShelterService();
  private shelterId: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as RouterParams;
    if (params && params.shelterId) {
      this.shelterId = params.shelterId;
      this.loadShelterDetail();
    }
  }

  async loadShelterDetail(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    const result: ShelterDetailResult = await this.shelterService.getShelterDetail(this.shelterId);

    if (result.success && result.shelter !== null) {
      this.shelter = result.shelter;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  getMapMarker(): MapMarker[] {
    if (this.shelter !== null && this.shelter.address !== null &&
        this.shelter.address.latitude !== 0 && this.shelter.address.longitude !== 0) {
      const marker = new MapMarker(
        this.shelter.id,
        this.shelter.address.latitude,
        this.shelter.address.longitude,
        this.shelter.name
      );
      marker.color = this.shelter.is_verified ? '#4CAF50' : '#FF6B35';
      marker.description = this.shelter.is_verified ? 'Verified Shelter' : 'Shelter';
      return [marker];
    }
    return [];
  }

  getOccupancyRate(): number {
    if (this.shelter === null || this.shelter.capacity === 0) return 0;
    return Math.round((this.shelter.current_animals / this.shelter.capacity) * 100);
  }

  // 拨打电话 - 使用 Want 打开拨号界面
  makePhoneCall(phoneNumber: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.call',
        uri: `tel:${phoneNumber}`
      };
      context.startAbility(want).then(() => {
        console.info('[ShelterDetail] Open dialer success');
      }).catch((err: Error) => {
        console.error('[ShelterDetail] Open dialer error:', JSON.stringify(err));
      });
    } catch (error) {
      console.error('[ShelterDetail] makePhoneCall exception:', JSON.stringify(error));
    }
  }

  @Builder
  InfoRow(icon: Resource, label: string, value: string): void {
    Row() {
      SymbolGlyph(icon)
        .fontSize(18)
        .fontColor(['#757575'])
        .margin({ right: 12 })
      Column() {
        Text(label)
          .fontSize(12)
          .fontColor('#9E9E9E')
        Text(value)
          .fontSize(14)
          .fontColor('#424242')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  StatCard(label: string, value: string, color: string): void {
    Column() {
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(12)
        .fontColor('#757575')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  build() {
    Column() {
      // Header
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#424242'])
          .onClick(() => { router.back(); })
        Text('Shelter Details')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
          .layoutWeight(1)
        if (this.shelter !== null && this.shelter.is_verified) {
          Row() {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(16)
              .fontColor(['#4CAF50'])
            Text('Verified')
              .fontSize(12)
              .fontColor('#4CAF50')
              .margin({ left: 4 })
          }
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#4CAF50')
          Text('Loading...')
            .fontSize(14)
            .fontColor('#757575')
            .margin({ top: 12 })
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
            .margin({ top: 12 })
          Button('Retry')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#4CAF50')
            .borderRadius(20)
            .margin({ top: 16 })
            .onClick(() => { this.loadShelterDetail(); })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.shelter !== null) {
        // Tab switcher - Info / Map
        Row() {
          // Info Tab
          Column() {
            Text('Info')
              .fontSize(14)
              .fontWeight(this.currentTab === 'info' ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === 'info' ? '#4CAF50' : '#757575')
            if (this.currentTab === 'info') {
              Row()
                .width(40)
                .height(3)
                .backgroundColor('#4CAF50')
                .borderRadius(2)
                .margin({ top: 8 })
            }
          }
          .layoutWeight(1)
          .padding({ top: 12, bottom: 8 })
          .onClick(() => { this.currentTab = 'info'; })

          // Map Tab
          Column() {
            Row() {
              SymbolGlyph($r('sys.symbol.map'))
                .fontSize(16)
                .fontColor([this.currentTab === 'map' ? '#4CAF50' : '#757575'])
                .margin({ right: 4 })
              Text('Map')
                .fontSize(14)
                .fontWeight(this.currentTab === 'map' ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.currentTab === 'map' ? '#4CAF50' : '#757575')
            }
            if (this.currentTab === 'map') {
              Row()
                .width(40)
                .height(3)
                .backgroundColor('#4CAF50')
                .borderRadius(2)
                .margin({ top: 8 })
            }
          }
          .layoutWeight(1)
          .padding({ top: 12, bottom: 8 })
          .onClick(() => { this.currentTab = 'map'; })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderWidth({ bottom: 1 })
        .borderColor('#F0F0F0')

        // Content based on current tab
        if (this.currentTab === 'info') {
          // Info content
          Scroll() {
            Column() {
              // Cover image
              if (this.shelter.cover_image.length > 0) {
                Image(this.shelter.cover_image)
                  .width('100%')
                  .height(200)
                  .objectFit(ImageFit.Cover)
              } else {
                Column() {
                  SymbolGlyph($r('sys.symbol.house_fill'))
                    .fontSize(48)
                    .fontColor(['#4CAF50'])
                }
                .width('100%')
                .height(160)
                .backgroundColor('#E8F5E9')
                .justifyContent(FlexAlign.Center)
              }

              // Shelter name and logo
              Row() {
                if (this.shelter.logo.length > 0) {
                  Image(this.shelter.logo)
                    .width(60)
                    .height(60)
                    .borderRadius(30)
                    .objectFit(ImageFit.Cover)
                    .margin({ right: 16 })
                }
                Column() {
                  Text(this.shelter.name)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#212121')
                  if (this.shelter.address !== null) {
                    Text(this.shelter.address.getFullAddress())
                      .fontSize(13)
                      .fontColor('#757575')
                      .margin({ top: 4 })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(16)

              // Stats cards
              Row({ space: 12 }) {
                this.StatCard('Animals', `${this.shelter.current_animals}`, '#4CAF50')
                this.StatCard('Capacity', `${this.shelter.capacity}`, '#2196F3')
                this.StatCard('Occupancy', `${this.getOccupancyRate()}%`,
                  this.getOccupancyRate() > 80 ? '#F44336' : '#4CAF50')
              }
              .width('100%')
              .padding({ left: 16, right: 16 })

              // Description
              if (this.shelter.description.length > 0) {
                Column() {
                  Text('About')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#212121')
                  Text(this.shelter.description)
                    .fontSize(14)
                    .fontColor('#616161')
                    .margin({ top: 8 })
                    .lineHeight(22)
                }
                .width('100%')
                .padding(16)
                .margin({ top: 12 })
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .alignItems(HorizontalAlign.Start)
              }

              // Contact info
              Column() {
                Text('Contact Information')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#212121')
                  .margin({ bottom: 8 })

                if (this.shelter.phone.length > 0) {
                  this.InfoRow($r('sys.symbol.phone_fill'), 'Phone', this.shelter.phone)
                  Divider().color('#F0F0F0')
                }
                if (this.shelter.email.length > 0) {
                  this.InfoRow($r('sys.symbol.envelope_fill'), 'Email', this.shelter.email)
                  Divider().color('#F0F0F0')
                }
                if (this.shelter.website.length > 0) {
                  this.InfoRow($r('sys.symbol.link'), 'Website', this.shelter.website)
                }
              }
              .width('100%')
              .padding(16)
              .margin({ top: 12 })
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .alignItems(HorizontalAlign.Start)

              // Quick map preview - tap to switch to map tab
              if (this.shelter.address !== null && this.shelter.address.latitude !== 0) {
                Column() {
                  Row() {
                    Text('Location')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#212121')
                    Blank()
                    Row() {
                      SymbolGlyph($r('sys.symbol.map'))
                        .fontSize(14)
                        .fontColor(['#4CAF50'])
                      Text('View Interactive Map')
                        .fontSize(13)
                        .fontColor('#4CAF50')
                        .margin({ left: 4 })
                    }
                    .onClick(() => { this.currentTab = 'map'; })
                  }
                  .width('100%')
                  .margin({ bottom: 12 })

                  // Address display
                  Row() {
                    SymbolGlyph($r('sys.symbol.map'))
                      .fontSize(20)
                      .fontColor(['#4CAF50'])
                      .margin({ right: 8 })
                    Text(this.shelter.address.getFullAddress())
                      .fontSize(14)
                      .fontColor('#424242')
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8)
                  .onClick(() => { this.currentTab = 'map'; })
                }
                .width('100%')
                .padding(16)
                .margin({ top: 12 })
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .alignItems(HorizontalAlign.Start)
              }

              // Bottom spacing
              Row().height(100)
            }
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        } else {
          // Map content - Dynamic MapView
          if (this.shelter.address !== null && this.shelter.address.latitude !== 0) {
            Column() {
              // Map info bar
              Row() {
                SymbolGlyph($r('sys.symbol.map'))
                  .fontSize(16)
                  .fontColor(['#4CAF50'])
                  .margin({ right: 8 })
                Text(this.shelter.address.getFullAddress())
                  .fontSize(13)
                  .fontColor('#424242')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderWidth({ bottom: 1 })
              .borderColor('#F0F0F0')

              // Dynamic MapView
              MapView({
                markers: this.getMapMarker(),
                centerLat: this.shelter.address.latitude,
                centerLng: this.shelter.address.longitude,
                zoom: 15,
                mapboxToken: MapConfig.MAPBOX_TOKEN
              })
                .width('100%')
                .layoutWeight(1)
            }
            .width('100%')
            .layoutWeight(1)
          } else {
            // No location available
            Column() {
              SymbolGlyph($r('sys.symbol.map'))
                .fontSize(48)
                .fontColor(['#BDBDBD'])
              Text('No location data')
                .fontSize(16)
                .fontColor('#757575')
                .margin({ top: 12 })
              Text('This shelter has not provided location information')
                .fontSize(13)
                .fontColor('#9E9E9E')
                .margin({ top: 4 })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }
        }

        // Bottom action buttons
        Row({ space: 12 }) {
          if (this.shelter.phone.length > 0) {
            Button() {
              Row() {
                SymbolGlyph($r('sys.symbol.phone_fill'))
                  .fontSize(18)
                  .fontColor(['#FFFFFF'])
                Text('Call')
                  .fontSize(15)
                  .fontColor('#FFFFFF')
                  .margin({ left: 8 })
              }
            }
            .layoutWeight(1)
            .height(48)
            .backgroundColor('#4CAF50')
            .borderRadius(24)
            .onClick(() => {
              if (this.shelter !== null && this.shelter.phone.length > 0) {
                this.makePhoneCall(this.shelter.phone);
              }
            })
          }

          Button() {
            Row() {
              SymbolGlyph($r('sys.symbol.heart_fill'))
                .fontSize(18)
                .fontColor(['#FFFFFF'])
              Text('Donate')
                .fontSize(15)
                .fontColor('#FFFFFF')
                .margin({ left: 8 })
            }
          }
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#FF6B35')
          .borderRadius(24)
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/DonationFormPage' });
            } catch (err) {
              console.error('Navigation error', JSON.stringify(err));
            }
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: -2 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
