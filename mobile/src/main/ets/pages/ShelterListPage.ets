// Shelter List Page
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { LoadingView, EmptyView, ErrorView } from '../components/CommonViews';
import { SearchBar } from '../components/SearchBar';
import { Shelter } from '../models/index';
import { ShelterService, ShelterFilter } from '../services/ShelterService';
import { MapConfig } from '../services/ApiConfig';
import { MapView, MapMarker } from '../components/MapView';

// View mode type
type ViewMode = 'list' | 'map';

@Entry
@Component
struct ShelterListPage {
  @State shelters: Shelter[] = [];
  @State mapMarkers: MapMarker[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State searchText: string = '';
  @State viewMode: ViewMode = 'list';  // 默认列表视图
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

    console.info('[ShelterList] Loading shelters with search:', this.searchText);

    const result = await this.shelterService.getShelters(filter);

    console.info('[ShelterList] Got result, success:', result.success, 'count:', result.shelters.length);

    if (result.success) {
      this.shelters = result.shelters;
      this.convertToMapMarkers();
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  // Convert shelters to map markers
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
        marker.description = shelter.is_verified ? '✓ Verified' : 'Shelter';
        marker.type = 'shelter';
        marker.color = shelter.is_verified ? '#4CAF50' : '#FF6B35';
        markers.push(marker);
      }
    }
    this.mapMarkers = markers;
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
          .layoutWeight(1)

        // View mode toggle
        Row({ space: 8 }) {
          // List view button
          Row() {
            SymbolGlyph($r('sys.symbol.list_bullet'))
              .fontSize(18)
              .fontColor([this.viewMode === 'list' ? '#4CAF50' : '#9E9E9E'])
          }
          .width(36)
          .height(36)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.viewMode === 'list' ? '#E8F5E9' : '#F5F5F5')
          .borderRadius(8)
          .onClick(() => { this.viewMode = 'list'; })

          // Map view button
          Row() {
            SymbolGlyph($r('sys.symbol.map'))
              .fontSize(18)
              .fontColor([this.viewMode === 'map' ? '#4CAF50' : '#9E9E9E'])
          }
          .width(36)
          .height(36)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.viewMode === 'map' ? '#E8F5E9' : '#F5F5F5')
          .borderRadius(8)
          .onClick(() => { this.viewMode = 'map'; })
        }
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 12, bottom: 12 })

      // Search bar (hide in map mode)
      Row() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(18)
          .fontColor(['#9E9E9E'])
          .margin({ left: 12 })
          .onClick(() => {
            console.info('[ShelterList] Search icon clicked, searchText:', this.searchText);
            this.loadShelters();
          })

        TextInput({ placeholder: 'Search shelters...' })
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
            console.info('[ShelterList] Search submitted:', this.searchText);
            this.loadShelters();
          })

        // 清除按钮 - 搜索文字不为空时显示
        if (this.searchText.length > 0) {
          SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
            .fontSize(18)
            .fontColor(['#9E9E9E'])
            .margin({ right: 12 })
            .onClick(() => {
              this.searchText = '';
              this.loadShelters();
            })
        }
      }
      .width('100%')
      .height(44)
      .backgroundColor('#F5F5F5')
      .borderRadius(22)
      .margin({ left: 16, right: 16 })
      .visibility(this.viewMode === 'list' ? Visibility.Visible : Visibility.None)

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
      } else if (this.viewMode === 'list') {
        // List View
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
      } else {
        // Map View
        Column() {
          if (this.mapMarkers.length === 0) {
            // No locations available
            Column() {
              SymbolGlyph($r('sys.symbol.map'))
                .fontSize(48)
                .fontColor(['#BDBDBD'])
              Text('No location data')
                .fontSize(16)
                .fontColor('#757575')
                .margin({ top: 12 })
              Text('Shelters with location will appear on the map')
                .fontSize(13)
                .fontColor('#9E9E9E')
                .margin({ top: 4 })
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .padding(32)
          } else {
            // Dynamic Map
            MapView({
              markers: this.mapMarkers,
              centerLat: this.mapMarkers.length > 0 ? this.mapMarkers[0].latitude : MapConfig.DEFAULT_LAT,
              centerLng: this.mapMarkers.length > 0 ? this.mapMarkers[0].longitude : MapConfig.DEFAULT_LNG,
              zoom: 11,
              mapboxToken: MapConfig.MAPBOX_TOKEN,
              onMarkerClick: (marker: MapMarker) => {
                // 点击标记跳转到对应 Shelter 详情页
                console.info('[ShelterList] Marker clicked, navigating to shelter:', marker.id);
                try {
                  router.pushUrl({
                    url: 'pages/ShelterDetailPage',
                    params: { shelterId: marker.id }
                  });
                } catch (err) {
                  console.error('Navigation error', JSON.stringify(err));
                }
              }
            })
              .width('100%')
              .layoutWeight(1)
          }

          // Bottom info bar
          Row() {
            SymbolGlyph($r('sys.symbol.info_circle'))
              .fontSize(14)
              .fontColor(['#9E9E9E'])
              .margin({ right: 6 })
            Text(`${this.mapMarkers.length} shelters on map`)
              .fontSize(13)
              .fontColor('#757575')
            Blank()
            Text(`${this.shelters.length} total`)
              .fontSize(13)
              .fontColor('#9E9E9E')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .backgroundColor('#FFFFFF')
          .borderWidth({ top: 1 })
          .borderColor('#F0F0F0')
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
