// My Profile Page - User Profile View and Edit
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { UserService, UserResult } from '../services/UserService';
import { User, UpdateProfileRequest } from '../models/index';

@Entry
@Component
struct EditProfilePage {
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;
  @State isEditMode: boolean = false;  // Start in view mode
  @State username: string = '';
  @State email: string = '';
  @State firstName: string = '';
  @State lastName: string = '';
  @State phone: string = '';
  @State avatar: string = '';
  @State livingSituation: string = '';
  @State hasYard: boolean = false;
  @State hasExperience: boolean = false;
  @State otherPets: string = '';
  @State additionalNotes: string = '';

  private userService: UserService = new UserService();

  aboutToAppear(): void {
    this.loadUserInfo();
  }

  async loadUserInfo(): Promise<void> {
    console.info('[EditProfile] Loading user info...');
    this.isLoading = true;
    const result: UserResult = await this.userService.getCurrentUser();
    console.info('[EditProfile] Result success:', result.success);
    if (result.success && result.data !== null) {
      console.info('[EditProfile] User:', result.data.username, result.data.email);
      this.username = result.data.username;
      this.email = result.data.email;
      this.firstName = result.data.first_name;
      this.lastName = result.data.last_name;
      this.avatar = result.data.getAvatar();
      if (result.data.profile !== null) {
        console.info('[EditProfile] Profile phone:', result.data.profile.phone);
        this.phone = result.data.profile.phone;
        this.livingSituation = result.data.profile.living_situation;
        this.hasYard = result.data.profile.has_yard;
        this.hasExperience = result.data.profile.has_experience;
        this.otherPets = result.data.profile.other_pets;
        this.additionalNotes = result.data.profile.additional_notes;
      }
    } else {
      console.error('[EditProfile] Failed:', result.errorMessage);
    }
    this.isLoading = false;
  }

  async saveProfile(): Promise<void> {
    this.isSaving = true;
    const updateData = new UpdateProfileRequest();
    updateData.first_name = this.firstName;
    updateData.last_name = this.lastName;
    updateData.phone = this.phone;
    updateData.living_situation = this.livingSituation;
    updateData.has_yard = this.hasYard;
    updateData.has_experience = this.hasExperience;
    updateData.other_pets = this.otherPets;
    updateData.additional_notes = this.additionalNotes;

    const result = await this.userService.updateProfile(updateData);
    this.isSaving = false;

    if (result.success) {
      promptAction.showToast({ message: 'Profile updated successfully!' });
      this.isEditMode = false;  // Return to view mode after save
    } else {
      promptAction.showToast({ message: result.errorMessage || 'Failed to update profile' });
    }
  }

  @Builder
  SectionHeader(title: string, icon: Resource): void {
    Row() {
      SymbolGlyph(icon)
        .fontSize(18)
        .fontColor(['#FF6B35'])
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#424242')
        .margin({ left: 8 })
    }
    .width('100%')
    .margin({ top: 24, bottom: 12 })
  }

  @Builder
  ReadOnlyField(label: string, value: string): void {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#9E9E9E')
        .margin({ bottom: 4 })
      Text(value.length > 0 ? value : '-')
        .fontSize(15)
        .fontColor('#424242')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  InputField(label: string, value: string, placeholder: string, onChange: (value: string) => void): void {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#9E9E9E')
        .margin({ bottom: 6 })
      TextInput({ text: value, placeholder: placeholder })
        .height(46)
        .fontSize(15)
        .fontColor('#424242')
        .placeholderColor('#BDBDBD')
        .backgroundColor('#F8F8F8')
        .borderRadius(10)
        .padding({ left: 14, right: 14 })
        .onChange(onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 6, bottom: 6 })
  }

  @Builder
  TextAreaField(label: string, value: string, placeholder: string, onChange: (value: string) => void): void {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#9E9E9E')
        .margin({ bottom: 6 })
      TextArea({ text: value, placeholder: placeholder })
        .height(88)
        .fontSize(15)
        .fontColor('#424242')
        .placeholderColor('#BDBDBD')
        .backgroundColor('#F8F8F8')
        .borderRadius(10)
        .padding(12)
        .onChange(onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 6, bottom: 6 })
  }

  @Builder
  SwitchField(label: string, value: boolean, onChange: (value: boolean) => void): void {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#424242')
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#FF6B35')
        .onChange(onChange)
        .enabled(this.isEditMode)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  SwitchViewField(label: string, value: boolean): void {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#424242')
        .layoutWeight(1)
      Text(value ? 'Yes' : 'No')
        .fontSize(15)
        .fontColor(value ? '#4CAF50' : '#9E9E9E')
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  build() {
    Column() {
      // Header
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor(['#424242'])
          .onClick(() => { router.back(); })
        Text('My Profile')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
          .layoutWeight(1)
        if (this.isSaving) {
          LoadingProgress()
            .width(24)
            .height(24)
            .color('#FF6B35')
        } else if (this.isEditMode) {
          Text('Save')
            .fontSize(16)
            .fontColor('#FF6B35')
            .fontWeight(FontWeight.Medium)
            .onClick(() => { this.saveProfile(); })
        } else {
          Text('Edit')
            .fontSize(16)
            .fontColor('#FF6B35')
            .fontWeight(FontWeight.Medium)
            .onClick(() => { this.isEditMode = true; })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#FF6B35')
          Text('Loading...')
            .fontSize(14)
            .fontColor('#9E9E9E')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            // Avatar section
            Column() {
              Stack() {
                if (this.avatar.length > 0) {
                  Image(this.avatar)
                    .width(100)
                    .height(100)
                    .borderRadius(50)
                    .objectFit(ImageFit.Cover)
                } else {
                  Column() {
                    SymbolGlyph($r('sys.symbol.person_fill'))
                      .fontSize(44)
                      .fontColor(['#757575'])
                  }
                  .width(100)
                  .height(100)
                  .borderRadius(50)
                  .backgroundColor('#E0E0E0')
                  .justifyContent(FlexAlign.Center)
                }
                // Camera overlay - only show in edit mode
                if (this.isEditMode) {
                  Column() {
                    SymbolGlyph($r('sys.symbol.camera_fill'))
                      .fontSize(16)
                      .fontColor(['#FFFFFF'])
                  }
                  .width(32)
                  .height(32)
                  .borderRadius(16)
                  .backgroundColor('#FF6B35')
                  .justifyContent(FlexAlign.Center)
                  .position({ x: '68%', y: '68%' })
                }
              }
              .width(100)
              .height(100)

              if (this.isEditMode) {
                Text('Change Photo')
                  .fontSize(14)
                  .fontColor('#FF6B35')
                  .margin({ top: 8 })
              } else {
                // Display name in view mode
                Text(this.firstName.length > 0 || this.lastName.length > 0 ?
                  `${this.firstName} ${this.lastName}`.trim() : this.username)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#212121')
                  .margin({ top: 12 })
                Text(`@${this.username}`)
                  .fontSize(14)
                  .fontColor('#9E9E9E')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .padding({ top: 24, bottom: 16 })
            .alignItems(HorizontalAlign.Center)

            // Form content
            Column() {
              // Account Info Section
              this.SectionHeader('Account Info', $r('sys.symbol.person_fill'))
              Column() {
                this.ReadOnlyField('Username', this.username)
                Divider().color('#F0F0F0').margin({ top: 4, bottom: 4 })
                this.ReadOnlyField('Email', this.email)
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)

              // Personal Info Section
              this.SectionHeader('Personal Info', $r('sys.symbol.person_2_fill'))
              if (this.isEditMode) {
                Column() {
                  this.InputField('First Name', this.firstName, 'Enter first name', (value: string) => {
                    this.firstName = value;
                  })
                  this.InputField('Last Name', this.lastName, 'Enter last name', (value: string) => {
                    this.lastName = value;
                  })
                  this.InputField('Phone', this.phone, 'Enter phone number', (value: string) => {
                    this.phone = value;
                  })
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
              } else {
                Column() {
                  this.ReadOnlyField('First Name', this.firstName)
                  Divider().color('#F0F0F0').margin({ top: 4, bottom: 4 })
                  this.ReadOnlyField('Last Name', this.lastName)
                  Divider().color('#F0F0F0').margin({ top: 4, bottom: 4 })
                  this.ReadOnlyField('Phone', this.phone)
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
              }

              // Living Situation Section
              this.SectionHeader('Living Situation', $r('sys.symbol.house_fill'))
              if (this.isEditMode) {
                Column() {
                  this.InputField('Home Type', this.livingSituation, 'e.g., Apartment, House', (value: string) => {
                    this.livingSituation = value;
                  })
                  Divider().color('#F0F0F0').margin({ top: 8, bottom: 4 })
                  this.SwitchField('Has Yard', this.hasYard, (value: boolean) => {
                    this.hasYard = value;
                  })
                  Divider().color('#F0F0F0').margin({ top: 4, bottom: 4 })
                  this.SwitchField('Has Pet Experience', this.hasExperience, (value: boolean) => {
                    this.hasExperience = value;
                  })
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
              } else {
                Column() {
                  this.ReadOnlyField('Home Type', this.livingSituation)
                  Divider().color('#F0F0F0').margin({ top: 4, bottom: 4 })
                  this.SwitchViewField('Has Yard', this.hasYard)
                  Divider().color('#F0F0F0').margin({ top: 4, bottom: 4 })
                  this.SwitchViewField('Has Pet Experience', this.hasExperience)
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
              }

              // Additional Info Section
              this.SectionHeader('Additional Info', $r('sys.symbol.doc_text_fill'))
              if (this.isEditMode) {
                Column() {
                  this.TextAreaField('Other Pets', this.otherPets, 'Describe other pets you have', (value: string) => {
                    this.otherPets = value;
                  })
                  this.TextAreaField('Notes', this.additionalNotes, 'Any additional information', (value: string) => {
                    this.additionalNotes = value;
                  })
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
              } else {
                Column() {
                  this.ReadOnlyField('Other Pets', this.otherPets)
                  Divider().color('#F0F0F0').margin({ top: 4, bottom: 4 })
                  this.ReadOnlyField('Notes', this.additionalNotes)
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
              }

              // Save button at bottom - only in edit mode
              if (this.isEditMode) {
                Button('Save Changes')
                  .width('100%')
                  .height(50)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#FF6B35')
                  .borderRadius(25)
                  .margin({ top: 32, bottom: 40 })
                  .enabled(!this.isSaving)
                  .onClick(() => { this.saveProfile(); })
              } else {
                // Spacer for bottom in view mode
                Row().height(40)
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
