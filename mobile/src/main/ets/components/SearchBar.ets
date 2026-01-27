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
      Text('🔍')
        .fontSize(16)
        .margin({ left: 12 })

      TextInput({ text: this.searchText, placeholder: this.placeholder })
        .fontSize(15)
        .fontColor('#212121')
        .placeholderColor('#BDBDBD')
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .height(40)
        .padding({ left: 8, right: 8 })
        .onChange((value: string) => {
          this.searchText = value;
        })
        .onSubmit(() => {
          this.onSearch(this.searchText);
        })

      if (this.searchText.length > 0) {
        Text('✕')
          .fontSize(18)
          .fontColor('#9E9E9E')
          .margin({ right: 12 })
          .onClick(() => {
            this.searchText = '';
            this.onSearch('');
          })
      }
    }
    .width('100%')
    .height(44)
    .backgroundColor('#F5F5F5')
    .borderRadius(22)
  }
}
