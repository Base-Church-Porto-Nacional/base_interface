import type {
  PageParams,
  PageResponse,
  Pessoa,
  PessoaHistorico,
} from '../types'
import type {
  ApiJornada,
  ApiJornadaUpdate,
  ApiPessoa,
  ApiPessoaCreate,
  ApiPessoaEtapa,
  ApiPessoaHistorico,
  ApiPessoaHistoricoCreate,
  ApiPessoaServico,
} from '../types/api'
import { mapHistorico, mapJornadaToEtapas, mapPessoa } from '../types/mappers'
import { api } from './api'
import { delay, mockHistoricos, mockPessoas, isMockEnabled } from '../mocks/data'

function paginate<T>(items: T[], page = 0, size = 20): PageResponse<T> {
  const start = page * size
  const content = items.slice(start, start + size)
  return {
    content,
    totalElements: items.length,
    totalPages: Math.max(1, Math.ceil(items.length / size)),
    page,
    size,
  }
}

async function enrichPessoa(apiPessoa: ApiPessoa): Promise<Pessoa> {
  let jornada
  let tipos: Pessoa['tipos'] = []
  try {
    const [j, etapas] = await Promise.all([
      api.get<ApiJornada>(`/pessoas/${apiPessoa.id}/jornada`),
      api
        .get<ApiPessoaEtapa[]>(`/pessoas/${apiPessoa.id}/jornada/etapas`)
        .catch(() => []),
    ])
    jornada = mapJornadaToEtapas(j, etapas)
    if (j.membro) tipos = ['MEMBRO']
    else tipos = ['VISITANTE']
  } catch {
    jornada = undefined
  }

  try {
    const links = await api.get<ApiPessoaServico[]>(
      `/voluntarios/pessoa/${apiPessoa.id}`,
    )
    const ministerios = [...new Set(links.map((l) => l.ministerioNome))]
    if (links.length > 0 && !tipos.includes('VOLUNTARIO')) {
      tipos = [...tipos, 'VOLUNTARIO']
    }
    return mapPessoa(apiPessoa, { jornada, tipos, ministerios })
  } catch {
    return mapPessoa(apiPessoa, { jornada, tipos })
  }
}

export const pessoaService = {
  async list(params: PageParams = {}): Promise<PageResponse<Pessoa>> {
    if (isMockEnabled()) {
      let items = [...mockPessoas]
      const search = params.search?.trim().toLowerCase()
      if (search) {
        items = items.filter(
          (p) =>
            p.nome.toLowerCase().includes(search) ||
            p.email.toLowerCase().includes(search) ||
            p.telefone.includes(search),
        )
      }
      const filtro = params.filtro?.toUpperCase()
      if (filtro && filtro !== 'TODOS') {
        items = items.filter((p) =>
          p.tipos.includes(filtro as Pessoa['tipos'][number]),
        )
      }
      return delay(paginate(items, params.page ?? 0, params.size ?? 20))
    }

    const list = await api.get<ApiPessoa[]>('/pessoas')
    let mapped = await Promise.all(list.map((p) => enrichPessoa(p)))

    const search = params.search?.trim().toLowerCase()
    if (search) {
      mapped = mapped.filter(
        (p) =>
          p.nome.toLowerCase().includes(search) ||
          p.email.toLowerCase().includes(search) ||
          p.telefone.includes(search),
      )
    }
    const filtro = params.filtro?.toUpperCase()
    if (filtro && filtro !== 'TODOS') {
      mapped = mapped.filter((p) =>
        p.tipos.includes(filtro as Pessoa['tipos'][number]),
      )
    }

    return paginate(mapped, params.page ?? 0, params.size ?? 20)
  },

  async getById(id: string): Promise<Pessoa> {
    if (isMockEnabled()) {
      const pessoa = mockPessoas.find((p) => p.id === id)
      if (!pessoa) throw new Error('Pessoa não encontrada.')
      return delay(pessoa)
    }
    const pessoa = await api.get<ApiPessoa>(`/pessoas/${id}`)
    return enrichPessoa(pessoa)
  },

  async create(data: Partial<Pessoa>): Promise<Pessoa> {
    if (isMockEnabled()) {
      const created: Pessoa = {
        id: `p${Date.now()}`,
        nome: data.nome ?? '',
        telefone: data.telefone ?? '',
        email: data.email ?? '',
        status: 'ATIVO',
        tipos: data.tipos ?? ['VISITANTE'],
        ministerios: data.ministerios ?? [],
        dataCadastro: new Date().toISOString().slice(0, 10),
      }
      mockPessoas.unshift(created)
      return delay(created)
    }

    const body: ApiPessoaCreate = {
      nome: data.nome ?? '',
      email: data.email || undefined,
      telefone: data.telefone || undefined,
    }
    const created = await api.post<ApiPessoa>('/pessoas', body)
    return mapPessoa(created, { tipos: ['VISITANTE'], ministerios: [] })
  },

  async update(id: string, data: Partial<Pessoa>): Promise<Pessoa> {
    if (isMockEnabled()) {
      const index = mockPessoas.findIndex((p) => p.id === id)
      if (index < 0) throw new Error('Pessoa não encontrada.')
      mockPessoas[index] = { ...mockPessoas[index], ...data }
      return delay(mockPessoas[index])
    }

    const updated = await api.put<ApiPessoa>(`/pessoas/${id}`, {
      nome: data.nome,
      email: data.email,
      telefone: data.telefone,
      dataNascimento: data.nascimento,
      ativo: data.status ? data.status === 'ATIVO' : undefined,
    })
    return enrichPessoa(updated)
  },

  async deactivate(id: string): Promise<void> {
    if (isMockEnabled()) {
      const pessoa = mockPessoas.find((p) => p.id === id)
      if (pessoa) pessoa.status = 'INATIVO'
      return delay(undefined)
    }
    const current = await api.get<ApiPessoa>(`/pessoas/${id}`)
    await api.put(`/pessoas/${id}`, {
      nome: current.nome,
      nomeSocial: current.nomeSocial,
      email: current.email,
      telefone: current.telefone,
      dataNascimento: current.dataNascimento,
      observacoes: current.observacoes,
      ativo: false,
    })
  },

  async listHistorico(pessoaId: string): Promise<PessoaHistorico[]> {
    if (isMockEnabled()) {
      return delay(mockHistoricos.filter((h) => h.pessoaId === pessoaId))
    }
    const list = await api.get<ApiPessoaHistorico[]>(
      `/pessoas/${pessoaId}/historico`,
    )
    return list.map(mapHistorico)
  },

  async createHistorico(
    pessoaId: string,
    data: ApiPessoaHistoricoCreate,
  ): Promise<PessoaHistorico> {
    if (isMockEnabled()) {
      const created: PessoaHistorico = {
        id: `h${Date.now()}`,
        pessoaId,
        descricao: data.descricao,
        autorNome: data.autorNome,
        autorCargo: data.autorCargo ?? null,
        dataRegistro: data.dataRegistro,
      }
      mockHistoricos.unshift(created)
      return delay(created)
    }
    const created = await api.post<ApiPessoaHistorico>(
      `/pessoas/${pessoaId}/historico`,
      data,
    )
    return mapHistorico(created)
  },

  async updateHistorico(
    pessoaId: string,
    historicoId: string,
    data: ApiPessoaHistoricoCreate,
  ): Promise<PessoaHistorico> {
    if (isMockEnabled()) {
      const index = mockHistoricos.findIndex((h) => h.id === historicoId)
      if (index < 0) throw new Error('Histórico não encontrado.')
      mockHistoricos[index] = {
        ...mockHistoricos[index],
        ...data,
        autorCargo: data.autorCargo ?? null,
      }
      return delay(mockHistoricos[index])
    }
    const updated = await api.put<ApiPessoaHistorico>(
      `/pessoas/${pessoaId}/historico/${historicoId}`,
      data,
    )
    return mapHistorico(updated)
  },

  async deleteHistorico(pessoaId: string, historicoId: string): Promise<void> {
    if (isMockEnabled()) {
      const index = mockHistoricos.findIndex((h) => h.id === historicoId)
      if (index >= 0) mockHistoricos.splice(index, 1)
      return delay(undefined)
    }
    await api.delete(`/pessoas/${pessoaId}/historico/${historicoId}`)
  },

  async getJornada(pessoaId: string): Promise<ApiJornada> {
    if (isMockEnabled()) {
      return delay({
        id: `j-${pessoaId}`,
        pessoaId,
        aceitouJesus: true,
        dataAceitouJesus: '2022-02-05',
        batizado: true,
        dataBatismo: '2022-04-17',
        concluiuTrilhaBase: false,
        dataConclusaoTrilhaBase: null,
        membro: false,
        dataMembro: null,
      })
    }
    return api.get<ApiJornada>(`/pessoas/${pessoaId}/jornada`)
  },

  async updateJornada(
    pessoaId: string,
    data: ApiJornadaUpdate,
  ): Promise<ApiJornada> {
    if (isMockEnabled()) {
      return delay({ id: `j-${pessoaId}`, pessoaId, ...data })
    }
    return api.put<ApiJornada>(`/pessoas/${pessoaId}/jornada`, data)
  },

  async listEtapasPessoa(pessoaId: string): Promise<ApiPessoaEtapa[]> {
    if (isMockEnabled()) return delay([])
    return api.get<ApiPessoaEtapa[]>(`/pessoas/${pessoaId}/jornada/etapas`)
  },
}
