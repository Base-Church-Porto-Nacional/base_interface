import type {
  DashboardStats,
  Escala,
  JornadaEtapaCatalogo,
  Ministerio,
  Papel,
  Pessoa,
  PessoaHistorico,
  Servico,
  Usuario,
  Voluntario,
  DisponibilidadeSemanal,
  Indisponibilidade,
  AuthUser,
} from '../types'

export const mockUser: AuthUser = {
  id: 'u1',
  nome: 'Ana Costa',
  email: 'ana.costa@base.church',
  roles: ['ADMIN', 'PASTOR'],
  pessoaId: 'p1',
}

export const mockPessoas: Pessoa[] = [
  {
    id: 'p1',
    nome: 'Ana Costa',
    telefone: '(11) 98888-1001',
    email: 'ana.costa@base.church',
    status: 'ATIVO',
    tipos: ['MEMBRO', 'LIDER', 'PASTOR'],
    ministerios: ['Louvor', 'Pastoral'],
    dataCadastro: '2022-03-12',
    nascimento: '1988-05-14',
    jornada: [
      { id: 'j1', titulo: 'Visitante', status: 'CONCLUIDO', data: '2022-01-10' },
      { id: 'j2', titulo: 'Aceitou Jesus', status: 'CONCLUIDO', data: '2022-02-05', responsavel: 'Pr. Marcos' },
      { id: 'j3', titulo: 'Batizado', status: 'CONCLUIDO', data: '2022-04-17' },
      { id: 'j4', titulo: 'Trilha da Base', status: 'CONCLUIDO', data: '2022-08-20' },
      { id: 'j5', titulo: 'Membro', status: 'CONCLUIDO', data: '2022-09-01' },
      { id: 'j6', titulo: 'Voluntário', status: 'CONCLUIDO', data: '2023-01-15' },
      { id: 'j7', titulo: 'Líder', status: 'ATUAL', data: '2024-02-10' },
    ],
  },
  {
    id: 'p2',
    nome: 'João da Silva',
    telefone: '(11) 97777-2002',
    email: 'joao.silva@email.com',
    status: 'ATIVO',
    tipos: ['MEMBRO', 'VOLUNTARIO', 'LIDER'],
    ministerios: ['Louvor'],
    dataCadastro: '2023-01-20',
    nascimento: '1995-08-22',
    jornada: [
      { id: 'j1', titulo: 'Visitante', status: 'CONCLUIDO', data: '2022-11-06' },
      { id: 'j2', titulo: 'Aceitou Jesus', status: 'CONCLUIDO', data: '2022-12-18' },
      { id: 'j3', titulo: 'Batizado', status: 'CONCLUIDO', data: '2023-03-12' },
      { id: 'j4', titulo: 'Trilha da Base', status: 'CONCLUIDO', data: '2023-06-30' },
      { id: 'j5', titulo: 'Membro', status: 'CONCLUIDO', data: '2023-07-15' },
      { id: 'j6', titulo: 'Voluntário', status: 'CONCLUIDO', data: '2023-09-01' },
      { id: 'j7', titulo: 'Líder', status: 'ATUAL', data: '2025-01-20' },
    ],
  },
  {
    id: 'p3',
    nome: 'Maria Oliveira',
    telefone: '(11) 96666-3003',
    email: 'maria.oliveira@email.com',
    status: 'ATIVO',
    tipos: ['MEMBRO', 'VOLUNTARIO'],
    ministerios: ['Louvor', 'Infantil'],
    dataCadastro: '2023-05-08',
  },
  {
    id: 'p4',
    nome: 'Gustavo Antunes',
    telefone: '(11) 95555-4004',
    email: 'gustavo@email.com',
    status: 'ATIVO',
    tipos: ['MEMBRO', 'VOLUNTARIO'],
    ministerios: ['Louvor', 'Mídia'],
    dataCadastro: '2024-02-14',
  },
  {
    id: 'p5',
    nome: 'Pedro Santos',
    telefone: '(11) 94444-5005',
    email: 'pedro.santos@email.com',
    status: 'ATIVO',
    tipos: ['VOLUNTARIO'],
    ministerios: ['Louvor'],
    dataCadastro: '2024-06-01',
  },
  {
    id: 'p6',
    nome: 'Carla Mendes',
    telefone: '(11) 93333-6006',
    email: 'carla.mendes@email.com',
    status: 'ATIVO',
    tipos: ['VISITANTE'],
    ministerios: [],
    dataCadastro: '2026-08-10',
  },
  {
    id: 'p7',
    nome: 'Carlos Lima',
    telefone: '(11) 92222-7007',
    email: 'carlos.lima@email.com',
    status: 'ATIVO',
    tipos: ['MEMBRO', 'VOLUNTARIO', 'LIDER'],
    ministerios: ['Mídia'],
    dataCadastro: '2021-11-03',
  },
  {
    id: 'p8',
    nome: 'Beatriz Rocha',
    telefone: '(11) 91111-8008',
    email: 'beatriz.rocha@email.com',
    status: 'INATIVO',
    tipos: ['MEMBRO'],
    ministerios: ['Recepção'],
    dataCadastro: '2020-04-19',
  },
]

export const mockMinisterios: Ministerio[] = [
  {
    id: 'm1',
    nome: 'Louvor',
    liderNome: 'João Silva',
    liderId: 'p2',
    totalVoluntarios: 32,
    totalServicos: 6,
    ativo: true,
  },
  {
    id: 'm2',
    nome: 'Mídia',
    liderNome: 'Carlos Lima',
    liderId: 'p7',
    totalVoluntarios: 18,
    totalServicos: 4,
    ativo: true,
  },
  {
    id: 'm3',
    nome: 'Infantil',
    liderNome: 'Maria Oliveira',
    liderId: 'p3',
    totalVoluntarios: 14,
    totalServicos: 3,
    ativo: true,
  },
  {
    id: 'm4',
    nome: 'Recepção',
    liderNome: 'Ana Costa',
    liderId: 'p1',
    totalVoluntarios: 22,
    totalServicos: 2,
    ativo: true,
  },
  {
    id: 'm5',
    nome: 'Intercessão',
    liderNome: 'Ana Costa',
    liderId: 'p1',
    totalVoluntarios: 11,
    totalServicos: 1,
    ativo: true,
  },
]

export const mockServicos: Servico[] = [
  { id: 's1', ministerioId: 'm1', nome: 'Vocal', ativo: true, totalVoluntarios: 12 },
  { id: 's2', ministerioId: 'm1', nome: 'Violão', ativo: true, totalVoluntarios: 8 },
  { id: 's3', ministerioId: 'm1', nome: 'Guitarra', ativo: true, totalVoluntarios: 6 },
  { id: 's4', ministerioId: 'm1', nome: 'Baixo', ativo: true, totalVoluntarios: 4 },
  { id: 's5', ministerioId: 'm1', nome: 'Teclado', ativo: true, totalVoluntarios: 5 },
  { id: 's6', ministerioId: 'm1', nome: 'Bateria', ativo: true, totalVoluntarios: 3 },
  { id: 's7', ministerioId: 'm2', nome: 'Projeção', ativo: true, totalVoluntarios: 7 },
  { id: 's8', ministerioId: 'm2', nome: 'Som', ativo: true, totalVoluntarios: 5 },
  { id: 's9', ministerioId: 'm2', nome: 'Câmera', ativo: true, totalVoluntarios: 4 },
  { id: 's10', ministerioId: 'm2', nome: 'Transmissão', ativo: true, totalVoluntarios: 3 },
]

export const mockVoluntarios: Voluntario[] = [
  {
    id: 'v1',
    pessoaId: 'p4',
    pessoaNome: 'Gustavo Antunes',
    servicoId: 's2',
    servicoNome: 'Violão',
    ministerioId: 'm1',
    ministerioNome: 'Louvor',
    cargo: 'Líder',
    dataEntrada: '2024-03-01',
    ativo: true,
    observacoes: null,
    liderResponsavelId: 'p2',
    liderResponsavelNome: 'João da Silva',
  },
  {
    id: 'v1b',
    pessoaId: 'p4',
    pessoaNome: 'Gustavo Antunes',
    servicoId: 's3',
    servicoNome: 'Guitarra',
    ministerioId: 'm1',
    ministerioNome: 'Louvor',
    cargo: 'Auxiliar',
    dataEntrada: '2024-03-01',
    ativo: true,
    observacoes: null,
    liderResponsavelId: 'p2',
  },
  {
    id: 'v2',
    pessoaId: 'p2',
    pessoaNome: 'João da Silva',
    servicoId: 's1',
    servicoNome: 'Vocal',
    ministerioId: 'm1',
    ministerioNome: 'Louvor',
    cargo: 'Líder',
    dataEntrada: '2023-02-01',
    ativo: true,
    observacoes: null,
    liderResponsavelId: null,
  },
  {
    id: 'v3',
    pessoaId: 'p3',
    pessoaNome: 'Maria Oliveira',
    servicoId: 's1',
    servicoNome: 'Vocal',
    ministerioId: 'm1',
    ministerioNome: 'Louvor',
    cargo: 'Auxiliar',
    dataEntrada: '2023-06-01',
    ativo: true,
    observacoes: null,
    liderResponsavelId: 'p2',
  },
  {
    id: 'v4',
    pessoaId: 'p5',
    pessoaNome: 'Pedro Santos',
    servicoId: 's3',
    servicoNome: 'Guitarra',
    ministerioId: 'm1',
    ministerioNome: 'Louvor',
    cargo: null,
    dataEntrada: '2024-06-15',
    ativo: true,
    observacoes: null,
    liderResponsavelId: 'p2',
  },
  {
    id: 'v5',
    pessoaId: 'p7',
    pessoaNome: 'Carlos Lima',
    servicoId: 's8',
    servicoNome: 'Som',
    ministerioId: 'm2',
    ministerioNome: 'Mídia',
    cargo: 'Líder',
    dataEntrada: '2022-01-10',
    ativo: true,
    observacoes: null,
    liderResponsavelId: null,
  },
]

export const mockHistoricos: PessoaHistorico[] = [
  {
    id: 'h1',
    pessoaId: 'p1',
    descricao: 'Participou do encontro de líderes.',
    autorNome: 'Pr. Marcos',
    autorCargo: 'Pastor',
    dataRegistro: '2026-08-10',
  },
  {
    id: 'h2',
    pessoaId: 'p4',
    descricao: 'Iniciou voluntariado no Louvor.',
    autorNome: 'João da Silva',
    autorCargo: 'Líder',
    dataRegistro: '2024-03-01',
  },
]

export const mockPapeis: Papel[] = [
  { id: 'papel1', nome: 'ADMIN', descricao: 'Administrador do sistema' },
  { id: 'papel2', nome: 'PASTOR', descricao: 'Pastor' },
  { id: 'papel3', nome: 'LIDER', descricao: 'Líder de ministério' },
  { id: 'papel4', nome: 'VOLUNTARIO', descricao: 'Voluntário' },
  { id: 'papel5', nome: 'MEMBRO', descricao: 'Membro' },
]

export const mockJornadaEtapas: JornadaEtapaCatalogo[] = [
  {
    id: 'je1',
    codigo: 'CURSO_MEMBRO',
    nome: 'Curso de membros',
    descricao: 'Formação para novos membros',
    ordem: 10,
    ativo: true,
  },
  {
    id: 'je2',
    codigo: 'DISCIPULADO',
    nome: 'Discipulado',
    ordem: 20,
    ativo: true,
  },
]

export const mockEscalas: Escala[] = [
  {
    id: 'e1',
    nome: 'Culto de Domingo',
    data: '2026-08-24',
    horario: '18:00',
    totalVoluntarios: 8,
    confirmados: 5,
    pendentes: 2,
    status: 'PUBLICADA',
    ministerios: [
      {
        nome: 'Louvor',
        slots: [
          { servico: 'Vocal', voluntarioNome: 'João', status: 'CONFIRMADO' },
          { servico: 'Vocal', voluntarioNome: 'Maria', status: 'CONFIRMADO' },
          { servico: 'Violão', voluntarioNome: 'Gustavo', status: 'CONFIRMADO' },
          { servico: 'Guitarra', voluntarioNome: 'Pedro', status: 'PENDENTE' },
          { servico: 'Baixo', voluntarioNome: 'Carlos', status: 'CONFIRMADO' },
          { servico: 'Bateria', status: 'SEM_VOLUNTARIO' },
        ],
      },
      {
        nome: 'Mídia',
        slots: [
          { servico: 'Projeção', voluntarioNome: 'Gustavo', status: 'CONFIRMADO' },
          { servico: 'Som', voluntarioNome: 'Carlos', status: 'PENDENTE' },
        ],
      },
    ],
  },
  {
    id: 'e2',
    nome: 'Culto de Quarta',
    data: '2026-08-27',
    horario: '20:00',
    totalVoluntarios: 5,
    confirmados: 2,
    pendentes: 3,
    status: 'PUBLICADA',
    ministerios: [
      {
        nome: 'Louvor',
        slots: [
          { servico: 'Vocal', voluntarioNome: 'Maria', status: 'CONFIRMADO' },
          { servico: 'Violão', voluntarioNome: 'Gustavo', status: 'PENDENTE' },
          { servico: 'Teclado', status: 'SEM_VOLUNTARIO' },
        ],
      },
    ],
  },
  {
    id: 'e3',
    nome: 'Culto de Domingo',
    data: '2026-08-31',
    horario: '10:00',
    totalVoluntarios: 6,
    confirmados: 0,
    pendentes: 6,
    status: 'RASCUNHO',
    ministerios: [
      {
        nome: 'Recepção',
        slots: [
          { servico: 'Porta', voluntarioNome: 'Beatriz', status: 'PENDENTE' },
          { servico: 'Boas-vindas', status: 'SEM_VOLUNTARIO' },
        ],
      },
    ],
  },
]

export const mockUsuarios: Usuario[] = [
  {
    id: 'u1',
    nome: 'Ana Costa',
    pessoaNome: 'Ana Costa',
    email: 'ana.costa@base.church',
    roles: ['ADMIN', 'PASTOR'],
    status: 'ATIVO',
    ultimoAcesso: '2026-08-20T18:30:00',
  },
  {
    id: 'u2',
    nome: 'João Silva',
    pessoaNome: 'João da Silva',
    email: 'joao.silva@email.com',
    roles: ['MEMBRO', 'VOLUNTARIO', 'LIDER'],
    status: 'ATIVO',
    ultimoAcesso: '2026-08-19T21:00:00',
  },
  {
    id: 'u3',
    nome: 'Gustavo Antunes',
    pessoaNome: 'Gustavo Antunes',
    email: 'gustavo@email.com',
    roles: ['MEMBRO', 'VOLUNTARIO'],
    status: 'ATIVO',
    ultimoAcesso: '2026-08-18T09:15:00',
  },
]

export const mockDashboard: DashboardStats = {
  totalPessoas: 248,
  totalMembros: 183,
  totalVoluntarios: 74,
  totalLideres: 31,
  escalasPendentes: 12,
  visitantesRecentes: 8,
  proximasEscalas: [
    {
      id: 'e1',
      data: '2026-08-24',
      horario: '18:00',
      ministerio: 'Louvor',
      totalVoluntarios: 6,
      confirmados: 4,
      pendentes: 1,
    },
    {
      id: 'e2',
      data: '2026-08-27',
      horario: '20:00',
      ministerio: 'Louvor',
      totalVoluntarios: 3,
      confirmados: 1,
      pendentes: 1,
    },
    {
      id: 'e1b',
      data: '2026-08-24',
      horario: '18:00',
      ministerio: 'Mídia',
      totalVoluntarios: 2,
      confirmados: 1,
      pendentes: 1,
    },
  ],
  jornada: {
    novosVisitantes: 14,
    aceitaramJesus: 6,
    batizados: 4,
    trilhaBase: 9,
    novosMembros: 5,
  },
}

export const mockDisponibilidade: DisponibilidadeSemanal[] = [
  { dia: 'Domingo', diaSemana: 'DOMINGO', periodos: ['Manhã', 'Noite'] },
  { dia: 'Segunda-feira', diaSemana: 'SEGUNDA', periodos: [] },
  { dia: 'Terça-feira', diaSemana: 'TERCA', periodos: [] },
  { dia: 'Quarta-feira', diaSemana: 'QUARTA', periodos: ['Noite'] },
  { dia: 'Quinta-feira', diaSemana: 'QUINTA', periodos: [] },
  { dia: 'Sexta-feira', diaSemana: 'SEXTA', periodos: [] },
  { dia: 'Sábado', diaSemana: 'SABADO', periodos: [] },
]

export const mockIndisponibilidades: Indisponibilidade[] = [
  { id: 'i1', data: '2026-09-20', motivo: 'Viagem' },
]

export function delay<T>(data: T, ms = 280): Promise<T> {
  return new Promise((resolve) => {
    setTimeout(() => resolve(data), ms)
  })
}

export const isMockEnabled = (): boolean =>
  String(import.meta.env.VITE_USE_MOCK).toLowerCase() === 'true'

