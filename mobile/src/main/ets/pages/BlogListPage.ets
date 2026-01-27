// Blog List Page
import { router } from '@kit.ArkUI';
import { LoadingView, EmptyView, ErrorView } from '../components/CommonViews';
import { BlogService, BlogArticle, ArticleFilter } from '../services/BlogService';

@Entry
@Component
struct BlogListPage {
  @State articles: BlogArticle[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  private blogService: BlogService = new BlogService();

  aboutToAppear(): void {
    this.loadArticles();
  }

  async loadArticles(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    const filter = new ArticleFilter();
    filter.page = 1;
    filter.page_size = 50;

    const result = await this.blogService.getArticles(filter);

    if (result.success) {
      this.articles = result.articles;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  @Builder
  ArticleCard(article: BlogArticle): void {
    Row() {
      // Cover image
      if (article.cover.length > 0) {
        Image(article.cover)
          .width(100)
          .height(80)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.doc_text_fill'))
            .fontSize(24)
            .fontColor(['#2196F3'])
        }
        .width(100)
        .height(80)
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
              .fontSize(12)
              .fontColor(['#9E9E9E'])
            Text(` ${article.author.username}`)
              .fontSize(12)
              .fontColor('#9E9E9E')
          }
          .margin({ top: 4 })
        }

        Row() {
          Row() {
            SymbolGlyph($r('sys.symbol.doc_text_fill'))
              .fontSize(12)
              .fontColor(['#9E9E9E'])
            Text(` ${article.count} views`)
              .fontSize(12)
              .fontColor('#9E9E9E')
          }

          Text(article.getFormattedDate())
            .fontSize(12)
            .fontColor('#BDBDBD')
            .margin({ left: 16 })
        }
        .margin({ top: 8 })
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
          url: 'pages/BlogDetailPage',
          params: { articleId: article.id }
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
        .onClick(() => { router.back(); })

        Text('Blog')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2196F3')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 12, bottom: 12 })

      // Content
      if (this.isLoading) {
        LoadingView({ message: 'Loading...' })
          .layoutWeight(1)
      } else if (this.hasError) {
        ErrorView({
          message: this.errorMessage,
          onRetry: () => {
            this.loadArticles();
          }
        })
          .layoutWeight(1)
      } else if (this.articles.length === 0) {
        EmptyView({
          title: 'No Articles',
          subtitle: 'Check back later'
        })
          .layoutWeight(1)
      } else {
        List({ space: 12 }) {
          ForEach(this.articles, (article: BlogArticle) => {
            ListItem() {
              this.ArticleCard(article)
            }
            .padding({ left: 16, right: 16 })
          })
        }
        .layoutWeight(1)
        .padding({ top: 8, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
