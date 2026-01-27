// Pet Donation Form Page
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct DonationFormPage {
  @State petName: string = '';
  @State species: string = '';
  @State breed: string = '';
  @State sex: string = 'male';
  @State ageYears: string = '';
  @State ageMonths: string = '';
  @State description: string = '';
  @State contactPhone: string = '';

  // Health traits
  @State vaccinated: boolean = false;
  @State dewormed: boolean = false;
  @State sterilized: boolean = false;
  @State microchipped: boolean = false;
  @State trained: boolean = false;
  @State childFriendly: boolean = false;

  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  private speciesOptions: string[] = ['Dog', 'Cat', 'Rabbit', 'Bird', 'Other'];

  validateForm(): boolean {
    if (this.petName.trim().length === 0) {
      this.errorMessage = 'Please enter pet name';
      return false;
    }
    if (this.species.length === 0) {
      this.errorMessage = 'Please select species';
      return false;
    }
    if (this.description.trim().length < 10) {
      this.errorMessage = 'Please provide a description (at least 10 characters)';
      return false;
    }
    if (this.contactPhone.trim().length === 0) {
      this.errorMessage = 'Please provide a contact phone number';
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

    // In a real implementation, this would call the API
    // For now, we'll simulate a submission
    await new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve();
      }, 1500);
    });

    promptAction.showToast({
      message: 'Donation submitted for review!',
      duration: 2000
    });
    router.back();

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

        Text('Donate a Pet')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4CAF50')
          .margin({ left: 8 })

        Blank()
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          // Info banner
          Row() {
            Text('ℹ')
              .fontSize(18)
              .fontColor('#4CAF50')

            Text('Your donation will be reviewed before being published.')
              .fontSize(13)
              .fontColor('#4CAF50')
              .margin({ left: 8 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#E8F5E9')
          .borderRadius(8)

          // Pet name
          Column() {
            Text('Pet Name *')
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
                this.errorMessage = '';
              })
          }
          .width('100%')
          .margin({ top: 20 })

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
                  .backgroundColor(this.species === option ? '#4CAF50' : '#F5F5F5')
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

          // Breed
          Column() {
            Text('Breed')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            TextInput({ text: this.breed, placeholder: 'Enter breed (optional)' })
              .fontSize(16)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(50)
              .padding({ left: 16, right: 16 })
              .margin({ top: 8 })
              .onChange((value: string) => {
                this.breed = value;
              })
          }
          .width('100%')
          .margin({ top: 20 })

          // Sex selection
          Column() {
            Text('Sex *')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            Row({ space: 16 }) {
              Row() {
                Radio({ value: 'male', group: 'donationSex' })
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
                Radio({ value: 'female', group: 'donationSex' })
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

          // Age
          Row() {
            Column() {
              Text('Age (Years)')
                .fontSize(14)
                .fontColor('#616161')

              TextInput({ text: this.ageYears, placeholder: '0' })
                .fontSize(16)
                .fontColor('#212121')
                .placeholderColor('#BDBDBD')
                .backgroundColor('#F5F5F5')
                .borderRadius(12)
                .height(50)
                .padding({ left: 16, right: 16 })
                .margin({ top: 8 })
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.ageYears = value;
                })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column() {
              Text('Age (Months)')
                .fontSize(14)
                .fontColor('#616161')

              TextInput({ text: this.ageMonths, placeholder: '0' })
                .fontSize(16)
                .fontColor('#212121')
                .placeholderColor('#BDBDBD')
                .backgroundColor('#F5F5F5')
                .borderRadius(12)
                .height(50)
                .padding({ left: 16, right: 16 })
                .margin({ top: 8 })
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.ageMonths = value;
                })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 16 })
          }
          .width('100%')
          .margin({ top: 20 })

          // Health traits
          Column() {
            Text('Health & Traits')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            Column() {
              this.buildCheckbox('Vaccinated', this.vaccinated, (checked: boolean) => {
                this.vaccinated = checked;
              })
              this.buildCheckbox('Dewormed', this.dewormed, (checked: boolean) => {
                this.dewormed = checked;
              })
              this.buildCheckbox('Sterilized/Neutered', this.sterilized, (checked: boolean) => {
                this.sterilized = checked;
              })
              this.buildCheckbox('Microchipped', this.microchipped, (checked: boolean) => {
                this.microchipped = checked;
              })
              this.buildCheckbox('House Trained', this.trained, (checked: boolean) => {
                this.trained = checked;
              })
              this.buildCheckbox('Child Friendly', this.childFriendly, (checked: boolean) => {
                this.childFriendly = checked;
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

            TextArea({ text: this.description, placeholder: 'Describe the pet, its personality, and any special needs...' })
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

          // Contact phone
          Column() {
            Text('Contact Phone *')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            TextInput({ text: this.contactPhone, placeholder: 'Your phone number' })
              .fontSize(16)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(50)
              .padding({ left: 16, right: 16 })
              .margin({ top: 8 })
              .type(InputType.PhoneNumber)
              .onChange((value: string) => {
                this.contactPhone = value;
                this.errorMessage = '';
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
          Button(this.isLoading ? 'Submitting...' : 'Submit Donation')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.isLoading ? '#A5D6A7' : '#4CAF50')
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

  @Builder
  buildCheckbox(label: string, checked: boolean, onChange: (checked: boolean) => void): void {
    Row() {
      Checkbox()
        .select(checked)
        .selectedColor('#4CAF50')
        .onChange((value: boolean) => {
          onChange(value);
        })

      Text(label)
        .fontSize(14)
        .fontColor('#424242')
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
}
