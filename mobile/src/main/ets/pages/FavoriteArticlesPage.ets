// Favorite Articles Page
import { router } from '@kit.ArkUI';
import { BlogService, BlogArticle } from '../services/BlogService';
import { TokenManager } from '../services/TokenManager';

@Entry
@Component
struct FavoriteArticlesPage {
  @State articles: BlogArticle[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State isLoggedIn: boolean = false;

  private blogService: BlogService = new BlogService();

  aboutToAppear(): void {
    this.isLoggedIn = TokenManager.getInstance().isLoggedIn();
    if (this.isLoggedIn) {
      this.loadFavoriteArticles();
    } else {
      this.isLoading = false;
    }
  }

  onPageShow(): void {
    // Refresh when page becomes visible
    if (this.isLoggedIn) {
      this.loadFavoriteArticles();
    }
  }

  async loadFavoriteArticles(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    const result = await this.blogService.getFavoriteArticles();

    if (result.success) {
      this.articles = result.articles;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  formatDate(dateStr: string): string {
    if (dateStr.length === 0) return '';
    const date = new Date(dateStr);
    const options: Intl.DateTimeFormatOptions = {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    };
    return date.toLocaleDateString('en-US', options);
  }

  @Builder
  ArticleItem(article: BlogArticle): void {
    Row() {
      // Cover image
      if (article.cover.length > 0) {
        Image(article.cover)
          .width(80)
          .height(80)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.doc_text'))
            .fontSize(32)
            .fontColor(['#BDBDBD'])
        }
        .width(80)
        .height(80)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .justifyContent(FlexAlign.Center)
      }

      // Article info
      Column() {
        Text(article.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(article.excerpt)
          .fontSize(13)
          .fontColor('#757575')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 4 })

        Row() {
          if (article.author !== null) {
            Text(article.author.username)
              .fontSize(12)
              .fontColor('#9E9E9E')
          }

          Text(this.formatDate(article.pub_date))
            .fontSize(12)
            .fontColor('#9E9E9E')
            .margin({ left: article.author !== null ? 12 : 0 })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/BlogDetailPage',
        params: { articleId: article.id }
      });
    })
  }

  build() {
    Column() {
      // Header
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#424242'])
          .onClick(() => { router.back(); })

        Text('Favorite Articles')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })

        Blank()

        if (this.articles.length > 0) {
          Text(`${this.articles.length} articles`)
            .fontSize(14)
            .fontColor('#9E9E9E')
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      if (!this.isLoggedIn) {
        // Not logged in state
        Column() {
          SymbolGlyph($r('sys.symbol.person_fill'))
            .fontSize(64)
            .fontColor(['#BDBDBD'])

          Text('Please Login')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#757575')
            .margin({ top: 16 })

          Text('Login to view your favorite articles')
            .fontSize(14)
            .fontColor('#9E9E9E')
            .margin({ top: 8 })

          Button('Login')
            .width(120)
            .height(40)
            .backgroundColor('#FF6B35')
            .fontColor('#FFFFFF')
            .fontSize(14)
            .borderRadius(20)
            .margin({ top: 24 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/LoginPage' });
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.isLoading) {
        // Loading state
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#FF6B35')

          Text('Loading...')
            .fontSize(14)
            .fontColor('#9E9E9E')
            .margin({ top: 16 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        // Error state
        Column() {
          SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
            .fontSize(64)
            .fontColor(['#F44336'])

          Text('Failed to load')
            .fontSize(16)
            .fontColor('#757575')
            .margin({ top: 16 })

          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#9E9E9E')
            .margin({ top: 8 })

          Button('Retry')
            .width(100)
            .height(36)
            .backgroundColor('#FF6B35')
            .fontColor('#FFFFFF')
            .fontSize(14)
            .borderRadius(18)
            .margin({ top: 16 })
            .onClick(() => {
              this.loadFavoriteArticles();
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.articles.length === 0) {
        // Empty state
        Column() {
          SymbolGlyph($r('sys.symbol.bookmark'))
            .fontSize(64)
            .fontColor(['#BDBDBD'])

          Text('No Favorites Yet')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#757575')
            .margin({ top: 16 })

          Text('Articles you favorite will appear here')
            .fontSize(14)
            .fontColor('#9E9E9E')
            .margin({ top: 8 })

          Button('Browse Articles')
            .width(140)
            .height(40)
            .backgroundColor('#FF6B35')
            .fontColor('#FFFFFF')
            .fontSize(14)
            .borderRadius(20)
            .margin({ top: 24 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/BlogListPage' });
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // Article list
        List({ space: 12 }) {
          ForEach(this.articles, (article: BlogArticle) => {
            ListItem() {
              this.ArticleItem(article)
            }
          })
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
