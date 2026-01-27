// Help Page
import { router } from '@kit.ArkUI';

@Entry
@Component
struct HelpPage {
  @Builder
  FaqItem(question: string, answer: string): void {
    Column() {
      Text(question)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#212121')

      Text(answer)
        .fontSize(14)
        .fontColor('#757575')
        .margin({ top: 8 })
        .lineHeight(20)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
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

        Text('Help & Feedback')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          Text('FAQ')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 12 })

          Column() {
            this.FaqItem(
              'How do I adopt a pet?',
              'Browse available pets on the Adopt page, tap to view details, then click "Apply to Adopt" to submit your application.'
            )

            this.FaqItem(
              'How do I report a lost pet?',
              'Tap the "+" button on the Lost page, fill in the pet information and upload photos to publish.'
            )

            this.FaqItem(
              'How do I become a foster family?',
              'Go to the "Holiday Foster" page, tap "Apply Now" and fill out the application form.'
            )

            this.FaqItem(
              'How do I contact a shelter?',
              'On the shelter details page, you can find contact information including phone, email, and address.'
            )

            this.FaqItem(
              'How do I update my profile?',
              'Go to the Profile tab and tap "Edit Profile" below your avatar.'
            )
          }
          .padding({ left: 16, right: 16 })

          Text('Contact Us')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .width('100%')
            .padding({ left: 16, top: 24, bottom: 12 })

          Column() {
            Row() {
              SymbolGlyph($r('sys.symbol.envelope_fill'))
                .fontSize(20)
                .fontColor(['#2196F3'])
              Text('support@straypet.com')
                .fontSize(14)
                .fontColor('#2196F3')
                .margin({ left: 12 })
            }
            .width('100%')
            .padding(16)

            Row() {
              SymbolGlyph($r('sys.symbol.phone_fill'))
                .fontSize(20)
                .fontColor(['#2196F3'])
              Text('+1 800-123-4567')
                .fontSize(14)
                .fontColor('#2196F3')
                .margin({ left: 12 })
            }
            .width('100%')
            .padding(16)
          }
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16, bottom: 40 })

        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
