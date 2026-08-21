import type { Papel, Usuario } from '../types'
import type {
  ApiPapel,
  ApiUsuario,
  ApiUsuarioCreate,
  ApiUsuarioUpdate,
} from '../types/api'
import { mapPapel, mapUsuario } from '../types/mappers'
import { api } from './api'
import { delay, mockPapeis, mockUsuarios, isMockEnabled } from '../mocks/data'

export const papelService = {
  async list(): Promise<Papel[]> {
    if (isMockEnabled()) return delay([...mockPapeis])
    const list = await api.get<ApiPapel[]>('/papeis')
    return list.map(mapPapel)
  },

  async create(data: { nome: string; descricao?: string }): Promise<Papel> {
    if (isMockEnabled()) {
      const created: Papel = {
        id: `papel${Date.now()}`,
        nome: data.nome,
        descricao: data.descricao,
      }
      mockPapeis.push(created)
      return delay(created)
    }
    const created = await api.post<ApiPapel>('/papeis', data)
    return mapPapel(created)
  },
}

export const usuarioService = {
  async list(): Promise<Usuario[]> {
    if (isMockEnabled()) return delay([...mockUsuarios])
    const list = await api.get<ApiUsuario[]>('/usuarios')
    return list.map(mapUsuario)
  },

  async getById(id: string): Promise<Usuario> {
    if (isMockEnabled()) {
      const item = mockUsuarios.find((u) => u.id === id)
      if (!item) throw new Error('Usuário não encontrado.')
      return delay(item)
    }
    const item = await api.get<ApiUsuario>(`/usuarios/${id}`)
    return mapUsuario(item)
  },

  async create(data: ApiUsuarioCreate): Promise<Usuario> {
    if (isMockEnabled()) {
      const created: Usuario = {
        id: `u${Date.now()}`,
        nome: data.username,
        pessoaId: data.pessoaId,
        pessoaNome: data.pessoaId ?? '—',
        email: data.email ?? '',
        roles: (data.papeis ?? []) as Usuario['roles'],
        status: data.ativo === false ? 'INATIVO' : 'ATIVO',
      }
      mockUsuarios.unshift(created)
      return delay(created)
    }
    const created = await api.post<ApiUsuario>('/usuarios', data)
    return mapUsuario(created)
  },

  async update(id: string, data: ApiUsuarioUpdate): Promise<Usuario> {
    if (isMockEnabled()) {
      const index = mockUsuarios.findIndex((u) => u.id === id)
      if (index < 0) throw new Error('Usuário não encontrado.')
      mockUsuarios[index] = {
        ...mockUsuarios[index],
        nome: data.username ?? mockUsuarios[index].nome,
        email: data.email ?? mockUsuarios[index].email,
        pessoaId: data.pessoaId ?? mockUsuarios[index].pessoaId,
        roles: (data.papeis as Usuario['roles']) ?? mockUsuarios[index].roles,
        status:
          data.ativo === undefined
            ? mockUsuarios[index].status
            : data.ativo
              ? 'ATIVO'
              : 'INATIVO',
      }
      return delay(mockUsuarios[index])
    }
    const updated = await api.put<ApiUsuario>(`/usuarios/${id}`, data)
    return mapUsuario(updated)
  },

  async remove(id: string): Promise<void> {
    if (isMockEnabled()) {
      const index = mockUsuarios.findIndex((u) => u.id === id)
      if (index >= 0) mockUsuarios.splice(index, 1)
      return delay(undefined)
    }
    await api.delete(`/usuarios/${id}`)
  },
}
