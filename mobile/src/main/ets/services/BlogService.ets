// Blog API Service
// Following ArkTS strict typing rules

import { HttpClient } from './HttpClient';
import { ApiConfig } from './ApiConfig';

// Blog models
export class BlogAuthor {
  id: number = 0;
  username: string = '';
  avatar: string = '';

  constructor() {}
}

export class BlogCategory {
  id: number = 0;
  name: string = '';
  parent: number | null = null;
  add_date: string = '';
  pub_date: string = '';

  constructor() {}
}

export class BlogTag {
  id: number = 0;
  name: string = '';
  article_count: number = 0;

  constructor() {}
}

export class BlogArticle {
  id: number = 0;
  title: string = '';
  content: string = '';
  excerpt: string = '';
  cover: string = '';
  author: BlogAuthor | null = null;
  category: string = '';
  tags: string[] = [];
  count: number = 0;
  is_favorited: boolean = false;
  add_date: string = '';
  pub_date: string = '';

  constructor() {}

  getFormattedDate(): string {
    if (this.pub_date.length === 0) return '';
    const date = new Date(this.pub_date);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
}

export class ArticleListResult {
  success: boolean = false;
  articles: BlogArticle[] = [];
  count: number = 0;
  next: string = '';
  previous: string = '';
  errorMessage: string = '';

  constructor() {}
}

export class ArticleDetailResult {
  success: boolean = false;
  article: BlogArticle | null = null;
  errorMessage: string = '';

  constructor() {}
}

export class CategoryListResult {
  success: boolean = false;
  categories: BlogCategory[] = [];
  errorMessage: string = '';

  constructor() {}
}

export class TagListResult {
  success: boolean = false;
  tags: BlogTag[] = [];
  errorMessage: string = '';

  constructor() {}
}

// Comment models
export class CommentUser {
  id: number = 0;
  username: string = '';
  avatar: string = '';

  constructor() {}
}

export class BlogComment {
  id: number = 0;
  user: CommentUser | null = null;
  content: string = '';
  add_date: string = '';
  pub_date: string = '';
  parent: number | null = null;
  replies: BlogComment[] = [];

  constructor() {}

  getFormattedDate(): string {
    if (this.add_date.length === 0) return '';
    const date = new Date(this.add_date);
    const now = new Date();

    // Check if same day
    const isToday = date.getFullYear() === now.getFullYear() &&
                    date.getMonth() === now.getMonth() &&
                    date.getDate() === now.getDate();

    // Check if yesterday
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const isYesterday = date.getFullYear() === yesterday.getFullYear() &&
                        date.getMonth() === yesterday.getMonth() &&
                        date.getDate() === yesterday.getDate();

    // Format time as HH:MM AM/PM
    let hours = date.getHours();
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    hours = hours ? hours : 12; // 0 should be 12
    const timeStr = `${hours.toString().padStart(2, '0')}:${minutes} ${ampm}`;

    if (isToday) {
      return `Today, ${timeStr}`;
    } else if (isYesterday) {
      return `Yesterday, ${timeStr}`;
    } else {
      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const day = date.getDate().toString().padStart(2, '0');
      return `${month}/${day}, ${timeStr}`;
    }
  }
}

export class CommentListResult {
  success: boolean = false;
  comments: BlogComment[] = [];
  count: number = 0;
  errorMessage: string = '';

  constructor() {}
}

export class PostCommentResult {
  success: boolean = false;
  comment: BlogComment | null = null;
  errorMessage: string = '';

  constructor() {}
}

// Archive item for grouping articles by month
export class ArchiveItem {
  year: number = 0;
  month: number = 0;
  count: number = 0;
  label: string = '';

  constructor() {}
}

export class ArticleFilter {
  category: string = '';
  tag: string = '';
  search: string = '';
  ordering: string = '-pub_date'; // Default: Latest first. Options: '-pub_date', 'pub_date', '-count'
  page: number = 1;
  page_size: number = 20;

  constructor() {}

  toQueryParams(): Map<string, string> {
    const params = new Map<string, string>();
    if (this.category.length > 0) params.set('category', this.category);
    if (this.tag.length > 0) params.set('tag', this.tag);
    if (this.search.length > 0) params.set('search', this.search);
    if (this.ordering.length > 0) params.set('ordering', this.ordering);
    params.set('page', this.page.toString());
    params.set('page_size', this.page_size.toString());
    return params;
  }
}

// API Endpoints for Blog
class BlogEndpoints {
  static readonly ARTICLES: string = 'blog/article/';
  static readonly ARTICLE_DETAIL: string = 'blog/article/{id}/';
  static readonly ARTICLE_COMMENTS: string = 'blog/article/{id}/comments/';
  static readonly ARTICLE_ADD_COMMENT: string = 'blog/article/{id}/add_comment/';
  static readonly CATEGORIES: string = 'blog/category/';
  static readonly TAGS: string = 'blog/tag/';
}

export class BlogService {
  private httpClient: HttpClient;

  constructor() {
    this.httpClient = HttpClient.getInstance();
  }

  async getArticles(filter: ArticleFilter): Promise<ArticleListResult> {
    const result = new ArticleListResult();
    const url = ApiConfig.buildUrlWithQuery(BlogEndpoints.ARTICLES, filter.toQueryParams());

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const article = this.parseArticle(item);
            result.articles.push(article);
          });
        }

        result.count = Number(parsed['count']) || 0;
        result.next = String(parsed['next'] || '');
        result.previous = String(parsed['previous'] || '');
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get articles';
    }

    return result;
  }

  async getArticleDetail(articleId: number): Promise<ArticleDetailResult> {
    const result = new ArticleDetailResult();
    const endpoint = BlogEndpoints.ARTICLE_DETAIL.replace('{id}', articleId.toString());
    const url = ApiConfig.BASE_URL + endpoint;

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.article = this.parseArticle(parsed);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get article detail';
    }

    return result;
  }

  async getCategories(): Promise<CategoryListResult> {
    const result = new CategoryListResult();
    const url = ApiConfig.BASE_URL + BlogEndpoints.CATEGORIES;

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const category = this.parseCategory(item);
            result.categories.push(category);
          });
        }

        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get categories';
    }

    return result;
  }

  async getTags(): Promise<TagListResult> {
    const result = new TagListResult();
    const url = ApiConfig.BASE_URL + BlogEndpoints.TAGS;

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const tag = new BlogTag();
            tag.id = Number(item['id']) || 0;
            tag.name = String(item['name'] || '');
            tag.article_count = Number(item['article_count']) || 0;
            result.tags.push(tag);
          });
        }

        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get tags';
    }

    return result;
  }

  // Generate archives from articles
  generateArchives(articles: BlogArticle[]): ArchiveItem[] {
    const archiveMap = new Map<string, ArchiveItem>();
    const monthNames: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    articles.forEach((article: BlogArticle) => {
      if (article.pub_date.length > 0) {
        const date = new Date(article.pub_date);
        const year = date.getFullYear();
        const month = date.getMonth();
        const key = `${year}-${month}`;

        const existing = archiveMap.get(key);
        if (existing !== undefined) {
          existing.count += 1;
        } else {
          const item = new ArchiveItem();
          item.year = year;
          item.month = month + 1;
          item.count = 1;
          item.label = `${monthNames[month]} ${year}`;
          archiveMap.set(key, item);
        }
      }
    });

    // Convert to array and sort by date descending
    const archives: ArchiveItem[] = [];
    archiveMap.forEach((value: ArchiveItem) => {
      archives.push(value);
    });

    archives.sort((a: ArchiveItem, b: ArchiveItem) => {
      if (a.year !== b.year) return b.year - a.year;
      return b.month - a.month;
    });

    return archives;
  }

  private parseArticle(data: Record<string, Object>): BlogArticle {
    const article = new BlogArticle();
    article.id = Number(data['id']) || 0;
    article.title = String(data['title'] || '');
    article.content = String(data['content'] || '');
    article.excerpt = String(data['excerpt'] || '');
    article.cover = String(data['cover'] || '');
    article.category = String(data['category'] || '');
    article.count = Number(data['count']) || 0;
    article.is_favorited = Boolean(data['is_favorited']);
    article.add_date = String(data['add_date'] || '');
    article.pub_date = String(data['pub_date'] || '');

    // Parse author
    const authorData = data['author'] as Record<string, Object> | null;
    if (authorData !== null && authorData !== undefined) {
      article.author = this.parseAuthor(authorData);
    }

    // Parse tags
    const tagsData = data['tags'] as Array<string>;
    if (Array.isArray(tagsData)) {
      article.tags = tagsData;
    }

    return article;
  }

  private parseAuthor(data: Record<string, Object>): BlogAuthor {
    const author = new BlogAuthor();
    author.id = Number(data['id']) || 0;
    author.username = String(data['username'] || '');
    author.avatar = String(data['avatar'] || '');
    return author;
  }

  private parseCategory(data: Record<string, Object>): BlogCategory {
    const category = new BlogCategory();
    category.id = Number(data['id']) || 0;
    category.name = String(data['name'] || '');
    const parentVal = data['parent'];
    if (parentVal !== null && parentVal !== undefined) {
      category.parent = Number(parentVal);
    }
    category.add_date = String(data['add_date'] || '');
    category.pub_date = String(data['pub_date'] || '');
    return category;
  }

  private parseErrorMessage(responseData: string): string {
    try {
      const parsed = JSON.parse(responseData) as Record<string, Object>;
      if (parsed['detail'] !== undefined) {
        return String(parsed['detail']);
      }
      return 'Request failed';
    } catch (e) {
      return responseData || 'Request failed';
    }
  }

  // Comment related methods
  async getComments(articleId: number): Promise<CommentListResult> {
    const result = new CommentListResult();
    const endpoint = BlogEndpoints.ARTICLE_COMMENTS.replace('{id}', articleId.toString());
    const url = ApiConfig.BASE_URL + endpoint;

    try {
      const response = await this.httpClient.get(url, true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        const resultsArray = parsed['results'] as Array<Record<string, Object>>;

        if (Array.isArray(resultsArray)) {
          resultsArray.forEach((item: Record<string, Object>) => {
            const comment = this.parseComment(item);
            result.comments.push(comment);
          });
        }

        result.count = Number(parsed['count']) || result.comments.length;
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to get comments';
    }

    return result;
  }

  async postComment(articleId: number, content: string, parentId: number | null = null): Promise<PostCommentResult> {
    const result = new PostCommentResult();
    const endpoint = BlogEndpoints.ARTICLE_ADD_COMMENT.replace('{id}', articleId.toString());
    const url = ApiConfig.BASE_URL + endpoint;

    const bodyData: Record<string, Object> = new Object() as Record<string, Object>;
    bodyData['content'] = content;

    if (parentId !== null) {
      bodyData['parent'] = parentId;
    }

    try {
      const response = await this.httpClient.post(url, JSON.stringify(bodyData), true);

      if (response.success) {
        const parsed = JSON.parse(response.data) as Record<string, Object>;
        result.comment = this.parseComment(parsed);
        result.success = true;
      } else {
        result.errorMessage = this.parseErrorMessage(response.data);
      }
    } catch (error) {
      result.errorMessage = error instanceof Error ? error.message : 'Failed to post comment';
    }

    return result;
  }

  private parseComment(data: Record<string, Object>): BlogComment {
    const comment = new BlogComment();
    comment.id = Number(data['id']) || 0;
    comment.content = String(data['content'] || '');
    comment.add_date = String(data['add_date'] || '');
    comment.pub_date = String(data['pub_date'] || '');

    const parentVal = data['parent'];
    if (parentVal !== null && parentVal !== undefined) {
      comment.parent = Number(parentVal);
    }

    // Parse user
    const userData = data['user'] as Record<string, Object> | null;
    if (userData !== null && userData !== undefined) {
      const user = new CommentUser();
      user.id = Number(userData['id']) || 0;
      user.username = String(userData['username'] || '');
      user.avatar = String(userData['avatar'] || '');
      comment.user = user;
    }

    // Parse replies
    const repliesData = data['replies'] as Array<Record<string, Object>>;
    if (Array.isArray(repliesData)) {
      repliesData.forEach((replyData: Record<string, Object>) => {
        const reply = this.parseComment(replyData);
        comment.replies.push(reply);
      });
    }

    return comment;
  }
}
