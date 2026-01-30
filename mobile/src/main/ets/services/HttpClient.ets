// HTTP Client Service
// Following ArkTS strict typing rules

import { http } from '@kit.NetworkKit';
import { ApiConfig } from './ApiConfig';
import { TokenManager } from './TokenManager';

export class HttpResponse {
  code: number = 0;
  data: string = '';
  success: boolean = false;
  errorMessage: string = '';

  constructor(code: number = 0, data: string = '', success: boolean = false, errorMessage: string = '') {
    this.code = code;
    this.data = data;
    this.success = success;
    this.errorMessage = errorMessage;
  }
}

export class HttpClient {
  private static instance: HttpClient | null = null;

  static getInstance(): HttpClient {
    if (HttpClient.instance === null) {
      HttpClient.instance = new HttpClient();
    }
    return HttpClient.instance;
  }

  private getHeaders(needAuth: boolean): Object {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };

    if (needAuth) {
      const token = TokenManager.getInstance().getAccessToken();
      if (token.length > 0) {
        headers['Authorization'] = `Bearer ${token}`;
      }
    }

    return headers;
  }

  async get(url: string, needAuth: boolean = true): Promise<HttpResponse> {
    const httpRequest = http.createHttp();
    const response = new HttpResponse();
    const headers = this.getHeaders(needAuth);
    console.info('[HttpClient] GET', url);
    console.info('[HttpClient] Auth:', needAuth ? 'required' : 'none');

    try {
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: ApiConfig.TIMEOUT,
        readTimeout: ApiConfig.TIMEOUT
      });

      response.code = result.responseCode;
      response.success = result.responseCode >= 200 && result.responseCode < 300;
      console.info('[HttpClient] Response code:', result.responseCode);

      if (typeof result.result === 'string') {
        response.data = result.result;
      } else {
        response.data = JSON.stringify(result.result);
      }

      // Handle 401 - try to refresh token
      if (result.responseCode === 401 && needAuth) {
        console.info('[HttpClient] Got 401, trying to refresh token...');
        httpRequest.destroy();
        const refreshed = await TokenManager.getInstance().refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          console.info('[HttpClient] Token refreshed, retrying request...');
          return this.get(url, needAuth);
        } else {
          console.error('[HttpClient] Token refresh failed');
          response.errorMessage = 'Authentication failed. Please login again.';
        }
        return response;
      }
    } catch (error) {
      response.success = false;
      if (error instanceof Error) {
        response.errorMessage = error.message;
      } else {
        response.errorMessage = 'Unknown error occurred';
      }
      console.error('[HttpClient] Error:', response.errorMessage);
    } finally {
      httpRequest.destroy();
    }

    return response;
  }

  async post(url: string, body: string, needAuth: boolean = true): Promise<HttpResponse> {
    const httpRequest = http.createHttp();
    const response = new HttpResponse();

    try {
      console.info('[HttpClient] POST request to:', url);
      console.info('[HttpClient] POST body:', body);
      const headers = this.getHeaders(needAuth);
      console.info('[HttpClient] POST headers:', JSON.stringify(headers));
      
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: body.length > 0 ? body : '{}',
        connectTimeout: ApiConfig.TIMEOUT,
        readTimeout: ApiConfig.TIMEOUT
      });

      response.code = result.responseCode;
      response.success = result.responseCode >= 200 && result.responseCode < 300;
      console.info('[HttpClient] POST response code:', result.responseCode);

      if (typeof result.result === 'string') {
        response.data = result.result;
      } else {
        response.data = JSON.stringify(result.result);
      }

      // Handle 401 - try to refresh token
      if (result.responseCode === 401 && needAuth) {
        console.info('[HttpClient] POST got 401, trying to refresh token...');
        httpRequest.destroy();
        const refreshed = await TokenManager.getInstance().refreshAccessToken();
        if (refreshed) {
          console.info('[HttpClient] Token refreshed, retrying POST request...');
          return this.post(url, body, needAuth);
        } else {
          console.error('[HttpClient] Token refresh failed for POST');
          response.errorMessage = 'Authentication failed. Please login again.';
        }
        return response;
      }
    } catch (error) {
      response.success = false;
      if (error instanceof Error) {
        response.errorMessage = error.message;
        console.error('[HttpClient] POST error:', error.message);
      } else {
        response.errorMessage = 'Unknown error occurred';
        console.error('[HttpClient] POST unknown error:', JSON.stringify(error));
      }
    } finally {
      httpRequest.destroy();
    }

    return response;
  }

  async put(url: string, body: string, needAuth: boolean = true): Promise<HttpResponse> {
    const httpRequest = http.createHttp();
    const response = new HttpResponse();

    try {
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.PUT,
        header: this.getHeaders(needAuth),
        extraData: body,
        connectTimeout: ApiConfig.TIMEOUT,
        readTimeout: ApiConfig.TIMEOUT
      });

      response.code = result.responseCode;
      response.success = result.responseCode >= 200 && result.responseCode < 300;

      if (typeof result.result === 'string') {
        response.data = result.result;
      } else {
        response.data = JSON.stringify(result.result);
      }
    } catch (error) {
      response.success = false;
      if (error instanceof Error) {
        response.errorMessage = error.message;
      } else {
        response.errorMessage = 'Unknown error occurred';
      }
    } finally {
      httpRequest.destroy();
    }

    return response;
  }

  async patch(url: string, body: string, needAuth: boolean = true): Promise<HttpResponse> {
    const httpRequest = http.createHttp();
    const response = new HttpResponse();

    try {
      // Note: Using PUT as PATCH is not available in HarmonyOS http module
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.PUT,
        header: this.getHeaders(needAuth),
        extraData: body,
        connectTimeout: ApiConfig.TIMEOUT,
        readTimeout: ApiConfig.TIMEOUT
      });

      response.code = result.responseCode;
      response.success = result.responseCode >= 200 && result.responseCode < 300;

      if (typeof result.result === 'string') {
        response.data = result.result;
      } else {
        response.data = JSON.stringify(result.result);
      }
    } catch (error) {
      response.success = false;
      if (error instanceof Error) {
        response.errorMessage = error.message;
      } else {
        response.errorMessage = 'Unknown error occurred';
      }
    } finally {
      httpRequest.destroy();
    }

    return response;
  }

  async delete(url: string, needAuth: boolean = true): Promise<HttpResponse> {
    const httpRequest = http.createHttp();
    const response = new HttpResponse();

    try {
      const result = await httpRequest.request(url, {
        method: http.RequestMethod.DELETE,
        header: this.getHeaders(needAuth),
        connectTimeout: ApiConfig.TIMEOUT,
        readTimeout: ApiConfig.TIMEOUT
      });

      response.code = result.responseCode;
      response.success = result.responseCode >= 200 && result.responseCode < 300;

      if (typeof result.result === 'string') {
        response.data = result.result;
      } else {
        response.data = JSON.stringify(result.result);
      }
    } catch (error) {
      response.success = false;
      if (error instanceof Error) {
        response.errorMessage = error.message;
      } else {
        response.errorMessage = 'Unknown error occurred';
      }
    } finally {
      httpRequest.destroy();
    }

    return response;
  }
}
