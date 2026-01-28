// Pet Detail Page
// Following ArkTS strict typing rules

import { Pet, PetPhoto } from '../models/Pet';
import { PetService, PetDetailResult } from '../services/PetService';
import { TokenManager } from '../services/TokenManager';
import { LoadingView, ErrorView } from '../components/CommonViews';
import { TraitChip, StatusBadge } from '../components/Chips';
import { router, promptAction } from '@kit.ArkUI';

interface RouterParams {
  petId: number;
}

@Entry
@Component
struct PetDetailPage {
  @State pet: Pet | null = null;
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State currentPhotoIndex: number = 0;
  @State showAdoptDialog: boolean = false;
  @State adoptMessage: string = '';
  @State showLoginDialog: boolean = false;
  @State isFavoriting: boolean = false;

  private petService: PetService = new PetService();
  private tokenManager: TokenManager = TokenManager.getInstance();
  private petId: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as RouterParams | null;
    if (params !== null) {
      this.petId = params.petId;
      this.loadPetDetail();
    }
  }

  async loadPetDetail(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    const result: PetDetailResult = await this.petService.getPetDetail(this.petId);

    if (result.success && result.pet !== null) {
      this.pet = result.pet;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  async toggleFavorite(): Promise<void> {
    if (this.pet === null) return;

    // Check if user is logged in
    if (!this.tokenManager.isLoggedIn()) {
      this.showLoginDialog = true;
      return;
    }

    if (this.isFavoriting) return;
    this.isFavoriting = true;

    const currentState = this.pet.is_favorited;
    const result = await this.petService.toggleFavorite(this.pet.id, currentState);
    if (result.success && this.pet !== null) {
      this.pet.is_favorited = result.is_favorited;
      // Show feedback
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

    this.isFavoriting = false;
  }

  goToLogin(): void {
    this.showLoginDialog = false;
    router.pushUrl({ url: 'pages/LoginPage' });
  }

  getAllPhotos(): string[] {
    const photos: string[] = [];
    if (this.pet !== null) {
      if (this.pet.cover.length > 0) {
        photos.push(this.pet.cover);
      }
      this.pet.photos.forEach((photo: PetPhoto) => {
        if (photo.image.length > 0) {
          photos.push(photo.image);
        }
      });
    }
    return photos;
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

        Text('Pet Details')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#424242')
          .margin({ left: 8 })

        Blank()

        if (this.pet !== null) {
          Row() {
            SymbolGlyph(this.pet.is_favorited ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
              .fontSize(24)
              .fontColor([this.pet.is_favorited ? '#FF4081' : '#424242'])
          }
          .width(40)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.toggleFavorite();
          })
        }
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      // Content
      if (this.isLoading) {
        LoadingView({ message: 'Loading pet details...' })
          .layoutWeight(1)
      } else if (this.hasError) {
        ErrorView({
          message: this.errorMessage,
          onRetry: () => {
            this.loadPetDetail();
          }
        })
          .layoutWeight(1)
      } else if (this.pet !== null) {
        Scroll() {
          Column() {
            // Photo gallery
            Swiper() {
              ForEach(this.getAllPhotos(), (photoUrl: string) => {
                Image(photoUrl)
                  .width('100%')
                  .height(300)
                  .objectFit(ImageFit.Cover)
              })
            }
            .width('100%')
            .height(300)
            .indicator(true)
            .onChange((index: number) => {
              this.currentPhotoIndex = index;
            })
            Column() {
              // Name and status
              Row() {
                Text(this.pet.name)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#212121')
                  .layoutWeight(1)

                StatusBadge({
                  status: this.pet.status,
                  label: this.pet.getStatusDisplay()
                })
              }
              .width('100%')

              // Basic info
              Row() {
                // Species and breed
                Column() {
                  Text('Species')
                    .fontSize(12)
                    .fontColor('#9E9E9E')
                  Text(this.pet.species)
                    .fontSize(14)
                    .fontColor('#424242')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)

                Column() {
                  Text('Breed')
                    .fontSize(12)
                    .fontColor('#9E9E9E')
                  Text(this.pet.breed.length > 0 ? this.pet.breed : 'Unknown')
                    .fontSize(14)
                    .fontColor('#424242')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)

                Column() {
                  Text('Age')
                    .fontSize(12)
                    .fontColor('#9E9E9E')
                  Text(this.pet.getAgeString())
                    .fontSize(14)
                    .fontColor('#424242')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)

                Column() {
                  Text('Sex')
                    .fontSize(12)
                    .fontColor('#9E9E9E')
                  Text(this.pet.getSexDisplay())
                    .fontSize(14)
                    .fontColor(this.pet.sex === 'male' ? '#2196F3' : '#E91E63')
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
              }
              .width('100%')
              .margin({ top: 16 })

              // Description
              if (this.pet.description.length > 0) {
                Column() {
                  Text('About')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#212121')

                  Text(this.pet.description)
                    .fontSize(14)
                    .fontColor('#616161')
                    .margin({ top: 8 })
                    .lineHeight(22)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ top: 20 })
              }

              // Traits
              Column() {
                Text('Traits')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#212121')

                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.pet.getTraits(), (trait: string) => {
                    TraitChip({ label: trait })
                      .margin({ right: 8, bottom: 8 })
                  })
                }
                .margin({ top: 12 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ top: 20 })

              // Location
              if (this.pet.address !== null) {
                Column() {
                  Text('Location')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#212121')

                  Row() {
                    Text('📍')
                      .fontSize(14)

                    Text(this.pet.address.getFullAddress())
                      .fontSize(14)
                      .fontColor('#616161')
                      .margin({ left: 8 })
                  }
                  .margin({ top: 8 })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ top: 20 })
              }

              // Contact info
              if (this.pet.contact_phone.length > 0) {
                Column() {
                  Text('Contact')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#212121')

                  Row() {
                    Text('📞')
                      .fontSize(14)

                    Text(this.pet.contact_phone)
                      .fontSize(14)
                      .fontColor('#2196F3')
                      .margin({ left: 8 })
                  }
                  .margin({ top: 8 })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ top: 20 })
              }

              // Shelter info
              if (this.pet.shelter !== null) {
                Column() {
                  Text('Shelter')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#212121')

                  Row() {
                    if (this.pet.shelter.logo.length > 0) {
                      Image(this.pet.shelter.logo)
                        .width(40)
                        .height(40)
                        .borderRadius(20)
                    }

                    Column() {
                      Text(this.pet.shelter.name)
                        .fontSize(14)
                        .fontColor('#424242')

                      if (this.pet.shelter.is_verified) {
                        Row() {
                          Text('✓')
                            .fontSize(12)
                            .fontColor('#4CAF50')
                          Text('Verified')
                            .fontSize(11)
                            .fontColor('#4CAF50')
                            .margin({ left: 4 })
                        }
                        .margin({ top: 4 })
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .margin({ left: 12 })
                  }
                  .margin({ top: 8 })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ top: 20 })
              }

              // Spacer for bottom button
              Row()
                .height(80)
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius({ topLeft: 24, topRight: 24 })
            .margin({ top: -20 })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }

      // Adopt button
      if (this.pet !== null && this.pet.status === 'available') {
        Row() {
          Button('Apply for Adoption')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF6B35')
            .borderRadius(24)
            .width('90%')
            .height(48)
            .onClick(() => {
              // Check if user is logged in
              if (!this.tokenManager.isLoggedIn()) {
                this.showLoginDialog = true;
                return;
              }
              router.pushUrl({
                url: 'pages/AdoptionFormPage',
                params: { petId: this.pet?.id, petName: this.pet?.name }
              });
            })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
        .shadow({
          radius: 8,
          color: 'rgba(0,0,0,0.1)',
          offsetX: 0,
          offsetY: -2
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
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
