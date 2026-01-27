// Lost Pet Report Form Page
// Following ArkTS strict typing rules

import { LostService, LostDetailResult } from '../services/LostService';
import { LostRequest } from '../models/Lost';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct LostFormPage {
  @State petName: string = '';
  @State species: string = '';
  @State breed: string = '';
  @State color: string = '';
  @State sex: string = 'male';
  @State petSize: string = '';
  @State description: string = '';
  @State contactPhone: string = '';
  @State contactEmail: string = '';
  @State reward: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  private lostService: LostService = new LostService();
  private speciesOptions: string[] = ['Dog', 'Cat', 'Rabbit', 'Bird', 'Other'];
  private sizeOptions: string[] = ['Small', 'Medium', 'Large', 'Extra Large'];

  validateForm(): boolean {
    if (this.species.length === 0) {
      this.errorMessage = 'Please select species';
      return false;
    }
    if (this.description.trim().length < 10) {
      this.errorMessage = 'Please provide a description (at least 10 characters)';
      return false;
    }
    if (this.contactPhone.length === 0 && this.contactEmail.length === 0) {
      this.errorMessage = 'Please provide at least one contact method';
      return false;
    }
    return true;
  }

  async handleSubmit(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    const request = new LostRequest();
    request.pet_name = this.petName.trim();
    request.species = this.species.toLowerCase();
    request.breed = this.breed.trim();
    request.color = this.color.trim();
    request.sex = this.sex;
    request.size = this.petSize.toLowerCase();
    request.description = this.description.trim();
    request.contact_phone = this.contactPhone.trim();
    request.contact_email = this.contactEmail.trim();
    if (this.reward.length > 0) {
      request.reward = Number.parseFloat(this.reward);
    }
    request.lost_time = new Date().toISOString();

    const result: LostDetailResult = await this.lostService.reportLost(request);

    if (result.success) {
      promptAction.showToast({
        message: 'Lost pet report submitted!',
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
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor(['#424242'])
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.back();
        })

        Text('Report Lost Pet')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F44336')
          .margin({ left: 8 })

        Blank()
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          // Pet name
          Column() {
            Text('Pet Name (optional)')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            TextInput({ text: this.petName, placeholder: 'Enter pet name' })
              .fontSize(16)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(50)
              .padding({ left: 16, right: 16 })
              .margin({ top: 8 })
              .onChange((value: string) => {
                this.petName = value;
              })
          }
          .width('100%')

          // Species selection
          Column() {
            Text('Species *')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            Row({ space: 8 }) {
              ForEach(this.speciesOptions, (option: string) => {
                Button(option)
                  .fontSize(13)
                  .fontColor(this.species === option ? '#FFFFFF' : '#616161')
                  .backgroundColor(this.species === option ? '#FF6B35' : '#F5F5F5')
                  .borderRadius(20)
                  .height(36)
                  .onClick(() => {
                    this.species = option;
                    this.errorMessage = '';
                  })
              })
            }
            .margin({ top: 8 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 20 })

          // Breed and color
          Row() {
            Column() {
              Text('Breed')
                .fontSize(14)
                .fontColor('#616161')

              TextInput({ text: this.breed, placeholder: 'Breed' })
                .fontSize(15)
                .fontColor('#212121')
                .placeholderColor('#BDBDBD')
                .backgroundColor('#F5F5F5')
                .borderRadius(12)
                .height(46)
                .padding({ left: 16, right: 16 })
                .margin({ top: 8 })
                .onChange((value: string) => {
                  this.breed = value;
                })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column() {
              Text('Color')
                .fontSize(14)
                .fontColor('#616161')

              TextInput({ text: this.color, placeholder: 'Color' })
                .fontSize(15)
                .fontColor('#212121')
                .placeholderColor('#BDBDBD')
                .backgroundColor('#F5F5F5')
                .borderRadius(12)
                .height(46)
                .padding({ left: 16, right: 16 })
                .margin({ top: 8 })
                .onChange((value: string) => {
                  this.color = value;
                })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 16 })
          }
          .width('100%')
          .margin({ top: 20 })

          // Sex selection
          Column() {
            Text('Sex')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            Row({ space: 16 }) {
              Row() {
                Radio({ value: 'male', group: 'sex' })
                  .checked(this.sex === 'male')
                  .onChange((isChecked: boolean) => {
                    if (isChecked) this.sex = 'male';
                  })
                Text('Male')
                  .fontSize(14)
                  .fontColor('#424242')
                  .margin({ left: 8 })
              }

              Row() {
                Radio({ value: 'female', group: 'sex' })
                  .checked(this.sex === 'female')
                  .onChange((isChecked: boolean) => {
                    if (isChecked) this.sex = 'female';
                  })
                Text('Female')
                  .fontSize(14)
                  .fontColor('#424242')
                  .margin({ left: 8 })
              }
            }
            .margin({ top: 8 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 20 })

          // Size selection
          Column() {
            Text('Size')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            Row({ space: 8 }) {
              ForEach(this.sizeOptions, (option: string) => {
                Button(option)
                  .fontSize(12)
                  .fontColor(this.petSize === option ? '#FFFFFF' : '#616161')
                  .backgroundColor(this.petSize === option ? '#FF6B35' : '#F5F5F5')
                  .borderRadius(16)
                  .height(32)
                  .onClick(() => {
                    this.petSize = option;
                  })
              })
            }
            .margin({ top: 8 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 20 })

          // Description
          Column() {
            Text('Description *')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            TextArea({ text: this.description, placeholder: 'Describe your pet and where it was last seen...' })
              .fontSize(15)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(120)
              .padding(16)
              .margin({ top: 8 })
              .onChange((value: string) => {
                this.description = value;
                this.errorMessage = '';
              })
          }
          .width('100%')
          .margin({ top: 20 })

          // Contact info
          Column() {
            Text('Contact Information *')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            TextInput({ text: this.contactPhone, placeholder: 'Phone number' })
              .fontSize(15)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(46)
              .padding({ left: 16, right: 16 })
              .margin({ top: 8 })
              .type(InputType.PhoneNumber)
              .onChange((value: string) => {
                this.contactPhone = value;
                this.errorMessage = '';
              })

            TextInput({ text: this.contactEmail, placeholder: 'Email address' })
              .fontSize(15)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(46)
              .padding({ left: 16, right: 16 })
              .margin({ top: 8 })
              .type(InputType.Email)
              .onChange((value: string) => {
                this.contactEmail = value;
                this.errorMessage = '';
              })
          }
          .width('100%')
          .margin({ top: 20 })

          // Reward
          Column() {
            Text('Reward (optional)')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            TextInput({ text: this.reward, placeholder: 'Amount in your currency' })
              .fontSize(15)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(46)
              .padding({ left: 16, right: 16 })
              .margin({ top: 8 })
              .type(InputType.Number)
              .onChange((value: string) => {
                this.reward = value;
              })
          }
          .width('100%')
          .margin({ top: 20 })

          // Error message
          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(13)
              .fontColor('#F44336')
              .width('100%')
              .margin({ top: 16 })
          }

          // Submit button
          Button(this.isLoading ? 'Submitting...' : 'Report Lost Pet')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.isLoading ? '#EF9A9A' : '#F44336')
            .borderRadius(24)
            .width('100%')
            .height(50)
            .margin({ top: 32, bottom: 32 })
            .enabled(!this.isLoading)
            .onClick(() => {
              this.handleSubmit();
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
