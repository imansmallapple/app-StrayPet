// Lost List Page - Standalone page with back button
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { Lost } from '../models/Lost';
import { LostService, LostFilter, LostListResult } from '../services/LostService';
import { LoadingView, EmptyView, ErrorView } from '../components/CommonViews';
import { SearchBar } from '../components/SearchBar';
import { FilterChip } from '../components/Chips';

@Entry
@Component
struct LostListPage {
  @State lostPets: Lost[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State searchText: string = '';
  @State selectedSpecies: string = '';
  @State viewMode: string = 'list'; // 'list' or 'map'
  @State currentPage: number = 1;
  @State hasMore: boolean = true;
  @State isLoadingMore: boolean = false;

  private lostService: LostService = new LostService();
  private speciesList: string[] = ['All', 'Dog', 'Cat', 'Rabbit', 'Other'];

  aboutToAppear(): void {
    this.loadLostPets();
  }

  getSpeciesKey(label: string): string {
    const map: Map<string, string> = new Map([
      ['All', ''],
      ['Dog', 'dog'],
      ['Cat', 'cat'],
      ['Rabbit', 'rabbit'],
      ['Other', 'other']
    ]);
    return map.get(label) || '';
  }

  async loadLostPets(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    this.currentPage = 1;

    const filter = new LostFilter();
    filter.page = this.currentPage;

    const speciesKey = this.getSpeciesKey(this.selectedSpecies);
    if (speciesKey.length > 0) {
      filter.species = speciesKey;
    }

    if (this.searchText.length > 0) {
      filter.search = this.searchText;
    }

    const result: LostListResult = await this.lostService.getLosts(filter);

    if (result.success) {
      this.lostPets = result.losts;
      this.hasMore = result.losts.length >= 10;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  @Builder
  LostCard(lost: Lost): void {
    Row() {
      // Photo
      if (lost.photo.length > 0) {
        Image(lost.photo)
          .width(100)
          .height(100)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('🐾')
            .fontSize(32)
        }
        .width(100)
        .height(100)
        .borderRadius(10)
        .backgroundColor('#FFEBEE')
        .justifyContent(FlexAlign.Center)
      }

      // Info
      Column() {
        Row() {
          Text(lost.pet_name.length > 0 ? lost.pet_name : lost.species)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Blank()

          Text(lost.getStatusDisplay())
            .fontSize(11)
            .fontColor('#FFFFFF')
            .backgroundColor(lost.getStatusColor())
            .borderRadius(8)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        }
        .width('100%')

        Text(`${lost.species} · ${lost.breed.length > 0 ? lost.breed : 'Unknown breed'}`)
          .fontSize(13)
          .fontColor('#757575')
          .margin({ top: 4 })

        if (lost.color.length > 0) {
          Text(`Color: ${lost.color}`)
            .fontSize(12)
            .fontColor('#9E9E9E')
            .margin({ top: 2 })
        }

        Row() {
          Text(`📅 ${lost.lost_time.substring(0, 10)}`)
            .fontSize(11)
            .fontColor('#BDBDBD')

          if (lost.reward > 0) {
            Blank()
            Text(`💰 ¥${lost.reward}`)
              .fontSize(12)
              .fontColor('#4CAF50')
              .fontWeight(FontWeight.Bold)
          }
        }
        .width('100%')
        .margin({ top: 6 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      try {
        router.pushUrl({
          url: 'pages/LostDetailPage',
          params: { lostId: lost.id }
        });
      } catch (err) {
        console.error('Navigation error', JSON.stringify(err));
      }
    })
  }

  @Builder
  ViewModeToggle(): void {
    Row() {
      Text('📋')
        .fontSize(18)
        .padding(8)
        .backgroundColor(this.viewMode === 'list' ? '#FFE0B2' : '#FFFFFF')
        .borderRadius(8)
        .onClick(() => {
          this.viewMode = 'list';
        })

      Text('🗺️')
        .fontSize(18)
        .padding(8)
        .margin({ left: 4 })
        .backgroundColor(this.viewMode === 'map' ? '#FFE0B2' : '#FFFFFF')
        .borderRadius(8)
        .onClick(() => {
          this.viewMode = 'map';
        })
    }
    .padding(4)
    .backgroundColor('#F5F5F5')
    .borderRadius(10)
  }

  @Builder
  MapView(): void {
    Column() {
      SymbolGlyph($r('sys.symbol.map'))
        .fontSize(48)
        .fontColor(['#757575'])
        .margin({ bottom: 16 })

      Text('Map View')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#424242')

      Text('Coming soon...')
        .fontSize(14)
        .fontColor('#9E9E9E')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F5F5')
  }

  build() {
    Column() {
      // Header with back button
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

        Text('Lost Pets')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F44336')
          .margin({ left: 8 })

        Blank()

        this.ViewModeToggle()

        SymbolGlyph($r('sys.symbol.plus_circle_fill'))
          .fontSize(24)
          .fontColor(['#F44336'])
          .margin({ left: 12 })
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/LostFormPage' });
            } catch (err) {
              console.error('Navigation error', JSON.stringify(err));
            }
          })
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 12, bottom: 8 })

      // Search bar
      Row() {
        SearchBar({
          searchText: $searchText,
          placeholder: 'Search lost pets...',
          onSearch: () => {
            this.loadLostPets();
          }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // Species filter
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.speciesList, (species: string) => {
            FilterChip({
              label: species,
              selected: this.selectedSpecies === species || (this.selectedSpecies === '' && species === 'All'),
              onTap: () => {
                this.selectedSpecies = species === 'All' ? '' : species;
                this.loadLostPets();
              }
            })
          })
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .margin({ top: 10 })

      // Content based on view mode
      if (this.viewMode === 'map') {
        this.MapView()
      } else {
        // List view
        if (this.isLoading) {
          LoadingView({ message: 'Loading...' })
            .layoutWeight(1)
        } else if (this.hasError) {
          ErrorView({
            message: this.errorMessage,
            onRetry: () => {
              this.loadLostPets();
            }
          })
            .layoutWeight(1)
        } else if (this.lostPets.length === 0) {
          EmptyView({
            title: 'No Lost Pets',
            subtitle: 'Help lost pets find their way home',
            actionText: 'Report Lost Pet',
            onAction: () => {
              try {
                router.pushUrl({ url: 'pages/LostFormPage' });
              } catch (err) {
                console.error('Navigation error', JSON.stringify(err));
              }
            }
          })
            .layoutWeight(1)
        } else {
          List({ space: 12 }) {
            ForEach(this.lostPets, (lost: Lost) => {
              ListItem() {
                this.LostCard(lost)
              }
              .padding({ left: 16, right: 16 })
            })
          }
          .layoutWeight(1)
          .padding({ top: 12, bottom: 12 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
