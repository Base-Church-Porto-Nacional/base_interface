const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8080/api'

export class ApiError extends Error {
  status: number
  errorCode?: string
  path?: string
  body: unknown

  constructor(
    message: string,
    status: number,
    body?: unknown,
    errorCode?: string,
    path?: string,
  ) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.body = body
    this.errorCode = errorCode
    this.path = path
  }
}

type RequestOptions = Omit<RequestInit, 'body'> & {
  body?: unknown
  token?: string | null
}

function getStoredToken(): string | null {
  return localStorage.getItem('base_access_token')
}

export function setAccessToken(token: string | null): void {
  if (token) {
    localStorage.setItem('base_access_token', token)
  } else {
    localStorage.removeItem('base_access_token')
  }
}

function clearSession(): void {
  setAccessToken(null)
  localStorage.removeItem('base_user')
}

function redirectToLogin(): void {
  if (typeof window === 'undefined') return
  if (window.location.pathname === '/login') return
  const next = `${window.location.pathname}${window.location.search}`
  window.location.assign(`/login?next=${encodeURIComponent(next)}`)
}

function parseErrorPayload(payload: unknown, status: number): ApiError {
  if (typeof payload === 'object' && payload !== null) {
    const body = payload as Record<string, unknown>
    const message =
      typeof body.message === 'string' ? body.message : `Erro ${status}`
    const errorCode = typeof body.error === 'string' ? body.error : undefined
    const path = typeof body.path === 'string' ? body.path : undefined
    return new ApiError(message, status, payload, errorCode, path)
  }
  return new ApiError(`Erro ${status}`, status, payload)
}

export async function apiRequest<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const { body, token, headers: customHeaders, ...rest } = options
  const authToken = token === undefined ? getStoredToken() : token

  const headers: HeadersInit = {
    Accept: 'application/json',
    ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
    ...(authToken ? { Authorization: `Bearer ${authToken}` } : {}),
    ...customHeaders,
  }

  const response = await fetch(`${API_URL}${path}`, {
    ...rest,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })

  if (response.status === 401) {
    clearSession()
    redirectToLogin()
    throw new ApiError('Sessão expirada. Faça login novamente.', 401)
  }

  if (response.status === 204) {
    return undefined as T
  }

  const contentType = response.headers.get('content-type')
  const isJson = contentType?.includes('application/json')
  const payload = isJson ? await response.json() : await response.text()

  if (!response.ok) {
    throw parseErrorPayload(payload, response.status)
  }

  return payload as T
}

export async function apiDownload(
  path: string,
  filename: string,
  options: RequestOptions = {},
): Promise<void> {
  const { body, token, headers: customHeaders, ...rest } = options
  const authToken = token === undefined ? getStoredToken() : token

  const headers: HeadersInit = {
    ...(authToken ? { Authorization: `Bearer ${authToken}` } : {}),
    ...customHeaders,
  }

  const response = await fetch(`${API_URL}${path}`, {
    ...rest,
    method: rest.method ?? 'GET',
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })

  if (response.status === 401) {
    clearSession()
    redirectToLogin()
    throw new ApiError('Sessão expirada. Faça login novamente.', 401)
  }

  if (!response.ok) {
    const contentType = response.headers.get('content-type')
    const isJson = contentType?.includes('application/json')
    const payload = isJson ? await response.json() : await response.text()
    throw parseErrorPayload(payload, response.status)
  }

  const blob = await response.blob()
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = filename
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  URL.revokeObjectURL(url)
}

export const api = {
  get: <T>(path: string, options?: RequestOptions) =>
    apiRequest<T>(path, { ...options, method: 'GET' }),
  post: <T>(path: string, body?: unknown, options?: RequestOptions) =>
    apiRequest<T>(path, { ...options, method: 'POST', body }),
  put: <T>(path: string, body?: unknown, options?: RequestOptions) =>
    apiRequest<T>(path, { ...options, method: 'PUT', body }),
  patch: <T>(path: string, body?: unknown, options?: RequestOptions) =>
    apiRequest<T>(path, { ...options, method: 'PATCH', body }),
  delete: <T>(path: string, options?: RequestOptions) =>
    apiRequest<T>(path, { ...options, method: 'DELETE' }),
  download: apiDownload,
}
