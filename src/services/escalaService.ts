import type { Escala } from '../types'
import type {
  ApiEscala,
  ApiEscalaCreate,
  ApiEscalaServico,
  ApiEscalaServicoCreate,
  ApiEscalaUpdate,
  ApiEscalaVoluntario,
  ApiEscalaVoluntarioCreate,
} from '../types/api'
import { mapEscala } from '../types/mappers'
import { api } from './api'
import { delay, mockEscalas, isMockEnabled } from '../mocks/data'

export interface NovaEscalaPayload {
  nome: string
  data: string
  horario: string
  local?: string
  descricao?: string
  ministerioIds: string[]
  servicos: { servicoId: string; quantidade: number }[]
}

export const escalaService = {
  async list(): Promise<Escala[]> {
    if (isMockEnabled()) return delay([...mockEscalas])
    const list = await api.get<ApiEscala[]>('/escalas')
    return list.map(mapEscala)
  },

  async getById(id: string): Promise<Escala> {
    if (isMockEnabled()) {
      const item = mockEscalas.find((e) => e.id === id)
      if (!item) throw new Error('Escala não encontrada.')
      return delay(item)
    }
    const item = await api.get<ApiEscala>(`/escalas/${id}`)
    return mapEscala(item)
  },

  async create(payload: NovaEscalaPayload): Promise<Escala> {
    if (isMockEnabled()) {
      const created: Escala = {
        id: `e${Date.now()}`,
        nome: payload.nome,
        data: payload.data,
        horario: payload.horario,
        local: payload.local,
        totalVoluntarios: 0,
        confirmados: 0,
        pendentes: 0,
        status: 'RASCUNHO',
        ministerios: [],
      }
      mockEscalas.unshift(created)
      return delay(created)
    }

    const body: ApiEscalaCreate = {
      titulo: payload.nome,
      descricao: payload.descricao,
      dataEvento: payload.data,
      horaInicio:
        payload.horario.length === 5
          ? `${payload.horario}:00`
          : payload.horario,
      localEvento: payload.local,
      servicos: payload.servicos
        .filter((s) => s.quantidade > 0)
        .map((s) => ({
          servicoId: s.servicoId,
          quantidadeNecessaria: s.quantidade,
        })),
    }

    const created = await api.post<ApiEscala>('/escalas', body)
    return mapEscala(created)
  },

  async update(id: string, data: ApiEscalaUpdate): Promise<Escala> {
    if (isMockEnabled()) {
      const index = mockEscalas.findIndex((e) => e.id === id)
      if (index < 0) throw new Error('Escala não encontrada.')
      mockEscalas[index] = {
        ...mockEscalas[index],
        nome: data.titulo,
        data: data.dataEvento,
        horario: data.horaInicio.slice(0, 5),
        local: data.localEvento ?? undefined,
        status: data.ativo === false ? 'RASCUNHO' : mockEscalas[index].status,
      }
      return delay(mockEscalas[index])
    }
    const updated = await api.put<ApiEscala>(`/escalas/${id}`, data)
    return mapEscala(updated)
  },

  async remove(id: string): Promise<void> {
    if (isMockEnabled()) {
      const index = mockEscalas.findIndex((e) => e.id === id)
      if (index >= 0) mockEscalas.splice(index, 1)
      return delay(undefined)
    }
    await api.delete(`/escalas/${id}`)
  },

  async addServico(
    escalaId: string,
    data: ApiEscalaServicoCreate,
  ): Promise<ApiEscalaServico> {
    if (isMockEnabled()) {
      return delay({
        id: `es${Date.now()}`,
        servicoId: data.servicoId,
        servicoNome: '—',
        quantidadeNecessaria: data.quantidadeNecessaria,
      })
    }
    return api.post(`/escalas/${escalaId}/servicos`, data)
  },

  async updateServico(
    escalaId: string,
    servicoEscalaId: string,
    data: ApiEscalaServicoCreate,
  ): Promise<ApiEscalaServico> {
    if (isMockEnabled()) {
      return delay({
        id: servicoEscalaId,
        servicoId: data.servicoId,
        servicoNome: '—',
        quantidadeNecessaria: data.quantidadeNecessaria,
      })
    }
    return api.put(`/escalas/${escalaId}/servicos/${servicoEscalaId}`, data)
  },

  async removeServico(escalaId: string, servicoEscalaId: string): Promise<void> {
    if (isMockEnabled()) return delay(undefined)
    await api.delete(`/escalas/${escalaId}/servicos/${servicoEscalaId}`)
  },

  async addDesignacao(
    escalaId: string,
    data: ApiEscalaVoluntarioCreate,
  ): Promise<ApiEscalaVoluntario> {
    if (isMockEnabled()) {
      return delay({
        id: `ev${Date.now()}`,
        pessoaId: data.pessoaId,
        pessoaNome: '—',
        servicoId: data.servicoId,
        servicoNome: '—',
        status: data.status ?? 'PENDENTE',
        observacoes: data.observacoes ?? null,
      })
    }
    return api.post(`/escalas/${escalaId}/voluntarios`, data)
  },

  async updateDesignacao(
    escalaId: string,
    designacaoId: string,
    data: ApiEscalaVoluntarioCreate,
  ): Promise<ApiEscalaVoluntario> {
    if (isMockEnabled()) {
      return delay({
        id: designacaoId,
        pessoaId: data.pessoaId,
        pessoaNome: '—',
        servicoId: data.servicoId,
        servicoNome: '—',
        status: data.status ?? 'PENDENTE',
        observacoes: data.observacoes ?? null,
      })
    }
    return api.put(`/escalas/${escalaId}/voluntarios/${designacaoId}`, data)
  },

  async removeDesignacao(
    escalaId: string,
    designacaoId: string,
  ): Promise<void> {
    if (isMockEnabled()) return delay(undefined)
    await api.delete(`/escalas/${escalaId}/voluntarios/${designacaoId}`)
  },

  async gerarSugestao(escalaId: string): Promise<Escala> {
    if (isMockEnabled()) {
      const item = mockEscalas.find((e) => e.id === escalaId)
      if (!item) throw new Error('Escala não encontrada.')
      return delay(item, 600)
    }
    // Backend stub — ScheduleGenerationService ainda sem algoritmo.
    return this.getById(escalaId)
  },

  async publicar(id: string): Promise<Escala> {
    if (isMockEnabled()) {
      const item = mockEscalas.find((e) => e.id === id)
      if (!item) throw new Error('Escala não encontrada.')
      item.status = 'PUBLICADA'
      return delay(item)
    }
    const current = await api.get<ApiEscala>(`/escalas/${id}`)
    const updated = await api.put<ApiEscala>(`/escalas/${id}`, {
      titulo: current.titulo,
      descricao: current.descricao,
      dataEvento: current.dataEvento,
      horaInicio: current.horaInicio,
      horaFim: current.horaFim,
      localEvento: current.localEvento,
      ativo: true,
    })
    return mapEscala(updated)
  },

  async confirmarSlot(escalaId: string, designacaoId: string): Promise<void> {
    if (isMockEnabled()) return delay(undefined)
    await api.put(`/escalas/${escalaId}/voluntarios/${designacaoId}/status`, {
      status: 'CONFIRMADO',
    })
  },

  async recusarSlot(escalaId: string, designacaoId: string): Promise<void> {
    if (isMockEnabled()) return delay(undefined)
    await api.put(`/escalas/${escalaId}/voluntarios/${designacaoId}/status`, {
      status: 'RECUSADO',
    })
  },
}
