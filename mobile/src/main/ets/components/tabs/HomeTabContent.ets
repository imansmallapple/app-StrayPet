// Home Tab Content - Banner + Quick Entry + Recommendations + Shelters + Blog
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { Pet, Shelter } from '../../models/Pet';
import { Lost } from '../../models/Lost';
import { PetService, PetFilter, PetListResult } from '../../services/PetService';
import { LostService, LostFilter, LostListResult } from '../../services/LostService';
import { ShelterService, ShelterFilter, ShelterListResult } from '../../services/ShelterService';
import { BlogService, BlogArticle, ArticleListResult, ArticleFilter } from '../../services/BlogService';
import { SocialService } from '../../services/SocialService';
import { TokenManager } from '../../services/TokenManager';

@Component
export struct HomeTabContent {
  @State bannerIndex: number = 0;
  @State recommendedPets: Pet[] = [];
  @State recentLostPets: Lost[] = [];
  @State nearbyShelters: Shelter[] = [];
  @State latestArticles: BlogArticle[] = [];
  @State isLoading: boolean = true;
  @State unreadNotificationCount: number = 0;

  // Callback for tab switching
  onSwitchTab: (tabIndex: number) => void = () => {};

  private petService: PetService = new PetService();
  private lostService: LostService = new LostService();
  private shelterService: ShelterService = new ShelterService();
  private blogService: BlogService = new BlogService();
  private socialService: SocialService = new SocialService();
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

    // Wait for TokenManager to be initialized
    await TokenManager.getInstance().waitForInit();

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

    // Load nearby shelters
    const shelterFilter = new ShelterFilter();
    shelterFilter.page = 1;
    shelterFilter.page_size = 5;
    const shelterResult = await this.shelterService.getShelters(shelterFilter);
    if (shelterResult.success) {
      this.nearbyShelters = shelterResult.shelters.slice(0, 5);
    }

    // Load latest blog articles
    const articleFilter = new ArticleFilter();
    articleFilter.page = 1;
    articleFilter.page_size = 3;
    const articleResult = await this.blogService.getArticles(articleFilter);
    if (articleResult.success) {
      this.latestArticles = articleResult.articles;
    }

    // Load unread notification count if logged in
    if (TokenManager.getInstance().getAccessToken().length > 0) {
      const notifResult = await this.socialService.getNotifications(1, 1);
      if (notifResult.success) {
        this.unreadNotificationCount = notifResult.unread_count;
      }
    }

    this.isLoading = false;
  }

  @Builder
  QuickEntryItem(icon: Resource, label: string, color: string, action: () => void): void {
    Column() {
      Column() {
        SymbolGlyph(icon)
          .fontSize(24)
          .fontColor(['#FFFFFF'])
      }
      .width(48)
      .height(48)
      .backgroundColor(color)
      .borderRadius(24)
      .justifyContent(FlexAlign.Center)

      Text(label)
        .fontSize(11)
        .fontColor('#424242')
        .margin({ top: 6 })
    }
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

      Row() {
        Text(actionText)
          .fontSize(14)
          .fontColor('#FF6B35')
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(14)
          .fontColor(['#FF6B35'])
      }
      .onClick(() => onAction())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20, bottom: 12 })
  }

  @Builder
  PetMiniCard(pet: Pet): void {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        if (pet.cover.length > 0) {
          Image(pet.cover)
            .width('100%')
            .height(110)
            .borderRadius({ topLeft: 12, topRight: 12 })
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text('🐾')
              .fontSize(36)
          }
          .width('100%')
          .height(110)
          .borderRadius({ topLeft: 12, topRight: 12 })
          .backgroundColor('#E8E8E8')
          .justifyContent(FlexAlign.Center)
        }

        // Gender badge with semi-transparent background
        Row() {
          Text(pet.sex === 'male' ? '♂' : '♀')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(pet.sex === 'male' ? '#1976D2' : '#C2185B')
        }
        .width(24)
        .height(24)
        .backgroundColor('#FFFFFFDD')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8, right: 8 })
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
          .margin({ top: 4 })
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 8, bottom: 10 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('48%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 6, color: '#1A000000', offsetX: 0, offsetY: 2 })
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
          .width(70)
          .height(70)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('🐾')
            .fontSize(28)
        }
        .width(70)
        .height(70)
        .borderRadius(10)
        .backgroundColor('#FFEBEE')
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Row() {
          Text(lost.pet_name.length > 0 ? lost.pet_name : lost.species)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#D32F2F')
            .layoutWeight(1)

          Text(lost.getStatusDisplay())
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor(lost.getStatusColor())
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        }
        .width('100%')

        Text(`${lost.species} · ${lost.breed.length > 0 ? lost.breed : 'Unknown breed'}`)
          .fontSize(12)
          .fontColor('#757575')
          .margin({ top: 6 })

        Row() {
          SymbolGlyph($r('sys.symbol.calendar'))
            .fontSize(12)
            .fontColor(['#9E9E9E'])
          Text(lost.lost_time.substring(0, 10))
            .fontSize(11)
            .fontColor('#9E9E9E')
            .margin({ left: 4 })

          if (lost.reward > 0) {
            Blank()
            Text(`Reward: $${lost.reward}`)
              .fontSize(11)
              .fontColor('#4CAF50')
              .fontWeight(FontWeight.Medium)
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
    .margin({ bottom: 10 })
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
  ShelterCard(shelter: Shelter): void {
    Row() {
      // Logo
      if (shelter.logo.length > 0) {
        Image(shelter.logo)
          .width(56)
          .height(56)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.house_fill'))
            .fontSize(24)
            .fontColor(['#4CAF50'])
        }
        .width(56)
        .height(56)
        .borderRadius(12)
        .backgroundColor('#E8F5E9')
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Row() {
          Text(shelter.name)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#212121')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (shelter.is_verified) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(14)
              .fontColor(['#4CAF50'])
          }
        }
        .width('100%')

        if (shelter.address !== null) {
          Text(shelter.address.city.length > 0 ? shelter.address.city : shelter.address.getFullAddress())
            .fontSize(12)
            .fontColor('#757575')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }

        Row() {
          SymbolGlyph($r('sys.symbol.pawprint_fill'))
            .fontSize(12)
            .fontColor(['#FF6B35'])
          Text(`${shelter.current_animals} pets`)
            .fontSize(11)
            .fontColor('#FF6B35')
            .margin({ left: 4 })
        }
        .margin({ top: 6 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })
    }
    .width(220)
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
    .margin({ right: 12 })
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

  @Builder
  BlogCard(article: BlogArticle): void {
    Row() {
      // Cover image
      if (article.cover.length > 0) {
        Image(article.cover)
          .width(100)
          .height(80)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.doc_text_fill'))
            .fontSize(28)
            .fontColor(['#2196F3'])
        }
        .width(100)
        .height(80)
        .borderRadius(10)
        .backgroundColor('#E3F2FD')
        .justifyContent(FlexAlign.Center)
      }

      Column() {
        Text(article.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        Row() {
          if (article.author !== null) {
            Text(article.author.username)
              .fontSize(11)
              .fontColor('#757575')
          }
          Blank()
          Text(article.getFormattedDate())
            .fontSize(11)
            .fontColor('#9E9E9E')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .height(80)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 10 })
    .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      try {
        router.pushUrl({
          url: 'pages/BlogDetailPage',
          params: { articleId: article.id }
        });
      } catch (err) {
        console.error('Navigation error', JSON.stringify(err));
      }
    })
  }

  build() {
    Scroll() {
      Column() {
        // Header
        Row() {
          Column() {
            Text('StrayPet')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF6B35')
            Text('Find your perfect companion')
              .fontSize(12)
              .fontColor('#9E9E9E')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Stack() {
            Row() {
              SymbolGlyph($r('sys.symbol.bell_fill'))
                .fontSize(22)
                .fontColor(['#424242'])
            }
            .width(40)
            .height(40)
            .backgroundColor('#F5F5F5')
            .borderRadius(20)
            .justifyContent(FlexAlign.Center)

            // Unread notification badge
            if (this.unreadNotificationCount > 0) {
              Text(this.unreadNotificationCount > 99 ? '99+' : this.unreadNotificationCount.toString())
                .fontSize(10)
                .fontColor('#FFFFFF')
                .backgroundColor('#F44336')
                .borderRadius(10)
                .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                .position({ x: '60%', y: 0 })
            }
          }
          .width(40)
          .height(40)
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

        // Quick Entry - Row 1
        Row() {
          this.QuickEntryItem($r('sys.symbol.heart_fill'), 'Adopt', '#FF6B35', () => {
            this.navigateTo('pages/AdoptListPage');
          })
          this.QuickEntryItem($r('sys.symbol.magnifyingglass'), 'Lost', '#F44336', () => {
            this.navigateTo('pages/LostListPage');
          })
          this.QuickEntryItem($r('sys.symbol.house_fill'), 'Shelter', '#4CAF50', () => {
            this.navigateTo('pages/ShelterListPage');
          })
          this.QuickEntryItem($r('sys.symbol.person_2_fill'), 'Foster', '#9C27B0', () => {
            this.navigateTo('pages/HolidayFamilyPage');
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20 })
        .justifyContent(FlexAlign.SpaceAround)

        // Quick Entry - Row 2
        Row() {
          this.QuickEntryItem($r('sys.symbol.doc_text_fill'), 'Blog', '#2196F3', () => {
            this.navigateTo('pages/BlogListPage');
          })
          this.QuickEntryItem($r('sys.symbol.message_fill'), 'Message', '#00BCD4', () => {
            this.onSwitchTab(3); // Switch to Messages tab
          })
          this.QuickEntryItem($r('sys.symbol.person_crop_circle_fill'), 'Profile', '#795548', () => {
            this.onSwitchTab(4); // Switch to Profile tab
          })
          this.QuickEntryItem($r('sys.symbol.questionmark_circle_fill'), 'Help', '#607D8B', () => {
            this.navigateTo('pages/HelpPage');
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })
        .justifyContent(FlexAlign.SpaceAround)

        // Recent Lost Pets Alert
        if (this.recentLostPets.length > 0) {
          this.SectionHeader('🚨 Lost Pets Alert', 'View All', () => {
            this.navigateTo('pages/LostListPage');
          })

          Column() {
            ForEach(this.recentLostPets, (lost: Lost) => {
              this.LostAlertCard(lost)
            })
          }
          .padding({ left: 16, right: 16 })
        }

        // Nearby Shelters - Horizontal scroll
        if (this.nearbyShelters.length > 0) {
          this.SectionHeader('Nearby Shelters', 'View All', () => {
            this.navigateTo('pages/ShelterListPage');
          })

          Scroll() {
            Row() {
              ForEach(this.nearbyShelters, (shelter: Shelter) => {
                this.ShelterCard(shelter)
              })
            }
            .padding({ left: 16, right: 16 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }

        // Recommended Pets
        this.SectionHeader('Pets for Adoption', 'View All', () => {
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
              Column() {
                this.PetMiniCard(pet)
              }
              .margin({ bottom: 12 })
            })
          }
          .padding({ left: 16, right: 16 })
        }

        // Latest Blog Articles
        if (this.latestArticles.length > 0) {
          this.SectionHeader('Pet Care Tips', 'View All', () => {
            this.navigateTo('pages/BlogListPage');
          })

          Column() {
            ForEach(this.latestArticles, (article: BlogArticle) => {
              this.BlogCard(article)
            })
          }
          .padding({ left: 16, right: 16 })
        }

        // Bottom spacing
        Blank()
          .height(24)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
    .scrollBar(BarState.Off)
  }
}
