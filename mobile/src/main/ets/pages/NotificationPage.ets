// Notification Page - View all notifications
// Following ArkTS strict typing rules

import { router, promptAction } from '@kit.ArkUI';
import { SocialService, Notification } from '../services/SocialService';
import { TokenManager } from '../services/TokenManager';

@Entry
@Component
struct NotificationPage {
  @State notifications: Notification[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State currentPage: number = 1;
  @State hasMore: boolean = true;
  @State isLoadingMore: boolean = false;

  private socialService: SocialService = new SocialService();

  aboutToAppear(): void {
    this.loadNotifications();
  }

  async loadNotifications(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;
    this.currentPage = 1;

    await TokenManager.getInstance().waitForInit();

    const result = await this.socialService.getNotifications(this.currentPage);

    if (result.success) {
      this.notifications = result.notifications;
      this.hasMore = result.notifications.length >= 20;
    } else {
      this.hasError = true;
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  async loadMoreNotifications(): Promise<void> {
    if (this.isLoadingMore || !this.hasMore) return;

    this.isLoadingMore = true;
    this.currentPage++;

    const result = await this.socialService.getNotifications(this.currentPage);

    if (result.success) {
      this.notifications = this.notifications.concat(result.notifications);
      this.hasMore = result.notifications.length >= 20;
    }

    this.isLoadingMore = false;
  }

  async handleNotificationTap(notification: Notification): Promise<void> {
    // Mark as read
    if (!notification.is_read) {
      await this.socialService.markNotificationAsRead(notification.id);
      notification.is_read = true;
      // Trigger UI update
      this.notifications = [...this.notifications];
    }

    // Navigate based on notification type
    switch (notification.notification_type) {
      case 'friend_request':
        router.pushUrl({ url: 'pages/FriendsPage' });
        break;
      case 'holiday_family_apply':
      case 'holiday_family_approve':
      case 'holiday_family_reject':
        if (notification.holiday_family_application_id !== null) {
          router.pushUrl({
            url: 'pages/HolidayFamilyDetailPage',
            params: { applicationId: notification.holiday_family_application_id }
          });
        }
        break;
      case 'reply':
      case 'mention':
        // Navigate to blog or comment if available
        promptAction.showToast({ message: 'View comment details' });
        break;
      default:
        break;
    }
  }

  async handleAcceptFriendRequest(notification: Notification): Promise<void> {
    if (notification.friendship_id === null || notification.friendship_id === 0) {
      promptAction.showToast({ message: 'Invalid friend request' });
      return;
    }

    const result = await this.socialService.acceptFriendRequest(notification.friendship_id);
    if (result.success) {
      promptAction.showToast({ message: 'Friend request accepted!' });
      notification.is_read = true;
      this.notifications = [...this.notifications];
    } else {
      const errorMsg = result.errorMessage.length > 0 ? result.errorMessage : 'Failed to accept friend request';
      promptAction.showToast({ message: errorMsg });
    }
  }

  async handleRejectFriendRequest(notification: Notification): Promise<void> {
    if (notification.friendship_id === null || notification.friendship_id === 0) {
      promptAction.showToast({ message: 'Invalid friend request' });
      return;
    }

    const result = await this.socialService.rejectFriendRequest(notification.friendship_id);
    if (result.success) {
      promptAction.showToast({ message: 'Friend request rejected' });
      notification.is_read = true;
      this.notifications = [...this.notifications];
    } else {
      const errorMsg = result.errorMessage.length > 0 ? result.errorMessage : 'Failed to reject friend request';
      promptAction.showToast({ message: errorMsg });
    }
  }

  @Builder
  HeaderBuilder(): void {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor(['#424242'])
        .onClick(() => { router.back(); })

      Text('Notifications')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .margin({ left: 16 })

      Blank()

      // Unread count
      if (this.notifications.filter((n: Notification) => !n.is_read).length > 0) {
        Text(`${this.notifications.filter((n: Notification) => !n.is_read).length} unread`)
          .fontSize(12)
          .fontColor('#FF6B35')
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  NotificationItem(notification: Notification): void {
    Row() {
      // Icon
      Column() {
        Text(notification.getIcon())
          .fontSize(20)
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
              .width(8)
              .height(8)
              .fill('#FF6B35')
              .margin({ left: 6 })
          }

          Blank()

          Text(notification.getFormattedTime())
            .fontSize(11)
            .fontColor('#BDBDBD')
        }
        .width('100%')

        if (notification.from_user !== null) {
          Text(`From ${notification.from_user.username}`)
            .fontSize(13)
            .fontColor('#9E9E9E')
            .margin({ top: 2 })
        }

        if (notification.content.length > 0) {
          Text(notification.content)
            .fontSize(13)
            .fontColor('#757575')
            .margin({ top: 4 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        if (notification.comment_content.length > 0) {
          Text(`"${notification.comment_content}"`)
            .fontSize(12)
            .fontColor('#9E9E9E')
            .fontStyle(FontStyle.Italic)
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        // Friend request actions
        if (notification.notification_type === 'friend_request' && !notification.is_read) {
          Row() {
            Button('Accept')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor('#4CAF50')
              .borderRadius(14)
              .height(28)
              .type(ButtonType.Normal)
              .stateEffect(true)
              .onClick(() => {
                console.info('[NotificationPage] Accept button clicked');
                this.handleAcceptFriendRequest(notification);
              })

            Button('Reject')
              .fontSize(12)
              .fontColor('#F44336')
              .backgroundColor('#FFEBEE')
              .borderRadius(14)
              .height(28)
              .type(ButtonType.Normal)
              .stateEffect(true)
              .margin({ left: 8 })
              .onClick(() => {
                console.info('[NotificationPage] Reject button clicked');
                this.handleRejectFriendRequest(notification);
              })
          }
          .margin({ top: 8 })
          .hitTestBehavior(HitTestMode.Block)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(notification.is_read ? '#FFFFFF' : '#FFFBF5')
    .onClick(() => { this.handleNotificationTap(notification); })
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
          Text('Loading...')
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
            .onClick(() => { this.loadNotifications(); })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding(24)
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
        List() {
          ForEach(this.notifications, (notification: Notification) => {
            ListItem() {
              this.NotificationItem(notification)
            }
          })

          // Load more indicator
          if (this.hasMore) {
            ListItem() {
              Row() {
                if (this.isLoadingMore) {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .color('#FF6B35')
                  Text('Loading...')
                    .fontSize(13)
                    .fontColor('#9E9E9E')
                    .margin({ left: 8 })
                } else {
                  Text('Load more')
                    .fontSize(13)
                    .fontColor('#FF6B35')
                }
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.Center)
              .onClick(() => { this.loadMoreNotifications(); })
            }
          }
        }
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
        .layoutWeight(1)
        .onReachEnd(() => {
          if (this.hasMore && !this.isLoadingMore) {
            this.loadMoreNotifications();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
