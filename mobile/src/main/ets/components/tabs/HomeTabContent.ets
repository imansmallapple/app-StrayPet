// Home Tab Content - Banner + Quick Entry + Recommendations
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { Pet } from '../../models/Pet';
import { Lost } from '../../models/Lost';
import { PetService, PetFilter, PetListResult } from '../../services/PetService';
import { LostService, LostFilter, LostListResult } from '../../services/LostService';

@Component
export struct HomeTabContent {
  @State bannerIndex: number = 0;
  @State recommendedPets: Pet[] = [];
  @State recentLostPets: Lost[] = [];
  @State isLoading: boolean = true;

  private petService: PetService = new PetService();
  private lostService: LostService = new LostService();
  private bannerImages: string[] = [
    'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800',
    'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800',
    'https://images.unsplash.com/photo-1425082661705-1834bfd09dca?w=800'
  ];

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.isLoading = true;

    // Load recommended pets
    const petFilter = new PetFilter();
    petFilter.page = 1;
    petFilter.page_size = 4;
    const petResult = await this.petService.getPets(petFilter);
    if (petResult.success) {
      this.recommendedPets = petResult.pets;
    }

    // Load recent lost pets
    const lostFilter = new LostFilter();
    lostFilter.page = 1;
    const lostResult = await this.lostService.getLosts(lostFilter);
    if (lostResult.success) {
      this.recentLostPets = lostResult.losts.slice(0, 3);
    }

    this.isLoading = false;
  }

  @Builder
  QuickEntryItem(icon: Resource, label: string, color: string, action: () => void): void {
    Column() {
      SymbolGlyph(icon)
        .fontSize(28)
        .fontColor([color])

      Text(label)
        .fontSize(12)
        .fontColor('#424242')
        .margin({ top: 6 })
    }
    .width('22%')
    .height(80)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      action();
    })
  }

  navigateTo(route: string): void {
    try {
      router.pushUrl({ url: route });
    } catch (err) {
      console.error('Navigation error', JSON.stringify(err));
    }
  }

  @Builder
  SectionHeader(title: string, actionText: string, onAction: () => void): void {
    Row() {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')

      Blank()

      Text(actionText)
        .fontSize(14)
        .fontColor('#FF6B35')
        .onClick(() => onAction())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 8 })
  }

  @Builder
  PetMiniCard(pet: Pet): void {
    Column() {
      if (pet.cover.length > 0) {
        Image(pet.cover)
          .width('100%')
          .height(100)
          .borderRadius({ topLeft: 10, topRight: 10 })
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('🐾')
            .fontSize(32)
        }
        .width('100%')
        .height(100)
        .borderRadius({ topLeft: 10, topRight: 10 })
        .backgroundColor('#E0E0E0')
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Text(pet.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${pet.species} · ${pet.getAgeString()}`)
          .fontSize(11)
          .fontColor('#757575')
          .margin({ top: 2 })
      }
      .width('100%')
      .padding(8)
      .alignItems(HorizontalAlign.Start)
    }
    .width('48%')
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      try {
        router.pushUrl({
          url: 'pages/PetDetailPage',
          params: { petId: pet.id }
        });
      } catch (err) {
        console.error('Navigation error', JSON.stringify(err));
      }
    })
  }

  @Builder
  LostAlertCard(lost: Lost): void {
    Row() {
      if (lost.photo.length > 0) {
        Image(lost.photo)
          .width(60)
          .height(60)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('🐾')
            .fontSize(24)
        }
        .width(60)
        .height(60)
        .borderRadius(8)
        .backgroundColor('#FFEBEE')
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Row() {
          Text('🚨')
            .fontSize(12)
          Text(lost.pet_name.length > 0 ? lost.pet_name : lost.species)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#D32F2F')
            .margin({ left: 4 })
        }

        Text(`${lost.species} · ${lost.breed.length > 0 ? lost.breed : 'Unknown'}`)
          .fontSize(12)
          .fontColor('#757575')
          .margin({ top: 4 })

        Text(`Lost: ${lost.lost_time.substring(0, 10)}`)
          .fontSize(11)
          .fontColor('#BDBDBD')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })

      if (lost.reward > 0) {
        Text(`$${lost.reward}`)
          .fontSize(12)
          .fontColor('#4CAF50')
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ bottom: 8 })
    .shadow({ radius: 2, color: '#0D000000', offsetX: 0, offsetY: 1 })
  }

  build() {
    Scroll() {
      Column() {
        // Header
        Row() {
          Text('StrayPet')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B35')

          Blank()

          Text('🔔')
            .fontSize(24)
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/NotificationPage' });
              } catch (err) {
                console.error('Navigation error', JSON.stringify(err));
              }
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        // Banner
        Swiper() {
          ForEach(this.bannerImages, (img: string, index: number) => {
            Stack() {
              Image(img)
                .width('100%')
                .height(160)
                .objectFit(ImageFit.Cover)
                .borderRadius(12)

              Column() {
                Text('Give a Stray Pet a Home')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('Help stray pets find their forever home')
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .margin({ top: 4 })
              }
              .padding(16)
            }
            .width('100%')
          })
        }
        .autoPlay(true)
        .interval(4000)
        .indicator(true)
        .indicatorStyle({ selectedColor: '#FF6B35', color: '#FFFFFF' })
        .margin({ left: 16, right: 16, top: 8 })

        // Quick Entry
        Row({ space: 8 }) {
          this.QuickEntryItem($r('sys.symbol.heart_fill'), 'Adopt', '#FF6B35', () => {
            this.navigateTo('pages/AdoptListPage');
          })
          this.QuickEntryItem($r('sys.symbol.magnifyingglass'), 'Lost', '#F44336', () => {
            this.navigateTo('pages/LostListPage');
          })
          this.QuickEntryItem($r('sys.symbol.house_fill'), 'Shelter', '#4CAF50', () => {
            this.navigateTo('pages/ShelterListPage');
          })
          this.QuickEntryItem($r('sys.symbol.doc_text_fill'), 'Blog', '#2196F3', () => {
            this.navigateTo('pages/BlogListPage');
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
        .justifyContent(FlexAlign.SpaceBetween)

        // Second row of quick entry
        Row({ space: 8 }) {
          this.QuickEntryItem($r('sys.symbol.person_2_fill'), 'Foster', '#9C27B0', () => {
            this.navigateTo('pages/HolidayFamilyPage');
          })
          this.QuickEntryItem($r('sys.symbol.plus_circle'), 'Found', '#FF9800', () => {
            this.navigateTo('pages/LostFormPage'); // Navigate to report found pet
          })
          this.QuickEntryItem($r('sys.symbol.gift_fill'), 'Donate', '#E91E63', () => {
            this.navigateTo('pages/DonationFormPage');
          })
          this.QuickEntryItem($r('sys.symbol.questionmark_circle_fill'), 'Help', '#607D8B', () => {
            this.navigateTo('pages/HelpPage');
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12 })
        .justifyContent(FlexAlign.SpaceBetween)

        // Recent Lost Pets Alert
        if (this.recentLostPets.length > 0) {
          this.SectionHeader('Recently Lost', 'View All', () => {
            this.navigateTo('pages/LostListPage');
          })

          Column() {
            ForEach(this.recentLostPets, (lost: Lost) => {
              this.LostAlertCard(lost)
            })
          }
          .padding({ left: 16, right: 16 })
        }

        // Recommended Pets
        this.SectionHeader('Recommended', 'View All', () => {
          this.navigateTo('pages/AdoptListPage');
        })

        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#FF6B35')
            Text('Loading...')
              .fontSize(14)
              .fontColor('#9E9E9E')
              .margin({ top: 8 })
          }
          .width('100%')
          .height(150)
          .justifyContent(FlexAlign.Center)
        } else {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            ForEach(this.recommendedPets, (pet: Pet) => {
              this.PetMiniCard(pet)
            })
          }
          .padding({ left: 16, right: 16 })
        }

        // Bottom spacing
        Blank()
          .height(20)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
    .scrollBar(BarState.Off)
  }
}
