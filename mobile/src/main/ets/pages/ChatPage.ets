// Chat Page - Private messaging with a user
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { SocialService, PrivateMessage, SimpleUser } from '../services/SocialService';
import { TokenManager } from '../services/TokenManager';

interface ChatParams {
  userId: number;
  username: string;
  avatar: string;
}

@Entry
@Component
struct ChatPage {
  @State messages: PrivateMessage[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State inputText: string = '';
  @State isSending: boolean = false;
  @State userId: number = 0;
  @State username: string = '';
  @State avatar: string = '';

  private socialService: SocialService = new SocialService();
  private currentUserId: number = 0;
  private scroller: Scroller = new Scroller();
  private refreshTimer: number = -1;
  private readonly REFRESH_INTERVAL: number = 3000; // Refresh every 3 seconds

  aboutToAppear(): void {
    // Get params from router
    const params = router.getParams() as ChatParams;
    if (params !== null && params !== undefined) {
      this.userId = params.userId || 0;
      this.username = params.username || '';
      this.avatar = params.avatar || '';
    }

    this.currentUserId = TokenManager.getInstance().getUserId();
    this.loadMessages();
    this.startAutoRefresh();
  }

  aboutToDisappear(): void {
    this.stopAutoRefresh();
  }

  startAutoRefresh(): void {
    this.refreshTimer = setInterval(() => {
      this.refreshMessages();
    }, this.REFRESH_INTERVAL);
  }

  stopAutoRefresh(): void {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = -1;
    }
  }

  async refreshMessages(): Promise<void> {
    // Don't refresh if we're still loading or sending
    if (this.isLoading || this.isSending || this.userId === 0) return;

    const result = await this.socialService.getConversation(this.userId);
    if (result.success) {
      // Only update if there are new messages
      if (result.messages.length !== this.messages.length) {
        this.messages = result.messages;
        // Scroll to bottom if new messages arrived
        setTimeout(() => {
          this.scrollToBottom();
        }, 50);
      }
    }
  }

  async loadMessages(): Promise<void> {
    if (this.userId === 0) {
      this.hasError = true;
      this.errorMessage = 'Invalid user';
      this.isLoading = false;
      return;
    }

    this.isLoading = true;
    this.hasError = false;

    await TokenManager.getInstance().waitForInit();

    const result = await this.socialService.getConversation(this.userId);

    if (result.success) {
      this.messages = result.messages;
      // Scroll to bottom after loading
      setTimeout(() => {
        this.scrollToBottom();
      }, 100);
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  async sendMessage(): Promise<void> {
    if (this.inputText.trim().length === 0 || this.isSending) return;

    this.isSending = true;
    const content = this.inputText.trim();
    this.inputText = '';

    const result = await this.socialService.sendMessage(this.userId, content);

    if (result.success) {
      // Add message locally for instant feedback
      const newMessage = new PrivateMessage();
      newMessage.id = Date.now();
      newMessage.content = content;
      newMessage.sender = new SimpleUser(this.currentUserId, TokenManager.getInstance().getUsername());
      newMessage.recipient = new SimpleUser(this.userId, this.username, this.avatar);
      newMessage.created_at = new Date().toISOString();
      this.messages.push(newMessage);

      // Scroll to bottom
      setTimeout(() => {
        this.scrollToBottom();
      }, 50);
    } else {
      // Show error and restore input
      this.inputText = content;
      this.errorMessage = result.errorMessage;
    }

    this.isSending = false;
  }

  scrollToBottom(): void {
    this.scroller.scrollEdge(Edge.Bottom);
  }

  @Builder
  HeaderBuilder(): void {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor(['#424242'])
        .onClick(() => { router.back(); })

      // Avatar
      if (this.avatar.length > 0) {
        Image(this.avatar)
          .width(36)
          .height(36)
          .borderRadius(18)
          .objectFit(ImageFit.Cover)
          .margin({ left: 12 })
      } else {
        Column() {
          Text(this.username.length > 0 ? this.username.charAt(0).toUpperCase() : '?')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor('#FF6B35')
        .justifyContent(FlexAlign.Center)
        .margin({ left: 12 })
      }

      Text(this.username)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .margin({ left: 10 })

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 2, color: 'rgba(0,0,0,0.1)', offsetY: 1 })
  }

  @Builder
  MessageBubble(message: PrivateMessage): void {
    Column() {
      if (message.is_system) {
        // System message - centered
        Column() {
          Text(message.content)
            .fontSize(12)
            .fontColor('#9E9E9E')
            .textAlign(TextAlign.Center)
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 8 })
      } else {
        Row() {
          if (message.sender.id !== this.currentUserId) {
            // Other's avatar
            if (message.sender.avatar.length > 0) {
              Image(message.sender.avatar)
                .width(32)
                .height(32)
                .borderRadius(16)
                .objectFit(ImageFit.Cover)
            } else {
              Column() {
                Text(message.sender.username.charAt(0).toUpperCase())
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
              }
              .width(32)
              .height(32)
              .borderRadius(16)
              .backgroundColor('#9C27B0')
              .justifyContent(FlexAlign.Center)
            }
          }

          Column() {
            Text(message.content)
              .fontSize(15)
              .fontColor(message.sender.id === this.currentUserId ? '#FFFFFF' : '#212121')
              .padding({ left: 14, right: 14, top: 10, bottom: 10 })
              .backgroundColor(message.sender.id === this.currentUserId ? '#FF6B35' : '#F0F0F0')
              .borderRadius({
                topLeft: message.sender.id === this.currentUserId ? 16 : 4,
                topRight: message.sender.id === this.currentUserId ? 4 : 16,
                bottomLeft: 16,
                bottomRight: 16
              })
              .constraintSize({ maxWidth: '70%' })

            Text(message.getFormattedTime())
              .fontSize(10)
              .fontColor('#BDBDBD')
              .margin({ top: 4 })
          }
          .alignItems(message.sender.id === this.currentUserId ? HorizontalAlign.End : HorizontalAlign.Start)
          .margin({ left: message.sender.id === this.currentUserId ? 0 : 8, right: message.sender.id === this.currentUserId ? 8 : 0 })
        }
        .width('100%')
        .justifyContent(message.sender.id === this.currentUserId ? FlexAlign.End : FlexAlign.Start)
        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
      }
    }
  }

  @Builder
  InputArea(): void {
    Row() {
      TextInput({ placeholder: 'Type a message...', text: this.inputText })
        .fontSize(15)
        .placeholderFont({ size: 15 })
        .placeholderColor('#BDBDBD')
        .backgroundColor('#F5F5F5')
        .borderRadius(24)
        .padding({ left: 16, right: 16 })
        .height(44)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.inputText = value;
        })
        .onSubmit(() => {
          this.sendMessage();
        })

      // Send button
      Column() {
        if (this.isSending) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#FFFFFF')
        } else {
          SymbolGlyph($r('sys.symbol.paperplane_fill'))
            .fontSize(20)
            .fontColor(['#FFFFFF'])
        }
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor(this.inputText.trim().length > 0 ? '#FF6B35' : '#BDBDBD')
      .justifyContent(FlexAlign.Center)
      .margin({ left: 8 })
      .onClick(() => {
        this.sendMessage();
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: -1 })
  }

  @Builder
  EmptyState(): void {
    Column() {
      SymbolGlyph($r('sys.symbol.message_fill'))
        .fontSize(64)
        .fontColor(['#E0E0E0'])
        .margin({ bottom: 16 })

      Text('No messages yet')
        .fontSize(16)
        .fontColor('#9E9E9E')

      Text('Start the conversation!')
        .fontSize(14)
        .fontColor('#BDBDBD')
        .margin({ top: 4 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      this.HeaderBuilder()

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#FF6B35')
          Text('Loading messages...')
            .fontSize(14)
            .fontColor('#9E9E9E')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.hasError) {
        Column() {
          SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
            .fontSize(48)
            .fontColor(['#F44336'])
            .margin({ bottom: 16 })

          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#757575')
            .textAlign(TextAlign.Center)

          Button('Retry')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF6B35')
            .borderRadius(20)
            .margin({ top: 16 })
            .onClick(() => { this.loadMessages(); })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding(24)
      } else if (this.messages.length === 0) {
        this.EmptyState()
      } else {
        // Messages list
        List({ scroller: this.scroller }) {
          ForEach(this.messages, (message: PrivateMessage) => {
            ListItem() {
              this.MessageBubble(message)
            }
          })
        }
        .layoutWeight(1)
        .backgroundColor('#FAFAFA')
      }

      this.InputArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
