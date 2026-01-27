// Holiday Family Page
import { router } from '@kit.ArkUI';

@Entry
@Component
struct HolidayFamilyPage {
  @Builder
  FeatureCard(icon: Resource, title: string, description: string): void {
    Column() {
      SymbolGlyph(icon)
        .fontSize(32)
        .fontColor(['#9C27B0'])
        .margin({ bottom: 8 })

      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .textAlign(TextAlign.Center)

      Text(description)
        .fontSize(12)
        .fontColor('#757575')
        .textAlign(TextAlign.Center)
        .margin({ top: 4 })
    }
    .width('48%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 2 })
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

        Text('Holiday Foster Home')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#9C27B0')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          // Banner
          Column() {
            SymbolGlyph($r('sys.symbol.person_3_fill'))
              .fontSize(64)
              .fontColor(['#FFFFFF'])
              .margin({ bottom: 16 })

            Text('Become a Foster Family')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            Text('Provide a warm home for stray pets during holidays')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .opacity(0.9)
              .margin({ top: 8 })
          }
          .width('100%')
          .padding({ top: 40, bottom: 40 })
          .backgroundColor('#9C27B0')
          .alignItems(HorizontalAlign.Center)

          // Features
          Text('Program Features')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .width('100%')
            .padding({ left: 16, top: 24, bottom: 12 })

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            this.FeatureCard($r('sys.symbol.house_fill'), 'Temporary Home', 'Provide short-term foster care')
            this.FeatureCard($r('sys.symbol.heart_fill'), 'Make a Difference', 'Help ease shelter overcrowding')
            this.FeatureCard($r('sys.symbol.person_2_fill'), 'Family Activity', 'Bond with family members')
            this.FeatureCard($r('sys.symbol.star_fill'), 'Community Support', 'Join a caring community')
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          // Requirements
          Column() {
            Text('Requirements')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#212121')
              .margin({ bottom: 12 })

            Text('✓ Stable living environment')
              .fontSize(14)
              .fontColor('#424242')
              .padding({ top: 6, bottom: 6 })
            Text('✓ Experience or willingness to care for pets')
              .fontSize(14)
              .fontColor('#424242')
              .padding({ top: 6, bottom: 6 })
            Text('✓ Adequate living space')
              .fontSize(14)
              .fontColor('#424242')
              .padding({ top: 6, bottom: 6 })
            Text('✓ Commitment to return pets on time')
              .fontSize(14)
              .fontColor('#424242')
              .padding({ top: 6, bottom: 6 })
          }
          .width('100%')
          .padding(16)
          .margin({ top: 16, left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)

          // Apply button
          Button('Apply Now')
            .fontSize(18)
            .fontColor('#FFFFFF')
            .backgroundColor('#9C27B0')
            .borderRadius(24)
            .width('90%')
            .height(50)
            .margin({ top: 32, bottom: 40 })
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/HolidayFamilyApplyPage' });
              } catch (err) {
                console.error('Navigation error', JSON.stringify(err));
              }
            })
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
