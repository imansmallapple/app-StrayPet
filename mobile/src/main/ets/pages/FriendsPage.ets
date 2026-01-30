// Friends Page - View and manage friends
// Following ArkTS strict typing rules

import { router, promptAction } from '@kit.ArkUI';
import { SocialService, Friend, Notification, SearchUser } from '../services/SocialService';
import { TokenManager } from '../services/TokenManager';

@Entry
@Component
struct FriendsPage {
  @State friends: Friend[] = [];
  @State pendingRequests: Notification[] = [];
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  @State errorMessage: string = '';
  @State activeTab: number = 0; // 0: Friends, 1: Requests
  @State showDeleteDialog: boolean = false;
  @State selectedFriend: Friend | null = null;
  @State showSearchDialog: boolean = false;
  @State searchQuery: string = '';
  @State searchResults: SearchUser[] = [];
  @State isSearching: boolean = false;
  @State processingIds: number[] = []; // Track which requests are being processed

  private socialService: SocialService = new SocialService();

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    this.hasError = false;

    await TokenManager.getInstance().waitForInit();

    // Load friends
    const friendsResult = await this.socialService.getFriendsList();
    if (friendsResult.success) {
      this.friends = friendsResult.friends;
    }

    // Load notifications for pending friend requests
    const notificationsResult = await this.socialService.getNotifications();
    if (notificationsResult.success) {
      // Filter for pending friend requests
      this.pendingRequests = notificationsResult.notifications.filter((n: Notification) =>
        n.notification_type === 'friend_request' && !n.is_read
      );
    }

    if (!friendsResult.success && !notificationsResult.success) {
      this.hasError = true;
      this.errorMessage = friendsResult.errorMessage.length > 0 ? friendsResult.errorMessage : notificationsResult.errorMessage;
    }

    this.isLoading = false;
  }

  async handleAcceptRequest(notification: Notification): Promise<void> {
    console.info('[FriendsPage] handleAcceptRequest called, notification:', JSON.stringify(notification));
    console.info('[FriendsPage] friendship_id:', notification.friendship_id, 'type:', typeof notification.friendship_id);

    if (notification.friendship_id === null || notification.friendship_id === 0) {
      promptAction.showToast({ message: 'Invalid friend request (no friendship_id)' });
      return;
    }

    // Prevent double-click
    if (this.processingIds.includes(notification.id)) {
      return;
    }
    this.processingIds.push(notification.id);

    const result = await this.socialService.acceptFriendRequest(notification.friendship_id);
    console.info('[FriendsPage] acceptFriendRequest result:', JSON.stringify(result));
    if (result.success) {
      promptAction.showToast({ message: 'Friend request accepted!' });
      await this.loadData();
    } else {
      const errorMsg = result.errorMessage.length > 0 ? result.errorMessage : 'Failed to accept friend request';
      promptAction.showToast({ message: errorMsg });
    }

    // Remove from processing
    this.processingIds = this.processingIds.filter((id: number) => id !== notification.id);
  }

  async handleRejectRequest(notification: Notification): Promise<void> {
    console.info('[FriendsPage] handleRejectRequest called, friendship_id:', notification.friendship_id);

    if (notification.friendship_id === null || notification.friendship_id === 0) {
      promptAction.showToast({ message: 'Invalid friend request (no friendship_id)' });
      return;
    }

    // Prevent double-click
    if (this.processingIds.includes(notification.id)) {
      return;
    }
    this.processingIds.push(notification.id);

    const result = await this.socialService.rejectFriendRequest(notification.friendship_id);
    console.info('[FriendsPage] rejectFriendRequest result:', JSON.stringify(result));
    if (result.success) {
      promptAction.showToast({ message: 'Friend request rejected' });
      await this.loadData();
    } else {
      const errorMsg = result.errorMessage.length > 0 ? result.errorMessage : 'Failed to reject friend request';
      promptAction.showToast({ message: errorMsg });
    }

    // Remove from processing
    this.processingIds = this.processingIds.filter((id: number) => id !== notification.id);
  }

  async handleDeleteFriend(friend: Friend): Promise<void> {
    const result = await this.socialService.deleteFriend(friend.friendship_id);
    if (result.success) {
      promptAction.showToast({ message: 'Friend removed' });
      this.loadData();
    } else {
      promptAction.showToast({ message: result.errorMessage });
    }
    this.showDeleteDialog = false;
    this.selectedFriend = null;
  }

  async handleSearch(): Promise<void> {
    if (this.searchQuery.trim().length < 2) {
      promptAction.showToast({ message: 'Please enter at least 2 characters' });
      return;
    }

    this.isSearching = true;
    const result = await this.socialService.searchUsers(this.searchQuery.trim());
    if (result.success) {
      this.searchResults = result.users;
    } else {
      promptAction.showToast({ message: result.errorMessage });
    }
    this.isSearching = false;
  }

  async handleAddFriendFromSearch(user: SearchUser): Promise<void> {
    const result = await this.socialService.addFriend(user.id);
    if (result.success) {
      promptAction.showToast({ message: 'Friend request sent!' });
      // Refresh search results
      await this.handleSearch();
    } else {
      promptAction.showToast({ message: result.errorMessage });
    }
  }

  @Builder
  HeaderBuilder(): void {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor(['#424242'])
        .onClick(() => { router.back(); })

      Text('Friends')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')
        .margin({ left: 16 })

      Blank()

      // Search icon
      Column() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(20)
          .fontColor(['#FF6B35'])
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor('#FFF3E0')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.showSearchDialog = true;
        this.searchQuery = '';
        this.searchResults = [];
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  TabSelector(): void {
    Row() {
      Text('Friends')
        .fontSize(16)
        .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeTab === 0 ? '#FF6B35' : '#757575')
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .borderRadius(20)
        .backgroundColor(this.activeTab === 0 ? '#FFF3E0' : 'transparent')
        .onClick(() => { this.activeTab = 0; })

      Stack() {
        Text('Requests')
          .fontSize(16)
          .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.activeTab === 1 ? '#FF6B35' : '#757575')
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .borderRadius(20)
          .backgroundColor(this.activeTab === 1 ? '#FFF3E0' : 'transparent')

        if (this.pendingRequests.length > 0) {
          Text(this.pendingRequests.length.toString())
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor('#F44336')
            .borderRadius(8)
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            .position({ x: '80%', y: 0 })
        }
      }
      .margin({ left: 8 })
      .onClick(() => { this.activeTab = 1; })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  FriendItem(friend: Friend): void {
    Row() {
      // Avatar
      if (friend.avatar.length > 0) {
        Image(friend.avatar)
          .width(50)
          .height(50)
          .borderRadius(25)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text(friend.username.charAt(0).toUpperCase())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width(50)
        .height(50)
        .borderRadius(25)
        .backgroundColor('#FF6B35')
        .justifyContent(FlexAlign.Center)
      }

      // Info
      Column() {
        Text(friend.username)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')

        if (friend.email.length > 0) {
          Text(friend.email)
            .fontSize(13)
            .fontColor('#757575')
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      // Actions
      Row() {
        // Chat button
        Column() {
          SymbolGlyph($r('sys.symbol.message_fill'))
            .fontSize(18)
            .fontColor(['#FF6B35'])
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor('#FFF3E0')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/ChatPage',
            params: { userId: friend.id, username: friend.username, avatar: friend.avatar }
          });
        })

        // Delete button
        Column() {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize(18)
            .fontColor(['#F44336'])
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor('#FFEBEE')
        .justifyContent(FlexAlign.Center)
        .margin({ left: 8 })
        .onClick(() => {
          this.selectedFriend = friend;
          this.showDeleteDialog = true;
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      router.pushUrl({
        url: 'pages/ChatPage',
        params: { userId: friend.id, username: friend.username, avatar: friend.avatar }
      });
    })
  }

  @Builder
  RequestItem(notification: Notification): void {
    Row() {
      // Avatar placeholder
      Column() {
        Text(notification.from_user !== null ? notification.from_user.username.charAt(0).toUpperCase() : '?')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width(50)
      .height(50)
      .borderRadius(25)
      .backgroundColor('#9C27B0')
      .justifyContent(FlexAlign.Center)

      // Info
      Column() {
        Text(notification.from_user !== null ? notification.from_user.username : 'Unknown')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#212121')

        Text(notification.content.length > 0 ? notification.content : 'wants to add you as a friend')
          .fontSize(13)
          .fontColor('#757575')
          .margin({ top: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(notification.getFormattedTime())
          .fontSize(11)
          .fontColor('#BDBDBD')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      // Accept/Reject buttons
      Row() {
        Button('Accept')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#4CAF50')
          .borderRadius(16)
          .height(32)
          .type(ButtonType.Normal)
          .stateEffect(true)
          .onClick(() => {
            console.info('[FriendsPage] Accept button clicked');
            console.info('[FriendsPage] notification id:', notification.id);
            console.info('[FriendsPage] friendship_id:', notification.friendship_id);
            this.handleAcceptRequest(notification);
          })

        Button('Reject')
          .fontSize(13)
          .fontColor('#F44336')
          .backgroundColor('#FFEBEE')
          .borderRadius(16)
          .height(32)
          .type(ButtonType.Normal)
          .stateEffect(true)
          .margin({ left: 8 })
          .onClick(() => {
            console.info('[FriendsPage] Reject button clicked');
            this.handleRejectRequest(notification);
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  FriendsContent(): void {
    if (this.friends.length === 0) {
      Column() {
        SymbolGlyph($r('sys.symbol.person_2_fill'))
          .fontSize(64)
          .fontColor(['#E0E0E0'])
          .margin({ bottom: 16 })

        Text('No Friends Yet')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#424242')

        Text('Start connecting with other pet lovers!')
          .fontSize(14)
          .fontColor('#9E9E9E')
          .margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List() {
        ForEach(this.friends, (friend: Friend) => {
          ListItem() {
            this.FriendItem(friend)
          }
        })
      }
      .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 78 })
      .layoutWeight(1)
    }
  }

  @Builder
  RequestsContent(): void {
    if (this.pendingRequests.length === 0) {
      Column() {
        SymbolGlyph($r('sys.symbol.person_badge_plus'))
          .fontSize(64)
          .fontColor(['#E0E0E0'])
          .margin({ bottom: 16 })

        Text('No Pending Requests')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#424242')

        Text('Friend requests will appear here')
          .fontSize(14)
          .fontColor('#9E9E9E')
          .margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List() {
        ForEach(this.pendingRequests, (notification: Notification) => {
          ListItem() {
            this.RequestItem(notification)
          }
        })
      }
      .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 78 })
      .layoutWeight(1)
    }
  }

  @Builder
  DeleteConfirmDialog(): void {
    Column() {
      Text('Remove Friend')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#212121')

      Text(`Are you sure you want to remove ${this.selectedFriend !== null ? this.selectedFriend.username : 'this friend'}?`)
        .fontSize(14)
        .fontColor('#757575')
        .margin({ top: 12 })
        .textAlign(TextAlign.Center)

      Row() {
        Button('Cancel')
          .fontSize(14)
          .fontColor('#757575')
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .layoutWeight(1)
          .height(40)
          .onClick(() => {
            this.showDeleteDialog = false;
            this.selectedFriend = null;
          })

        Button('Remove')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#F44336')
          .borderRadius(20)
          .layoutWeight(1)
          .height(40)
          .margin({ left: 12 })
          .onClick(() => {
            if (this.selectedFriend !== null) {
              this.handleDeleteFriend(this.selectedFriend);
            }
          })
      }
      .width('100%')
      .margin({ top: 24 })
    }
    .width('80%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  build() {
    Stack() {
      Column() {
        this.HeaderBuilder()

        this.TabSelector()

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
              .onClick(() => { this.loadData(); })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding(24)
        } else {
          if (this.activeTab === 0) {
            this.FriendsContent()
          } else {
            this.RequestsContent()
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')

      // Delete confirmation dialog
      if (this.showDeleteDialog) {
        Column() {
          this.DeleteConfirmDialog()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showDeleteDialog = false;
          this.selectedFriend = null;
        })
      }

      // Search dialog
      if (this.showSearchDialog) {
        Column() {
          Column() {
            // Header
            Row() {
              Text('Search Users')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#212121')

              Blank()

              SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(20)
                .fontColor(['#757575'])
                .onClick(() => {
                  this.showSearchDialog = false;
                  this.searchQuery = '';
                  this.searchResults = [];
                })
            }
            .width('100%')
            .padding({ bottom: 16 })

            // Search input
            Row() {
              TextInput({ placeholder: 'Enter username or email...', text: this.searchQuery })
                .fontSize(15)
                .layoutWeight(1)
                .height(44)
                .backgroundColor('#F5F5F5')
                .borderRadius(22)
                .padding({ left: 16, right: 16 })
                .onChange((value: string) => {
                  this.searchQuery = value;
                })
                .onSubmit(() => {
                  this.handleSearch();
                })

              Button('Search')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor('#FF6B35')
                .borderRadius(22)
                .height(44)
                .margin({ left: 8 })
                .onClick(() => {
                  this.handleSearch();
                })
            }
            .width('100%')

            // Search results
            if (this.isSearching) {
              Column() {
                LoadingProgress()
                  .width(32)
                  .height(32)
                  .color('#FF6B35')
                Text('Searching...')
                  .fontSize(14)
                  .fontColor('#9E9E9E')
                  .margin({ top: 8 })
              }
              .width('100%')
              .padding({ top: 32, bottom: 32 })
            } else if (this.searchResults.length === 0 && this.searchQuery.length > 0) {
              Column() {
                Text('No users found')
                  .fontSize(14)
                  .fontColor('#9E9E9E')
              }
              .width('100%')
              .padding({ top: 32, bottom: 32 })
            } else {
              List() {
                ForEach(this.searchResults, (user: SearchUser) => {
                  ListItem() {
                    Row() {
                      // Avatar
                      if (user.avatar.length > 0) {
                        Image(user.avatar)
                          .width(44)
                          .height(44)
                          .borderRadius(22)
                          .objectFit(ImageFit.Cover)
                      } else {
                        Column() {
                          Text(user.username.charAt(0).toUpperCase())
                            .fontSize(18)
                            .fontWeight(FontWeight.Bold)
                            .fontColor('#FFFFFF')
                        }
                        .width(44)
                        .height(44)
                        .borderRadius(22)
                        .backgroundColor('#9C27B0')
                        .justifyContent(FlexAlign.Center)
                      }

                      // Info
                      Column() {
                        Text(user.username)
                          .fontSize(15)
                          .fontWeight(FontWeight.Medium)
                          .fontColor('#212121')
                        Text(user.email)
                          .fontSize(12)
                          .fontColor('#757575')
                          .margin({ top: 2 })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      .margin({ left: 12 })

                      // Action button
                      if (user.friendship_status === 'accepted') {
                        Text('Friends')
                          .fontSize(12)
                          .fontColor('#4CAF50')
                          .backgroundColor('#E8F5E9')
                          .borderRadius(12)
                          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      } else if (user.friendship_status === 'pending') {
                        if (user.is_sent_by_me) {
                          Text('Pending')
                            .fontSize(12)
                            .fontColor('#FF9800')
                            .backgroundColor('#FFF3E0')
                            .borderRadius(12)
                            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                        } else {
                          Button('Accept')
                            .fontSize(12)
                            .fontColor('#FFFFFF')
                            .backgroundColor('#4CAF50')
                            .borderRadius(12)
                            .height(28)
                            .onClick(() => {
                              if (user.friendship_id !== null) {
                                this.socialService.acceptFriendRequest(user.friendship_id).then((result) => {
                                  if (result.success) {
                                    promptAction.showToast({ message: 'Friend request accepted!' });
                                    this.handleSearch();
                                    this.loadData();
                                  } else {
                                    promptAction.showToast({ message: result.errorMessage });
                                  }
                                });
                              }
                            })
                        }
                      } else {
                        Button('Add')
                          .fontSize(12)
                          .fontColor('#FFFFFF')
                          .backgroundColor('#FF6B35')
                          .borderRadius(12)
                          .height(28)
                          .onClick(() => {
                            this.handleAddFriendFromSearch(user);
                          })
                      }
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10 })
                    .onClick(() => {
                      this.showSearchDialog = false;
                      router.pushUrl({
                        url: 'pages/UserProfilePage',
                        params: { userId: user.id, username: user.username, avatar: user.avatar }
                      });
                    })
                  }
                })
              }
              .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 56 })
              .height(300)
              .margin({ top: 16 })
            }
          }
          .width('90%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
