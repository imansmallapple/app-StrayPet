// Profile Tab Content - User Profile and Settings
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { TokenManager } from '../../services/TokenManager';
import { UserService, UserResult } from '../../services/UserService';

// Menu item model
class MenuItem {
  icon: Resource | null = null;
  label: string = '';
  route: string = '';
  showBadge: boolean = false;
  badgeCount: number = 0;

  constructor(icon: Resource, label: string, route: string, showBadge: boolean = false, badgeCount: number = 0) {
    this.icon = icon;
    this.label = label;
    this.route = route;
    this.showBadge = showBadge;
    this.badgeCount = badgeCount;
  }
}

@Component
export struct ProfileTabContent {
  @Prop isLoggedIn: boolean = false;
  @State username: string = '';
  @State email: string = '';
  @State avatar: string = '';
  @State isLoading: boolean = false;

  private userService: UserService = new UserService();

  aboutToAppear(): void {
    if (this.isLoggedIn) {
      this.loadUserInfo();
    }
  }

  async loadUserInfo(): Promise<void> {
    this.isLoading = true;
    const result: UserResult = await this.userService.getCurrentUser();
    if (result.success && result.data !== null) {
      this.username = result.data.username;
      this.email = result.data.email;
      this.avatar = result.data.getAvatar();
    }
    this.isLoading = false;
  }

  handleLogout(): void {
    TokenManager.getInstance().clearTokens();
    // Force refresh
    this.isLoggedIn = false;
    this.username = '';
    this.email = '';
    this.avatar = '';
  }

  @Builder
  ProfileHeader(): void {
    Column() {
      // Avatar
      if (this.avatar.length > 0) {
        Image(this.avatar)
          .width(80)
          .height(80)
          .borderRadius(40)
          .objectFit(ImageFit.Cover)
          .border({ width: 3, color: '#FFFFFF' })
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.person_fill'))
            .fontSize(36)
            .fontColor(['#757575'])
        }
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor('#E0E0E0')
        .justifyContent(FlexAlign.Center)
        .border({ width: 3, color: '#FFFFFF' })
      }

      Text(this.username.length > 0 ? this.username : 'User')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 12 })

      Text(this.email.length > 0 ? this.email : '')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .opacity(0.8)
        .margin({ top: 4 })

      // Edit profile button
      Button('Edit Profile')
        .fontSize(14)
        .fontColor('#FF6B35')
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .height(36)
        .padding({ left: 20, right: 20 })
        .margin({ top: 16 })
        .onClick(() => {
          try {
            router.pushUrl({ url: 'pages/EditProfilePage' });
          } catch (err) {
            console.error('Navigation error', JSON.stringify(err));
          }
        })
    }
    .width('100%')
    .padding({ top: 40, bottom: 24 })
    .backgroundColor('#FF6B35')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  NotLoginHeader(): void {
    Column() {
      SymbolGlyph($r('sys.symbol.person_crop_circle_fill'))
        .fontSize(64)
        .fontColor(['#FFFFFF'])
        .margin({ bottom: 12 })

      Text('Not Signed In')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')

      Row() {
        Button('Sign In')
          .fontSize(14)
          .fontColor('#FF6B35')
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .height(36)
          .padding({ left: 24, right: 24 })
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/LoginPage' });
            } catch (err) {
              console.error('Navigation error', JSON.stringify(err));
            }
          })

        Button('Register')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('transparent')
          .borderRadius(20)
          .height(36)
          .padding({ left: 24, right: 24 })
          .border({ width: 1, color: '#FFFFFF' })
          .margin({ left: 12 })
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/RegisterPage' });
            } catch (err) {
              console.error('Navigation error', JSON.stringify(err));
            }
          })
      }
      .margin({ top: 16 })
    }
    .width('100%')
    .padding({ top: 50, bottom: 30 })
    .backgroundColor('#FF6B35')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MenuSection(title: string, items: MenuItem[]): void {
    Column() {
      if (title.length > 0) {
        Text(title)
          .fontSize(14)
          .fontColor('#9E9E9E')
          .padding({ left: 16, top: 16, bottom: 8 })
          .width('100%')
      }

      Column() {
        ForEach(items, (item: MenuItem, index: number) => {
          Row() {
            if (item.icon !== null) {
              SymbolGlyph(item.icon)
                .fontSize(20)
                .fontColor(['#FF6B35'])
                .width(32)
            }

            Text(item.label)
              .fontSize(16)
              .fontColor('#424242')
              .layoutWeight(1)

            if (item.showBadge && item.badgeCount > 0) {
              Text(item.badgeCount.toString())
                .fontSize(11)
                .fontColor('#FFFFFF')
                .backgroundColor('#FF6B35')
                .borderRadius(10)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .margin({ right: 8 })
            }

            Text('›')
              .fontSize(20)
              .fontColor('#BDBDBD')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            if (item.route.length > 0) {
              try {
                router.pushUrl({ url: item.route });
              } catch (err) {
                console.error('Navigation error', JSON.stringify(err));
              }
            }
          })

          if (index < items.length - 1) {
            Divider()
              .color('#F0F0F0')
              .strokeWidth(1)
              .margin({ left: 48 })
          }
        })
      }
      .borderRadius(12)
      .margin({ left: 16, right: 16 })
      .clip(true)
    }
  }

  build() {
    Scroll() {
      Column() {
        // Header
        if (this.isLoggedIn) {
          this.ProfileHeader()
        } else {
          this.NotLoginHeader()
        }

        // My content section
        this.MenuSection('My Content', [
          new MenuItem($r('sys.symbol.heart_fill'), 'Favorite Pets', 'pages/FavoritePetsPage'),
          new MenuItem($r('sys.symbol.bookmark_fill'), 'Favorite Articles', 'pages/FavoriteArticlesPage'),
          new MenuItem($r('sys.symbol.pawprint_fill'), 'My Pets', 'pages/MyPetsPage'),
          new MenuItem($r('sys.symbol.doc_text_fill'), 'My Articles', 'pages/MyArticlesPage'),
        ])

        // Social section
        this.MenuSection('Social', [
          new MenuItem($r('sys.symbol.person_2_fill'), 'Friends', 'pages/FriendsPage'),
          new MenuItem($r('sys.symbol.envelope_fill'), 'Friend Requests', 'pages/FriendRequestsPage', true, 0),
        ])

        // Settings section
        this.MenuSection('Settings', [
          new MenuItem($r('sys.symbol.bell_fill'), 'Notifications', 'pages/NotificationSettingsPage'),
          new MenuItem($r('sys.symbol.lock_fill'), 'Privacy', 'pages/PrivacySettingsPage'),
          new MenuItem($r('sys.symbol.questionmark_circle_fill'), 'Help & Feedback', 'pages/HelpPage'),
          new MenuItem($r('sys.symbol.info_circle_fill'), 'About', 'pages/AboutPage'),
        ])

        // Logout button (only show if logged in)
        if (this.isLoggedIn) {
          Button('Sign Out')
            .fontSize(16)
            .fontColor('#F44336')
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .width('90%')
            .height(48)
            .margin({ top: 24, bottom: 40 })
            .onClick(() => {
              this.handleLogout();
            })
        }

        // Bottom spacing
        Blank()
          .height(20)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .scrollBar(BarState.Off)
  }
}
