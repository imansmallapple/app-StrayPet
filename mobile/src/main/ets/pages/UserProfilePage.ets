// User Profile Page - View other user's profile and add friend
// Following ArkTS strict typing rules

import { router, promptAction } from '@kit.ArkUI';
import { SocialService, Friendship } from '../services/SocialService';
import { TokenManager } from '../services/TokenManager';

interface UserProfileParams {
  userId: number;
  username: string;
  avatar: string;
}

@Entry
@Component
struct UserProfilePage {
  @State userId: number = 0;
  @State username: string = '';
  @State avatar: string = '';
  @State isLoading: boolean = true;
  @State friendshipStatus: string = ''; // '', 'pending', 'accepted', 'blocked'
  @State friendshipId: number = 0;
  @State isSentByMe: boolean = false;
  @State isProcessing: boolean = false;

  private socialService: SocialService = new SocialService();
  private currentUserId: number = 0;

  aboutToAppear(): void {
    // Get params from router
    const params = router.getParams() as UserProfileParams;
    if (params !== null && params !== undefined) {
      this.userId = params.userId || 0;
      this.username = params.username || '';
      this.avatar = params.avatar || '';
    }

    this.currentUserId = TokenManager.getInstance().getUserId();
    this.checkFriendship();
  }

  async checkFriendship(): Promise<void> {
    if (this.userId === 0) {
      this.isLoading = false;
      return;
    }

    await TokenManager.getInstance().waitForInit();

    const result = await this.socialService.checkFriendship(this.userId);

    if (result.success && result.friendship !== null) {
      this.friendshipStatus = result.friendship.status;
      this.friendshipId = result.friendship.id;
      this.isSentByMe = result.friendship.from_user.id === this.currentUserId;
    }

    this.isLoading = false;
  }

  async handleAddFriend(): Promise<void> {
    if (this.isProcessing) return;
    this.isProcessing = true;

    const result = await this.socialService.addFriend(this.userId);

    if (result.success) {
      promptAction.showToast({ message: 'Friend request sent!' });
      this.friendshipStatus = 'pending';
      this.isSentByMe = true;
      if (result.friendship !== null) {
        this.friendshipId = result.friendship.id;
      }
    } else {
      promptAction.showToast({ message: result.errorMessage });
    }

    this.isProcessing = false;
  }

  async handleAcceptRequest(): Promise<void> {
    if (this.isProcessing || this.friendshipId === 0) return;
    this.isProcessing = true;

    const result = await this.socialService.acceptFriendRequest(this.friendshipId);

    if (result.success) {
      promptAction.showToast({ message: 'Friend request accepted!' });
      this.friendshipStatus = 'accepted';
    } else {
      promptAction.showToast({ message: result.errorMessage });
    }

    this.isProcessing = false;
  }

  async handleRejectRequest(): Promise<void> {
    if (this.isProcessing || this.friendshipId === 0) return;
    this.isProcessing = true;

    const result = await this.socialService.rejectFriendRequest(this.friendshipId);

    if (result.success) {
      promptAction.showToast({ message: 'Friend request rejected' });
      this.friendshipStatus = 'blocked';
    } else {
      promptAction.showToast({ message: result.errorMessage });
    }

    this.isProcessing = false;
  }

  async handleRemoveFriend(): Promise<void> {
    if (this.isProcessing || this.friendshipId === 0) return;
    this.isProcessing = true;

    const result = await this.socialService.deleteFriend(this.friendshipId);

    if (result.success) {
      promptAction.showToast({ message: 'Friend removed' });
      this.friendshipStatus = '';
      this.friendshipId = 0;
    } else {
      promptAction.showToast({ message: result.errorMessage });
    }

    this.isProcessing = false;
  }

  @Builder
  HeaderBuilder(): void {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor(['#424242'])
        .onClick(() => { router.back(); })

      Text('Profile')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .margin({ left: 16 })

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ActionButton(): void {
    Column() {
      if (this.isLoading || this.isProcessing) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color('#FF6B35')
      } else if (this.friendshipStatus === 'accepted') {
        // Already friends - show chat and remove options
        Row() {
          Button('Chat')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#FF6B35')
            .borderRadius(20)
            .height(40)
            .layoutWeight(1)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ChatPage',
                params: { userId: this.userId, username: this.username, avatar: this.avatar }
              });
            })

          Button('Remove')
            .fontSize(14)
            .fontColor('#F44336')
            .backgroundColor('#FFEBEE')
            .borderRadius(20)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => { this.handleRemoveFriend(); })
        }
        .width('100%')
      } else if (this.friendshipStatus === 'pending') {
        if (this.isSentByMe) {
          // Request sent by me - show pending
          Button('Request Sent')
            .fontSize(14)
            .fontColor('#757575')
            .backgroundColor('#F5F5F5')
            .borderRadius(20)
            .height(40)
            .width('100%')
            .enabled(false)
        } else {
          // Request received - show accept/reject
          Row() {
            Button('Accept')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#4CAF50')
              .borderRadius(20)
              .height(40)
              .layoutWeight(1)
              .onClick(() => { this.handleAcceptRequest(); })

            Button('Reject')
              .fontSize(14)
              .fontColor('#F44336')
              .backgroundColor('#FFEBEE')
              .borderRadius(20)
              .height(40)
              .layoutWeight(1)
              .margin({ left: 12 })
              .onClick(() => { this.handleRejectRequest(); })
          }
          .width('100%')
        }
      } else if (this.friendshipStatus === 'blocked') {
        // Blocked
        Button('Blocked')
          .fontSize(14)
          .fontColor('#757575')
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .height(40)
          .width('100%')
          .enabled(false)
      } else {
        // No relationship - show add friend
        Button('Add Friend')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B35')
          .borderRadius(20)
          .height(40)
          .width('100%')
          .onClick(() => { this.handleAddFriend(); })
      }
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24 })
  }

  build() {
    Column() {
      this.HeaderBuilder()

      Scroll() {
        Column() {
          // Avatar
          Column() {
            if (this.avatar.length > 0) {
              Image(this.avatar)
                .width(100)
                .height(100)
                .borderRadius(50)
                .objectFit(ImageFit.Cover)
            } else {
              Column() {
                Text(this.username.length > 0 ? this.username.charAt(0).toUpperCase() : '?')
                  .fontSize(40)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
              }
              .width(100)
              .height(100)
              .borderRadius(50)
              .backgroundColor('#FF6B35')
              .justifyContent(FlexAlign.Center)
            }
          }
          .margin({ top: 32 })

          // Username
          Text(this.username)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#212121')
            .margin({ top: 16 })

          // Friend status badge
          if (this.friendshipStatus === 'accepted') {
            Row() {
              Text('✓ Friend')
                .fontSize(12)
                .fontColor('#4CAF50')
            }
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor('#E8F5E9')
            .borderRadius(12)
            .margin({ top: 8 })
          }

          // Action buttons
          this.ActionButton()

          // Message button (if friends)
          if (this.friendshipStatus === 'accepted') {
            Column() {
              Divider()
                .color('#F0F0F0')
                .margin({ top: 24, bottom: 24 })

              Text('You are friends with ' + this.username)
                .fontSize(14)
                .fontColor('#9E9E9E')
            }
            .width('100%')
            .padding({ left: 24, right: 24 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
