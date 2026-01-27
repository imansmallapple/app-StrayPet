// Shelter List Page
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { LoadingView, EmptyView, ErrorView } from '../components/CommonViews';
import { SearchBar } from '../components/SearchBar';
import { Shelter } from '../models/index';
import { ShelterService, ShelterFilter } from '../services/ShelterService';
import { MapConfig } from '../services/ApiConfig';

@Entry
@Component
struct ShelterListPage {
  @State shelters: Shelter[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State searchText: string = '';
  private shelterService: ShelterService = new ShelterService();

  aboutToAppear(): void {
    this.loadShelters();
  }

  async loadShelters(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    const filter = new ShelterFilter();
    filter.search = this.searchText;
    filter.page = 1;
    filter.page_size = 50;

    const result = await this.shelterService.getShelters(filter);

    if (result.success) {
      this.shelters = result.shelters;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  getOccupancyRate(shelter: Shelter): number {
    if (shelter.capacity === 0) return 0;
    return Math.round((shelter.current_animals / shelter.capacity) * 100);
  }

  getShelterAddress(shelter: Shelter): string {
    if (shelter.address !== null) {
      return shelter.address.getFullAddress();
    }
    return 'No address';
  }

  // Generate Mapbox static map URL
  getStaticMapUrl(shelter: Shelter): string {
    if (shelter.address !== null && shelter.address.latitude !== 0 && shelter.address.longitude !== 0) {
      const lng = shelter.address.longitude;
      const lat = shelter.address.latitude;
      const color = shelter.is_verified ? '4CAF50' : 'FF6B35';
      // Mapbox Static Images API with marker
      return `https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/pin-s+${color}(${lng},${lat})/${lng},${lat},14,0/400x240@2x?access_token=${MapConfig.MAPBOX_TOKEN}`;
    }
    return '';
  }

  @Builder
  ShelterCard(shelter: Shelter): void {
    Column() {
      // Cover image or Static Map
      if (shelter.cover_image.length > 0) {
        Image(shelter.cover_image)
          .width('100%')
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 12, topRight: 12 })
      } else if (shelter.address !== null && shelter.address.latitude !== 0) {
        // Show static map if location available
        Image(this.getStaticMapUrl(shelter))
          .width('100%')
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 12, topRight: 12 })
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.house_fill'))
            .fontSize(32)
            .fontColor(['#4CAF50'])
        }
        .width('100%')
        .height(120)
        .backgroundColor('#E8F5E9')
        .borderRadius({ topLeft: 12, topRight: 12 })
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Row() {
          Text(shelter.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
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

        Text(this.getShelterAddress(shelter))
          .fontSize(12)
          .fontColor('#757575')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })

        Row() {
          Row() {
            SymbolGlyph($r('sys.symbol.pawprint_fill'))
              .fontSize(14)
              .fontColor(['#9E9E9E'])
            Text(` ${shelter.current_animals}/${shelter.capacity}`)
              .fontSize(12)
              .fontColor('#9E9E9E')
          }

          Blank()

          Text(`${this.getOccupancyRate(shelter)}%`)
            .fontSize(12)
            .fontColor(this.getOccupancyRate(shelter) > 80 ? '#F44336' : '#4CAF50')
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .width('100%')
      .padding(12)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
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
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor(['#424242'])
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.back();
        })

        Text('Shelters')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4CAF50')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 12, bottom: 12 })

      // Search
      Row() {
        SearchBar({
          searchText: $searchText,
          placeholder: 'Search shelters...',
          onSearch: () => {
            this.loadShelters();
          }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // Content
      if (this.isLoading) {
        LoadingView({ message: 'Loading...' })
          .layoutWeight(1)
      } else if (this.hasError) {
        ErrorView({
          message: this.errorMessage,
          onRetry: () => {
            this.loadShelters();
          }
        })
          .layoutWeight(1)
      } else if (this.shelters.length === 0) {
        EmptyView({
          title: 'No Shelters',
          subtitle: 'Check back later'
        })
          .layoutWeight(1)
      } else {
        List({ space: 16 }) {
          ForEach(this.shelters, (shelter: Shelter) => {
            ListItem() {
              this.ShelterCard(shelter)
            }
            .padding({ left: 16, right: 16 })
          })
        }
        .layoutWeight(1)
        .padding({ top: 16, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
