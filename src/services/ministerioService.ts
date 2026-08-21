import type { Ministerio, Servico } from '../types'
import type {
  ApiMinisterio,
  ApiMinisterioCreate,
  ApiServico,
  ApiServicoCreate,
} from '../types/api'
import { mapMinisterio, mapServico } from '../types/mappers'
import { api } from './api'
import { delay, mockMinisterios, mockServicos, isMockEnabled } from '../mocks/data'

export const ministerioService = {
  async list(): Promise<Ministerio[]> {
    if (isMockEnabled()) return delay([...mockMinisterios])

    const ministerios = await api.get<ApiMinisterio[]>('/ministerios')
    return Promise.all(
      ministerios.map(async (m) => {
        const servicos = await api
          .get<ApiServico[]>(`/ministerios/${m.id}/servicos`)
          .catch(() => [])
        return mapMinisterio(m, servicos.length, 0)
      }),
    )
  },

  async getById(id: string): Promise<Ministerio> {
    if (isMockEnabled()) {
      const item = mockMinisterios.find((m) => m.id === id)
      if (!item) throw new Error('Ministério não encontrado.')
      return delay(item)
    }
    const m = await api.get<ApiMinisterio>(`/ministerios/${id}`)
    const servicos = await api
      .get<ApiServico[]>(`/ministerios/${id}/servicos`)
      .catch(() => [])
    return mapMinisterio(m, servicos.length, 0)
  },

  async create(data: ApiMinisterioCreate): Promise<Ministerio> {
    if (isMockEnabled()) {
      const created: Ministerio = {
        id: `m${Date.now()}`,
        nome: data.nome,
        liderNome: '—',
        totalVoluntarios: 0,
        totalServicos: 0,
        descricao: data.descricao,
        ativo: data.ativo ?? true,
      }
      mockMinisterios.unshift(created)
      return delay(created)
    }
    const created = await api.post<ApiMinisterio>('/ministerios', data)
    return mapMinisterio(created)
  },

  async update(id: string, data: ApiMinisterioCreate): Promise<Ministerio> {
    if (isMockEnabled()) {
      const index = mockMinisterios.findIndex((m) => m.id === id)
      if (index < 0) throw new Error('Ministério não encontrado.')
      mockMinisterios[index] = {
        ...mockMinisterios[index],
        nome: data.nome,
        descricao: data.descricao,
        ativo: data.ativo ?? mockMinisterios[index].ativo,
      }
      return delay(mockMinisterios[index])
    }
    const updated = await api.put<ApiMinisterio>(`/ministerios/${id}`, data)
    return mapMinisterio(updated)
  },

  async listServicos(ministerioId: string): Promise<Servico[]> {
    if (isMockEnabled()) {
      return delay(mockServicos.filter((s) => s.ministerioId === ministerioId))
    }
    const list = await api.get<ApiServico[]>(
      `/ministerios/${ministerioId}/servicos`,
    )
    return list.map((s) => mapServico(s))
  },
}

export const servicoService = {
  async create(
    ministerioId: string,
    data: ApiServicoCreate,
  ): Promise<Servico> {
    if (isMockEnabled()) {
      const created: Servico = {
        id: `s${Date.now()}`,
        ministerioId,
        nome: data.nome,
        ativo: data.ativo ?? true,
        totalVoluntarios: 0,
      }
      mockServicos.push(created)
      return delay(created)
    }
    const created = await api.post<ApiServico>(
      `/ministerios/${ministerioId}/servicos`,
      data,
    )
    return mapServico(created)
  },

  async update(id: string, data: Partial<Servico> & { descricao?: string }): Promise<Servico> {
    if (isMockEnabled()) {
      const index = mockServicos.findIndex((s) => s.id === id)
      if (index < 0) throw new Error('Serviço não encontrado.')
      mockServicos[index] = { ...mockServicos[index], ...data }
      return delay(mockServicos[index])
    }
    const updated = await api.put<ApiServico>(`/servicos/${id}`, {
      nome: data.nome,
      descricao: data.descricao,
      ativo: data.ativo,
    })
    return mapServico(updated)
  },

  async remove(id: string): Promise<void> {
    if (isMockEnabled()) {
      const index = mockServicos.findIndex((s) => s.id === id)
      if (index >= 0) mockServicos.splice(index, 1)
      return delay(undefined)
    }
    await api.delete(`/servicos/${id}`)
  },
}
