// Home Page - Pet List with Bottom Navigation
// Following ArkTS strict typing rules

import { Pet } from '../models/Pet';
import { Lost } from '../models/Lost';
import { PetService, PetFilter, PetListResult } from '../services/PetService';
import { LostService, LostFilter, LostListResult } from '../services/LostService';
import { PetCard } from '../components/PetCard';
import { LoadingView, EmptyView, ErrorView } from '../components/CommonViews';
import { SearchBar } from '../components/SearchBar';
import { FilterChip } from '../components/Chips';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct HomePage {
  @State currentTab: number = 0;
  @State pets: Pet[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State searchText: string = '';
  @State selectedSpecies: string = '';
  @State currentPage: number = 1;
  @State hasMore: boolean = true;
  @State isLoadingMore: boolean = false;

  // Lost pets state
  @State lostPets: Lost[] = [];
  @State isLoadingLost: boolean = false;
  @State hasErrorLost: boolean = false;
  @State errorMessageLost: string = '';

  private petService: PetService = new PetService();
  private lostService: LostService = new LostService();
  private speciesList: string[] = ['All', 'Dog', 'Cat', 'Rabbit', 'Bird', 'Other'];
  private tabController: TabsController = new TabsController();

  aboutToAppear(): void {
    this.loadPets();
  }

  async loadPets(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    this.currentPage = 1;

    const filter = new PetFilter();
    filter.page = this.currentPage;
    if (this.selectedSpecies.length > 0 && this.selectedSpecies !== 'All') {
      filter.species = this.selectedSpecies.toLowerCase();
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
    if (this.selectedSpecies.length > 0 && this.selectedSpecies !== 'All') {
      filter.species = this.selectedSpecies.toLowerCase();
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

  async loadLostPets(): Promise<void> {
    this.isLoadingLost = true;
    this.hasErrorLost = false;

    const filter = new LostFilter();
    filter.page = 1;

    const result: LostListResult = await this.lostService.getLosts(filter);

    if (result.success) {
      this.lostPets = result.losts;
    } else {
      this.hasErrorLost = true;
      this.errorMessageLost = result.errorMessage;
    }

    this.isLoadingLost = false;
  }

  async toggleFavorite(pet: Pet, index: number): Promise<void> {
    const result = await this.petService.toggleFavorite(pet.id);
    if (result.success) {
      const updatedPet = this.pets[index];
      updatedPet.is_favorited = result.is_favorited;
      this.pets[index] = updatedPet;
    }
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

  @Builder
  buildHomeContent(): void {
    Column() {
      // Header
      Row() {
        Text('StrayPet')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')

        Blank()

        Text('+')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#424242')
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/DonationFormPage' });
            } catch (err) {
              console.error('Navigation error', JSON.stringify(err));
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // Search bar
      Row() {
        SearchBar({
          searchText: $searchText,
          placeholder: 'Search pets...',
          onSearch: () => {
            this.loadPets();
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
                this.loadPets();
              }
            })
          })
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .margin({ top: 12 })

      // Pet list
      if (this.isLoading) {
        LoadingView({ message: 'Loading pets...' })
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
          title: 'No pets found',
          subtitle: 'Try adjusting your search or filters'
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
  }

  @Builder
  buildLostContent(): void {
    Column() {
      // Header
      Row() {
        Text('Lost Pets')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F44336')

        Blank()

        Text('+')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#424242')
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/LostFormPage' });
            } catch (err) {
              console.error('Navigation error', JSON.stringify(err));
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // Content
      if (this.isLoadingLost) {
        LoadingView({ message: 'Loading lost pets...' })
          .layoutWeight(1)
      } else if (this.hasErrorLost) {
        ErrorView({
          message: this.errorMessageLost,
          onRetry: () => {
            this.loadLostPets();
          }
        })
          .layoutWeight(1)
      } else if (this.lostPets.length === 0) {
        EmptyView({
          title: 'No lost pets reported',
          subtitle: 'Help find missing pets in your area',
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
        .padding({ top: 8, bottom: 12 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  LostCard(lost: Lost): void {
    Row() {
      // Photo
      if (lost.photo.length > 0) {
        Image(lost.photo)
          .width(100)
          .height(100)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('🐾')
            .fontSize(32)
        }
        .width(100)
        .height(100)
        .borderRadius(8)
        .backgroundColor('#E0E0E0')
        .justifyContent(FlexAlign.Center)
      }

      // Info
      Column() {
        Row() {
          Text(lost.pet_name.length > 0 ? lost.pet_name : `${lost.species}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')

          Blank()

          Text(lost.getStatusDisplay())
            .fontSize(12)
            .fontColor(lost.getStatusColor())
            .fontWeight(FontWeight.Medium)
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

        if (lost.reward > 0) {
          Text(`💰 Reward: $${lost.reward}`)
            .fontSize(12)
            .fontColor('#4CAF50')
            .fontWeight(FontWeight.Medium)
            .margin({ top: 4 })
        }

        Text(`Lost: ${lost.lost_time.substring(0, 10)}`)
          .fontSize(11)
          .fontColor('#BDBDBD')
          .margin({ top: 4 })
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
  }

  @Builder
  buildFavoritesContent(): void {
    Column() {
      Row() {
        Text('Favorites')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      EmptyView({
        title: 'No favorites yet',
        subtitle: 'Tap the heart icon on pets you like',
        actionText: 'Browse Pets',
        onAction: () => {
          this.currentTab = 0;
          this.tabController.changeIndex(0);
        }
      })
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  buildProfileContent(): void {
    Column() {
      Row() {
        Text('Profile')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#424242')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      EmptyView({
        title: 'Login Required',
        subtitle: 'Sign in to view your profile',
        actionText: 'Login',
        onAction: () => {
          try {
            router.pushUrl({ url: 'pages/LoginPage' });
          } catch (err) {
            console.error('Navigation error', JSON.stringify(err));
          }
        }
      })
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  TabBarItem(index: number, label: string, iconText: string): void {
    Column() {
      Text(iconText)
        .fontSize(22)
        .fontColor(this.currentTab === index ? '#FF6B35' : '#9E9E9E')

      Text(label)
        .fontSize(11)
        .fontColor(this.currentTab === index ? '#FF6B35' : '#9E9E9E')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
      TabContent() {
        this.buildHomeContent()
      }
      .tabBar(this.TabBarItem(0, 'Home', '🏠'))

      TabContent() {
        this.buildLostContent()
      }
      .tabBar(this.TabBarItem(1, 'Lost', '🔍'))

      TabContent() {
        this.buildFavoritesContent()
      }
      .tabBar(this.TabBarItem(2, 'Favorites', '❤️'))

      TabContent() {
        this.buildProfileContent()
      }
      .tabBar(this.TabBarItem(3, 'Profile', '👤'))
    }
    .barHeight(56)
    .barBackgroundColor('#FFFFFF')
    .onChange((index: number) => {
      this.currentTab = index;
      // Load lost pets when switching to Lost tab
      if (index === 1 && this.lostPets.length === 0 && !this.isLoadingLost) {
        this.loadLostPets();
      }
    })
    .width('100%')
    .height('100%')
  }
}
