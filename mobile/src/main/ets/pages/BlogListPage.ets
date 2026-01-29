// Blog List Page
import { router } from '@kit.ArkUI';
import { LoadingView, EmptyView, ErrorView } from '../components/CommonViews';
import { BlogService, BlogArticle, ArticleFilter, BlogTag, ArchiveItem } from '../services/BlogService';

// Sort option enum
enum SortOption {
  LATEST = '-pub_date',
  OLDEST = 'pub_date',
  MOST_VIEWED = '-count'
}

@Entry
@Component
struct BlogListPage {
  @State articles: BlogArticle[] = [];
  @State filteredArticles: BlogArticle[] = [];
  @State tags: BlogTag[] = [];
  @State archives: ArchiveItem[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';

  // Filter states
  @State searchText: string = '';
  @State selectedSortOption: SortOption = SortOption.LATEST;
  @State selectedTagId: number = 0; // 0 means all
  @State selectedArchive: string = ''; // Empty means all
  @State showSortMenu: boolean = false;
  @State showArchivePanel: boolean = false;

  private blogService: BlogService = new BlogService();

  aboutToAppear(): void {
    this.loadData();
  }

  // Helper method to extract tag name from "id:name" format
  getTagName(tag: string): string {
    const colonIndex = tag.indexOf(':');
    if (colonIndex >= 0 && colonIndex < tag.length - 1) {
      return tag.substring(colonIndex + 1);
    }
    return tag;
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    // Load articles and tags in parallel
    const filter = new ArticleFilter();
    filter.page = 1;
    filter.page_size = 100;
    filter.ordering = this.selectedSortOption;

    const articlesResult = await this.blogService.getArticles(filter);
    const tagsResult = await this.blogService.getTags();

    if (articlesResult.success) {
      this.articles = articlesResult.articles;
      this.archives = this.blogService.generateArchives(this.articles);
      this.applyFilters();
    } else {
      this.hasError = true;
      this.errorMessage = articlesResult.errorMessage;
    }

    if (tagsResult.success) {
      this.tags = tagsResult.tags;
    }

    this.isLoading = false;
  }

  applyFilters(): void {
    let result = this.articles;

    // Apply search filter
    if (this.searchText.length > 0) {
      const searchLower = this.searchText.toLowerCase();
      result = result.filter((article: BlogArticle) => {
        return article.title.toLowerCase().includes(searchLower) ||
               (article.excerpt.length > 0 && article.excerpt.toLowerCase().includes(searchLower));
      });
    }

    // Apply tag filter
    if (this.selectedTagId > 0) {
      result = result.filter((article: BlogArticle) => {
        return article.tags.some((tag: string) => {
          // Tag format is "id:name"
          const parts = tag.split(':');
          if (parts.length >= 1) {
            return parseInt(parts[0]) === this.selectedTagId;
          }
          return false;
        });
      });
    }

    // Apply archive filter
    if (this.selectedArchive.length > 0) {
      const parts = this.selectedArchive.split('-');
      if (parts.length === 2) {
        const filterYear = parseInt(parts[0]);
        const filterMonth = parseInt(parts[1]);
        result = result.filter((article: BlogArticle) => {
          if (article.pub_date.length > 0) {
            const date = new Date(article.pub_date);
            return date.getFullYear() === filterYear && (date.getMonth() + 1) === filterMonth;
          }
          return false;
        });
      }
    }

    // Apply sorting
    result = this.sortArticles(result);

    this.filteredArticles = result;
  }

  sortArticles(articles: BlogArticle[]): BlogArticle[] {
    const sorted = [...articles];
    sorted.sort((a: BlogArticle, b: BlogArticle) => {
      switch (this.selectedSortOption) {
        case SortOption.OLDEST:
          return new Date(a.pub_date).getTime() - new Date(b.pub_date).getTime();
        case SortOption.MOST_VIEWED:
          return b.count - a.count;
        default: // LATEST
          return new Date(b.pub_date).getTime() - new Date(a.pub_date).getTime();
      }
    });
    return sorted;
  }

  getSortLabel(): string {
    switch (this.selectedSortOption) {
      case SortOption.OLDEST:
        return 'Oldest';
      case SortOption.MOST_VIEWED:
        return 'Most Viewed';
      default:
        return 'Latest';
    }
  }

  @Builder
  SearchBar(): void {
    Row() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(18)
        .fontColor(['#9E9E9E'])
        .margin({ right: 8 })

      TextInput({ placeholder: 'Search articles...', text: this.searchText })
        .layoutWeight(1)
        .height(36)
        .backgroundColor(Color.Transparent)
        .placeholderColor('#9E9E9E')
        .placeholderFont({ size: 14 })
        .fontSize(14)
        .fontColor('#212121')
        .onChange((value: string) => {
          this.searchText = value;
          this.applyFilters();
        })

      if (this.searchText.length > 0) {
        SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
          .fontSize(18)
          .fontColor(['#9E9E9E'])
          .onClick(() => {
            this.searchText = '';
            this.applyFilters();
          })
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#F5F5F5')
    .borderRadius(22)
  }

  @Builder
  SortButton(): void {
    Row() {
      Text(this.getSortLabel())
        .fontSize(13)
        .fontColor('#2196F3')
        .fontWeight(FontWeight.Medium)

      SymbolGlyph($r('sys.symbol.chevron_down'))
        .fontSize(14)
        .fontColor(['#2196F3'])
        .margin({ left: 4 })
    }
    .height(32)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#E3F2FD')
    .borderRadius(16)
    .onClick(() => {
      this.showSortMenu = !this.showSortMenu;
    })
  }

  @Builder
  SortMenu(): void {
    Column() {
      this.SortMenuItem('Latest', SortOption.LATEST)
      this.SortMenuItem('Oldest', SortOption.OLDEST)
      this.SortMenuItem('Most Viewed', SortOption.MOST_VIEWED)
    }
    .width(140)
    .padding(8)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#33000000', offsetX: 0, offsetY: 4 })
  }

  @Builder
  SortMenuItem(label: string, option: SortOption): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(this.selectedSortOption === option ? '#2196F3' : '#424242')
        .fontWeight(this.selectedSortOption === option ? FontWeight.Medium : FontWeight.Normal)

      if (this.selectedSortOption === option) {
        Blank()
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(14)
          .fontColor(['#2196F3'])
      }
    }
    .width('100%')
    .height(40)
    .padding({ left: 12, right: 12 })
    .borderRadius(8)
    .backgroundColor(this.selectedSortOption === option ? '#E3F2FD' : Color.Transparent)
    .onClick(() => {
      this.selectedSortOption = option;
      this.showSortMenu = false;
      this.applyFilters();
    })
  }

  @Builder
  TagChips(): void {
    Scroll() {
      Row({ space: 8 }) {
        // All tags chip
        this.TagChip('All', 0)

        ForEach(this.tags, (tag: BlogTag) => {
          this.TagChip(tag.name, tag.id)
        })
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  TagChip(name: string, id: number): void {
    Text(name)
      .fontSize(13)
      .fontColor(this.selectedTagId === id ? '#FFFFFF' : '#616161')
      .fontWeight(FontWeight.Medium)
      .height(30)
      .padding({ left: 14, right: 14 })
      .backgroundColor(this.selectedTagId === id ? '#2196F3' : '#EEEEEE')
      .borderRadius(15)
      .onClick(() => {
        this.selectedTagId = id;
        this.applyFilters();
      })
  }

  @Builder
  ArchiveSection(): void {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.folder_fill'))
          .fontSize(18)
          .fontColor(['#FF9800'])
          .margin({ right: 8 })

        Text('Archives')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#424242')

        Blank()

        SymbolGlyph(this.showArchivePanel ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
          .fontSize(16)
          .fontColor(['#9E9E9E'])
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: this.showArchivePanel ? 0 : 12, bottomRight: this.showArchivePanel ? 0 : 12 })
      .onClick(() => {
        this.showArchivePanel = !this.showArchivePanel;
      })

      if (this.showArchivePanel) {
        Column() {
          // All archives option
          this.ArchiveItem('All Articles', '', this.articles.length)

          ForEach(this.archives, (archive: ArchiveItem) => {
            this.ArchiveItem(archive.label, `${archive.year}-${archive.month}`, archive.count)
          })
        }
        .width('100%')
        .padding({ left: 8, right: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')
        .borderRadius({ bottomLeft: 12, bottomRight: 12 })
      }
    }
  }

  @Builder
  ArchiveItem(label: string, key: string, count: number): void {
    Row() {
      SymbolGlyph($r('sys.symbol.doc_text'))
        .fontSize(14)
        .fontColor([this.selectedArchive === key ? '#2196F3' : '#9E9E9E'])
        .margin({ right: 8 })

      Text(label)
        .fontSize(14)
        .fontColor(this.selectedArchive === key ? '#2196F3' : '#616161')
        .fontWeight(this.selectedArchive === key ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1)

      Text(`${count}`)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .backgroundColor(this.selectedArchive === key ? '#2196F3' : '#BDBDBD')
        .borderRadius(10)
    }
    .width('100%')
    .height(40)
    .padding({ left: 12, right: 12 })
    .borderRadius(8)
    .backgroundColor(this.selectedArchive === key ? '#E3F2FD' : Color.Transparent)
    .onClick(() => {
      this.selectedArchive = key;
      this.showArchivePanel = false;
      this.applyFilters();
    })
  }

  @Builder
  ArticleCard(article: BlogArticle): void {
    Column() {
      Row() {
        // Cover image
        if (article.cover.length > 0) {
          Image(article.cover)
            .width(90)
            .height(70)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
        } else {
          Column() {
            SymbolGlyph($r('sys.symbol.doc_text_fill'))
              .fontSize(24)
              .fontColor(['#2196F3'])
          }
          .width(90)
          .height(70)
          .backgroundColor('#E3F2FD')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        }

        Column() {
          Text(article.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (article.author !== null) {
            Row() {
              SymbolGlyph($r('sys.symbol.person_fill'))
                .fontSize(11)
                .fontColor(['#9E9E9E'])
              Text(` ${article.author.username}`)
                .fontSize(11)
                .fontColor('#9E9E9E')
            }
            .margin({ top: 4 })
          }

          Row() {
            Row() {
              SymbolGlyph($r('sys.symbol.eye'))
                .fontSize(11)
                .fontColor(['#9E9E9E'])
              Text(` ${article.count}`)
                .fontSize(11)
                .fontColor('#9E9E9E')
            }

            Text(article.getFormattedDate())
              .fontSize(11)
              .fontColor('#BDBDBD')
              .margin({ left: 12 })
          }
          .margin({ top: 6 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 12 })
      }
      .width('100%')

      // Tags row
      if (article.tags.length > 0) {
        Row({ space: 6 }) {
          ForEach(article.tags.slice(0, 3), (tag: string) => {
            Text(this.getTagName(tag))
              .fontSize(10)
              .fontColor('#2196F3')
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor('#E3F2FD')
              .borderRadius(10)
          })
        }
        .width('100%')
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
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

  @Builder
  FilterSummary(): void {
    if (this.selectedTagId > 0 || this.selectedArchive.length > 0 || this.searchText.length > 0) {
      Row({ space: 8 }) {
        Text(`${this.filteredArticles.length} results`)
          .fontSize(12)
          .fontColor('#757575')

        if (this.selectedTagId > 0 || this.selectedArchive.length > 0 || this.searchText.length > 0) {
          Text('Clear filters')
            .fontSize(12)
            .fontColor('#2196F3')
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.selectedTagId = 0;
              this.selectedArchive = '';
              this.searchText = '';
              this.applyFilters();
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 4 })
    }
  }

  build() {
    Stack() {
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
          .onClick(() => { router.back(); })

          Text('Blog')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
            .margin({ left: 8 })

          Blank()

          // Sort button
          this.SortButton()
        }
        .width('100%')
        .padding({ left: 8, right: 16, top: 12, bottom: 8 })

        // Search bar
        Row() {
          this.SearchBar()
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 4 })

        // Content
        if (this.isLoading) {
          LoadingView({ message: 'Loading...' })
            .layoutWeight(1)
        } else if (this.hasError) {
          ErrorView({
            message: this.errorMessage,
            onRetry: () => {
              this.loadData();
            }
          })
            .layoutWeight(1)
        } else {
          Scroll() {
            Column() {
              // Archive section
              Column() {
                this.ArchiveSection()
              }
              .width('100%')
              .padding({ left: 16, right: 16 })

              // Filter summary
              this.FilterSummary()

              // Articles list
              if (this.filteredArticles.length === 0) {
                EmptyView({
                  title: 'No Articles Found',
                  subtitle: 'Try adjusting your filters'
                })
                  .height(300)
              } else {
                Column({ space: 12 }) {
                  ForEach(this.filteredArticles, (article: BlogArticle) => {
                    Column() {
                      this.ArticleCard(article)
                    }
                    .padding({ left: 16, right: 16 })
                  })
                }
                .padding({ bottom: 24 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .align(Alignment.Top)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')

      // Sort menu overlay
      if (this.showSortMenu) {
        Column() {
          Column()
            .width('100%')
            .height('100%')
            .onClick(() => {
              this.showSortMenu = false;
            })
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })

        Column() {
          this.SortMenu()
        }
        .position({ right: 16, top: 60 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
