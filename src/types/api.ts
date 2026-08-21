/** Contratos alinhados ao backend Spring (`base_api`). */

export interface ApiErrorBody {
  status: number
  error: string
  message: string
  path: string
}

export interface ApiLoginRequest {
  username: string
  senha: string
}

export interface ApiLoginResponse {
  token: string
  tipo: string
  usuarioId: string
  username: string
  papeis: string[]
}

export interface ApiPessoa {
  id: string
  nome: string
  nomeSocial: string | null
  email: string | null
  telefone: string | null
  dataNascimento: string | null
  dataCadastro: string
  ativo: boolean
  observacoes: string | null
  createdAt: string
  updatedAt: string
}

export interface ApiPessoaCreate {
  nome: string
  nomeSocial?: string
  email?: string
  telefone?: string
  dataNascimento?: string
  observacoes?: string
}

export interface ApiPessoaUpdate extends ApiPessoaCreate {
  ativo?: boolean
}

export interface ApiPessoaHistorico {
  id: string
  pessoaId: string
  descricao: string
  autorNome: string
  autorCargo: string | null
  dataRegistro: string
}

export interface ApiPessoaHistoricoCreate {
  descricao: string
  autorNome: string
  autorCargo?: string | null
  dataRegistro: string
}

export interface ApiJornada {
  id: string
  pessoaId: string
  aceitouJesus: boolean
  dataAceitouJesus: string | null
  batizado: boolean
  dataBatismo: string | null
  concluiuTrilhaBase: boolean
  dataConclusaoTrilhaBase: string | null
  membro: boolean
  dataMembro: string | null
}

export type ApiJornadaUpdate = Omit<ApiJornada, 'id' | 'pessoaId'>

export interface ApiJornadaEtapaCatalogo {
  id: string
  codigo: string
  nome: string
  descricao: string | null
  ordem: number | null
  ativo: boolean
}

export interface ApiPessoaEtapa {
  id: string
  pessoaId: string
  etapaId: string
  etapaCodigo: string
  etapaNome: string
  concluida: boolean
  dataConclusao: string | null
  observacoes: string | null
}

export interface ApiMinisterio {
  id: string
  nome: string
  descricao: string | null
  ativo: boolean
  createdAt: string
  updatedAt: string
}

export interface ApiMinisterioCreate {
  nome: string
  descricao?: string
  ativo?: boolean
}

export interface ApiServico {
  id: string
  ministerioId: string
  nome: string
  descricao: string | null
  ativo: boolean
  createdAt: string
  updatedAt: string
}

export interface ApiServicoCreate {
  nome: string
  descricao?: string
  ativo?: boolean
}

/** Vínculo pessoa ↔ serviço (voluntário). */
export interface ApiPessoaServico {
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

export interface ApiVoluntarioCreate {
  pessoaId: string
  servicoId: string
  cargo?: string | null
  dataEntrada?: string | null
  ativo?: boolean
  observacoes?: string | null
  liderResponsavelId?: string | null
}

export type ApiVoluntarioUpdate = ApiVoluntarioCreate

export interface ApiEscala {
  id: string
  titulo: string
  descricao: string | null
  dataEvento: string
  horaInicio: string
  horaFim: string | null
  localEvento: string | null
  ativo: boolean
  servicos: ApiEscalaServico[]
  voluntarios: ApiEscalaVoluntario[]
  createdAt: string
  updatedAt: string
}

export interface ApiEscalaServico {
  id: string
  servicoId: string
  servicoNome: string
  quantidadeNecessaria: number
}

export interface ApiEscalaVoluntario {
  id: string
  pessoaId: string
  pessoaNome: string
  servicoId: string
  servicoNome: string
  status: 'PENDENTE' | 'CONFIRMADO' | 'RECUSADO' | 'SUBSTITUIDO'
  observacoes: string | null
}

export interface ApiEscalaCreate {
  titulo: string
  descricao?: string
  dataEvento: string
  horaInicio: string
  horaFim?: string
  localEvento?: string
  servicos: { servicoId: string; quantidadeNecessaria: number }[]
}

export interface ApiEscalaUpdate {
  titulo: string
  descricao?: string | null
  dataEvento: string
  horaInicio: string
  horaFim?: string | null
  localEvento?: string | null
  ativo?: boolean
}

export interface ApiEscalaServicoCreate {
  servicoId: string
  quantidadeNecessaria: number
}

export interface ApiEscalaVoluntarioCreate {
  pessoaId: string
  servicoId: string
  status?: 'PENDENTE' | 'CONFIRMADO' | 'RECUSADO' | 'SUBSTITUIDO'
  observacoes?: string | null
}

export interface ApiUsuario {
  id: string
  pessoaId: string | null
  username: string
  email: string | null
  ativo: boolean
  papeis: string[]
  createdAt: string
  updatedAt: string
}

export interface ApiUsuarioCreate {
  username: string
  senha: string
  email?: string | null
  pessoaId?: string | null
  ativo?: boolean
  papelIds?: string[]
  papeis?: string[]
}

export interface ApiUsuarioUpdate {
  username?: string
  senha?: string
  email?: string | null
  pessoaId?: string | null
  ativo?: boolean
  papelIds?: string[]
  papeis?: string[]
}

export interface ApiPapel {
  id: string
  nome: string
  descricao: string | null
}

export interface ApiDisponibilidadeSemanal {
  id: string
  pessoaId: string
  diaSemana: string
  horaInicio: string
  horaFim: string
  disponivel: boolean
  observacoes: string | null
}

export interface ApiDisponibilidadeSemanalCreate {
  pessoaId: string
  diaSemana: string
  horaInicio: string
  horaFim: string
  disponivel?: boolean
  observacoes?: string | null
}

export interface ApiIndisponibilidade {
  id: string
  pessoaId: string
  dataInicio: string
  dataFim: string
  motivo: string | null
}

export interface ApiIndisponibilidadeCreate {
  pessoaId: string
  dataInicio: string
  dataFim: string
  motivo?: string | null
}

export type ApiExportRecurso =
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

export type ApiExportFormato = 'txt' | 'md' | 'xlsx'
