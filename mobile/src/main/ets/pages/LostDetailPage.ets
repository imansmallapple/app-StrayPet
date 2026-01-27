// Lost Pet Detail Page
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { Lost } from '../models/Lost';
import { LostService, LostDetailResult } from '../services/LostService';
import { LoadingView, ErrorView } from '../components/CommonViews';

@Entry
@Component
struct LostDetailPage {
  @State lost: Lost | null = null;
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';

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
      } else {
        this.DetailContent()
      }

      // Bottom action buttons
      if (!this.isLoading && !this.hasError && this.lost !== null) {
        Row() {
          Button('Contact Owner')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF6B35')
            .borderRadius(24)
            .height(48)
            .layoutWeight(1)
            .onClick(() => {
              // Call functionality
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
