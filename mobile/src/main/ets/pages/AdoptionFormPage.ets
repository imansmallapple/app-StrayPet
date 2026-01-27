// Adoption Application Form Page
// Following ArkTS strict typing rules

import { AdoptionService, AdoptionDetailResult } from '../services/AdoptionService';
import { AdoptionRequest } from '../models/Adoption';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

interface RouterParams {
  petId: number;
  petName: string;
}

@Entry
@Component
struct AdoptionFormPage {
  @State petId: number = 0;
  @State petName: string = '';
  @State message: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  private adoptionService: AdoptionService = new AdoptionService();

  aboutToAppear(): void {
    const params = router.getParams() as RouterParams | null;
    if (params !== null) {
      this.petId = params.petId;
      this.petName = params.petName;
    }
  }

  async handleSubmit(): Promise<void> {
    if (this.message.trim().length < 20) {
      this.errorMessage = 'Please write at least 20 characters about why you want to adopt this pet';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    const request = new AdoptionRequest(this.petId, this.message.trim());
    const result: AdoptionDetailResult = await this.adoptionService.createAdoption(request);

    if (result.success) {
      promptAction.showToast({
        message: 'Application submitted successfully!',
        duration: 2000
      });
      router.back();
    } else {
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#424242')
          .onClick(() => {
            router.back();
          })

        Text('Adoption Application')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .margin({ left: 16 })

        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      Scroll() {
        Column() {
          // Pet info card
          Row() {
            Column() {
              Text('Applying to adopt')
                .fontSize(12)
                .fontColor('#9E9E9E')

              Text(this.petName)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF6B35')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFF3E0')
          .borderRadius(12)

          // Message section
          Column() {
            Text('Why do you want to adopt this pet?')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#212121')

            Text('Tell the owner about yourself and why you would be a great pet parent.')
              .fontSize(13)
              .fontColor('#9E9E9E')
              .margin({ top: 4 })

            TextArea({ text: this.message, placeholder: 'Write your message here...' })
              .fontSize(15)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(200)
              .padding(16)
              .margin({ top: 12 })
              .onChange((value: string) => {
                this.message = value;
                this.errorMessage = '';
              })

            Text(`${this.message.length}/500 characters`)
              .fontSize(12)
              .fontColor('#9E9E9E')
              .margin({ top: 8 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 24 })

          // Tips
          Column() {
            Text('Tips for a great application:')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#424242')

            Column() {
              this.buildTip('Describe your living situation')
              this.buildTip('Share your experience with pets')
              this.buildTip('Explain how you will care for the pet')
              this.buildTip('Mention if you have other pets or children')
            }
            .margin({ top: 8 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#E3F2FD')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 24 })

          // Error message
          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(13)
              .fontColor('#F44336')
              .width('100%')
              .margin({ top: 16 })
          }

          // Submit button
          Button(this.isLoading ? 'Submitting...' : 'Submit Application')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.isLoading ? '#FFAB91' : '#FF6B35')
            .borderRadius(24)
            .width('100%')
            .height(50)
            .margin({ top: 32 })
            .enabled(!this.isLoading)
            .onClick(() => {
              this.handleSubmit();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 32 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildTip(text: string): void {
    Row() {
      Text('•')
        .fontSize(14)
        .fontColor('#2196F3')
        .margin({ right: 8 })

      Text(text)
        .fontSize(13)
        .fontColor('#616161')
    }
    .margin({ top: 4 })
  }
}
