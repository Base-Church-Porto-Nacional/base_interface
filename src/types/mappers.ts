import type {
  ApiEscala,
  ApiJornada,
  ApiMinisterio,
  ApiPapel,
  ApiPessoa,
  ApiPessoaEtapa,
  ApiPessoaHistorico,
  ApiPessoaServico,
  ApiServico,
  ApiUsuario,
} from './api'
import type {
  Escala,
  EscalaSlot,
  EscalaSlotStatus,
  JornadaEtapa,
  Ministerio,
  Papel,
  Pessoa,
  PessoaHistorico,
  Role,
  Servico,
  Usuario,
  Voluntario,
} from './index'

export function mapPessoa(api: ApiPessoa, extras?: Partial<Pessoa>): Pessoa {
  return {
    id: api.id,
    nome: api.nome,
    telefone: api.telefone ?? '',
    email: api.email ?? '',
    status: api.ativo ? 'ATIVO' : 'INATIVO',
    tipos: extras?.tipos ?? [],
    ministerios: extras?.ministerios ?? [],
    dataCadastro: api.dataCadastro,
    nascimento: api.dataNascimento ?? undefined,
    jornada: extras?.jornada,
  }
}

export function mapHistorico(api: ApiPessoaHistorico): PessoaHistorico {
  return {
    id: api.id,
    pessoaId: api.pessoaId,
    descricao: api.descricao,
    autorNome: api.autorNome,
    autorCargo: api.autorCargo,
    dataRegistro: api.dataRegistro,
  }
}

export function mapJornadaToEtapas(
  jornada: ApiJornada | null,
  etapas: ApiPessoaEtapa[] = [],
): JornadaEtapa[] {
  const base: JornadaEtapa[] = [
    {
      id: 'aceitou',
      titulo: 'Aceitou Jesus',
      status: jornada?.aceitouJesus ? 'CONCLUIDO' : 'PENDENTE',
      data: jornada?.dataAceitouJesus ?? undefined,
    },
    {
      id: 'batizado',
      titulo: 'Batizado',
      status: jornada?.batizado ? 'CONCLUIDO' : 'PENDENTE',
      data: jornada?.dataBatismo ?? undefined,
    },
    {
      id: 'trilha',
      titulo: 'Trilha da Base',
      status: jornada?.concluiuTrilhaBase ? 'CONCLUIDO' : 'PENDENTE',
      data: jornada?.dataConclusaoTrilhaBase ?? undefined,
    },
    {
      id: 'membro',
      titulo: 'Membro',
      status: jornada?.membro ? 'CONCLUIDO' : 'PENDENTE',
      data: jornada?.dataMembro ?? undefined,
    },
  ]

  const extras = etapas.map((e) => ({
    id: e.id,
    titulo: e.etapaNome,
    status: (e.concluida ? 'CONCLUIDO' : 'PENDENTE') as JornadaEtapa['status'],
    data: e.dataConclusao ?? undefined,
    observacoes: e.observacoes ?? undefined,
  }))

  return [...base, ...extras]
}

export function mapMinisterio(
  api: ApiMinisterio,
  totalServicos = 0,
  totalVoluntarios = 0,
): Ministerio {
  return {
    id: api.id,
    nome: api.nome,
    liderNome: '—',
    totalVoluntarios,
    totalServicos,
    descricao: api.descricao ?? undefined,
    ativo: api.ativo,
  }
}

export function mapServico(api: ApiServico, totalVoluntarios = 0): Servico {
  return {
    id: api.id,
    ministerioId: api.ministerioId,
    nome: api.nome,
    ativo: api.ativo,
    totalVoluntarios,
  }
}

export function mapVoluntario(api: ApiPessoaServico): Voluntario {
  return {
    id: api.id,
    pessoaId: api.pessoaId,
    pessoaNome: api.pessoaNome,
    servicoId: api.servicoId,
    servicoNome: api.servicoNome,
    ministerioId: api.ministerioId,
    ministerioNome: api.ministerioNome,
    cargo: api.cargo,
    dataEntrada: api.dataEntrada,
    ativo: api.ativo,
    observacoes: api.observacoes,
    liderResponsavelId: api.liderResponsavelId,
    liderResponsavelNome: api.liderResponsavelNome ?? null,
  }
}

function mapSlotStatus(
  status: ApiEscala['voluntarios'][number]['status'],
): EscalaSlotStatus {
  if (status === 'CONFIRMADO') return 'CONFIRMADO'
  if (status === 'RECUSADO') return 'RECUSADO'
  return 'PENDENTE'
}

export function mapEscala(api: ApiEscala): Escala {
  const byMinisterio = new Map<string, EscalaSlot[]>()

  for (const servico of api.servicos) {
    const slotsForServico = api.voluntarios.filter(
      (v) => v.servicoId === servico.servicoId,
    )
    const slots: EscalaSlot[] = []

    for (const vol of slotsForServico) {
      slots.push({
        servico: servico.servicoNome,
        servicoId: servico.servicoId,
        voluntarioNome: vol.pessoaNome,
        voluntarioId: vol.pessoaId,
        designacaoId: vol.id,
        status: mapSlotStatus(vol.status),
      })
    }

    const missing = Math.max(
      0,
      servico.quantidadeNecessaria - slotsForServico.length,
    )
    for (let i = 0; i < missing; i += 1) {
      slots.push({
        servico: servico.servicoNome,
        servicoId: servico.servicoId,
        status: 'SEM_VOLUNTARIO',
      })
    }

    const key = 'Serviços'
    const current = byMinisterio.get(key) ?? []
    byMinisterio.set(key, [...current, ...slots])
  }

  const confirmados = api.voluntarios.filter(
    (v) => v.status === 'CONFIRMADO',
  ).length
  const pendentes = api.voluntarios.filter((v) => v.status === 'PENDENTE').length

  return {
    id: api.id,
    nome: api.titulo,
    data: api.dataEvento,
    horario: api.horaInicio.slice(0, 5),
    local: api.localEvento ?? undefined,
    totalVoluntarios: api.voluntarios.length,
    confirmados,
    pendentes,
    status: api.ativo ? 'PUBLICADA' : 'RASCUNHO',
    ministerios: [...byMinisterio.entries()].map(([nome, slots]) => ({
      nome,
      slots,
    })),
  }
}

export function mapUsuario(api: ApiUsuario): Usuario {
  return {
    id: api.id,
    nome: api.username,
    pessoaId: api.pessoaId,
    pessoaNome: api.pessoaId ?? '—',
    email: api.email ?? '',
    roles: mapRoles(api.papeis),
    status: api.ativo ? 'ATIVO' : 'INATIVO',
    ultimoAcesso: api.updatedAt,
  }
}

export function mapPapel(api: ApiPapel): Papel {
  return {
    id: api.id,
    nome: api.nome,
    descricao: api.descricao ?? undefined,
  }
}

export function mapRoles(papeis: string[]): Role[] {
  return papeis.filter((p): p is Role =>
    ['ADMIN', 'PASTOR', 'LIDER', 'VOLUNTARIO', 'MEMBRO'].includes(p),
  )
}
