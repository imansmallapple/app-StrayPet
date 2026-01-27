# StrayPet 移动端 App 前端需求文档

## 项目概述
流浪宠物救助平台移动端应用，复用现有Django后端API。

---

## 一、页面结构

### 底部导航栏 (Tab Bar)
| Tab | 图标 | 页面 |
|-----|------|------|
| 首页 | 🏠 | Home |
| 领养 | 🐾 | Adopt |
| 走失 | 🔍 | Lost |
| 消息 | 💬 | Messages |
| 我的 | 👤 | Profile |

---

## 二、各模块页面与功能

### 1. 首页 (Home)
**页面**: `HomeScreen`

**功能**:
- Banner轮播图/宣传语
- 快捷入口：领养、走失、收容所、博客、假日家庭
- 推荐宠物展示（可选）
- 最新走失宠物提醒（可选）

---

### 2. 领养模块 (Adoption)

#### 2.1 宠物列表页
**页面**: `AdoptListScreen`

**功能**:
- 宠物卡片列表（图片、名字、品种、年龄、地点）
- 下拉刷新 + 上拉加载更多
- 筛选功能：
  - 城市
  - 物种：狗、猫、兔子、其他
  - 性别：公、母
  - 体型：小型、中型、大型
  - 特征：已绝育、已疫苗、亲近小孩、已训练等
- 搜索框（按名字搜索）
- 收藏/取消收藏

#### 2.2 宠物详情页
**页面**: `AdoptDetailScreen`

**参数**: `petId`

**展示信息**:
- 照片轮播
- 基本信息：名字、物种、品种、性别、年龄、体型
- 健康状态：疫苗、驱虫、绝育、芯片
- 性格特征：亲近小孩、喜欢玩耍、喜欢散步、与狗相处好、与猫相处好等
- 详细描述
- 联系电话
- 所属收容所信息（名称、地址、电话、网站）
- 地图定位

**操作**:
- 收藏按钮
- 申请领养按钮

#### 2.3 领养申请页
**页面**: `AdoptApplyScreen`

**参数**: `petId`

**表单字段**:
- 申请留言（可选）
- 提交按钮

#### 2.4 发布宠物页（管理员）
**页面**: `AdoptAddScreen`

**表单字段**:
- 照片上传（多张）
- 名字、物种、品种、性别
- 年龄（年、月）
- 体型
- 城市、地址
- 描述
- 健康状态勾选
- 性格特征勾选
- 联系电话

---

### 3. 走失宠物模块 (Lost Pet)

#### 3.1 走失列表页
**页面**: `LostListScreen`

**功能**:
- 地图视图：显示所有走失宠物位置
- 列表视图：走失宠物卡片
- 切换地图/列表模式
- 筛选：城市、物种、时间范围
- 搜索框

#### 3.2 走失详情页
**页面**: `LostDetailScreen`

**参数**: `lostId`

**展示信息**:
- 照片
- 宠物名、物种、品种、颜色、性别、体型
- 走失时间
- 走失地点（地址 + 地图）
- 描述
- 悬赏金额（如有）
- 联系方式：电话、邮箱
- 状态：寻找中/已找到

**操作**:
- 联系发布者
- 分享

#### 3.3 发布走失页
**页面**: `LostPostScreen`

**表单字段**:
- 照片上传
- 宠物名、物种、品种、颜色
- 性别、体型
- 走失时间（日期选择器）
- 走失地点（地址选择器 + 地图定位）
- 描述
- 悬赏金额（可选）
- 联系电话、联系邮箱

---

### 4. 发现流浪宠物 (Found/Stray)

#### 4.1 指南页
**页面**: `FoundGuideScreen`

**内容**:
- 操作指南（4步）：
  1. 在附近寻找主人
  2. 社交媒体发布
  3. 检查芯片
  4. 联系收容所
- 附近收容所列表入口

---

### 5. 收容所模块 (Shelters)

#### 5.1 收容所列表页
**页面**: `ShelterListScreen`

**功能**:
- 收容所卡片列表
- 显示：名称、地址、电话、容量
- 地图视图（可选）
- 搜索

#### 5.2 收容所详情页
**页面**: `ShelterDetailScreen`

**参数**: `shelterId`

**展示信息**:
- Logo、封面图
- 名称、描述
- 联系方式：电话、邮箱、网站
- 地址 + 地图
- 容量信息：总容量、当前数量、入住率
- 成立年份
- 社交媒体链接
- 该收容所的宠物列表

---

### 6. 博客模块 (Blog)

#### 6.1 文章列表页
**页面**: `BlogListScreen`

**功能**:
- 文章卡片列表（标题、摘要、作者、日期、阅读量）
- 搜索
- 标签筛选
- 排序：最新、最热
- 收藏文章

#### 6.2 文章详情页
**页面**: `BlogDetailScreen`

**参数**: `articleId`

**展示信息**:
- 标题
- 作者信息（头像、用户名）
- 发布日期
- 标签
- 正文内容（富文本渲染）
- 阅读量

**操作**:
- 收藏
- 评论列表
- 发表评论
- 回复评论

#### 6.3 发布文章页
**页面**: `BlogCreateScreen`

**表单字段**:
- 标题
- 摘要
- 正文（富文本编辑器）
- 分类
- 标签选择

---

### 7. 假日寄养家庭 (Holiday Family)

#### 7.1 介绍页
**页面**: `HolidayFamilyScreen`

**内容**:
- 项目介绍
- 4个特色卡片（临时家庭、做贡献、家庭活动、社区支持）
- 申请按钮
- 已认证家庭展示

#### 7.2 申请页
**页面**: `HolidayFamilyApplyScreen`

**表单字段**:
- 个人信息：姓名、邮箱、电话
- 地址：国家、州/省、城市、邮编、街道地址
- 可接收宠物数量
- 可接收宠物类型：狗、猫、兔子、其他
- 申请动机
- 自我介绍
- 身份证明上传
- 家庭照片上传（多张）
- 同意条款勾选

#### 7.3 认证用户详情页
**页面**: `CertifiedUserScreen`

**参数**: `userId`

**展示信息**:
- 用户头像、用户名
- 认证徽章
- 联系方式

---

### 8. 消息模块 (Messages)

#### 8.1 消息列表页
**页面**: `MessageListScreen`

**功能**:
- 对话列表
- 显示：对方头像、用户名、最后一条消息、时间、未读数
- 按时间排序

#### 8.2 对话详情页
**页面**: `ChatScreen`

**参数**: `userId`

**功能**:
- 聊天气泡界面
- 消息输入框
- 发送消息
- 自动滚动到最新
- 消息已读状态

---

### 9. 通知模块 (Notifications)

#### 9.1 通知列表页
**页面**: `NotificationScreen`

**功能**:
- 通知列表
- 类型：回复、提及、系统通知
- 标记已读
- 删除通知
- 点击跳转到对应内容

---

### 10. 用户模块 (User)

#### 10.1 个人中心页
**页面**: `ProfileScreen`

**功能模块**:
| 入口 | 跳转页面 |
|------|----------|
| 个人信息 | EditProfileScreen |
| 我收藏的宠物 | FavoritePetsScreen |
| 我收藏的文章 | FavoriteArticlesScreen |
| 我发布的文章 | MyArticlesScreen |
| 我发布的宠物 | MyPetsScreen |
| 我的好友 | FriendsScreen |
| 设置 | SettingsScreen |

#### 10.2 编辑个人信息页
**页面**: `EditProfileScreen`

**功能**:
- 头像上传/更换
- 用户名（只读）
- 姓名、邮箱、电话
- 修改密码入口

#### 10.3 收藏的宠物页
**页面**: `FavoritePetsScreen`

- 宠物卡片列表
- 取消收藏

#### 10.4 收藏的文章页
**页面**: `FavoriteArticlesScreen`

- 文章列表
- 取消收藏

#### 10.5 我的文章页
**页面**: `MyArticlesScreen`

- 我发布的文章列表
- 编辑/删除

#### 10.6 我的宠物页
**页面**: `MyPetsScreen`

- 我发布的宠物列表
- 编辑/删除/修改状态

#### 10.7 好友列表页
**页面**: `FriendsScreen`

- 好友列表
- 发起聊天
- 删除好友
- 好友请求列表

#### 10.8 查看其他用户页
**页面**: `UserProfileScreen`

**参数**: `userId`

- 用户头像、用户名
- 发布的文章
- 发起聊天
- 添加好友

---

### 11. 认证模块 (Auth)

#### 11.1 登录页
**页面**: `LoginScreen`

**表单字段**:
- 用户名/邮箱
- 密码
- 登录按钮
- 忘记密码链接
- 注册链接

#### 11.2 注册页
**页面**: `RegisterScreen`

**表单字段**:
- 用户名
- 邮箱
- 邮箱验证码（发送验证码按钮）
- 密码
- 确认密码
- 图形验证码
- 注册按钮

#### 11.3 忘记密码页
**页面**: `ForgotPasswordScreen`

**表单字段**:
- 邮箱
- 发送重置邮件按钮

#### 11.4 重置密码页
**页面**: `ResetPasswordScreen`

**表单字段**:
- 邮箱
- 验证码
- 新密码
- 确认新密码

---

## 三、API接口概览

### 基础URL
```
http://localhost:8000/
```

### 认证方式
- JWT Token (Bearer Token)
- accessToken + refreshToken
- 存储在本地（AsyncStorage等）

### 主要接口

| 模块 | 接口 | 方法 | 说明 |
|------|------|------|------|
| **认证** | `/user/token/` | POST | 登录获取token |
| | `/user/token/refresh/` | POST | 刷新token |
| | `/user/register/` | POST | 注册 |
| | `/user/me/` | GET/PATCH | 获取/更新个人信息 |
| | `/user/send_email_code/` | POST | 发送邮箱验证码 |
| | `/user/password/reset/request/` | POST | 请求重置密码 |
| | `/user/password/reset/confirm/` | POST | 确认重置密码 |
| **宠物** | `/pet/` | GET | 宠物列表（支持筛选分页） |
| | `/pet/{id}/` | GET | 宠物详情 |
| | `/pet/` | POST | 发布宠物 |
| | `/pet/{id}/` | PATCH | 更新宠物 |
| | `/pet/{id}/apply/` | POST | 申请领养 |
| | `/pet/{id}/favorite/` | POST | 收藏宠物 |
| | `/pet/{id}/unfavorite/` | DELETE | 取消收藏 |
| | `/pet/favorites/` | GET | 我收藏的宠物 |
| | `/pet/my_pets/` | GET | 我发布的宠物 |
| **走失** | `/pet/lost/` | GET | 走失宠物列表 |
| | `/pet/lost/{id}/` | GET | 走失详情 |
| | `/pet/lost/` | POST | 发布走失 |
| | `/pet/lost/all/` | GET | 所有走失宠物（地图用） |
| **收容所** | `/pet/shelter/` | GET | 收容所列表 |
| | `/pet/shelter/{id}/` | GET | 收容所详情 |
| **博客** | `/blog/article/` | GET | 文章列表 |
| | `/blog/article/{id}/` | GET | 文章详情 |
| | `/blog/article/` | POST | 发布文章 |
| | `/blog/tag/` | GET | 标签列表 |
| | `/blog/tag/popular/` | GET | 热门标签 |
| | `/blog/archive/` | GET | 归档 |
| | `/blog/comment/` | GET/POST | 评论 |
| **假日家庭** | `/holiday-family/apply/` | POST | 提交申请 |
| | `/holiday-family/applications/` | GET | 申请列表 |
| **消息** | `/user/messages/` | GET | 消息列表 |
| | `/user/messages/` | POST | 发送消息 |
| | `/user/messages/conversation/` | GET | 对话详情 |
| **通知** | `/user/notifications/` | GET | 通知列表 |
| | `/user/notifications/{id}/mark_as_read/` | POST | 标记已读 |
| | `/user/notifications/unread_count/` | GET | 未读数量 |
| **好友** | `/user/friendships/` | GET | 好友列表 |
| | `/user/friendships/add_friend/` | POST | 添加好友 |
| | `/user/friendships/{id}/accept/` | POST | 接受好友请求 |

---

## 四、数据模型

### User（用户）
```
id, username, email, first_name, last_name, phone,
avatar, is_staff, is_holiday_family_certified
```

### Pet（宠物）
```
id, name, species, breed, sex, age_years, age_months, size,
city, address, description, status, photo, photos[],
dewormed, vaccinated, microchipped, sterilized,
child_friendly, trained, loves_play, loves_walks,
good_with_dogs, good_with_cats, affectionate,
contact_phone, shelter_id, shelter_name, shelter_address
```

### LostPet（走失宠物）
```
id, pet_name, species, breed, color, sex, size,
city, street, latitude, longitude,
lost_time, description, reward, photo,
status (open/found/closed),
contact_phone, contact_email, reporter_username
```

### Shelter（收容所）
```
id, name, description, email, phone, website,
city, street, latitude, longitude,
logo_url, cover_url, capacity, current_animals,
is_verified, is_active, facebook_url, instagram_url
```

### Article（文章）
```
id, title, description, content, category, tags[],
count, add_date, author: {id, username, avatar}, is_favorited
```

### Message（消息）
```
id, sender: {id, username, avatar},
recipient: {id, username, avatar},
content, created_at, is_read
```

### Notification（通知）
```
id, notification_type (reply/mention/system),
content, is_read, created_at, related_object
```

---

## 五、通用功能需求

### 1. 认证与权限
- Token自动刷新机制
- 未登录时部分功能限制（收藏、发布、申请等）
- 登录状态持久化

### 2. 图片处理
- 图片上传（相机/相册）
- 图片压缩
- 图片预览轮播

### 3. 地图功能
- 显示位置标记
- 地址选择器
- 点击标记查看详情
- 导航到外部地图App

### 4. 列表通用功能
- 下拉刷新
- 上拉加载更多
- 空状态提示
- 加载中状态

### 5. 表单通用功能
- 输入验证
- 错误提示
- 提交loading状态
- 成功/失败反馈

### 6. 推送通知（可选）
- 新消息提醒
- 新通知提醒
- 领养申请状态更新

---

## 六、页面总数统计

| 模块 | 页面数 |
|------|--------|
| 首页 | 1 |
| 领养 | 4 |
| 走失 | 3 |
| 发现流浪 | 1 |
| 收容所 | 2 |
| 博客 | 3 |
| 假日家庭 | 3 |
| 消息 | 2 |
| 通知 | 1 |
| 用户 | 8 |
| 认证 | 4 |
| **总计** | **32** |

---

*文档生成日期：2026-01-26*
