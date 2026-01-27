// Main Page with Bottom Navigation
// Following ArkTS strict typing rules

import { router } from '@kit.ArkUI';
import { TokenManager } from '../services/TokenManager';

// Import tab content builders
import { HomeTabContent } from '../components/tabs/HomeTabContent';
import { AdoptTabContent } from '../components/tabs/AdoptTabContent';
import { LostTabContent } from '../components/tabs/LostTabContent';
import { MessageTabContent } from '../components/tabs/MessageTabContent';
import { ProfileTabContent } from '../components/tabs/ProfileTabContent';

@Entry
@Component
struct MainPage {
  @State currentTab: number = 0;
  @State isLoggedIn: boolean = false;
  private tabController: TabsController = new TabsController();

  aboutToAppear(): void {
    console.info('[MainPage] aboutToAppear');
    this.checkLoginStatus();
  }

  onPageShow(): void {
    // Re-check login status when page becomes visible (e.g., after login)
    console.info('[MainPage] onPageShow');
    this.checkLoginStatus();
  }

  checkLoginStatus(): void {
    const token = TokenManager.getInstance().getAccessToken();
    const wasLoggedIn = this.isLoggedIn;
    this.isLoggedIn = token.length > 0;
    console.info('[MainPage] Login status:', this.isLoggedIn, 'token length:', token.length);
  }

  @Builder
  TabBarItem(index: number, label: string, icon: Resource): void {
    Column() {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([this.currentTab === index ? '#FF6B35' : '#9E9E9E'])

      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? '#FF6B35' : '#9E9E9E')
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
      // Home
      TabContent() {
        HomeTabContent()
      }
      .tabBar(this.TabBarItem(0, 'Home', $r('sys.symbol.house_fill')))

      // Adopt
      TabContent() {
        AdoptTabContent()
      }
      .tabBar(this.TabBarItem(1, 'Adopt', $r('sys.symbol.heart_fill')))

      // Lost
      TabContent() {
        LostTabContent()
      }
      .tabBar(this.TabBarItem(2, 'Lost', $r('sys.symbol.magnifyingglass')))

      // Messages
      TabContent() {
        MessageTabContent({ isLoggedIn: this.isLoggedIn })
      }
      .tabBar(this.TabBarItem(3, 'Messages', $r('sys.symbol.message_fill')))

      // Profile
      TabContent() {
        ProfileTabContent({ isLoggedIn: this.isLoggedIn })
      }
      .tabBar(this.TabBarItem(4, 'Profile', $r('sys.symbol.person_fill')))
    }
    .barHeight(56)
    .barBackgroundColor('#FFFFFF')
    .onChange((index: number) => {
      this.currentTab = index;
    })
    .width('100%')
    .height('100%')
  }
}
