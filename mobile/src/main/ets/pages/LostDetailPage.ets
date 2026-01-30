// Lost Pet Detail Page
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { Lost } from '../models/Lost';
import { LostService, LostDetailResult } from '../services/LostService';
import { LoadingView, ErrorView } from '../components/CommonViews';
import { MapView, MapMarker } from '../components/MapView';
import { MapConfig } from '../services/ApiConfig';

// Tab type for switching views
type LostTab = 'info' | 'map';

@Entry
@Component
struct LostDetailPage {
  @State lost: Lost | null = null;
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State currentTab: LostTab = 'info';  // Default to info tab

  private lostService: LostService = new LostService();
  private lostId: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['lostId']) {
      this.lostId = Number(params['lostId']);
      this.loadLostDetail();
    }
  }

  async loadLostDetail(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    const result: LostDetailResult = await this.lostService.getLostDetail(this.lostId);

    if (result.success && result.lost !== null) {
      this.lost = result.lost;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  // Get map marker for this lost pet
  getMapMarker(): MapMarker[] {
    if (this.lost !== null && this.lost.address !== null &&
        this.lost.address.latitude !== 0 && this.lost.address.longitude !== 0) {
      console.info('[LostDetail] Creating marker with photo:', this.lost.photo);
      const marker = new MapMarker(
        this.lost.id,
        this.lost.address.latitude,
        this.lost.address.longitude,
        this.lost.pet_name.length > 0 ? this.lost.pet_name : this.lost.species
      );
      marker.color = this.lost.status === 'open' ? '#F44336' : (this.lost.status === 'found' ? '#4CAF50' : '#9E9E9E');
      marker.description = `${this.lost.species} · ${this.lost.getStatusDisplay()}`;
      marker.imageUrl = this.lost.photo;  // 使用宠物图片作为标记
      return [marker];
    }
    return [];
  }

  // Make phone call
  makePhoneCall(phoneNumber: string): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.call',
        uri: `tel:${phoneNumber}`
      };
      context.startAbility(want).then(() => {
        console.info('[LostDetail] Open dialer success');
      }).catch((err: Error) => {
        console.error('[LostDetail] Open dialer error:', JSON.stringify(err));
      });
    } catch (error) {
      console.error('[LostDetail] makePhoneCall exception:', JSON.stringify(error));
    }
  }

  @Builder
  InfoRow(label: string, value: string): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#757575')
        .width(80)

      Text(value)
        .fontSize(14)
        .fontColor('#212121')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  DetailContent(): void {
    if (this.lost !== null) {
      Scroll() {
      Column() {
        // Photo
        if (this.lost.photo.length > 0) {
          Image(this.lost.photo)
            .width('100%')
            .height(300)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text('🐾')
              .fontSize(64)
          }
          .width('100%')
          .height(200)
          .backgroundColor('#FFEBEE')
          .justifyContent(FlexAlign.Center)
        }

        Column() {
          // Status badge
          Row() {
            Text(this.lost.getStatusDisplay())
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor(this.lost.getStatusColor())
              .borderRadius(12)
              .padding({ left: 12, right: 12, top: 4, bottom: 4 })

            if (this.lost.reward > 0) {
              Blank()
              Text(`Reward: $${this.lost.reward}`)
                .fontSize(16)
                .fontColor('#4CAF50')
                .fontWeight(FontWeight.Bold)
            }
          }
          .width('100%')
          .margin({ bottom: 12 })

          // Pet name
          Text(this.lost.pet_name.length > 0 ? this.lost.pet_name : 'Unknown')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .width('100%')

          // Basic info section
          Column() {
            Text('Basic Information')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#424242')
              .margin({ bottom: 8 })

            this.InfoRow('Species', this.lost.species)
            this.InfoRow('Breed', this.lost.breed.length > 0 ? this.lost.breed : 'Unknown')
            this.InfoRow('Color', this.lost.color.length > 0 ? this.lost.color : 'Unknown')
            this.InfoRow('Sex', this.lost.getSexDisplay())
            this.InfoRow('Size', this.lost.size.length > 0 ? this.lost.size : 'Unknown')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 16 })

          // Lost info section
          Column() {
            Text('Lost Information')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#424242')
              .margin({ bottom: 8 })

            this.InfoRow('Lost Date', this.lost.lost_time.substring(0, 10))

            if (this.lost.address !== null) {
              this.InfoRow('Last Seen', this.lost.address.getFullAddress())
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 12 })

          // Description
          if (this.lost.description.length > 0) {
            Column() {
              Text('Description')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#424242')
                .margin({ bottom: 8 })

              Text(this.lost.description)
                .fontSize(14)
                .fontColor('#424242')
                .lineHeight(22)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ top: 12 })
            .alignItems(HorizontalAlign.Start)
          }

          // Contact info
          Column() {
            Text('Contact')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#424242')
              .margin({ bottom: 8 })

            if (this.lost.contact_phone.length > 0) {
              Row() {
                SymbolGlyph($r('sys.symbol.phone_fill'))
                  .fontSize(16)
                  .fontColor(['#2196F3'])
                Text(this.lost.contact_phone)
                  .fontSize(14)
                  .fontColor('#2196F3')
                  .margin({ left: 8 })
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .onClick(() => {
                this.makePhoneCall(this.lost!.contact_phone);
              })
            }

            if (this.lost.contact_email.length > 0) {
              Row() {
                SymbolGlyph($r('sys.symbol.envelope_fill'))
                  .fontSize(16)
                  .fontColor(['#2196F3'])
                Text(this.lost.contact_email)
                  .fontSize(14)
                  .fontColor('#2196F3')
                  .margin({ left: 8 })
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 12 })
          .alignItems(HorizontalAlign.Start)

          // Location section - tap to view map
          if (this.lost.address !== null && this.lost.address.latitude !== 0) {
            Column() {
              Row() {
                Text('Last Seen Location')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#424242')
                Blank()
                Row() {
                  SymbolGlyph($r('sys.symbol.map'))
                    .fontSize(14)
                    .fontColor(['#F44336'])
                  Text('View Map')
                    .fontSize(13)
                    .fontColor('#F44336')
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
                  .fontColor(['#F44336'])
                  .margin({ right: 8 })
                Text(this.lost.address.getFullAddress())
                  .fontSize(14)
                  .fontColor('#424242')
                  .layoutWeight(1)
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFF5F5')
              .borderRadius(8)
              .onClick(() => { this.currentTab = 'map'; })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .margin({ top: 12 })
            .alignItems(HorizontalAlign.Start)
          }

          // Bottom spacing
          Blank()
            .height(100)
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    }
  }

  @Builder
  MapContent(): void {
    if (this.lost !== null && this.lost.address !== null && this.lost.address.latitude !== 0) {
      Column() {
        // Map info bar
        Row() {
          SymbolGlyph($r('sys.symbol.map'))
            .fontSize(16)
            .fontColor(['#F44336'])
            .margin({ right: 8 })
          Text(this.lost.address.getFullAddress())
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
          centerLat: this.lost.address.latitude,
          centerLng: this.lost.address.longitude,
          zoom: 15,
          mapboxToken: MapConfig.MAPBOX_TOKEN
        })
          .width('100%')
          .layoutWeight(1)

        // Lost info overlay
        Row() {
          Column() {
            Text(this.lost.pet_name.length > 0 ? this.lost.pet_name : this.lost.species)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')
            Text(`Last seen: ${this.lost.lost_time.substring(0, 10)}`)
              .fontSize(12)
              .fontColor('#757575')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text(this.lost.getStatusDisplay())
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor(this.lost.getStatusColor())
            .borderRadius(12)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderWidth({ top: 1 })
        .borderColor('#F0F0F0')
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
          .margin({ top: 16 })
        Text('This lost pet report does not have location information')
          .fontSize(14)
          .fontColor('#9E9E9E')
          .margin({ top: 8 })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding(32)
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#424242'])
          .onClick(() => {
            router.back();
          })

        Text('Lost Pet Details')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#424242')
          .margin({ left: 16 })

        Blank()

        SymbolGlyph($r('sys.symbol.arrow_up_right'))
          .fontSize(20)
          .fontColor(['#424242'])
          .onClick(() => {
            // Share functionality
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // Content
      if (this.isLoading) {
        LoadingView({ message: 'Loading...' })
          .layoutWeight(1)
      } else if (this.hasError) {
        ErrorView({
          message: this.errorMessage,
          onRetry: () => {
            this.loadLostDetail();
          }
        })
          .layoutWeight(1)
      } else if (this.lost !== null) {
        // Tab switcher - Info / Map
        Row() {
          // Info Tab
          Column() {
            Text('Info')
              .fontSize(14)
              .fontWeight(this.currentTab === 'info' ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.currentTab === 'info' ? '#F44336' : '#757575')
            if (this.currentTab === 'info') {
              Row()
                .width(40)
                .height(3)
                .backgroundColor('#F44336')
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
                .fontColor([this.currentTab === 'map' ? '#F44336' : '#757575'])
                .margin({ right: 4 })
              Text('Map')
                .fontSize(14)
                .fontWeight(this.currentTab === 'map' ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.currentTab === 'map' ? '#F44336' : '#757575')
            }
            if (this.currentTab === 'map') {
              Row()
                .width(40)
                .height(3)
                .backgroundColor('#F44336')
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
          this.DetailContent()
        } else {
          this.MapContent()
        }
      }

      // Bottom action buttons
      if (!this.isLoading && !this.hasError && this.lost !== null && this.currentTab === 'info') {
        Row() {
          Button('Contact Owner')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#F44336')
            .borderRadius(24)
            .height(48)
            .layoutWeight(1)
            .onClick(() => {
              if (this.lost !== null && this.lost.contact_phone.length > 0) {
                this.makePhoneCall(this.lost.contact_phone);
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
