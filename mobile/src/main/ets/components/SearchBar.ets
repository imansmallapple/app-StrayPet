// Common UI Components
// Search Bar Component
// Following ArkTS strict typing rules

@Component
export struct SearchBar {
  @Link searchText: string;
  @Prop placeholder: string = 'Search...';
  onSearch: (text: string) => void = () => {};

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(18)
        .fontColor(['#9E9E9E'])
        .margin({ left: 12 })
        .onClick(() => {
          // Click search icon to trigger search
          this.onSearch(this.searchText);
        })

      TextInput({ text: $$this.searchText, placeholder: this.placeholder })
        .fontSize(15)
        .fontColor('#212121')
        .placeholderColor('#BDBDBD')
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .height(40)
        .padding({ left: 8, right: 12 })
        .onSubmit(() => {
          this.onSearch(this.searchText);
        })
        .onChange((value: string) => {
          this.searchText = value;
        })
    }
    .width('100%')
    .height(44)
    .backgroundColor('#F5F5F5')
    .borderRadius(22)
  }
}
