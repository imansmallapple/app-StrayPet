// Common UI Components
// Loading and Empty State Components
// Following ArkTS strict typing rules

@Component
export struct LoadingView {
  @Prop message: string = 'Loading...';

  build() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color('#FF6B35')

      Text(this.message)
        .fontSize(14)
        .fontColor('#757575')
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct EmptyView {
  @Prop icon: Resource = $r('app.media.startIcon');
  @Prop title: string = 'No Data';
  @Prop subtitle: string = '';
  @Prop actionText: string = '';
  onAction: () => void = () => {};

  build() {
    Column() {
      Image(this.icon)
        .width(80)
        .height(80)
        .fillColor('#BDBDBD')

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#424242')
        .margin({ top: 24 })

      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(14)
          .fontColor('#9E9E9E')
          .margin({ top: 8 })
          .textAlign(TextAlign.Center)
      }

      if (this.actionText.length > 0) {
        Button(this.actionText)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B35')
          .borderRadius(20)
          .height(40)
          .padding({ left: 24, right: 24 })
          .margin({ top: 24 })
          .onClick(() => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct ErrorView {
  @Prop message: string = 'Something went wrong';
  onRetry: () => void = () => {};

  build() {
    Column() {
      Text('⚠')
        .fontSize(64)
        .fontColor('#F44336')

      Text('Error')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#424242')
        .margin({ top: 16 })

      Text(this.message)
        .fontSize(14)
        .fontColor('#9E9E9E')
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)

      Button('Retry')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF6B35')
        .borderRadius(20)
        .height(40)
        .padding({ left: 24, right: 24 })
        .margin({ top: 24 })
        .onClick(() => {
          this.onRetry();
        })
    }
    .width('100%')
    .padding(32)
    .justifyContent(FlexAlign.Center)
  }
}
