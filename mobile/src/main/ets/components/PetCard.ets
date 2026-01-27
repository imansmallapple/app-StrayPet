// Common UI Components
// Pet Card Component
// Following ArkTS strict typing rules

import { Pet } from '../models/Pet';

@Component
export struct PetCard {
  @Prop pet: Pet = new Pet();
  onTap: () => void = () => {};
  onFavorite: () => void = () => {};

  build() {
    Column() {
      // Pet Image
      Stack({ alignContent: Alignment.TopEnd }) {
        if (this.pet.cover.length > 0) {
          Image(this.pet.cover)
            .width('100%')
            .aspectRatio(1)
            .objectFit(ImageFit.Cover)
            .borderRadius({ topLeft: 16, topRight: 16 })
        } else {
          Column() {
            Text('🐾')
              .fontSize(48)
              .opacity(0.4)
          }
          .width('100%')
          .aspectRatio(1)
          .backgroundColor('#F0F0F0')
          .justifyContent(FlexAlign.Center)
          .borderRadius({ topLeft: 16, topRight: 16 })
        }

        // Favorite button
        Column() {
          Text(this.pet.is_favorited ? '♥' : '♡')
            .fontSize(20)
            .fontColor(this.pet.is_favorited ? '#FF4081' : '#FFFFFF')
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor('rgba(0,0,0,0.35)')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8, right: 8 })
        .onClick(() => {
          this.onFavorite();
        })

        // Status badge
        if (this.pet.status !== 'available') {
          Text(this.pet.getStatusDisplay())
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor(this.pet.status === 'adopted' ? '#4CAF50' : '#FF9800')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .position({ x: 8, y: 8 })
        }
      }
      .width('100%')

      // Pet Info
      Column() {
        // Name and Sex
        Row() {
          Text(this.pet.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // Sex icon with background
          Text(this.pet.sex === 'male' ? '♂' : '♀')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.pet.sex === 'male' ? '#2196F3' : '#E91E63')
            .backgroundColor(this.pet.sex === 'male' ? '#E3F2FD' : '#FCE4EC')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(10)
        }
        .width('100%')

        // Species and Age
        Text(`${this.pet.species} · ${this.pet.getAgeString()}`)
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // Location
        if (this.pet.address !== null && this.pet.address.city.length > 0) {
          Row() {
            Text('📍')
              .fontSize(11)
            Text(this.pet.address.city)
              .fontSize(11)
              .fontColor('#AAAAAA')
              .margin({ left: 2 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .margin({ top: 6 })
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: 'rgba(0,0,0,0.1)',
      offsetX: 0,
      offsetY: 4
    })
    .clip(true)
    .onClick(() => {
      this.onTap();
    })
  }
}
