/**
 * apiClient.ts
 * Cliente HTTP tipado con soporte para JSON nativo, cabeceras seguras y control de errores.
 */

export interface ApiRequestOptions extends RequestInit {
  timeoutMs?: number;
}

export class ApiError extends Error {
  public status: number;
  public data?: unknown;

  constructor(message: string, status: number, data?: unknown) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

export async function apiClient<T>(url: string, options: ApiRequestOptions = {}): Promise<T> {
  const { timeoutMs = 15000, headers, ...restOptions } = options;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, {
      ...restOptions,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...headers,
      },
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      let errorBody: unknown;
      try {
        errorBody = await response.json();
      } catch {
        errorBody = await response.text();
      }
      throw new ApiError(
        `Error HTTP ${response.status}: ${response.statusText}`,
        response.status,
        errorBody
      );
    }

    return (await response.json()) as T;
  } catch (error: unknown) {
    clearTimeout(timeoutId);
    if (error instanceof ApiError) {
      throw error;
    }
    if (error instanceof Error && error.name === 'AbortError') {
      throw new ApiError(`Tiempo de espera agotado (${timeoutMs}ms) al conectar con ${url}`, 408);
    }
    const message = error instanceof Error ? error.message : 'Error desconocido de red';
    throw new ApiError(message, 500, error);
  }
}

export const api = {
  get: <T>(url: string, options?: ApiRequestOptions) =>
    apiClient<T>(url, { ...options, method: 'GET' }),

  post: <T>(url: string, body?: unknown, options?: ApiRequestOptions) =>
    apiClient<T>(url, {
      ...options,
      method: 'POST',
      body: body ? JSON.stringify(body) : undefined,
    }),

  put: <T>(url: string, body?: unknown, options?: ApiRequestOptions) =>
    apiClient<T>(url, {
      ...options,
      method: 'PUT',
      body: body ? JSON.stringify(body) : undefined,
    }),

  delete: <T>(url: string, options?: ApiRequestOptions) =>
    apiClient<T>(url, { ...options, method: 'DELETE' }),
};
