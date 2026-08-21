import type { Voluntario } from '../types'
import type {
  ApiMinisterio,
  ApiPessoaServico,
  ApiServico,
  ApiVoluntarioCreate,
} from '../types/api'
import { mapVoluntario } from '../types/mappers'
import { api } from './api'
import { delay, mockVoluntarios, isMockEnabled } from '../mocks/data'

async function listAllLinks(): Promise<ApiPessoaServico[]> {
  try {
    return await api.get<ApiPessoaServico[]>('/voluntarios')
  } catch {
    const ministerios = await api.get<ApiMinisterio[]>('/ministerios')
    const links: ApiPessoaServico[] = []
    for (const ministerio of ministerios) {
      const servicos = await api
        .get<ApiServico[]>(`/ministerios/${ministerio.id}/servicos`)
        .catch(() => [])
      for (const servico of servicos) {
        const porServico = await api
          .get<ApiPessoaServico[]>(`/voluntarios/servico/${servico.id}`)
          .catch(() => [])
        links.push(...porServico)
      }
    }
    return links
  }
}

export const voluntarioService = {
  async list(): Promise<Voluntario[]> {
    if (isMockEnabled()) return delay([...mockVoluntarios])
    const links = await listAllLinks()
    return links.map(mapVoluntario)
  },

  async listByPessoa(pessoaId: string): Promise<Voluntario[]> {
    if (isMockEnabled()) {
      return delay(mockVoluntarios.filter((v) => v.pessoaId === pessoaId))
    }
    const links = await api.get<ApiPessoaServico[]>(
      `/voluntarios/pessoa/${pessoaId}`,
    )
    return links.map(mapVoluntario)
  },

  async getById(id: string): Promise<Voluntario> {
    if (isMockEnabled()) {
      const item = mockVoluntarios.find((v) => v.id === id)
      if (!item) throw new Error('Voluntário não encontrado.')
      return delay(item)
    }
    const item = await api.get<ApiPessoaServico>(`/voluntarios/${id}`)
    return mapVoluntario(item)
  },

  async create(data: ApiVoluntarioCreate): Promise<Voluntario> {
    if (isMockEnabled()) {
      const created: Voluntario = {
        id: `v${Date.now()}`,
        pessoaId: data.pessoaId,
        pessoaNome: '—',
        servicoId: data.servicoId,
        servicoNome: '—',
        ministerioId: '',
        ministerioNome: '—',
        cargo: data.cargo ?? null,
        dataEntrada: data.dataEntrada ?? null,
        ativo: data.ativo ?? true,
        observacoes: data.observacoes ?? null,
        liderResponsavelId: data.liderResponsavelId ?? null,
      }
      mockVoluntarios.unshift(created)
      return delay(created)
    }
    const created = await api.post<ApiPessoaServico>('/voluntarios', data)
    return mapVoluntario(created)
  },

  async update(id: string, data: ApiVoluntarioCreate): Promise<Voluntario> {
    if (isMockEnabled()) {
      const index = mockVoluntarios.findIndex((v) => v.id === id)
      if (index < 0) throw new Error('Voluntário não encontrado.')
      mockVoluntarios[index] = {
        ...mockVoluntarios[index],
        pessoaId: data.pessoaId,
        servicoId: data.servicoId,
        cargo: data.cargo ?? null,
        dataEntrada: data.dataEntrada ?? null,
        ativo: data.ativo ?? true,
        observacoes: data.observacoes ?? null,
        liderResponsavelId: data.liderResponsavelId ?? null,
      }
      return delay(mockVoluntarios[index])
    }
    const updated = await api.put<ApiPessoaServico>(`/voluntarios/${id}`, data)
    return mapVoluntario(updated)
  },

  async remove(id: string): Promise<void> {
    if (isMockEnabled()) {
      const index = mockVoluntarios.findIndex((v) => v.id === id)
      if (index >= 0) mockVoluntarios.splice(index, 1)
      return delay(undefined)
    }
    await api.delete(`/voluntarios/${id}`)
  },
}
