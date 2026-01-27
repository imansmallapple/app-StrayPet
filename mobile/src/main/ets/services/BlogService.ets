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

export class ArticleFilter {
  category: string = '';
  tag: string = '';
  search: string = '';
  page: number = 1;
  page_size: number = 20;

  constructor() {}

  toQueryParams(): Map<string, string> {
    const params = new Map<string, string>();
    if (this.category.length > 0) params.set('category', this.category);
    if (this.tag.length > 0) params.set('tag', this.tag);
    if (this.search.length > 0) params.set('search', this.search);
    params.set('page', this.page.toString());
    params.set('page_size', this.page_size.toString());
    return params;
  }
}

// API Endpoints for Blog
class BlogEndpoints {
  static readonly ARTICLES: string = 'blog/article/';
  static readonly ARTICLE_DETAIL: string = 'blog/article/{id}/';
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
}
