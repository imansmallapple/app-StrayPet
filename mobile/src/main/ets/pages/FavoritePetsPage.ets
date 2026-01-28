// Favorite Pets Page
import { router, promptAction } from '@kit.ArkUI';
import { Pet } from '../models/Pet';
import { PetService, PetListResult } from '../services/PetService';
import { TokenManager } from '../services/TokenManager';
import { PetCard } from '../components/PetCard';
import { LoadingView, EmptyView, ErrorView } from '../components/CommonViews';

@Entry
@Component
struct FavoritePetsPage {
  @State pets: Pet[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State currentPage: number = 1;
  @State hasMore: boolean = false;
  @State isLoadingMore: boolean = false;

  private petService: PetService = new PetService();
  private tokenManager: TokenManager = TokenManager.getInstance();

  aboutToAppear(): void {
    if (this.tokenManager.isLoggedIn()) {
      this.loadFavorites();
    } else {
      this.isLoading = false;
      this.hasError = true;
      this.errorMessage = 'Please login to view your favorites';
    }
  }

  async loadFavorites(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    this.currentPage = 1;

    const result: PetListResult = await this.petService.getMyFavorites(this.currentPage);

    if (result.success) {
      this.pets = result.pets;
      this.hasMore = result.next.length > 0;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage || 'Failed to load favorites';
    }

    this.isLoading = false;
  }

  async loadMoreFavorites(): Promise<void> {
    if (this.isLoadingMore || !this.hasMore) {
      return;
    }

    this.isLoadingMore = true;
    this.currentPage += 1;

    const result: PetListResult = await this.petService.getMyFavorites(this.currentPage);

    if (result.success) {
      this.pets = this.pets.concat(result.pets);
      this.hasMore = result.next.length > 0;
    }

    this.isLoadingMore = false;
  }

  async toggleFavorite(pet: Pet, index: number): Promise<void> {
    const currentState = pet.is_favorited;
    const result = await this.petService.toggleFavorite(pet.id, currentState);

    if (result.success) {
      // Remove from list if unfavorited
      if (!result.is_favorited) {
        this.pets = this.pets.filter((p: Pet, i: number) => i !== index);
        promptAction.showToast({
          message: 'Removed from favorites',
          duration: 2000
        });
      }
    } else {
      promptAction.showToast({
        message: result.errorMessage || 'Failed to update favorite',
        duration: 2000
      });
    }
  }

  navigateToPetDetail(pet: Pet): void {
    router.pushUrl({
      url: 'pages/PetDetailPage',
      params: { petId: pet.id }
    });
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

        Text('Favorite Pets')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')
          .margin({ left: 8 })

        Blank()

        Text(`${this.pets.length}`)
          .fontSize(14)
          .fontColor('#9E9E9E')
          .margin({ right: 8 })
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // Content
      if (this.isLoading) {
        LoadingView({ message: 'Loading favorites...' })
          .layoutWeight(1)
      } else if (this.hasError) {
        ErrorView({
          message: this.errorMessage,
          onRetry: () => {
            this.loadFavorites();
          }
        })
          .layoutWeight(1)
      } else if (this.pets.length === 0) {
        Column() {
          Text('❤️')
            .fontSize(64)
            .margin({ bottom: 16 })

          Text('No Favorites Yet')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#424242')
            .margin({ bottom: 8 })

          Text('Tap the heart icon on any pet to save them here')
            .fontSize(14)
            .fontColor('#9E9E9E')
            .textAlign(TextAlign.Center)
            .padding({ left: 32, right: 32 })
            .margin({ bottom: 24 })

          Button('Browse Pets')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF6B35')
            .borderRadius(20)
            .padding({ left: 24, right: 24, top: 10, bottom: 10 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/AdoptListPage' });
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
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
          this.loadMoreFavorites();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
