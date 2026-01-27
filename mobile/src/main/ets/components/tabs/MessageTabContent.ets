// Message Tab Content - Conversation List and Notifications
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { LoadingView, EmptyView, ErrorView } from '../CommonViews';

// Message conversation model
class Conversation {
  id: number = 0;
  user_id: number = 0;
  username: string = '';
  avatar: string = '';
  last_message: string = '';
  last_time: string = '';
  unread_count: number = 0;

  constructor() {}
}

@Component
export struct MessageTabContent {
  @Prop isLoggedIn: boolean = false;
  @State conversations: Conversation[] = [];
  @State isLoading: boolean = false;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State activeTab: number = 0; // 0: Messages, 1: Notifications

  aboutToAppear(): void {
    if (this.isLoggedIn) {
      this.loadConversations();
    }
  }

  async loadConversations(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    // TODO: Implement API call to get conversations
    // For now, show empty state
    this.conversations = [];
    this.isLoading = false;
  }

  @Builder
  TabSelector(): void {
    Row() {
      Text('Chats')
        .fontSize(16)
        .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeTab === 0 ? '#FF6B35' : '#757575')
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .borderRadius(20)
        .backgroundColor(this.activeTab === 0 ? '#FFF3E0' : 'transparent')
        .onClick(() => {
          this.activeTab = 0;
        })

      Text('Notifications')
        .fontSize(16)
        .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeTab === 1 ? '#FF6B35' : '#757575')
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .borderRadius(20)
        .backgroundColor(this.activeTab === 1 ? '#FFF3E0' : 'transparent')
        .margin({ left: 8 })
        .onClick(() => {
          this.activeTab = 1;
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  ConversationItem(conv: Conversation): void {
    Row() {
      // Avatar
      if (conv.avatar.length > 0) {
        Image(conv.avatar)
          .width(50)
          .height(50)
          .borderRadius(25)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text('👤')
            .fontSize(24)
        }
        .width(50)
        .height(50)
        .borderRadius(25)
        .backgroundColor('#E0E0E0')
        .justifyContent(FlexAlign.Center)
      }

      // Content
      Column() {
        Row() {
          Text(conv.username)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#212121')

          Blank()

          Text(conv.last_time)
            .fontSize(12)
            .fontColor('#BDBDBD')
        }
        .width('100%')

        Row() {
          Text(conv.last_message)
            .fontSize(14)
            .fontColor('#757575')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (conv.unread_count > 0) {
            Text(conv.unread_count.toString())
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor('#FF6B35')
              .borderRadius(10)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ left: 8 })
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      try {
        router.pushUrl({
          url: 'pages/ChatPage',
          params: { userId: conv.user_id }
        });
      } catch (err) {
        console.error('Navigation error', JSON.stringify(err));
      }
    })
  }

  @Builder
  NotLoginContent(): void {
    Column() {
      SymbolGlyph($r('sys.symbol.message_fill'))
        .fontSize(64)
        .fontColor(['#E0E0E0'])
        .margin({ bottom: 16 })

      Text('Sign in to view messages')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#424242')

      Text('Chat with other users after signing in')
        .fontSize(14)
        .fontColor('#9E9E9E')
        .margin({ top: 8 })

      Button('Sign In')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF6B35')
        .borderRadius(24)
        .width(150)
        .height(44)
        .margin({ top: 24 })
        .onClick(() => {
          try {
            router.pushUrl({ url: 'pages/LoginPage' });
          } catch (err) {
            console.error('Navigation error', JSON.stringify(err));
          }
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  MessagesContent(): void {
    if (this.isLoading) {
      LoadingView({ message: 'Loading...' })
        .layoutWeight(1)
    } else if (this.hasError) {
      ErrorView({
        message: this.errorMessage,
        onRetry: () => {
          this.loadConversations();
        }
      })
        .layoutWeight(1)
    } else if (this.conversations.length === 0) {
      EmptyView({
        title: 'No Messages',
        subtitle: 'Start chatting with other users'
      })
        .layoutWeight(1)
    } else {
      List() {
        ForEach(this.conversations, (conv: Conversation) => {
          ListItem() {
            this.ConversationItem(conv)
          }
        })
      }
      .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 78 })
      .layoutWeight(1)
    }
  }

  @Builder
  NotificationsContent(): void {
    EmptyView({
      title: 'No Notifications',
      subtitle: 'Your notifications will appear here'
    })
      .layoutWeight(1)
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('Messages')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#424242')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (!this.isLoggedIn) {
        this.NotLoginContent()
      } else {
        // Tab selector
        this.TabSelector()

        // Content
        if (this.activeTab === 0) {
          this.MessagesContent()
        } else {
          this.NotificationsContent()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
