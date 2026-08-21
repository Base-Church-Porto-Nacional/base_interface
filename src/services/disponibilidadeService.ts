import type {
  DisponibilidadeSemanal,
  Indisponibilidade,
} from '../types'
import type {
  ApiDisponibilidadeSemanal,
  ApiDisponibilidadeSemanalCreate,
  ApiIndisponibilidade,
  ApiIndisponibilidadeCreate,
} from '../types/api'
import { api } from './api'
import {
  delay,
  mockDisponibilidade,
  mockIndisponibilidades,
  isMockEnabled,
} from '../mocks/data'
import { authService } from './authService'

const DIAS = [
  'DOMINGO',
  'SEGUNDA',
  'TERCA',
  'QUARTA',
  'QUINTA',
  'SEXTA',
  'SABADO',
] as const

const DIA_LABEL: Record<string, string> = {
  DOMINGO: 'Domingo',
  SEGUNDA: 'Segunda-feira',
  TERCA: 'Terça-feira',
  QUARTA: 'Quarta-feira',
  QUINTA: 'Quinta-feira',
  SEXTA: 'Sexta-feira',
  SABADO: 'Sábado',
}

const LABEL_TO_DIA: Record<string, string> = Object.fromEntries(
  Object.entries(DIA_LABEL).map(([k, v]) => [v, k]),
)

const PERIODO_HORAS: Record<string, { inicio: string; fim: string }> = {
  Manhã: { inicio: '08:00:00', fim: '12:00:00' },
  Tarde: { inicio: '12:00:00', fim: '18:00:00' },
  Noite: { inicio: '18:00:00', fim: '22:00:00' },
}

function requirePessoaId(): string {
  const pessoaId = authService.getStoredUser()?.pessoaId
  if (!pessoaId) {
    throw new Error('Usuário sem pessoa vinculada para disponibilidade.')
  }
  return pessoaId
}

function toPeriodo(horaInicio: string): string {
  const hour = Number(horaInicio.slice(0, 2))
  if (hour < 12) return 'Manhã'
  if (hour < 18) return 'Tarde'
  return 'Noite'
}

function emptyWeek(): DisponibilidadeSemanal[] {
  return DIAS.map((dia) => ({
    dia: DIA_LABEL[dia],
    diaSemana: dia,
    periodos: [],
  }))
}

export const disponibilidadeService = {
  async getSemanal(pessoaId?: string): Promise<DisponibilidadeSemanal[]> {
    if (isMockEnabled()) {
      return delay(
        mockDisponibilidade.map((d) => ({
          ...d,
          diaSemana: LABEL_TO_DIA[d.dia] ?? d.dia,
        })),
      )
    }

    const id = pessoaId ?? requirePessoaId()
    const list = await api.get<ApiDisponibilidadeSemanal[]>(
      `/disponibilidades/semanal/pessoa/${id}`,
    )

    return DIAS.map((dia) => {
      const slots = list.filter((item) => item.diaSemana === dia && item.disponivel)
      return {
        dia: DIA_LABEL[dia] ?? dia,
        diaSemana: dia,
        periodos: [...new Set(slots.map((s) => toPeriodo(s.horaInicio)))],
        slots: slots.map((s) => ({
          id: s.id,
          horaInicio: s.horaInicio,
          horaFim: s.horaFim,
          periodo: toPeriodo(s.horaInicio),
        })),
      }
    })
  },

  async getIndisponibilidades(
    pessoaId?: string,
  ): Promise<Indisponibilidade[]> {
    if (isMockEnabled()) return delay([...mockIndisponibilidades])

    const id = pessoaId ?? requirePessoaId()
    const list = await api.get<ApiIndisponibilidade[]>(
      `/disponibilidades/indisponibilidades/pessoa/${id}`,
    )
    return list.map((item) => ({
      id: item.id,
      data: item.dataInicio,
      dataFim: item.dataFim,
      motivo: item.motivo ?? undefined,
    }))
  },

  async updateSemanal(
    data: DisponibilidadeSemanal[],
    pessoaId?: string,
  ): Promise<DisponibilidadeSemanal[]> {
    if (isMockEnabled()) {
      mockDisponibilidade.splice(
        0,
        mockDisponibilidade.length,
        ...data.map(({ dia, diaSemana, periodos }) => ({
          dia,
          diaSemana,
          periodos,
        })),
      )
      return delay(data)
    }

    const id = pessoaId ?? requirePessoaId()
    const current = await api.get<ApiDisponibilidadeSemanal[]>(
      `/disponibilidades/semanal/pessoa/${id}`,
    )

    await Promise.all(
      current.map((slot) =>
        api.delete(`/disponibilidades/semanal/${slot.id}`).catch(() => undefined),
      ),
    )

    const creates: ApiDisponibilidadeSemanalCreate[] = []
    for (const day of data) {
      const diaSemana = day.diaSemana || LABEL_TO_DIA[day.dia] || day.dia
      for (const periodo of day.periodos) {
        const horas = PERIODO_HORAS[periodo]
        if (!horas) continue
        creates.push({
          pessoaId: id,
          diaSemana,
          horaInicio: horas.inicio,
          horaFim: horas.fim,
          disponivel: true,
        })
      }
    }

    await Promise.all(
      creates.map((body) =>
        api.post<ApiDisponibilidadeSemanal>('/disponibilidades/semanal', body),
      ),
    )

    return this.getSemanal(id)
  },

  async createIndisponibilidade(
    data: Omit<ApiIndisponibilidadeCreate, 'pessoaId'> & { pessoaId?: string },
  ): Promise<Indisponibilidade> {
    const pessoaId = data.pessoaId ?? requirePessoaId()
    if (isMockEnabled()) {
      const created: Indisponibilidade = {
        id: `i${Date.now()}`,
        data: data.dataInicio,
        dataFim: data.dataFim,
        motivo: data.motivo ?? undefined,
      }
      mockIndisponibilidades.push(created)
      return delay(created)
    }
    const created = await api.post<ApiIndisponibilidade>(
      '/disponibilidades/indisponibilidades',
      { ...data, pessoaId },
    )
    return {
      id: created.id,
      data: created.dataInicio,
      dataFim: created.dataFim,
      motivo: created.motivo ?? undefined,
    }
  },

  async deleteIndisponibilidade(id: string): Promise<void> {
    if (isMockEnabled()) {
      const index = mockIndisponibilidades.findIndex((i) => i.id === id)
      if (index >= 0) mockIndisponibilidades.splice(index, 1)
      return delay(undefined)
    }
    await api.delete(`/disponibilidades/indisponibilidades/${id}`)
  },

  emptyWeek,
}
