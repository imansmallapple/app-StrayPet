// Login Page
// Following ArkTS strict typing rules

import { UserService, LoginResult } from '../services/UserService';
import { TokenManager } from '../services/TokenManager';
import { LoginRequest } from '../models/User';
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { ApiConfig } from '../services/ApiConfig';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State captcha: string = '';
  @State captchaUid: string = '';
  @State captchaImage: string = '';
  @State isLoading: boolean = false;
  @State isCaptchaLoading: boolean = false;
  @State errorMessage: string = '';
  @State showPassword: boolean = false;

  private userService: UserService = new UserService();
  private context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.context = getContext(this) as common.UIAbilityContext;
    this.loadCaptcha();
  }

  async loadCaptcha(): Promise<void> {
    this.isCaptchaLoading = true;
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${ApiConfig.BASE_URL}user/captcha/`,
        {
          method: http.RequestMethod.GET,
          header: { 'Content-Type': 'application/json' },
          connectTimeout: 10000,
          readTimeout: 10000
        }
      );
      httpRequest.destroy();

      if (response.responseCode === 200) {
        const data = JSON.parse(response.result as string) as Record<string, string>;
        this.captchaUid = data['uid'] ?? '';
        this.captchaImage = data['image'] ?? '';
      }
    } catch (e) {
      console.error('Failed to load captcha:', JSON.stringify(e));
    }
    this.isCaptchaLoading = false;
  }

  async handleLogin(): Promise<void> {
    if (this.username.trim().length === 0) {
      this.errorMessage = 'Please enter your username';
      return;
    }
    if (this.password.length === 0) {
      this.errorMessage = 'Please enter your password';
      return;
    }
    if (this.captcha.trim().length === 0) {
      this.errorMessage = 'Please enter the captcha';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    const request = new LoginRequest(this.username.trim(), this.password, this.captcha.trim(), this.captchaUid);
    const result: LoginResult = await this.userService.login(request);

    if (result.success) {
      // Save tokens
      if (this.context !== null) {
        await TokenManager.getInstance().saveToPreferences(this.context);
      }

      // Get user info
      await this.userService.getCurrentUser();

      // Navigate to main page
      router.replaceUrl({ url: 'pages/MainPage' });
    } else {
      this.errorMessage = result.errorMessage;
      // Refresh captcha on error
      this.captcha = '';
      this.loadCaptcha();
    }

    this.isLoading = false;
  }

  build() {
    Column() {
      // Logo and title
      Column() {
        Image($r('app.media.startIcon'))
          .width(100)
          .height(100)

        Text('StrayPet')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')
          .margin({ top: 16 })

        Text('Find your perfect companion')
          .fontSize(14)
          .fontColor('#9E9E9E')
          .margin({ top: 8 })
      }
      .margin({ top: 60 })

      // Login form
      Column() {
        // Username input
        Column() {
          Text('Username')
            .fontSize(14)
            .fontColor('#616161')
            .width('100%')

          TextInput({ text: this.username, placeholder: 'Enter your username' })
            .fontSize(16)
            .fontColor('#212121')
            .placeholderColor('#BDBDBD')
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .height(50)
            .padding({ left: 16, right: 16 })
            .margin({ top: 8 })
            .onChange((value: string) => {
              this.username = value;
              this.errorMessage = '';
            })
        }
        .width('100%')

        // Password input
        Column() {
          Text('Password')
            .fontSize(14)
            .fontColor('#616161')
            .width('100%')

          Stack({ alignContent: Alignment.End }) {
            TextInput({ text: this.password, placeholder: 'Enter your password' })
              .fontSize(16)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(50)
              .padding({ left: 16, right: 48 })
              .type(this.showPassword ? InputType.Normal : InputType.Password)
              .onChange((value: string) => {
                this.password = value;
                this.errorMessage = '';
              })
              .onSubmit(() => {
                this.handleLogin();
              })

            Text(this.showPassword ? '👁' : '👁‍🗨')
              .fontSize(16)
              .margin({ right: 16 })
              .onClick(() => {
                this.showPassword = !this.showPassword;
              })
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('100%')
        .margin({ top: 20 })

        // Captcha input
        Column() {
          Text('Captcha')
            .fontSize(14)
            .fontColor('#616161')
            .width('100%')

          Row() {
            TextInput({ text: this.captcha, placeholder: 'Enter captcha' })
              .fontSize(16)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(50)
              .padding({ left: 16, right: 16 })
              .layoutWeight(1)
              .onChange((value: string) => {
                this.captcha = value;
                this.errorMessage = '';
              })
              .onSubmit(() => {
                this.handleLogin();
              })

            // Captcha image
            if (this.captchaImage.length > 0) {
              Image(this.captchaImage)
                .width(120)
                .height(50)
                .borderRadius(12)
                .margin({ left: 12 })
                .objectFit(ImageFit.Cover)
                .onClick(() => {
                  this.loadCaptcha();
                })
            } else {
              Column() {
                if (this.isCaptchaLoading) {
                  LoadingProgress()
                    .width(24)
                    .height(24)
                    .color('#FF6B35')
                } else {
                  Text('Tap to load')
                    .fontSize(12)
                    .fontColor('#9E9E9E')
                }
              }
              .width(120)
              .height(50)
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .margin({ left: 12 })
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.loadCaptcha();
              })
            }
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('100%')
        .margin({ top: 20 })

        // Error message
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage)
            .fontSize(13)
            .fontColor('#F44336')
            .width('100%')
            .margin({ top: 12 })
        }

        // Login button
        Button(this.isLoading ? 'Signing in...' : 'Sign In')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(this.isLoading ? '#FFAB91' : '#FF6B35')
          .borderRadius(24)
          .width('100%')
          .height(50)
          .margin({ top: 32 })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleLogin();
          })

        // Register link
        Row() {
          Text('Don\'t have an account? ')
            .fontSize(14)
            .fontColor('#9E9E9E')

          Text('Sign Up')
            .fontSize(14)
            .fontColor('#FF6B35')
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              router.pushUrl({ url: 'pages/RegisterPage' });
            })
        }
        .margin({ top: 24 })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })
      .margin({ top: 48 })

      Blank()

      // Back to home
      Text('Continue as Guest')
        .fontSize(14)
        .fontColor('#9E9E9E')
        .margin({ bottom: 32 })
        .onClick(() => {
          router.back();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
