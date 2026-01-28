// Adopt List Page - Standalone page with back button
// Following ArkTS strict typing rules

import { router, promptAction } from '@kit.ArkUI';
import { Pet } from '../models/Pet';
import { PetService, PetFilter, PetListResult } from '../services/PetService';
import { TokenManager } from '../services/TokenManager';
import { PetCard } from '../components/PetCard';
import { LoadingView, EmptyView, ErrorView } from '../components/CommonViews';
import { SearchBar } from '../components/SearchBar';
import { FilterChip } from '../components/Chips';

@Entry
@Component
struct AdoptListPage {
  @State pets: Pet[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State searchText: string = '';
  @State selectedSpecies: string = '';
  @State selectedSex: string = '';
  @State selectedSize: string = '';
  @State currentPage: number = 1;
  @State hasMore: boolean = true;
  @State isLoadingMore: boolean = false;
  @State showFilters: boolean = false;
  @State showLoginDialog: boolean = false;

  private petService: PetService = new PetService();
  private tokenManager: TokenManager = TokenManager.getInstance();
  private speciesList: string[] = ['All', 'Dog', 'Cat', 'Rabbit', 'Bird', 'Other'];
  private sexList: string[] = ['All', 'Male', 'Female'];
  private sizeList: string[] = ['All', 'Small', 'Medium', 'Large'];

  aboutToAppear(): void {
    this.loadPets();
  }

  getSpeciesKey(label: string): string {
    const map: Map<string, string> = new Map([
      ['All', ''],
      ['Dog', 'dog'],
      ['Cat', 'cat'],
      ['Rabbit', 'rabbit'],
      ['Bird', 'bird'],
      ['Other', 'other']
    ]);
    return map.get(label) || '';
  }

  getSexKey(label: string): string {
    const map: Map<string, string> = new Map([
      ['All', ''],
      ['Male', 'male'],
      ['Female', 'female']
    ]);
    return map.get(label) || '';
  }

  getSizeKey(label: string): string {
    const map: Map<string, string> = new Map([
      ['All', ''],
      ['Small', 'small'],
      ['Medium', 'medium'],
      ['Large', 'large']
    ]);
    return map.get(label) || '';
  }

  async loadPets(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    this.currentPage = 1;

    const filter = new PetFilter();
    filter.page = this.currentPage;

    const speciesKey = this.getSpeciesKey(this.selectedSpecies);
    if (speciesKey.length > 0) {
      filter.species = speciesKey;
    }

    const sexKey = this.getSexKey(this.selectedSex);
    if (sexKey.length > 0) {
      filter.sex = sexKey;
    }

    const sizeKey = this.getSizeKey(this.selectedSize);
    if (sizeKey.length > 0) {
      filter.size = sizeKey;
    }

    if (this.searchText.length > 0) {
      filter.search = this.searchText;
    }

    const result: PetListResult = await this.petService.getPets(filter);

    if (result.success) {
      this.pets = result.pets;
      this.hasMore = result.next.length > 0;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  async loadMorePets(): Promise<void> {
    if (this.isLoadingMore || !this.hasMore) {
      return;
    }

    this.isLoadingMore = true;
    this.currentPage += 1;

    const filter = new PetFilter();
    filter.page = this.currentPage;

    const speciesKey = this.getSpeciesKey(this.selectedSpecies);
    if (speciesKey.length > 0) {
      filter.species = speciesKey;
    }

    if (this.searchText.length > 0) {
      filter.search = this.searchText;
    }

    const result: PetListResult = await this.petService.getPets(filter);

    if (result.success) {
      this.pets = this.pets.concat(result.pets);
      this.hasMore = result.next.length > 0;
    }

    this.isLoadingMore = false;
  }

  async toggleFavorite(pet: Pet, index: number): Promise<void> {
    // Check if user is logged in
    if (!this.tokenManager.isLoggedIn()) {
      this.showLoginDialog = true;
      return;
    }

    const currentState = pet.is_favorited;
    const result = await this.petService.toggleFavorite(pet.id, currentState);
    if (result.success) {
      // Create a new array to trigger UI update
      const newPets = [...this.pets];
      newPets[index].is_favorited = result.is_favorited;
      this.pets = newPets;
      promptAction.showToast({
        message: result.is_favorited ? 'Added to favorites' : 'Removed from favorites',
        duration: 2000
      });
    } else {
      promptAction.showToast({
        message: result.errorMessage || 'Failed to update favorite',
        duration: 2000
      });
    }
  }

  goToLogin(): void {
    this.showLoginDialog = false;
    router.pushUrl({ url: 'pages/LoginPage' });
  }

  navigateToPetDetail(pet: Pet): void {
    try {
      router.pushUrl({
        url: 'pages/PetDetailPage',
        params: { petId: pet.id }
      });
    } catch (err) {
      console.error('Navigation error', JSON.stringify(err));
    }
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

        Text('Adopt a Pet')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')
          .margin({ left: 8 })

        Blank()

        SymbolGlyph($r('sys.symbol.plus_circle_fill'))
          .fontSize(24)
          .fontColor(['#FF6B35'])
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/DonationFormPage' });
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
          placeholder: 'Search pets...',
          onSearch: () => {
            this.loadPets();
          }
        })

        SymbolGlyph($r('sys.symbol.line_3_horizontal'))
          .fontSize(22)
          .fontColor(['#757575'])
          .margin({ left: 8 })
          .onClick(() => {
            this.showFilters = !this.showFilters;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // Species filter chips
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.speciesList, (species: string) => {
            FilterChip({
              label: species,
              selected: this.selectedSpecies === species || (this.selectedSpecies === '' && species === 'All'),
              onTap: () => {
                this.selectedSpecies = species === 'All' ? '' : species;
                this.loadPets();
              }
            })
          })
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .margin({ top: 10 })

      // Advanced filters (collapsible)
      if (this.showFilters) {
        Column() {
          // Sex filter
          Row() {
            Text('Sex:')
              .fontSize(14)
              .fontColor('#757575')
              .width(50)

            ForEach(this.sexList, (sex: string) => {
              Text(sex)
                .fontSize(12)
                .fontColor(this.selectedSex === sex || (this.selectedSex === '' && sex === 'All') ? '#FFFFFF' : '#757575')
                .backgroundColor(this.selectedSex === sex || (this.selectedSex === '' && sex === 'All') ? '#FF6B35' : '#F5F5F5')
                .borderRadius(12)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .margin({ left: 8 })
                .onClick(() => {
                  this.selectedSex = sex === 'All' ? '' : sex;
                  this.loadPets();
                })
            })
          }
          .width('100%')
          .margin({ top: 8 })

          // Size filter
          Row() {
            Text('Size:')
              .fontSize(14)
              .fontColor('#757575')
              .width(50)

            ForEach(this.sizeList, (size: string) => {
              Text(size)
                .fontSize(12)
                .fontColor(this.selectedSize === size || (this.selectedSize === '' && size === 'All') ? '#FFFFFF' : '#757575')
                .backgroundColor(this.selectedSize === size || (this.selectedSize === '' && size === 'All') ? '#FF6B35' : '#F5F5F5')
                .borderRadius(12)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .margin({ left: 8 })
                .onClick(() => {
                  this.selectedSize = size === 'All' ? '' : size;
                  this.loadPets();
                })
            })
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FAFAFA')
      }

      // Pet list
      if (this.isLoading) {
        LoadingView({ message: 'Loading...' })
          .layoutWeight(1)
      } else if (this.hasError) {
        ErrorView({
          message: this.errorMessage,
          onRetry: () => {
            this.loadPets();
          }
        })
          .layoutWeight(1)
      } else if (this.pets.length === 0) {
        EmptyView({
          title: 'No Pets Found',
          subtitle: 'Try adjusting your filters'
        })
          .layoutWeight(1)
      } else {
        List({ space: 12 }) {
          ForEach(this.pets, (pet: Pet, index: number) => {
            ListItem() {
              PetCard({
                pet: pet,
                onTap: () => {
                  this.navigateToPetDetail(pet);
                },
                onFavorite: () => {
                  this.toggleFavorite(pet, index);
                }
              })
            }
            .padding({ left: 4, right: 4 })
          })

          if (this.hasMore) {
            ListItem() {
              Row() {
                if (this.isLoadingMore) {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .color('#FF6B35')
                  Text('Loading more...')
                    .fontSize(14)
                    .fontColor('#9E9E9E')
                    .margin({ left: 8 })
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding(16)
            }
          }
        }
        .lanes(2, 8)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .layoutWeight(1)
        .onReachEnd(() => {
          this.loadMorePets();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
    // Login dialog
    .bindSheet($$this.showLoginDialog, this.LoginDialogBuilder(), {
      height: SheetSize.FIT_CONTENT,
      backgroundColor: '#FFFFFF',
      showClose: true,
      dragBar: true,
      blurStyle: BlurStyle.COMPONENT_THICK
    })
  }

  @Builder
  LoginDialogBuilder() {
    Column() {
      Text('🔐')
        .fontSize(48)
        .margin({ bottom: 16 })

      Text('Please Login First')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .margin({ bottom: 8 })

      Text('You need to login to add pets to your favorites.')
        .fontSize(14)
        .fontColor('#757575')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      Button('Login Now')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF6B35')
        .borderRadius(22)
        .onClick(() => {
          this.goToLogin();
        })

      Button('Cancel')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor('#757575')
        .backgroundColor(Color.Transparent)
        .margin({ top: 8 })
        .onClick(() => {
          this.showLoginDialog = false;
        })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 32, bottom: 32 })
  }
}
