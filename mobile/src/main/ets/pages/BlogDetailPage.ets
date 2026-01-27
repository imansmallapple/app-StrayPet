// Blog Detail Page - Placeholder
import { router } from '@kit.ArkUI';

@Entry
@Component
struct BlogDetailPage {
  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#424242'])
          .onClick(() => { router.back(); })
        Text('Article')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)

      Column() {
        SymbolGlyph($r('sys.symbol.doc_text_fill'))
          .fontSize(64)
          .fontColor(['#9E9E9E'])
        Text('Coming Soon...')
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
