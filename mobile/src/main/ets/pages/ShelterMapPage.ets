// Shelter Map Page - Display shelters on a map
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { Shelter } from '../models/Pet';
import { ShelterService, ShelterListResult, ShelterFilter } from '../services/ShelterService';
import { MapView, MapMarker } from '../components/MapView';
import { MapConfig } from '../services/ApiConfig';

@Entry
@Component
struct ShelterMapPage {
  @State shelters: Shelter[] = [];
  @State mapMarkers: MapMarker[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State showList: boolean = false;

  private shelterService: ShelterService = new ShelterService();

  aboutToAppear(): void {
    this.loadShelters();
  }

  async loadShelters(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    const filter = new ShelterFilter();
    const result: ShelterListResult = await this.shelterService.getShelters(filter);

    if (result.success) {
      this.shelters = result.shelters;
      this.convertToMapMarkers();
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  private convertToMapMarkers(): void {
    const markers: MapMarker[] = [];
    for (let i = 0; i < this.shelters.length; i++) {
      const shelter = this.shelters[i];
      if (shelter.address !== null && shelter.address.latitude !== 0 && shelter.address.longitude !== 0) {
        const marker = new MapMarker(
          shelter.id,
          shelter.address.latitude,
          shelter.address.longitude,
          shelter.name
        );
        marker.description = shelter.is_verified ? '✓ Verified Shelter' : 'Shelter';
        marker.type = 'shelter';
        marker.color = shelter.is_verified ? '#4CAF50' : '#FF6B35';
        marker.imageUrl = shelter.logo;
        markers.push(marker);
      }
    }
    this.mapMarkers = markers;
  }

  @Builder
  ShelterListItem(shelter: Shelter): void {
    Row() {
      // Logo
      if (shelter.logo.length > 0) {
        Image(shelter.logo)
          .width(50)
          .height(50)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.house_fill'))
            .fontSize(24)
            .fontColor(['#757575'])
        }
        .width(50)
        .height(50)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .justifyContent(FlexAlign.Center)
      }

      // Info
      Column() {
        Row() {
          Text(shelter.name)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#212121')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (shelter.is_verified) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(16)
              .fontColor(['#4CAF50'])
              .margin({ left: 4 })
          }
        }
        .width('100%')

        if (shelter.address !== null) {
          Text(shelter.address.getFullAddress())
            .fontSize(12)
            .fontColor('#757575')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }

        Text(`${shelter.current_animals} animals`)
          .fontSize(11)
          .fontColor('#9E9E9E')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor(['#BDBDBD'])
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .onClick(() => {
      try {
        router.pushUrl({
          url: 'pages/ShelterDetailPage',
          params: { shelterId: shelter.id }
        });
      } catch (err) {
        console.error('Navigation error', JSON.stringify(err));
      }
    })
  }

  build() {
    Column() {
      // Header
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#424242'])
          .onClick(() => { router.back(); })

        Text('Shelter Map')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
          .layoutWeight(1)

        // Toggle list/map view
        Row() {
          SymbolGlyph($r('sys.symbol.list_bullet'))
            .fontSize(18)
            .fontColor([this.showList ? '#FF6B35' : '#9E9E9E'])
        }
        .width(36)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.showList ? '#FFEBE6' : '#F5F5F5')
        .borderRadius(8)
        .onClick(() => { this.showList = !this.showList; })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#FF6B35')
          Text('Loading shelters...')
            .fontSize(14)
            .fontColor('#757575')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        Column() {
          SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
            .fontSize(48)
            .fontColor(['#F44336'])
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#757575')
            .margin({ top: 12 })
          Button('Retry')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF6B35')
            .borderRadius(20)
            .margin({ top: 16 })
            .onClick(() => { this.loadShelters(); })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.showList) {
        // List view
        List({ space: 8 }) {
          ForEach(this.shelters, (shelter: Shelter) => {
            ListItem() {
              this.ShelterListItem(shelter)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding(16)
      } else {
        // Map view
        if (this.mapMarkers.length === 0) {
          Column() {
            SymbolGlyph($r('sys.symbol.map'))
              .fontSize(48)
              .fontColor(['#757575'])
              .margin({ bottom: 16 })

            Text('No shelter locations')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#424242')

            Text('Shelters with location data will appear on the map')
              .fontSize(14)
              .fontColor('#9E9E9E')
              .margin({ top: 8 })
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding(32)
        } else {
          MapView({
            markers: this.mapMarkers,
            centerLat: this.mapMarkers.length > 0 ? this.mapMarkers[0].latitude : MapConfig.DEFAULT_LAT,
            centerLng: this.mapMarkers.length > 0 ? this.mapMarkers[0].longitude : MapConfig.DEFAULT_LNG,
            zoom: 11,
            mapboxToken: MapConfig.MAPBOX_TOKEN
          })
            .width('100%')
            .layoutWeight(1)
        }
      }

      // Bottom info bar
      Row() {
        Text(`${this.shelters.length} shelters`)
          .fontSize(13)
          .fontColor('#757575')
        Blank()
        Text(`${this.mapMarkers.length} on map`)
          .fontSize(13)
          .fontColor('#9E9E9E')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .borderWidth({ top: 1 })
      .borderColor('#F0F0F0')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
