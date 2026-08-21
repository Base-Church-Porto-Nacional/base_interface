import type { DashboardStats } from '../types'
import type { ApiEscala, ApiPessoa } from '../types/api'
import { mapEscala } from '../types/mappers'
import { api } from './api'
import { delay, mockDashboard, isMockEnabled } from '../mocks/data'
import { voluntarioService } from './voluntarioService'

export const dashboardService = {
  async getStats(): Promise<DashboardStats> {
    if (isMockEnabled()) return delay(mockDashboard)

    const [pessoas, escalas, voluntarios] = await Promise.all([
      api.get<ApiPessoa[]>('/pessoas'),
      api.get<ApiEscala[]>('/escalas'),
      voluntarioService.list(),
    ])

    const mappedEscalas = escalas.map(mapEscala).sort((a, b) => a.data.localeCompare(b.data))
    const proximas = mappedEscalas.slice(0, 5)

    return {
      totalPessoas: pessoas.length,
      totalMembros: pessoas.filter((p) => p.ativo).length,
      totalVoluntarios: new Set(voluntarios.map((v) => v.pessoaId)).size,
      totalLideres: 0,
      escalasPendentes: mappedEscalas.reduce((acc, e) => acc + e.pendentes, 0),
      visitantesRecentes: 0,
      proximasEscalas: proximas.map((e) => ({
        id: e.id,
        data: e.data,
        horario: e.horario,
        ministerio: e.ministerios[0]?.nome ?? 'Geral',
        totalVoluntarios: e.totalVoluntarios,
        confirmados: e.confirmados,
        pendentes: e.pendentes,
      })),
      jornada: {
        novosVisitantes: 0,
        aceitaramJesus: 0,
        batizados: 0,
        trilhaBase: 0,
        novosMembros: 0,
      },
    }
  },
}
