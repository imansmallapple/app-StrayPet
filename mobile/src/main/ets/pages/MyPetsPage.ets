// My Pets Page - Placeholder
import { router } from '@kit.ArkUI';

@Entry
@Component
struct MyPetsPage {
  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#424242'])
          .onClick(() => { router.back(); })
        Text('My Pets')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      Column() {
        SymbolGlyph($r('sys.symbol.pawprint_fill'))
          .fontSize(64)
          .fontColor(['#9E9E9E'])
        Text('No Posts Yet')
          .fontSize(16)
          .fontColor('#9E9E9E')
          .margin({ top: 16 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
