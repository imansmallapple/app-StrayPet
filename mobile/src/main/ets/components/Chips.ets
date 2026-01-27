// Common UI Components
// Trait Chip Component
// Following ArkTS strict typing rules

@Component
export struct TraitChip {
  @Prop label: string = '';
  @Prop icon: Resource | null = null;
  @Prop selected: boolean = false;
  @Prop chipBgColor: string = '#E8F5E9';
  @Prop chipTextColor: string = '#4CAF50';

  build() {
    Row() {
      if (this.icon !== null) {
        Image(this.icon)
          .width(14)
          .height(14)
          .fillColor(this.chipTextColor)
          .margin({ right: 4 })
      }

      Text(this.label)
        .fontSize(12)
        .fontColor(this.chipTextColor)
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor(this.chipBgColor)
    .borderRadius(16)
  }
}

@Component
export struct FilterChip {
  @Prop label: string = '';
  @Prop selected: boolean = false;
  onTap: () => void = () => {};

  build() {
    Row() {
      Text(this.label)
        .fontSize(13)
        .fontColor(this.selected ? '#FFFFFF' : '#616161')
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(this.selected ? '#FF6B35' : '#F5F5F5')
    .borderRadius(20)
    .onClick(() => {
      this.onTap();
    })
  }
}

@Component
export struct StatusBadge {
  @Prop status: string = '';
  @Prop label: string = '';

  private getBackgroundColor(): ResourceColor {
    const colorMap: Map<string, ResourceColor> = new Map([
      ['available', '#4CAF50'],
      ['pending', '#FF9800'],
      ['adopted', '#2196F3'],
      ['lost', '#F44336'],
      ['submitted', '#2196F3'],
      ['processing', '#FF9800'],
      ['approved', '#4CAF50'],
      ['rejected', '#F44336'],
      ['closed', '#9E9E9E'],
      ['open', '#F44336'],
      ['found', '#4CAF50']
    ]);
    const result = colorMap.get(this.status);
    return result !== undefined ? result : '#9E9E9E';
  }

  build() {
    Text(this.label)
      .fontSize(11)
      .fontColor('#FFFFFF')
      .backgroundColor(this.getBackgroundColor())
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(4)
  }
}
