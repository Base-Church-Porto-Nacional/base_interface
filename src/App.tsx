import { Navigate, Route, Routes, useParams } from 'react-router-dom'
import { AppLayout } from './components/layout/AppLayout'
import { AuthProvider } from './contexts/AuthContext'
import { ProtectedRoute } from './routes/ProtectedRoute'
import { PermissionGuard } from './routes/PermissionGuard'
import { LoginPage } from './pages/Login/LoginPage'
import { DashboardPage } from './pages/Dashboard/DashboardPage'
import { PessoasPage } from './pages/Pessoas/PessoasPage'
import { PessoaDetailPage } from './pages/Pessoas/PessoaDetailPage'
import { MembrosPage } from './pages/Membros/MembrosPage'
import { MinisteriosPage } from './pages/Ministerios/MinisteriosPage'
import { MinisterioDetailPage } from './pages/Ministerios/MinisterioDetailPage'
import { VoluntariosPage } from './pages/Voluntarios/VoluntariosPage'
import { LideresPage } from './pages/Voluntariado/LideresPage'
import { EscalasPage } from './pages/Escalas/EscalasPage'
import { EscalaDetailPage } from './pages/Escalas/EscalaDetailPage'
import { EscalaNovaPage } from './pages/Escalas/EscalaNovaPage'
import { DisponibilidadePage } from './pages/Disponibilidade/DisponibilidadePage'
import { UsuariosPage } from './pages/Usuarios/UsuariosPage'
import { CronogramaListPage } from './pages/Cronograma/CronogramaListPage'
import { PerfilInfoPage } from './pages/Perfil/PerfilInfoPage'
import { PerfilPausaPage } from './pages/Perfil/PerfilPausaPage'

function PessoaIdRedirect() {
  const { id } = useParams()
  return <Navigate to={`/membros/pessoa/${id}`} replace />
}

export default function App() {
  return (
    <AuthProvider>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route element={<ProtectedRoute />}>
          <Route element={<AppLayout />}>
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<DashboardPage />} />

            <Route
              path="/membros"
              element={
                <PermissionGuard permission="membros:view">
                  <MembrosPage />
                </PermissionGuard>
              }
            />
            <Route
              path="/membros/pessoas"
              element={
                <PermissionGuard permission="pessoas:view">
                  <PessoasPage />
                </PermissionGuard>
              }
            />
            <Route
              path="/membros/pessoa/:id"
              element={
                <PermissionGuard permission="pessoas:view">
                  <PessoaDetailPage />
                </PermissionGuard>
              }
            />

            <Route
              path="/voluntariado"
              element={<Navigate to="/voluntariado/voluntarios" replace />}
            />
            <Route
              path="/voluntariado/voluntarios"
              element={
                <PermissionGuard permission="voluntarios:view">
                  <VoluntariosPage />
                </PermissionGuard>
              }
            />
            <Route
              path="/voluntariado/lideres"
              element={
                <PermissionGuard permission="voluntarios:view">
                  <LideresPage />
                </PermissionGuard>
              }
            />
            <Route path="/voluntariado/escalas" element={<EscalasPage />} />
            <Route path="/voluntariado/escalas/nova" element={<EscalaNovaPage />} />
            <Route path="/voluntariado/escalas/:id" element={<EscalaDetailPage />} />
            <Route
              path="/voluntariado/ministerios"
              element={
                <PermissionGuard permission="ministerios:view">
                  <MinisteriosPage />
                </PermissionGuard>
              }
            />
            <Route
              path="/voluntariado/ministerios/:id"
              element={
                <PermissionGuard permission="ministerios:view">
                  <MinisterioDetailPage />
                </PermissionGuard>
              }
            />

            <Route
              path="/usuarios"
              element={
                <PermissionGuard permission="usuarios:view">
                  <UsuariosPage />
                </PermissionGuard>
              }
            />

            <Route path="/cronograma" element={<Navigate to="/cronograma/cultos" replace />} />
            <Route
              path="/cronograma/cultos"
              element={<CronogramaListPage kind="cultos" />}
            />
            <Route
              path="/cronograma/eventos"
              element={<CronogramaListPage kind="eventos" />}
            />

            <Route path="/perfil" element={<PerfilInfoPage />} />
            <Route path="/perfil/disponibilidade" element={<DisponibilidadePage />} />
            <Route path="/perfil/pausa" element={<PerfilPausaPage />} />

            {/* Compatibilidade com rotas antigas */}
            <Route path="/pessoas" element={<Navigate to="/membros/pessoas" replace />} />
            <Route path="/pessoas/:id" element={<PessoaIdRedirect />} />
            <Route path="/voluntarios" element={<Navigate to="/voluntariado/voluntarios" replace />} />
            <Route path="/ministerios" element={<Navigate to="/voluntariado/ministerios" replace />} />
            <Route path="/escalas" element={<Navigate to="/voluntariado/escalas" replace />} />
            <Route path="/escalas/nova" element={<Navigate to="/voluntariado/escalas/nova" replace />} />
            <Route path="/disponibilidade" element={<Navigate to="/perfil/disponibilidade" replace />} />
          </Route>
        </Route>

        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </AuthProvider>
  )
}
