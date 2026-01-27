// Favorite Pets Page - Placeholder
import { router } from '@kit.ArkUI';

@Entry
@Component
struct FavoritePetsPage {
  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#424242'])
          .onClick(() => { router.back(); })
        Text('Favorite Pets')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      Column() {
        SymbolGlyph($r('sys.symbol.heart_fill'))
          .fontSize(64)
          .fontColor(['#FF6B35'])
        Text('No Favorites')
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
