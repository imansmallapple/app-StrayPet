// Social Service - Friends, Messages, Notifications
// Following ArkTS strict typing rules

import { HttpClient } from './HttpClient';
import { ApiConfig, ApiEndpoints } from './ApiConfig';
import { TokenManager } from './TokenManager';

// ======================= Models =======================

export class SimpleUser {
  id: number = 0;
  username: string = '';
  avatar: string = '';

  constructor(id: number = 0, username: string = '', avatar: string = '') {
    this.id = id;
    this.username = username;
    this.avatar = avatar;
  }
}

export class Friend {
  id: number = 0;
  friendship_id: number = 0;
  username: string = '';
  email: string = '';
  avatar: string = '';

  constructor() {}
}

export class Friendship {
  id: number = 0;
  from_user: SimpleUser = new SimpleUser();
  to_user: SimpleUser = new SimpleUser();
  status: string = ''; // pending, accepted, blocked
  created_at: string = '';
  updated_at: string = '';

  constructor() {}

  getStatusDisplay(): string {
    const statusMap: Map<string, string> = new Map([
      ['pending', 'Pending'],
      ['accepted', 'Accepted'],
      ['blocked', 'Blocked']
    ]);
    const result = statusMap.get(this.status);
    return result !== undefined ? result : this.status;
  }
}

export class PrivateMessage {
  id: number = 0;
  sender: SimpleUser = new SimpleUser();
  recipient: SimpleUser = new SimpleUser();
  content: string = '';
  is_read: boolean = false;
  is_system: boolean = false;
  created_at: string = '';
  read_at: string = '';

  constructor() {}

  getFormattedTime(): string {
    if (this.created_at.length === 0) {
      return '';
    }
    try {
      const date = new Date(this.created_at);
      const now = new Date();
      const diff = now.getTime() - date.getTime();
      const days = Math.floor(diff / (1000 * 60 * 60 * 24));

      if (days === 0) {
        // Today - show time
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      } else if (days === 1) {
        return 'Yesterday';
      } else if (days < 7) {
        return `${days} days ago`;
      } else {
        return date.toLocaleDateString();
      }
    } catch (e) {
      return this.created_at;
    }
  }
}

export class Conversation {
  user_id: number = 0;
  username: string = '';
  avatar: string = '';
  last_message: string = '';
  last_time: string = '';
  unread_count: number = 0;
  is_system: boolean = false;

  constructor() {}
}

export class Notification {
  id: number = 0;
  notification_type: string = '';
  title: string = '';
  content: string = '';
  from_user: SimpleUser | null = null;
  comment_content: string = '';
  friendship_id: number | null = null;
  holiday_family_application_id: number | null = null;
  is_read: boolean = false;
  created_at: string = '';
  read_at: string = '';

  constructor() {}

  getTypeDisplay(): string {
    const typeMap: Map<string, string> = new Map([
      ['reply', 'Comment Reply'],
      ['mention', 'Mention'],
      ['friend_request', 'Friend Request'],
      ['system', 'System'],
      ['holiday_family_apply', 'Holiday Family Application'],
      ['holiday_family_approve', 'Application Approved'],
      ['holiday_family_reject', 'Application Rejected']
    ]);
    const result = typeMap.get(this.notification_type);
    return result !== undefined ? result : this.notification_type;
  }

  getIcon(): string {
    const iconMap: Map<string, string> = new Map([
      ['reply', '💬'],
      ['mention', '@'],
      ['friend_request', '👋'],
      ['system', '📢'],
      ['holiday_family_apply', '🏠'],
      ['holiday_family_approve', '✅'],
      ['holiday_family_reject', '❌']
    ]);
    const result = iconMap.get(this.notification_type);
    return result !== undefined ? result : '🔔';
  }

  getFormattedTime(): string {
    if (this.created_at.length === 0) {
      return '';
    }
    try {
      const date = new Date(this.created_at);
      const now = new Date();
      const diff = now.getTime() - date.getTime();
      const minutes = Math.floor(diff / (1000 * 60));
      const hours = Math.floor(diff / (1000 * 60 * 60));
      const days = Math.floor(diff / (1000 * 60 * 60 * 24));

      if (minutes < 1) {
        return 'Just now';
      } else if (minutes < 60) {
        return `${minutes}m ago`;
      } else if (hours < 24) {
        return `${hours}h ago`;
      } else if (days < 7) {
        return `${days}d ago`;
      } else {
        return date.toLocaleDateString();
      }
    } catch (e) {
      return this.created_at;
    }
  }
}

// ======================= Results =======================

export class FriendsListResult {
  success: boolean = false;
  friends: Friend[] = [];
  count: number = 0;
  errorMessage: string = '';

  constructor() {}
}

export class FriendshipResult {
  success: boolean = false;
  friendship: Friendship | null = null;
  errorMessage: string = '';

  constructor() {}
}

export class MessagesResult {
  success: boolean = false;
  messages: PrivateMessage[] = [];
  errorMessage: string = '';

  constructor() {}
}

export class ConversationsResult {
  success: boolean = false;
  conversations: Conversation[] = [];
  errorMessage: string = '';

  constructor() {}
}

export class NotificationsResult {
  success: boolean = false;
  notifications: Notification[] = [];
  count: number = 0;
  unread_count: number = 0;
  errorMessage: string = '';

  constructor() {}
}

export class SimpleResult {
  success: boolean = false;
  errorMessage: string = '';

  constructor() {}
}

// Search user result
export class SearchUser {
  id: number = 0;
  username: string = '';
  email: string = '';
  avatar: string = '';
  friendship_status: string | null = null;
  friendship_id: number | null = null;
  is_sent_by_me: boolean = false;

  constructor() {}
}

export class SearchUsersResult {
  success: boolean = false;
  users: SearchUser[] = [];
  count: number = 0;
  errorMessage: string = '';

  constructor() {}
}

// ======================= Service =======================

export class SocialService {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = HttpClient.getInstance();
  }

  // ======================= Friendship APIs =======================

  async getFriendsList(page: number = 1, pageSize: number = 20): Promise<FriendsListResult> {
    const result = new FriendsListResult();
    const queryParams = new Map<string, string>();
    queryParams.set('page', page.toString());
    queryParams.set('page_size', pageSize.toString());

    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.FRIENDS_LIST, queryParams);

    try {
      console.info('[SocialService] Getting friends list from:', url);
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const friend = new Friend();
            friend.id = Number(item['id']) || 0;
            friend.friendship_id = Number(item['friendship_id']) || 0;
            friend.username = String(item['username']) || '';
            friend.email = String(item['email']) || '';
            friend.avatar = String(item['avatar']) || '';
            result.friends.push(friend);
          });
        }

        result.count = Number(parsed['count']) || 0;
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get friends list';
      console.error('[SocialService] getFriendsList error:', result.errorMessage);
    }

    return result;
  }

  async searchUsers(query: string): Promise<SearchUsersResult> {
    const result = new SearchUsersResult();
    const queryParams = new Map<string, string>();
    queryParams.set('q', query);

    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.SEARCH_USERS, queryParams);

    try {
      console.info('[SocialService] Searching users with query:', query);
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Object[];

        if (resultsArray !== undefined && Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Object) => {
            const user = new SearchUser();
            const itemRecord = item as Record<string, Object>;
            user.id = Number(itemRecord['id']) || 0;
            user.username = String(itemRecord['username']) || '';
            user.email = String(itemRecord['email']) || '';
            user.avatar = String(itemRecord['avatar']) || '';
            user.friendship_status = itemRecord['friendship_status'] !== null && itemRecord['friendship_status'] !== undefined
              ? String(itemRecord['friendship_status']) : null;
            user.friendship_id = itemRecord['friendship_id'] !== null && itemRecord['friendship_id'] !== undefined
              ? Number(itemRecord['friendship_id']) : null;
            user.is_sent_by_me = Boolean(itemRecord['is_sent_by_me']) || false;
            result.users.push(user);
          });
        }

        result.count = Number(parsed['count']) || 0;
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to search users';
      console.error('[SocialService] searchUsers error:', result.errorMessage);
    }

    return result;
  }

  async addFriend(userId: number): Promise<FriendshipResult> {
    const result = new FriendshipResult();
    const url = ApiConfig.buildUrl(ApiEndpoints.FRIENDSHIP_ADD);

    try {
      console.info('[SocialService] Adding friend:', userId);
      const response = await this.httpClient.post(url, JSON.stringify({ user_id: userId }), true);

      if (response.success) {
        result.friendship = this.parseFriendship(response.data);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to add friend';
      console.error('[SocialService] addFriend error:', result.errorMessage);
    }

    return result;
  }

  async acceptFriendRequest(friendshipId: number): Promise<FriendshipResult> {
    const result = new FriendshipResult();
    const params = new Map<string, string>();
    params.set('id', friendshipId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.FRIENDSHIP_ACCEPT, params);

    try {
      console.info('[SocialService] Accepting friend request:', friendshipId, 'url:', url);
      const response = await this.httpClient.post(url, '{}', true);
      console.info('[SocialService] Response success:', response.success, 'code:', response.code);
      console.info('[SocialService] Response data:', response.data);
      console.info('[SocialService] Response errorMessage:', response.errorMessage);

      if (response.success) {
        result.friendship = this.parseFriendship(response.data);
        result.success = true;
      } else {
        // Check both response.errorMessage and parsed error from data
        if (response.errorMessage.length > 0) {
          result.errorMessage = response.errorMessage;
        } else if (response.data.length > 0) {
          result.errorMessage = this.parseErrorMessage(response.data);
        } else {
          result.errorMessage = 'Network error or server unreachable';
        }
        console.info('[SocialService] Final error message:', result.errorMessage);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to accept friend request';
      console.error('[SocialService] acceptFriendRequest error:', result.errorMessage);
    }

    return result;
  }

  async rejectFriendRequest(friendshipId: number): Promise<FriendshipResult> {
    const result = new FriendshipResult();
    const params = new Map<string, string>();
    params.set('id', friendshipId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.FRIENDSHIP_REJECT, params);

    try {
      console.info('[SocialService] Rejecting friend request:', friendshipId, 'url:', url);
      const response = await this.httpClient.post(url, '{}', true);

      if (response.success) {
        result.friendship = this.parseFriendship(response.data);
        result.success = true;
      } else {
        if (response.errorMessage.length > 0) {
          result.errorMessage = response.errorMessage;
        } else if (response.data.length > 0) {
          result.errorMessage = this.parseErrorMessage(response.data);
        } else {
          result.errorMessage = 'Network error or server unreachable';
        }
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to reject friend request';
      console.error('[SocialService] rejectFriendRequest error:', result.errorMessage);
    }

    return result;
  }

  async deleteFriend(friendshipId: number): Promise<SimpleResult> {
    const result = new SimpleResult();
    const params = new Map<string, string>();
    params.set('id', friendshipId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.FRIENDSHIP_DELETE, params);

    try {
      console.info('[SocialService] Deleting friend:', friendshipId);
      const response = await this.httpClient.delete(url, true);

      if (response.success) {
        result.success = true;
      } else {
        // 204 No Content is also success for DELETE
        if (response.data.length === 0) {
          result.success = true;
        } else {
          result.errorMessage = this.parseErrorMessage(response.data);
        }
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to delete friend';
      console.error('[SocialService] deleteFriend error:', result.errorMessage);
    }

    return result;
  }

  async checkFriendship(userId: number): Promise<FriendshipResult> {
    const result = new FriendshipResult();
    const queryParams = new Map<string, string>();
    queryParams.set('user_id', userId.toString());
    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.FRIENDSHIP_CHECK, queryParams);

    try {
      console.info('[SocialService] Checking friendship with user:', userId);
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        // Check if friendship exists (has an id)
        if (parsed['id'] !== null && parsed['id'] !== undefined) {
          result.friendship = this.parseFriendship(response.data);
        }
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to check friendship';
      console.error('[SocialService] checkFriendship error:', result.errorMessage);
    }

    return result;
  }

  // ======================= Message APIs =======================

  async getConversation(userId: number): Promise<MessagesResult> {
    const result = new MessagesResult();
    const queryParams = new Map<string, string>();
    queryParams.set('user_id', userId.toString());
    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.MESSAGE_CONVERSATION, queryParams);

    try {
      console.info('[SocialService] Getting conversation with user:', userId);
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const message = this.parseMessage(item);
            result.messages.push(message);
          });
        }

        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get conversation';
      console.error('[SocialService] getConversation error:', result.errorMessage);
    }

    return result;
  }

  async sendMessage(recipientId: number, content: string): Promise<SimpleResult> {
    const result = new SimpleResult();
    const url = ApiConfig.buildUrl(ApiEndpoints.MESSAGES);

    try {
      console.info('[SocialService] Sending message to user:', recipientId);
      const response = await this.httpClient.post(url, JSON.stringify({
        recipient_id: recipientId,
        content: content
      }), true);

      if (response.success) {
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to send message';
      console.error('[SocialService] sendMessage error:', result.errorMessage);
    }

    return result;
  }

  async getAllMessages(): Promise<ConversationsResult> {
    const result = new ConversationsResult();
    const url = ApiConfig.buildUrl(ApiEndpoints.MESSAGES);

    try {
      console.info('[SocialService] Getting all messages');
      const response = await this.httpClient.get(url, true);
      const currentUserId = TokenManager.getInstance().getUserId();
      console.info('[SocialService] Current user ID:', currentUserId);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;
        console.info('[SocialService] Total messages received:', resultsArray ? resultsArray.length : 0);

        // Group messages by conversation partner
        const conversationMap = new Map<number, Conversation>();

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>, index: number) => {
            const message = this.parseMessage(item);
            const senderId = message.sender.id;
            const recipientId = message.recipient.id;
            
            // Determine conversation partner: if I'm the sender, partner is recipient; otherwise partner is sender
            let partnerId: number;
            let partner: SimpleUser;
            
            if (senderId === currentUserId) {
              // I sent this message, partner is the recipient
              partnerId = recipientId;
              partner = message.recipient;
            } else {
              // I received this message, partner is the sender
              partnerId = senderId;
              partner = message.sender;
            }

            // Skip if we can't determine partner or partner is current user
            if (partnerId === 0 || partnerId === currentUserId) {
              console.info('[SocialService] Skipping message, partnerId:', partnerId);
              return;
            }

            let conv = conversationMap.get(partnerId);
            if (conv === undefined) {
              // First message for this partner (should be the most recent)
              conv = new Conversation();
              conv.user_id = partnerId;
              conv.username = partner.username;
              conv.avatar = partner.avatar;
              conv.last_message = message.content;
              conv.last_time = message.getFormattedTime();
              // Only count unread if I'm the recipient
              conv.unread_count = (!message.is_read && recipientId === currentUserId) ? 1 : 0;
              conv.is_system = message.is_system;
              conversationMap.set(partnerId, conv);
              console.info('[SocialService] New conversation with', partner.username, 'last_message:', message.content.substring(0, 30));
            } else {
              // Update unread count - only if I'm the recipient
              if (!message.is_read && recipientId === currentUserId) {
                conv.unread_count++;
              }
            }
          });
        }

        // Convert map to array
        conversationMap.forEach((conv: Conversation) => {
          result.conversations.push(conv);
        });
        
        console.info('[SocialService] Total conversations:', result.conversations.length);

        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get messages';
      console.error('[SocialService] getAllMessages error:', result.errorMessage);
    }

    return result;
  }

  async markMessageAsRead(messageId: number): Promise<SimpleResult> {
    const result = new SimpleResult();
    const params = new Map<string, string>();
    params.set('id', messageId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.MESSAGE_READ, params);

    try {
      const response = await this.httpClient.post(url, '', true);
      if (response.success) {
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to mark as read';
    }

    return result;
  }

  // ======================= Notification APIs =======================

  async getNotifications(page: number = 1, pageSize: number = 20): Promise<NotificationsResult> {
    const result = new NotificationsResult();
    const queryParams = new Map<string, string>();
    queryParams.set('page', page.toString());
    queryParams.set('page_size', pageSize.toString());

    const url = ApiConfig.buildUrlWithQuery(ApiEndpoints.NOTIFICATIONS, queryParams);

    try {
      console.info('[SocialService] Getting notifications from:', url);
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const notification = this.parseNotification(item);
            result.notifications.push(notification);
            if (!notification.is_read) {
              result.unread_count++;
            }
          });
        }

        result.count = Number(parsed['count']) || 0;
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get notifications';
      console.error('[SocialService] getNotifications error:', result.errorMessage);
    }

    return result;
  }

  async markNotificationAsRead(notificationId: number): Promise<SimpleResult> {
    const result = new SimpleResult();
    const params = new Map<string, string>();
    params.set('id', notificationId.toString());
    const url = ApiConfig.buildUrl(ApiEndpoints.NOTIFICATION_READ, params);

    try {
      const response = await this.httpClient.post(url, '', true);
      if (response.success) {
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to mark as read';
    }

    return result;
  }

  // ======================= Parse Helpers =======================

  private parseFriendship(jsonString: string): Friendship {
    const friendship = new Friendship();
    try {
      const parsed = JSON.parse(jsonString) as Record<string, Object>;
      friendship.id = Number(parsed['id']) || 0;
      friendship.status = String(parsed['status']) || '';
      friendship.created_at = String(parsed['created_at']) || '';
      friendship.updated_at = String(parsed['updated_at']) || '';

      const fromUserObj = parsed['from_user'] as Record<string, Object>;
      if (fromUserObj) {
        friendship.from_user = new SimpleUser(
          Number(fromUserObj['id']) || 0,
          String(fromUserObj['username']) || ''
        );
      }

      const toUserObj = parsed['to_user'] as Record<string, Object>;
      if (toUserObj) {
        friendship.to_user = new SimpleUser(
          Number(toUserObj['id']) || 0,
          String(toUserObj['username']) || ''
        );
      }
    } catch (error) {
      console.error('[SocialService] Failed to parse friendship:', error);
    }
    return friendship;
  }

  private parseMessage(item: Record<string, Object>): PrivateMessage {
    const message = new PrivateMessage();
    message.id = Number(item['id']) || 0;
    message.content = String(item['content']) || '';
    message.is_read = Boolean(item['is_read']);
    message.is_system = Boolean(item['is_system']);
    message.created_at = String(item['created_at']) || '';
    message.read_at = String(item['read_at']) || '';

    const senderObj = item['sender'] as Record<string, Object>;
    if (senderObj) {
      message.sender = new SimpleUser(
        Number(senderObj['id']) || 0,
        String(senderObj['username']) || '',
        String(senderObj['avatar']) || ''
      );
    }

    const recipientObj = item['recipient'] as Record<string, Object>;
    if (recipientObj) {
      message.recipient = new SimpleUser(
        Number(recipientObj['id']) || 0,
        String(recipientObj['username']) || '',
        String(recipientObj['avatar']) || ''
      );
    }

    return message;
  }

  private parseNotification(item: Record<string, Object>): Notification {
    const notification = new Notification();
    notification.id = Number(item['id']) || 0;
    notification.notification_type = item['notification_type'] !== null && item['notification_type'] !== undefined ? String(item['notification_type']) : '';
    notification.title = item['title'] !== null && item['title'] !== undefined ? String(item['title']) : '';
    notification.content = item['content'] !== null && item['content'] !== undefined ? String(item['content']) : '';
    notification.comment_content = item['comment_content'] !== null && item['comment_content'] !== undefined ? String(item['comment_content']) : '';
    notification.is_read = Boolean(item['is_read']);
    notification.created_at = item['created_at'] !== null && item['created_at'] !== undefined ? String(item['created_at']) : '';
    notification.read_at = item['read_at'] !== null && item['read_at'] !== undefined ? String(item['read_at']) : '';

    const friendshipId = item['friendship_id'];
    console.info('[SocialService] parseNotification friendshipId raw:', friendshipId, 'type:', typeof friendshipId);
    if (friendshipId !== null && friendshipId !== undefined && friendshipId !== 0) {
      notification.friendship_id = Number(friendshipId);
      console.info('[SocialService] parseNotification friendship_id set to:', notification.friendship_id);
    }

    const applicationId = item['holiday_family_application_id'];
    if (applicationId !== null && applicationId !== undefined && applicationId !== 0) {
      notification.holiday_family_application_id = Number(applicationId);
    }

    const fromUserObj = item['from_user'] as Record<string, Object>;
    if (fromUserObj) {
      notification.from_user = new SimpleUser(
        Number(fromUserObj['id']) || 0,
        String(fromUserObj['username']) || ''
      );
    }

    return notification;
  }

  private parseErrorMessage(jsonString: string): string {
    try {
      const parsed = JSON.parse(jsonString) as Record<string, Object>;
      if (parsed['detail'] !== undefined) {
        return String(parsed['detail']);
      }
      if (parsed['error'] !== undefined) {
        return String(parsed['error']);
      }
      const keys = Object.keys(parsed);
      if (keys.length > 0) {
        const firstValue = parsed[keys[0]];
        if (Array.isArray(firstValue) && firstValue.length > 0) {
          return String(firstValue[0]);
        }
        return String(firstValue);
      }
    } catch (error) {
      return jsonString;
    }
    return 'Unknown error';
  }
}
