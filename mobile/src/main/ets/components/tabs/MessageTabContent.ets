// Message Tab Content - Conversation List and Notifications
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { SocialService, Conversation, Notification } from '../../services/SocialService';
import { TokenManager } from '../../services/TokenManager';
import { LoadingView, EmptyView, ErrorView } from '../CommonViews';

@Component
export struct MessageTabContent {
  @Prop isLoggedIn: boolean = false;
  @Prop @Watch('onVisibilityChange') isVisible: boolean = false;
  @State conversations: Conversation[] = [];
  @State notifications: Notification[] = [];
  @State isLoading: boolean = false;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State activeTab: number = 0; // 0: Messages, 1: Notifications
  @State unreadNotifications: number = 0;

  private socialService: SocialService = new SocialService();
  private refreshTimer: number = -1;
  private readonly REFRESH_INTERVAL: number = 5000; // Refresh every 5 seconds

  aboutToAppear(): void {
    if (this.isLoggedIn) {
      this.loadData();
    }
  }

  aboutToDisappear(): void {
    this.stopAutoRefresh();
  }

  onVisibilityChange(): void {
    // Refresh data when tab becomes visible
    if (this.isVisible && this.isLoggedIn) {
      this.loadData();
      this.startAutoRefresh();
    } else {
      this.stopAutoRefresh();
    }
  }

  startAutoRefresh(): void {
    if (this.refreshTimer === -1) {
      this.refreshTimer = setInterval(() => {
        if (this.isVisible && this.isLoggedIn && !this.isLoading) {
          this.refreshData();
        }
      }, this.REFRESH_INTERVAL);
    }
  }

  stopAutoRefresh(): void {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = -1;
    }
  }

  async refreshData(): Promise<void> {
    // Silent refresh without loading indicator
    const convResult = await this.socialService.getAllMessages();
    if (convResult.success) {
      this.conversations = convResult.conversations;
    }

    const notifResult = await this.socialService.getNotifications(1, 20);
    if (notifResult.success) {
      this.notifications = notifResult.notifications;
      this.unreadNotifications = notifResult.unread_count;
    }
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    await TokenManager.getInstance().waitForInit();

    // Load conversations
    const convResult = await this.socialService.getAllMessages();
    if (convResult.success) {
      this.conversations = convResult.conversations;
    }

    // Load notifications
    const notifResult = await this.socialService.getNotifications(1, 20);
    if (notifResult.success) {
      this.notifications = notifResult.notifications;
      this.unreadNotifications = notifResult.unread_count;
    }

    if (!convResult.success && !notifResult.success) {
      this.hasError = true;
      this.errorMessage = convResult.errorMessage.length > 0 ? convResult.errorMessage : notifResult.errorMessage;
    }

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

      Stack() {
        Text('Notifications')
          .fontSize(16)
          .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.activeTab === 1 ? '#FF6B35' : '#757575')
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .borderRadius(20)
          .backgroundColor(this.activeTab === 1 ? '#FFF3E0' : 'transparent')

        if (this.unreadNotifications > 0) {
          Text(this.unreadNotifications > 99 ? '99+' : this.unreadNotifications.toString())
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('#F44336')
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .position({ x: '85%', y: 0 })
        }
      }
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
          Text(conv.username.length > 0 ? conv.username.charAt(0).toUpperCase() : '👤')
            .fontSize(conv.username.length > 0 ? 20 : 24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(50)
        .height(50)
        .borderRadius(25)
        .backgroundColor('#FF6B35')
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
          if (conv.is_system) {
            Text('🔔 ')
              .fontSize(12)
          }
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
          params: { userId: conv.user_id, username: conv.username, avatar: conv.avatar }
        });
      } catch (err) {
        console.error('Navigation error', JSON.stringify(err));
      }
    })
  }

  @Builder
  NotificationItem(notification: Notification): void {
    Row() {
      // Icon
      Column() {
        Text(notification.getIcon())
          .fontSize(18)
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor(notification.is_read ? '#F5F5F5' : '#FFF3E0')
      .justifyContent(FlexAlign.Center)

      // Content
      Column() {
        Row() {
          Text(notification.getTypeDisplay())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(notification.is_read ? '#757575' : '#212121')

          if (!notification.is_read) {
            Circle()
              .width(6)
              .height(6)
              .fill('#FF6B35')
              .margin({ left: 4 })
          }

          Blank()

          Text(notification.getFormattedTime())
            .fontSize(11)
            .fontColor('#BDBDBD')
        }
        .width('100%')

        if (notification.from_user !== null) {
          Text(`From ${notification.from_user.username}`)
            .fontSize(12)
            .fontColor('#9E9E9E')
            .margin({ top: 2 })
        }

        if (notification.content.length > 0) {
          Text(notification.content)
            .fontSize(13)
            .fontColor('#757575')
            .margin({ top: 2 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 10 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(notification.is_read ? '#FFFFFF' : '#FFFBF5')
    .onClick(() => {
      router.pushUrl({ url: 'pages/NotificationPage' });
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
          this.loadData();
        }
      })
        .layoutWeight(1)
    } else if (this.conversations.length === 0) {
      Column() {
        SymbolGlyph($r('sys.symbol.message_fill'))
          .fontSize(64)
          .fontColor(['#E0E0E0'])
          .margin({ bottom: 16 })

        Text('No Messages')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#424242')

        Text('Start chatting with friends!')
          .fontSize(14)
          .fontColor('#9E9E9E')
          .margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
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
    if (this.isLoading) {
      LoadingView({ message: 'Loading...' })
        .layoutWeight(1)
    } else if (this.notifications.length === 0) {
      Column() {
        SymbolGlyph($r('sys.symbol.bell_fill'))
          .fontSize(64)
          .fontColor(['#E0E0E0'])
          .margin({ bottom: 16 })

        Text('No Notifications')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#424242')

        Text('Your notifications will appear here')
          .fontSize(14)
          .fontColor('#9E9E9E')
          .margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      Column() {
        List() {
          ForEach(this.notifications.slice(0, 5), (notification: Notification) => {
            ListItem() {
              this.NotificationItem(notification)
            }
          })
        }
        .divider({ strokeWidth: 1, color: '#F0F0F0' })

        // View all button
        if (this.notifications.length > 0) {
          Row() {
            Text('View All Notifications')
              .fontSize(14)
              .fontColor('#FF6B35')
          }
          .width('100%')
          .height(48)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            router.pushUrl({ url: 'pages/NotificationPage' });
          })
        }
      }
      .layoutWeight(1)
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('Messages')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#424242')

        Blank()

        // Friends button
        Column() {
          SymbolGlyph($r('sys.symbol.person_2_fill'))
            .fontSize(20)
            .fontColor(['#FF6B35'])
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#FFF3E0')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.pushUrl({ url: 'pages/FriendsPage' });
        })
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
