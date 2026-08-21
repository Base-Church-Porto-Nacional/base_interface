export type Role =
  | 'ADMIN'
  | 'PASTOR'
  | 'LIDER'
  | 'VOLUNTARIO'
  | 'MEMBRO'

export type PessoaStatus = 'ATIVO' | 'INATIVO'

export type PessoaTipo =
  | 'VISITANTE'
  | 'MEMBRO'
  | 'VOLUNTARIO'
  | 'LIDER'
  | 'PASTOR'

export type EscalaSlotStatus =
  | 'CONFIRMADO'
  | 'PENDENTE'
  | 'RECUSADO'
  | 'SEM_VOLUNTARIO'

export type JornadaEtapaStatus = 'CONCLUIDO' | 'ATUAL' | 'PENDENTE'

export type ExportRecurso =
  | 'pessoas'
  | 'historicos'
  | 'jornadas'
  | 'ministerios'
  | 'servicos'
  | 'voluntarios'
  | 'escalas'
  | 'disponibilidades'
  | 'usuarios'
  | 'completo'

export type ExportFormato = 'txt' | 'md' | 'xlsx'

export interface AuthUser {
  id: string
  nome: string
  email: string
  roles: Role[]
  pessoaId?: string
  avatarUrl?: string
}

export interface LoginRequest {
  username: string
  password: string
}

export interface LoginResponse {
  accessToken: string
  refreshToken?: string
  user: AuthUser
}

export interface Pessoa {
  id: string
  nome: string
  telefone: string
  email: string
  status: PessoaStatus
  tipos: PessoaTipo[]
  ministerios: string[]
  dataCadastro: string
  nascimento?: string
  jornada?: JornadaEtapa[]
}

export interface PessoaHistorico {
  id: string
  pessoaId: string
  descricao: string
  autorNome: string
  autorCargo: string | null
  dataRegistro: string
}

export interface JornadaEtapa {
  id: string
  titulo: string
  status: JornadaEtapaStatus
  data?: string
  responsavel?: string
  observacoes?: string
}

export interface JornadaEtapaCatalogo {
  id: string
  codigo: string
  nome: string
  descricao?: string
  ordem?: number
  ativo: boolean
}

export interface Ministerio {
  id: string
  nome: string
  liderNome: string
  liderId?: string
  totalVoluntarios: number
  totalServicos: number
  descricao?: string
  ativo: boolean
}

export interface Servico {
  id: string
  ministerioId: string
  nome: string
  ativo: boolean
  totalVoluntarios: number
}

/** Vínculo pessoa ↔ serviço (fonte de verdade da API). */
export interface Voluntario {
  id: string
  pessoaId: string
  pessoaNome: string
  servicoId: string
  servicoNome: string
  ministerioId: string
  ministerioNome: string
  cargo: string | null
  dataEntrada: string | null
  ativo: boolean
  observacoes: string | null
  liderResponsavelId: string | null
  liderResponsavelNome?: string | null
}

export interface Escala {
  id: string
  nome: string
  data: string
  horario: string
  local?: string
  ministerios: EscalaMinisterio[]
  totalVoluntarios: number
  confirmados: number
  pendentes: number
  status: 'RASCUNHO' | 'PUBLICADA' | 'CONCLUIDA'
}

export interface EscalaMinisterio {
  nome: string
  slots: EscalaSlot[]
}

export interface EscalaSlot {
  servico: string
  servicoId?: string
  voluntarioNome?: string
  voluntarioId?: string
  designacaoId?: string
  status: EscalaSlotStatus
}

export interface Papel {
  id: string
  nome: string
  descricao?: string
}

export interface Usuario {
  id: string
  nome: string
  pessoaId?: string | null
  pessoaNome: string
  email: string
  roles: Role[]
  papelIds?: string[]
  status: PessoaStatus
  ultimoAcesso?: string
}

export interface DashboardStats {
  totalPessoas: number
  totalMembros: number
  totalVoluntarios: number
  totalLideres: number
  proximasEscalas: EscalaResumo[]
  escalasPendentes: number
  visitantesRecentes: number
  jornada: JornadaIndicadores
}

export interface EscalaResumo {
  id: string
  data: string
  horario: string
  ministerio: string
  totalVoluntarios: number
  confirmados: number
  pendentes: number
}

export interface JornadaIndicadores {
  novosVisitantes: number
  aceitaramJesus: number
  batizados: number
  trilhaBase: number
  novosMembros: number
}

export interface DisponibilidadeSemanal {
  dia: string
  diaSemana: string
  periodos: string[]
  slots?: DisponibilidadeSlot[]
}

export interface DisponibilidadeSlot {
  id?: string
  horaInicio: string
  horaFim: string
  periodo: string
}

export interface Indisponibilidade {
  id: string
  data: string
  dataFim?: string
  motivo?: string
}

export interface PageParams {
  page?: number
  size?: number
  search?: string
  filtro?: string
}

export interface PageResponse<T> {
  content: T[]
  totalElements: number
  totalPages: number
  page: number
  size: number
}
