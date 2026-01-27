// About Page
import { router } from '@kit.ArkUI';

@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#424242'])
          .onClick(() => { router.back(); })
        Text('About')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      Column() {
        SymbolGlyph($r('sys.symbol.pawprint_fill'))
          .fontSize(80)
          .fontColor(['#FF6B35'])
          .margin({ bottom: 16 })

        Text('StrayPet')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')

        Text('Stray Pet Rescue Platform')
          .fontSize(16)
          .fontColor('#757575')
          .margin({ top: 8 })

        Text('Version 1.0.0')
          .fontSize(14)
          .fontColor('#9E9E9E')
          .margin({ top: 24 })

        Column() {
          Text('Our Mission')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .margin({ bottom: 8 })

          Text('Help stray pets find warm homes,\nand treat every life with kindness.')
            .fontSize(14)
            .fontColor('#424242')
            .textAlign(TextAlign.Center)
            .lineHeight(22)
        }
        .width('90%')
        .padding(20)
        .backgroundColor('#FFF3E0')
        .borderRadius(12)
        .margin({ top: 32 })

        Text('© 2026 StrayPet Team')
          .fontSize(12)
          .fontColor('#BDBDBD')
          .margin({ top: 40 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
