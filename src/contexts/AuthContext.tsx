import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import type { AuthUser, LoginRequest, Role } from '../types'
import { authService } from '../services/authService'
import { hasPermission } from '../utils/permissions'

interface AuthContextValue {
  user: AuthUser | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (payload: LoginRequest) => Promise<void>
  logout: () => Promise<void>
  can: (permission: string) => boolean
  hasRole: (...roles: Role[]) => boolean
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(() =>
    authService.getStoredUser(),
  )
  const [isLoading, setIsLoading] = useState(false)

  const login = useCallback(async (payload: LoginRequest) => {
    setIsLoading(true)
    try {
      const response = await authService.login(payload)
      setUser(response.user)
    } finally {
      setIsLoading(false)
    }
  }, [])

  const logout = useCallback(async () => {
    await authService.logout()
    setUser(null)
  }, [])

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isAuthenticated: Boolean(user && authService.getToken()),
      isLoading,
      login,
      logout,
      can: (permission: string) => hasPermission(user?.roles, permission),
      hasRole: (...roles: Role[]) =>
        Boolean(user?.roles.some((role) => roles.includes(role))),
    }),
    [user, isLoading, login, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth deve ser usado dentro de AuthProvider')
  }
  return context
}
