// Register Page
// Following ArkTS strict typing rules

import { UserService, UserResult, LoginResult } from '../services/UserService';
import { TokenManager } from '../services/TokenManager';
import { RegisterRequest, LoginRequest } from '../models/User';
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State email: string = '';
  @State password: string = '';
  @State password2: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State showPassword: boolean = false;

  private userService: UserService = new UserService();
  private context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.context = getContext(this) as common.UIAbilityContext;
  }

  validateForm(): boolean {
    if (this.username.trim().length === 0) {
      this.errorMessage = 'Please enter username';
      return false;
    }
    if (this.username.trim().length < 3) {
      this.errorMessage = 'Username must be at least 3 characters';
      return false;
    }
    if (this.email.trim().length === 0) {
      this.errorMessage = 'Please enter email';
      return false;
    }
    if (!this.email.includes('@')) {
      this.errorMessage = 'Please enter a valid email';
      return false;
    }
    if (this.password.length < 6) {
      this.errorMessage = 'Password must be at least 6 characters';
      return false;
    }
    if (this.password !== this.password2) {
      this.errorMessage = 'Passwords do not match';
      return false;
    }
    return true;
  }

  async handleRegister(): Promise<void> {
    if (!this.validateForm()) {
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    const request = new RegisterRequest(
      this.username.trim(),
      this.email.trim(),
      this.password,
      this.password2
    );
    const result: UserResult = await this.userService.register(request);

    if (result.success) {
      // Auto login after registration
      const loginRequest = new LoginRequest(this.username.trim(), this.password);
      const loginResult: LoginResult = await this.userService.login(loginRequest);

      if (loginResult.success && this.context !== null) {
        await TokenManager.getInstance().saveToPreferences(this.context);
        router.replaceUrl({ url: 'pages/HomePage' });
      } else {
        // Registration successful but login failed, go to login page
        router.replaceUrl({ url: 'pages/LoginPage' });
      }
    } else {
      this.errorMessage = result.errorMessage;
    }

    this.isLoading = false;
  }

  build() {
    Column() {
      // Header
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#424242'])
          .onClick(() => {
            router.back();
          })

        Text('Create Account')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#212121')
          .margin({ left: 16 })

        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      Scroll() {
        Column() {
          // Username
          Column() {
            Text('Username')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            TextInput({ text: this.username, placeholder: 'Choose a username' })
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

          // Email
          Column() {
            Text('Email')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            TextInput({ text: this.email, placeholder: 'Enter your email' })
              .fontSize(16)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(50)
              .padding({ left: 16, right: 16 })
              .margin({ top: 8 })
              .type(InputType.Email)
              .onChange((value: string) => {
                this.email = value;
                this.errorMessage = '';
              })
          }
          .width('100%')
          .margin({ top: 20 })

          // Password
          Column() {
            Text('Password')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            Stack({ alignContent: Alignment.End }) {
              TextInput({ text: this.password, placeholder: 'Create a password' })
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

              Text(this.showPassword ? '👁' : '👁‍🗨')
                .fontSize(20)
                .fontColor('#9E9E9E')
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

          // Confirm Password
          Column() {
            Text('Confirm Password')
              .fontSize(14)
              .fontColor('#616161')
              .width('100%')

            TextInput({ text: this.password2, placeholder: 'Confirm your password' })
              .fontSize(16)
              .fontColor('#212121')
              .placeholderColor('#BDBDBD')
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .height(50)
              .padding({ left: 16, right: 16 })
              .margin({ top: 8 })
              .type(InputType.Password)
              .onChange((value: string) => {
                this.password2 = value;
                this.errorMessage = '';
              })
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

          // Register button
          Button(this.isLoading ? 'Creating account...' : 'Create Account')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.isLoading ? '#FFAB91' : '#FF6B35')
            .borderRadius(24)
            .width('100%')
            .height(50)
            .margin({ top: 32 })
            .enabled(!this.isLoading)
            .onClick(() => {
              this.handleRegister();
            })

          // Login link
          Row() {
            Text('Already have an account? ')
              .fontSize(14)
              .fontColor('#9E9E9E')

            Text('Login')
              .fontSize(14)
              .fontColor('#FF6B35')
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                router.replaceUrl({ url: 'pages/LoginPage' });
              })
          }
          .margin({ top: 24 })
        }
        .width('100%')
        .padding({ left: 32, right: 32, top: 24, bottom: 32 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
