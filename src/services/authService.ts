import type { AuthUser, LoginRequest, LoginResponse, Role } from '../types'
import type { ApiLoginRequest, ApiLoginResponse, ApiUsuario } from '../types/api'
import { mapRoles } from '../types/mappers'
import { api, setAccessToken } from './api'
import { delay, mockUser, isMockEnabled } from '../mocks/data'

function toAuthUser(login: ApiLoginResponse, usuario?: ApiUsuario | null): AuthUser {
  return {
    id: login.usuarioId,
    nome: usuario?.username ?? login.username,
    email: usuario?.email ?? login.username,
    roles: mapRoles(login.papeis),
    pessoaId: usuario?.pessoaId ?? undefined,
  }
}

export const authService = {
  async login(payload: LoginRequest): Promise<LoginResponse> {
    if (isMockEnabled()) {
      await delay(null)
      if (!payload.username || !payload.password) {
        throw new Error('Informe usuário e senha.')
      }
      const response: LoginResponse = {
        accessToken: 'mock-jwt-token',
        user: {
          ...mockUser,
          nome: payload.username,
          email: payload.username,
        },
      }
      setAccessToken(response.accessToken)
      localStorage.setItem('base_user', JSON.stringify(response.user))
      return response
    }

    const body: ApiLoginRequest = {
      username: payload.username,
      senha: payload.password,
    }

    const login = await api.post<ApiLoginResponse>('/auth/login', body, {
      token: null,
    })

    let usuario: ApiUsuario | null = null
    setAccessToken(login.token)
    try {
      usuario = await api.get<ApiUsuario>(`/usuarios/${login.usuarioId}`)
    } catch {
      // perfil completo é opcional no login
    }

    const user = toAuthUser(login, usuario)
    localStorage.setItem('base_user', JSON.stringify(user))

    return {
      accessToken: login.token,
      user,
    }
  },

  async logout(): Promise<void> {
    setAccessToken(null)
    localStorage.removeItem('base_user')
  },

  getStoredUser(): AuthUser | null {
    const raw = localStorage.getItem('base_user')
    if (!raw) return null
    try {
      const parsed = JSON.parse(raw) as AuthUser
      if (!parsed.roles) parsed.roles = [] as Role[]
      return parsed
    } catch {
      return null
    }
  },

  getToken(): string | null {
    return localStorage.getItem('base_access_token')
  },
}
