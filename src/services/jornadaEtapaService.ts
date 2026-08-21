import type { JornadaEtapaCatalogo } from '../types'
import type { ApiJornadaEtapaCatalogo } from '../types/api'
import { api } from './api'
import { delay, mockJornadaEtapas, isMockEnabled } from '../mocks/data'

function mapEtapa(api: ApiJornadaEtapaCatalogo): JornadaEtapaCatalogo {
  return {
    id: api.id,
    codigo: api.codigo,
    nome: api.nome,
    descricao: api.descricao ?? undefined,
    ordem: api.ordem ?? undefined,
    ativo: api.ativo,
  }
}

export const jornadaEtapaService = {
  async list(): Promise<JornadaEtapaCatalogo[]> {
    if (isMockEnabled()) return delay([...mockJornadaEtapas])
    const list = await api.get<ApiJornadaEtapaCatalogo[]>('/jornada-etapas')
    return list.map(mapEtapa)
  },

  async create(data: {
    codigo: string
    nome: string
    descricao?: string
    ordem?: number
  }): Promise<JornadaEtapaCatalogo> {
    if (isMockEnabled()) {
      const created: JornadaEtapaCatalogo = {
        id: `je${Date.now()}`,
        codigo: data.codigo,
        nome: data.nome,
        descricao: data.descricao,
        ordem: data.ordem,
        ativo: true,
      }
      mockJornadaEtapas.push(created)
      return delay(created)
    }
    const created = await api.post<ApiJornadaEtapaCatalogo>(
      '/jornada-etapas',
      data,
    )
    return mapEtapa(created)
  },

  async update(
    id: string,
    data: Partial<JornadaEtapaCatalogo>,
  ): Promise<JornadaEtapaCatalogo> {
    if (isMockEnabled()) {
      const index = mockJornadaEtapas.findIndex((e) => e.id === id)
      if (index < 0) throw new Error('Etapa não encontrada.')
      mockJornadaEtapas[index] = { ...mockJornadaEtapas[index], ...data }
      return delay(mockJornadaEtapas[index])
    }
    const updated = await api.put<ApiJornadaEtapaCatalogo>(
      `/jornada-etapas/${id}`,
      data,
    )
    return mapEtapa(updated)
  },

  async remove(id: string): Promise<void> {
    if (isMockEnabled()) {
      const index = mockJornadaEtapas.findIndex((e) => e.id === id)
      if (index >= 0) mockJornadaEtapas.splice(index, 1)
      return delay(undefined)
    }
    await api.delete(`/jornada-etapas/${id}`)
  },
}
