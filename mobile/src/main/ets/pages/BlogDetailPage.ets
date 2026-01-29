// Blog Detail Page
import { router, promptAction } from '@kit.ArkUI';
import { LoadingView, ErrorView } from '../components/CommonViews';
import { BlogService, BlogArticle, BlogComment } from '../services/BlogService';
import { TokenManager } from '../services/TokenManager';

interface RouterParams {
  articleId: number;
}

@Entry
@Component
struct BlogDetailPage {
  @State article: BlogArticle | null = null;
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State isFavorited: boolean = false;
  @State commentText: string = '';
  @State commentCount: number = 0;
  @State comments: BlogComment[] = [];
  @State isLoggedIn: boolean = false;
  @State isPostingComment: boolean = false;

  private blogService: BlogService = new BlogService();
  private articleId: number = 0;

  aboutToAppear(): void {
    this.isLoggedIn = TokenManager.getInstance().isLoggedIn();
    const params = router.getParams() as RouterParams;
    if (params && params.articleId) {
      this.articleId = params.articleId;
      this.loadArticle();
      this.loadComments();
    } else {
      this.hasError = true;
      this.errorMessage = 'No article ID provided';
      this.isLoading = false;
    }
  }

  async loadArticle(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    const result = await this.blogService.getArticleDetail(this.articleId);

    if (result.success && result.article) {
      this.article = result.article;
      this.isFavorited = result.article.is_favorited;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  async loadComments(): Promise<void> {
    const result = await this.blogService.getComments(this.articleId);
    if (result.success) {
      this.comments = result.comments;
      this.commentCount = result.count;
    }
  }

  async postComment(): Promise<void> {
    if (this.commentText.trim().length === 0) {
      promptAction.showToast({ message: 'Please enter a comment', duration: 2000 });
      return;
    }

    this.isPostingComment = true;

    const result = await this.blogService.postComment(this.articleId, this.commentText.trim());

    if (result.success) {
      this.commentText = '';
      promptAction.showToast({ message: 'Comment posted successfully', duration: 2000 });
      // Reload comments
      await this.loadComments();
    } else {
      promptAction.showToast({ message: result.errorMessage || 'Failed to post comment', duration: 2000 });
    }

    this.isPostingComment = false;
  }

  async toggleFavorite(): Promise<void> {
    // Toggle favorite state (TODO: implement API call)
    this.isFavorited = !this.isFavorited;
  }

  // Helper method to extract tag name from "id:name" format
  getTagName(tag: string): string {
    const colonIndex = tag.indexOf(':');
    if (colonIndex >= 0 && colonIndex < tag.length - 1) {
      return tag.substring(colonIndex + 1);
    }
    return tag;
  }

  formatDate(dateStr: string): string {
    if (dateStr.length === 0) return '';
    const date = new Date(dateStr);
    const options: Intl.DateTimeFormatOptions = {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    };
    return date.toLocaleDateString('en-US', options);
  }

  // Get tag color based on tag name
  getTagColor(tag: string): string {
    const name = this.getTagName(tag).toLowerCase();
    if (name.includes('cat')) return '#FF6B6B';
    if (name.includes('dog')) return '#4ECDC4';
    if (name.includes('adoption')) return '#45B7D1';
    if (name.includes('pet care')) return '#96CEB4';
    if (name.includes('health')) return '#FFEAA7';
    if (name.includes('training')) return '#DDA0DD';
    if (name.includes('news')) return '#98D8C8';
    return '#E3F2FD';
  }

  getTagTextColor(tag: string): string {
    const name = this.getTagName(tag).toLowerCase();
    if (name.includes('health')) return '#856404';
    return '#FFFFFF';
  }

  @Builder
  HeroHeader(): void {
    // Dark header with title
    Column() {
      // Back button row
      Row() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor(['#FFFFFF'])
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { router.back(); })

        Blank()

        // Star (Favorite) button
        Row() {
          SymbolGlyph(this.isFavorited ? $r('sys.symbol.star_fill') : $r('sys.symbol.star'))
            .fontSize(22)
            .fontColor([this.isFavorited ? '#FFD700' : '#FFFFFF'])
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.toggleFavorite();
        })
      }
      .width('100%')
      .padding({ left: 8, right: 8 })

      // Title
      Text(this.article!.title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 20 })
        .lineHeight(32)
    }
    .width('100%')
    .backgroundColor('#1A2332')
  }

  @Builder
  ContentCard(): void {
    Column() {
      // Article content
      Text(this.article!.content.length > 0 ? this.article!.content : this.article!.excerpt)
        .fontSize(15)
        .fontColor('#424242')
        .lineHeight(22)
        .width('100%')

      Divider()
        .color('#F0F0F0')
        .margin({ top: 16, bottom: 16 })

      // Author info
      if (this.article!.author !== null) {
        Row() {
          // Avatar placeholder
          Column() {
            if (this.article!.author.avatar.length > 0) {
              Image(this.article!.author.avatar)
                .width(40)
                .height(40)
                .borderRadius(20)
            } else {
              Text(this.article!.author.username.charAt(0).toUpperCase())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
            }
          }
          .width(40)
          .height(40)
          .backgroundColor('#FF9800')
          .borderRadius(20)
          .justifyContent(FlexAlign.Center)

          Text(this.article!.author.username)
            .fontSize(15)
            .fontColor('#FF9800')
            .fontWeight(FontWeight.Medium)
            .margin({ left: 12 })
        }
        .width('100%')
      }

      // Date and views row
      Row() {
        // Date
        Row() {
          SymbolGlyph($r('sys.symbol.calendar'))
            .fontSize(14)
            .fontColor(['#9E9E9E'])

          Text(this.formatDate(this.article!.pub_date))
            .fontSize(13)
            .fontColor('#757575')
            .margin({ left: 6 })
        }

        // Views
        Row() {
          SymbolGlyph($r('sys.symbol.eye'))
            .fontSize(14)
            .fontColor(['#9E9E9E'])

          Text(`${this.article!.count} views`)
            .fontSize(13)
            .fontColor('#757575')
            .margin({ left: 6 })
        }
        .margin({ left: 20 })
      }
      .width('100%')
      .margin({ top: 12 })

      // Tags
      if (this.article!.tags.length > 0) {
        Row({ space: 8 }) {
          ForEach(this.article!.tags, (tag: string) => {
            Text(this.getTagName(tag))
              .fontSize(12)
              .fontColor(this.getTagTextColor(tag))
              .fontWeight(FontWeight.Medium)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(this.getTagColor(tag))
              .borderRadius(14)
          })
        }
        .width('100%')
        .margin({ top: 16 })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  CommentItem(comment: BlogComment): void {
    Column() {
      Row() {
        // User avatar
        Column() {
          if (comment.user !== null && comment.user.avatar.length > 0) {
            Image(comment.user.avatar)
              .width(36)
              .height(36)
              .borderRadius(18)
          } else {
            Text(comment.user !== null ? comment.user.username.charAt(0).toUpperCase() : '?')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
        }
        .width(36)
        .height(36)
        .backgroundColor('#FF9800')
        .borderRadius(18)
        .justifyContent(FlexAlign.Center)

        Column() {
          Text(comment.user !== null ? comment.user.username : 'Unknown')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#424242')

          Text(comment.getFormattedDate())
            .fontSize(11)
            .fontColor('#9E9E9E')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')

      Text(comment.content)
        .fontSize(14)
        .fontColor('#424242')
        .lineHeight(20)
        .width('100%')
        .margin({ top: 8 })

      // Show replies if any
      if (comment.replies.length > 0) {
        Column() {
          ForEach(comment.replies, (reply: BlogComment) => {
            Column() {
              Row() {
                Column() {
                  Text(reply.user !== null ? reply.user.username.charAt(0).toUpperCase() : '?')
                    .fontSize(12)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                }
                .width(28)
                .height(28)
                .backgroundColor('#2196F3')
                .borderRadius(14)
                .justifyContent(FlexAlign.Center)

                Column() {
                  Text(reply.user !== null ? reply.user.username : 'Unknown')
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#424242')
                }
                .margin({ left: 8 })
              }

              Text(reply.content)
                .fontSize(13)
                .fontColor('#616161')
                .lineHeight(18)
                .width('100%')
                .margin({ top: 4 })
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ top: 8 })
          })
        }
        .width('100%')
        .margin({ top: 8, left: 46 })
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  CommentsSection(): void {
    Column() {
      // Comments header
      Row() {
        Text('Comments')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A2332')

        Text(`(${this.commentCount})`)
          .fontSize(16)
          .fontColor('#9E9E9E')
          .margin({ left: 4 })
      }
      .width('100%')

      if (this.comments.length === 0) {
        // Empty state
        Column() {
          SymbolGlyph($r('sys.symbol.doc_text'))
            .fontSize(48)
            .fontColor(['#E0E0E0'])

          Text('No comments yet. Be the first to comment!')
            .fontSize(14)
            .fontColor('#9E9E9E')
            .margin({ top: 12 })
        }
        .width('100%')
        .padding({ top: 32, bottom: 32 })
        .backgroundColor('#FFF8E1')
        .borderRadius(12)
        .margin({ top: 16 })
      } else {
        // Comments list
        Column() {
          ForEach(this.comments, (comment: BlogComment) => {
            this.CommentItem(comment)
            Divider()
              .color('#F0F0F0')
          })
        }
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
    .margin({ top: 16 })
  }

  @Builder
  BottomCommentBar(): void {
    if (this.isLoggedIn) {
      // Logged in: Show comment input
      Row() {
        // Comment input
        Row() {
          SymbolGlyph($r('sys.symbol.pencil_line'))
            .fontSize(16)
            .fontColor(['#9E9E9E'])
            .margin({ right: 8 })

          TextInput({ placeholder: 'Write a comment...', text: this.commentText })
            .layoutWeight(1)
            .height(36)
            .backgroundColor(Color.Transparent)
            .placeholderColor('#9E9E9E')
            .placeholderFont({ size: 14 })
            .fontSize(14)
            .fontColor('#212121')
            .onChange((value: string) => {
              this.commentText = value;
            })
        }
        .layoutWeight(1)
        .height(44)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#F5F5F5')
        .borderRadius(22)

        // Send button
        Row() {
          SymbolGlyph($r('sys.symbol.arrow_up_circle_fill'))
            .fontSize(20)
            .fontColor(['#FFFFFF'])
        }
        .width(44)
        .height(44)
        .backgroundColor(this.isPostingComment ? '#BDBDBD' : '#FF9800')
        .borderRadius(22)
        .justifyContent(FlexAlign.Center)
        .margin({ left: 12 })
        .onClick(() => {
          if (!this.isPostingComment) {
            this.postComment();
          }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: -2 })
    } else {
      // Not logged in: Show login prompt
      Row() {
        Row() {
          SymbolGlyph($r('sys.symbol.person_fill'))
            .fontSize(16)
            .fontColor(['#9E9E9E'])
            .margin({ right: 8 })

          Text('Please login to comment')
            .fontSize(14)
            .fontColor('#9E9E9E')
        }
        .width('100%')
        .height(44)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#F5F5F5')
        .borderRadius(22)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.pushUrl({ url: 'pages/LoginPage' });
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: -2 })
    }
  }

  build() {
    Column() {
      // Content
      if (this.isLoading) {
        LoadingView({ message: 'Loading article...' })
          .layoutWeight(1)
      } else if (this.hasError) {
        ErrorView({
          message: this.errorMessage,
          onRetry: () => {
            this.loadArticle();
          }
        })
          .layoutWeight(1)
      } else if (this.article !== null) {
        // Scrollable content
        Scroll() {
          Column() {
            // Hero header with dark background
            this.HeroHeader()

            // Main content area
            Column() {
              this.ContentCard()
              this.CommentsSection()
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 24 })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .edgeEffect(EdgeEffect.Spring)

        // Fixed bottom comment bar
        this.BottomCommentBar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
