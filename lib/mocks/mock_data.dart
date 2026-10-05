import '../models/models.dart';
import '../utils/format.dart';

const mockIgrejaMatriz = Igreja(
  id: 'i1',
  nome: 'Base Church',
  tipo: IgrejaTipo.matriz,
  pastorPessoaId: 'p1',
  pastorNome: 'Ana Costa',
  adminUsuarioId: 'u1',
  adminNome: 'Ana Costa',
  ativo: true,
);

const mockIgrejaFilial = Igreja(
  id: 'i2',
  nome: 'Base Church — Zona Sul',
  tipo: IgrejaTipo.filial,
  igrejaMatrizId: 'i1',
  pastorPessoaId: 'p8',
  pastorNome: 'Pedro Alves',
  adminUsuarioId: 'u2',
  adminNome: 'Luciana Rocha',
  ativo: true,
);

final mockIgrejas = <Igreja>[mockIgrejaMatriz, mockIgrejaFilial];

const mockUser = AuthUser(
  id: 'u1',
  nome: 'Ana Costa',
  email: 'ana.costa@base.church',
  roles: [Role.admin, Role.pastor],
  pessoaId: 'p1',
  igrejaId: 'i1',
  igrejaTipo: IgrejaTipo.matriz,
  igrejaNome: 'Base Church',
  igrejasVisiveis: [mockIgrejaMatriz, mockIgrejaFilial],
);

const mockUserFilial = AuthUser(
  id: 'u2',
  nome: 'Luciana Rocha',
  email: 'luciana.rocha@base.church',
  roles: [Role.admin],
  pessoaId: 'p9',
  igrejaId: 'i2',
  igrejaTipo: IgrejaTipo.filial,
  igrejaNome: 'Base Church — Zona Sul',
  igrejasVisiveis: [mockIgrejaFilial],
);

const mockUserLider = AuthUser(
  id: 'u3',
  nome: 'João da Silva',
  email: 'joao.silva@email.com',
  roles: [Role.lider, Role.voluntario, Role.membro],
  pessoaId: 'p2',
  igrejaId: 'i1',
  igrejaTipo: IgrejaTipo.matriz,
  igrejaNome: 'Base Church',
  igrejasVisiveis: [mockIgrejaMatriz],
);

const mockUserCoordenador = AuthUser(
  id: 'u5',
  nome: 'Maria Oliveira',
  email: 'maria.oliveira@email.com',
  roles: [Role.voluntario, Role.membro],
  pessoaId: 'p3',
  igrejaId: 'i1',
  igrejaTipo: IgrejaTipo.matriz,
  igrejaNome: 'Base Church',
  igrejasVisiveis: [mockIgrejaMatriz],
);

const mockUserMidia = AuthUser(
  id: 'u4',
  nome: 'Carlos Lima',
  email: 'carlos.lima@email.com',
  roles: [Role.lider, Role.voluntario, Role.membro],
  pessoaId: 'p7',
  igrejaId: 'i1',
  igrejaTipo: IgrejaTipo.matriz,
  igrejaNome: 'Base Church',
  igrejasVisiveis: [mockIgrejaMatriz],
);

const mockUserMembro = AuthUser(
  id: 'u6',
  nome: 'Fernanda Dias',
  email: 'fernanda.dias@email.com',
  roles: [Role.voluntario, Role.membro],
  pessoaId: 'p5',
  igrejaId: 'i1',
  igrejaTipo: IgrejaTipo.matriz,
  igrejaNome: 'Base Church',
  igrejasVisiveis: [mockIgrejaMatriz],
);

const mockUserPastorFilial = AuthUser(
  id: 'u7',
  nome: 'Pedro Alves',
  email: 'pedro.alves@base.church',
  roles: [Role.pastor],
  pessoaId: 'p8',
  igrejaId: 'i2',
  igrejaTipo: IgrejaTipo.filial,
  igrejaNome: 'Base Church — Zona Sul',
  igrejasVisiveis: [mockIgrejaFilial],
);

AuthUser mockUserByLogin(String username) {
  switch (username.trim().toLowerCase()) {
    case 'filial':
      return mockUserFilial;
    case 'joao':
      return mockUserLider;
    case 'maria':
      return mockUserCoordenador;
    case 'midia':
      return mockUserMidia;
    case 'membro':
      return mockUserMembro;
    case 'pedro':
      return mockUserPastorFilial;
    default:
      return mockUser;
  }
}

final mockPessoas = <Pessoa>[
  Pessoa(
    id: 'p1',
    nome: 'Ana Costa',
    telefone: '(11) 98888-1001',
    email: 'ana.costa@base.church',
    status: PessoaStatus.ativo,
    tipos: [PessoaTipo.membro, PessoaTipo.lider, PessoaTipo.pastor],
    ministerios: ['Pastoral', 'Recepção'],
    dataCadastro: '2022-03-12',
    igrejaId: 'i1',
    usuarioId: 'u1',
    jornada: const [
      JornadaEtapa(id: 'j3', titulo: 'Batizado', status: JornadaEtapaStatus.concluido),
    ],
  ),
  Pessoa(
    id: 'p2',
    nome: 'João da Silva',
    telefone: '(11) 97777-2002',
    email: 'joao.silva@email.com',
    status: PessoaStatus.ativo,
    tipos: [PessoaTipo.membro, PessoaTipo.voluntario, PessoaTipo.lider],
    ministerios: ['Louvor'],
    dataCadastro: '2023-01-20',
    igrejaId: 'i1',
    usuarioId: 'u3',
    jornada: const [
      JornadaEtapa(id: 'j3', titulo: 'Batizado', status: JornadaEtapaStatus.concluido),
    ],
  ),
  Pessoa(
    id: 'p3',
    nome: 'Maria Oliveira',
    telefone: '(11) 96666-3003',
    email: 'maria.oliveira@email.com',
    status: PessoaStatus.ativo,
    tipos: [PessoaTipo.membro, PessoaTipo.voluntario],
    ministerios: ['Louvor', 'Infantil'],
    dataCadastro: '2023-05-08',
    igrejaId: 'i1',
    usuarioId: 'u5',
    jornada: const [
      JornadaEtapa(id: 'j3', titulo: 'Batizado', status: JornadaEtapaStatus.concluido),
    ],
  ),
  Pessoa(
    id: 'p4',
    nome: 'Bruno Santos',
    telefone: '(11) 95555-4004',
    email: 'bruno.santos@email.com',
    status: PessoaStatus.ativo,
    tipos: [PessoaTipo.membro, PessoaTipo.voluntario],
    ministerios: ['Mídia'],
    dataCadastro: '2024-02-14',
    igrejaId: 'i1',
  ),
  Pessoa(
    id: 'p5',
    nome: 'Fernanda Dias',
    telefone: '(11) 94444-5005',
    email: 'fernanda.dias@email.com',
    status: PessoaStatus.ativo,
    tipos: [PessoaTipo.membro, PessoaTipo.voluntario],
    ministerios: ['Infantil'],
    dataCadastro: '2024-06-01',
    igrejaId: 'i1',
    usuarioId: 'u6',
  ),
  Pessoa(
    id: 'p6',
    nome: 'Carla Mendes',
    telefone: '(11) 93333-6006',
    email: 'carla.mendes@email.com',
    status: PessoaStatus.ativo,
    tipos: [PessoaTipo.visitante],
    ministerios: [],
    dataCadastro: '2026-08-10',
    igrejaId: 'i1',
  ),
  Pessoa(
    id: 'p7',
    nome: 'Carlos Lima',
    telefone: '(11) 92222-7007',
    email: 'carlos.lima@email.com',
    status: PessoaStatus.ativo,
    tipos: [PessoaTipo.membro, PessoaTipo.voluntario, PessoaTipo.lider],
    ministerios: ['Mídia'],
    dataCadastro: '2021-11-03',
    igrejaId: 'i1',
    usuarioId: 'u4',
    jornada: const [
      JornadaEtapa(id: 'j3', titulo: 'Batizado', status: JornadaEtapaStatus.concluido),
    ],
  ),
  Pessoa(
    id: 'p8',
    nome: 'Pedro Alves',
    telefone: '(11) 91111-8008',
    email: 'pedro.alves@base.church',
    status: PessoaStatus.ativo,
    tipos: [PessoaTipo.membro, PessoaTipo.pastor],
    ministerios: ['Pastoral'],
    dataCadastro: '2020-08-01',
    igrejaId: 'i2',
    usuarioId: 'u7',
    jornada: const [
      JornadaEtapa(id: 'j3', titulo: 'Batizado', status: JornadaEtapaStatus.concluido),
    ],
  ),
  Pessoa(
    id: 'p9',
    nome: 'Luciana Rocha',
    telefone: '(11) 90000-9009',
    email: 'luciana.rocha@base.church',
    status: PessoaStatus.ativo,
    tipos: [PessoaTipo.membro],
    ministerios: [],
    dataCadastro: '2025-01-15',
    igrejaId: 'i2',
    usuarioId: 'u2',
  ),
  Pessoa(
    id: 'p10',
    nome: 'Rafael Souza',
    telefone: '(11) 98877-1010',
    email: 'rafael.souza@email.com',
    status: PessoaStatus.ativo,
    tipos: [PessoaTipo.membro, PessoaTipo.voluntario],
    ministerios: ['Louvor Zona Sul'],
    dataCadastro: '2025-04-10',
    igrejaId: 'i2',
  ),
];

final mockHistoricos = <PessoaHistorico>[
  const PessoaHistorico(
    id: 'h1',
    pessoaId: 'p1',
    descricao: 'Participou do encontro de líderes.',
    autorNome: 'Pr. Marcos',
    autorCargo: 'Pastor',
    dataRegistro: '2026-08-10',
  ),
  const PessoaHistorico(
    id: 'h2',
    pessoaId: 'p2',
    descricao: 'Assumiu liderança do Louvor.',
    autorNome: 'Ana Costa',
    autorCargo: 'Pastora',
    dataRegistro: '2025-01-20',
  ),
];

final mockBasesMinisteriais = <BaseMinisterial>[
  const BaseMinisterial(
    id: 'b1',
    nome: 'Adoração',
    descricao: 'Louvor, mídia e ambientação dos cultos.',
    liderNome: 'João da Silva',
    liderPessoaId: 'p2',
    coordenadorPessoaId: 'p3',
    coordenadorNome: 'Maria Oliveira',
    ativo: true,
    igrejaId: 'i1',
  ),
  const BaseMinisterial(
    id: 'b2',
    nome: 'Serviço',
    descricao: 'Recepção, estacionamento e suporte à igreja.',
    liderNome: 'Ana Costa',
    liderPessoaId: 'p1',
    coordenadorPessoaId: 'p5',
    coordenadorNome: 'Fernanda Dias',
    ativo: true,
    igrejaId: 'i1',
  ),
  const BaseMinisterial(
    id: 'b3',
    nome: 'Missão',
    descricao: 'Evangelismo e ação missionária.',
    liderNome: 'Carlos Lima',
    liderPessoaId: 'p7',
    coordenadorPessoaId: 'p4',
    coordenadorNome: 'Bruno Santos',
    ativo: true,
    igrejaId: 'i1',
  ),
  const BaseMinisterial(
    id: 'b4',
    nome: 'Conectados',
    descricao: 'Acolhimento, redes e integração de novos membros.',
    liderNome: 'Carla Mendes',
    liderPessoaId: 'p6',
    coordenadorPessoaId: 'p9',
    coordenadorNome: 'Luciana Rocha',
    ativo: true,
    igrejaId: 'i1',
  ),
  const BaseMinisterial(
    id: 'b5',
    nome: 'Discipulado',
    descricao: 'Ensino, células e formação de líderes.',
    liderNome: 'Pedro Alves',
    liderPessoaId: 'p8',
    coordenadorPessoaId: 'p10',
    coordenadorNome: 'Rafael Souza',
    ativo: true,
    igrejaId: 'i1',
  ),
];

final mockMinisterios = <Ministerio>[
  Ministerio(
    id: 'm1',
    nome: 'Louvor',
    liderNome: 'João da Silva',
    liderPessoaId: 'p2',
    coordenadorPessoaId: 'p3',
    coordenadorNome: 'Maria Oliveira',
    totalVoluntarios: 4,
    totalServicos: 3,
    ativo: true,
    igrejaId: 'i1',
    tipo: MinisterioTipo.musica,
    descricao: 'Ministério de música e louvor.',
    anotacoes: 'Ensaio às quintas, 20h.',
    ordem: 'Abertura · Ofertório · Encerramento',
    baseMinisterialId: 'b1',
    baseMinisterialNome: 'Adoração',
    servicos: const [
      Servico(id: 's1c', ministerioId: 'm1', nome: 'Coordenador', ficcao: true, ativo: true),
      Servico(id: 's1a', ministerioId: 'm1', nome: 'Vocal', ficcao: false, ativo: true),
      Servico(id: 's1b', ministerioId: 'm1', nome: 'Violão', ficcao: false, ativo: true),
    ],
  ),
  Ministerio(
    id: 'm2',
    nome: 'Mídia',
    liderNome: 'Carlos Lima',
    liderPessoaId: 'p7',
    coordenadorPessoaId: 'p4',
    coordenadorNome: 'Bruno Santos',
    totalVoluntarios: 2,
    totalServicos: 3,
    ativo: true,
    igrejaId: 'i1',
    tipo: MinisterioTipo.midia,
    descricao: 'Projeção, som e transmissões.',
    baseMinisterialId: 'b1',
    baseMinisterialNome: 'Adoração',
    servicos: const [
      Servico(id: 's2c', ministerioId: 'm2', nome: 'Coordenador', ficcao: true, ativo: true),
      Servico(id: 's2a', ministerioId: 'm2', nome: 'Projeção', ficcao: false, ativo: true),
      Servico(id: 's2b', ministerioId: 'm2', nome: 'Som', ficcao: false, ativo: true),
    ],
  ),
  Ministerio(
    id: 'm3',
    nome: 'Infantil',
    liderNome: 'Maria Oliveira',
    liderPessoaId: 'p3',
    coordenadorPessoaId: 'p5',
    coordenadorNome: 'Fernanda Dias',
    totalVoluntarios: 2,
    totalServicos: 2,
    ativo: true,
    igrejaId: 'i1',
    tipo: MinisterioTipo.geral,
    baseMinisterialId: 'b5',
    baseMinisterialNome: 'Discipulado',
    servicos: const [
      Servico(id: 's3c', ministerioId: 'm3', nome: 'Coordenador', ficcao: true, ativo: true),
      Servico(id: 's3a', ministerioId: 'm3', nome: 'Professor', ficcao: false, ativo: true),
    ],
  ),
  Ministerio(
    id: 'm4',
    nome: 'Recepção',
    liderNome: 'Ana Costa',
    liderPessoaId: 'p1',
    coordenadorPessoaId: 'p1',
    coordenadorNome: 'Ana Costa',
    totalVoluntarios: 1,
    totalServicos: 2,
    ativo: true,
    igrejaId: 'i1',
    tipo: MinisterioTipo.geral,
    baseMinisterialId: 'b2',
    baseMinisterialNome: 'Serviço',
    servicos: const [
      Servico(id: 's4c', ministerioId: 'm4', nome: 'Coordenador', ficcao: true, ativo: true),
      Servico(id: 's4a', ministerioId: 'm4', nome: 'Recepção', ficcao: false, ativo: true),
    ],
  ),
  Ministerio(
    id: 'm5',
    nome: 'Louvor Zona Sul',
    liderNome: 'Rafael Souza',
    liderPessoaId: 'p10',
    coordenadorPessoaId: 'p10',
    coordenadorNome: 'Rafael Souza',
    totalVoluntarios: 1,
    totalServicos: 2,
    ativo: true,
    igrejaId: 'i2',
    tipo: MinisterioTipo.musica,
    baseMinisterialId: 'b1',
    baseMinisterialNome: 'Adoração',
    servicos: const [
      Servico(id: 's5c', ministerioId: 'm5', nome: 'Coordenador', ficcao: true, ativo: true),
      Servico(id: 's5a', ministerioId: 'm5', nome: 'Vocal', ficcao: false, ativo: true),
    ],
  ),
  Ministerio(
    id: 'm6',
    nome: 'Missões',
    liderNome: 'Carlos Lima',
    liderPessoaId: 'p7',
    coordenadorPessoaId: 'p4',
    coordenadorNome: 'Bruno Santos',
    totalVoluntarios: 2,
    totalServicos: 2,
    ativo: true,
    igrejaId: 'i1',
    tipo: MinisterioTipo.geral,
    descricao: 'Ação missionária e evangelismo.',
    baseMinisterialId: 'b3',
    baseMinisterialNome: 'Missão',
    servicos: const [
      Servico(id: 's6c', ministerioId: 'm6', nome: 'Coordenador', ficcao: true, ativo: true),
      Servico(id: 's6a', ministerioId: 'm6', nome: 'Evangelismo', ficcao: false, ativo: true),
    ],
  ),
  Ministerio(
    id: 'm7',
    nome: 'Acolhimento',
    liderNome: 'Carla Mendes',
    liderPessoaId: 'p6',
    coordenadorPessoaId: 'p9',
    coordenadorNome: 'Luciana Rocha',
    totalVoluntarios: 2,
    totalServicos: 1,
    ativo: true,
    igrejaId: 'i1',
    tipo: MinisterioTipo.geral,
    descricao: 'Acolhimento de visitantes e integração.',
    baseMinisterialId: 'b4',
    baseMinisterialNome: 'Conectados',
    servicos: const [
      Servico(id: 's7c', ministerioId: 'm7', nome: 'Coordenador', ficcao: true, ativo: true),
      Servico(id: 's7a', ministerioId: 'm7', nome: 'Recepção de visitantes', ficcao: false, ativo: true),
    ],
  ),
];

final mockUsuarios = <UsuarioConta>[
  const UsuarioConta(
    id: 'u1',
    username: 'admin',
    email: 'ana.costa@base.church',
    pessoaId: 'p1',
    pessoaNome: 'Ana Costa',
    igrejaId: 'i1',
    igrejaNome: 'Base Church',
    papeis: [Role.admin, Role.pastor],
    ativo: true,
  ),
  const UsuarioConta(
    id: 'u2',
    username: 'filial',
    email: 'luciana.rocha@base.church',
    pessoaId: 'p9',
    pessoaNome: 'Luciana Rocha',
    igrejaId: 'i2',
    igrejaNome: 'Base Church — Zona Sul',
    papeis: [Role.admin],
    ativo: true,
  ),
  const UsuarioConta(
    id: 'u3',
    username: 'joao',
    email: 'joao.silva@email.com',
    pessoaId: 'p2',
    pessoaNome: 'João da Silva',
    igrejaId: 'i1',
    igrejaNome: 'Base Church',
    papeis: [Role.lider, Role.voluntario, Role.membro],
    ativo: true,
  ),
  const UsuarioConta(
    id: 'u4',
    username: 'midia',
    email: 'carlos.lima@email.com',
    pessoaId: 'p7',
    pessoaNome: 'Carlos Lima',
    igrejaId: 'i1',
    igrejaNome: 'Base Church',
    papeis: [Role.lider, Role.voluntario, Role.membro],
    ativo: true,
  ),
  const UsuarioConta(
    id: 'u5',
    username: 'maria',
    email: 'maria.oliveira@email.com',
    pessoaId: 'p3',
    pessoaNome: 'Maria Oliveira',
    igrejaId: 'i1',
    igrejaNome: 'Base Church',
    papeis: [Role.voluntario, Role.membro],
    ativo: true,
  ),
  const UsuarioConta(
    id: 'u6',
    username: 'membro',
    email: 'fernanda.dias@email.com',
    pessoaId: 'p5',
    pessoaNome: 'Fernanda Dias',
    igrejaId: 'i1',
    igrejaNome: 'Base Church',
    papeis: [Role.voluntario, Role.membro],
    ativo: true,
  ),
  const UsuarioConta(
    id: 'u7',
    username: 'pedro',
    email: 'pedro.alves@base.church',
    pessoaId: 'p8',
    pessoaNome: 'Pedro Alves',
    igrejaId: 'i2',
    igrejaNome: 'Base Church — Zona Sul',
    papeis: [Role.pastor],
    ativo: true,
  ),
];

final mockEventos = <CultoEvento>[
  const CultoEvento(
    id: 'c1',
    titulo: 'Culto de domingo',
    tipo: TipoEvento.culto,
    data: '2026-08-02',
    horaInicio: '18:00',
    horaFim: '20:00',
    localEvento: 'Templo principal',
    igrejaId: 'i1',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    ativo: true,
  ),
  const CultoEvento(
    id: 'c2',
    titulo: 'Culto de domingo',
    tipo: TipoEvento.culto,
    data: '2026-08-09',
    horaInicio: '18:00',
    horaFim: '20:00',
    localEvento: 'Templo principal',
    igrejaId: 'i1',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    ativo: true,
  ),
  const CultoEvento(
    id: 'c3',
    titulo: 'Culto de domingo',
    tipo: TipoEvento.culto,
    data: '2026-08-16',
    horaInicio: '18:00',
    horaFim: '20:00',
    localEvento: 'Templo principal',
    igrejaId: 'i1',
    supervisorPessoaId: 'p7',
    supervisorNome: 'Carlos Lima',
    ativo: true,
  ),
  const CultoEvento(
    id: 'c4',
    titulo: 'Culto de domingo',
    tipo: TipoEvento.culto,
    data: '2026-08-23',
    horaInicio: '18:00',
    horaFim: '20:00',
    localEvento: 'Templo principal',
    igrejaId: 'i1',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    ativo: true,
  ),
  const CultoEvento(
    id: 'c5',
    titulo: 'Encontro de jovens',
    tipo: TipoEvento.evento,
    data: '2026-08-15',
    horaInicio: '19:00',
    horaFim: '21:30',
    localEvento: 'Salão',
    igrejaId: 'i1',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    ativo: true,
  ),
  const CultoEvento(
    id: 'c6',
    titulo: 'Culto de domingo',
    tipo: TipoEvento.culto,
    data: '2026-08-02',
    horaInicio: '18:00',
    localEvento: 'Zona Sul',
    igrejaId: 'i2',
    supervisorPessoaId: 'p8',
    supervisorNome: 'Pedro Alves',
    ativo: true,
  ),
];

final mockConteudosCulto = <ConteudoCulto>[
  const ConteudoCulto(
    eventoId: 'c2',
    textoPregacao: 'João 15 — Permanecei em mim.\n\n1. A videira verdadeira\n2. O fruto que permanece\n3. Amar uns aos outros',
    louvor: '1. Bondade de Deus\n2. Teu Santo Nome\n3. Oceanos',
    pregadorPessoaId: 'p1',
    pregadorNome: 'Ana Costa',
  ),
  const ConteudoCulto(
    eventoId: 'c3',
    textoPregacao: 'Salmo 23 — O Senhor é o meu pastor.',
    louvor: '1. Ao único\n2. Porque Ele vive',
    pregadorPessoaId: 'p1',
    pregadorNome: 'Ana Costa',
  ),
];

final mockCategoriasCulto = <CategoriaCulto>[
  const CategoriaCulto(
    id: 'cat1',
    igrejaId: 'i1',
    titulo: 'Domingo inesquecível',
    descricao: 'Culto oficial de domingo.',
    diaSemana: DiaSemana.domingo,
    horaInicio: '20:00:00',
    duracaoMinutos: 90,
    pregadorPadraoId: 'p1',
    pregadorPadraoNome: 'Ana Costa',
    ativo: true,
  ),
  const CategoriaCulto(
    id: 'cat2',
    igrejaId: 'i1',
    titulo: 'Sábado jovem',
    descricao: 'Culto voltado aos jovens.',
    diaSemana: DiaSemana.sabado,
    horaInicio: '19:30:00',
    duracaoMinutos: 120,
    pregadorPadraoId: 'p2',
    pregadorPadraoNome: 'João da Silva',
    ativo: true,
  ),
  const CategoriaCulto(
    id: 'cat3',
    igrejaId: 'i2',
    titulo: 'Domingo Zona Sul',
    descricao: null,
    diaSemana: DiaSemana.domingo,
    horaInicio: '18:00:00',
    duracaoMinutos: 90,
    pregadorPadraoId: 'p8',
    pregadorPadraoNome: 'Pedro Alves',
    ativo: true,
  ),
];

final mockCultos = <Culto>[
  Culto(
    id: 'culto-1',
    igrejaId: 'i1',
    categoriaCultoId: 'cat1',
    categoriaCultoTitulo: 'Domingo inesquecível',
    titulo: 'Culto de domingo',
    tema: 'Destravados: Conforto',
    data: '2026-09-06',
    horaInicio: '20:00:00',
    horaFim: '21:30:00',
    pregadorId: 'p1',
    pregadorNome: 'Ana Costa',
    status: CultoStatus.realizado,
    competencia: '2026-09',
    ativo: true,
    janelaConfiguracaoAberta: true,
    temRelatorio: true,
  ),
  Culto(
    id: 'culto-2',
    igrejaId: 'i1',
    categoriaCultoId: 'cat1',
    categoriaCultoTitulo: 'Domingo inesquecível',
    titulo: 'Culto de domingo',
    tema: 'Vinde a mim',
    data: '2026-09-13',
    horaInicio: '20:00:00',
    horaFim: '21:30:00',
    pregadorId: 'p1',
    pregadorNome: 'Ana Costa',
    status: CultoStatus.aberto,
    competencia: '2026-09',
    ativo: true,
    janelaConfiguracaoAberta: true,
    temRelatorio: false,
  ),
  Culto(
    id: 'culto-3',
    igrejaId: 'i1',
    categoriaCultoId: 'cat1',
    categoriaCultoTitulo: 'Domingo inesquecível',
    titulo: 'Culto de domingo',
    tema: null,
    data: '2026-09-20',
    horaInicio: '20:00:00',
    horaFim: '21:30:00',
    pregadorId: 'p1',
    pregadorNome: 'Ana Costa',
    status: CultoStatus.agendado,
    competencia: '2026-09',
    ativo: true,
    janelaConfiguracaoAberta: true,
    temRelatorio: false,
  ),
  Culto(
    id: 'culto-4',
    igrejaId: 'i1',
    categoriaCultoId: 'cat1',
    categoriaCultoTitulo: 'Domingo inesquecível',
    titulo: 'Culto de domingo',
    tema: null,
    data: '2026-09-27',
    horaInicio: '20:00:00',
    horaFim: '21:30:00',
    pregadorId: 'p8',
    pregadorNome: 'Pedro Alves',
    status: CultoStatus.agendado,
    competencia: '2026-09',
    ativo: true,
    janelaConfiguracaoAberta: false,
    temRelatorio: false,
  ),
  Culto(
    id: 'culto-5',
    igrejaId: 'i1',
    categoriaCultoId: 'cat2',
    categoriaCultoTitulo: 'Sábado jovem',
    titulo: 'Culto jovem',
    tema: 'Identidade',
    data: '2026-09-05',
    horaInicio: '19:30:00',
    horaFim: '21:30:00',
    pregadorId: 'p2',
    pregadorNome: 'João da Silva',
    status: CultoStatus.realizado,
    competencia: '2026-09',
    ativo: true,
    janelaConfiguracaoAberta: true,
    temRelatorio: true,
  ),
  Culto(
    id: 'culto-6',
    igrejaId: 'i1',
    categoriaCultoId: 'cat2',
    categoriaCultoTitulo: 'Sábado jovem',
    titulo: 'Culto jovem',
    tema: null,
    data: '2026-09-12',
    horaInicio: '19:30:00',
    horaFim: '21:30:00',
    pregadorId: 'p2',
    pregadorNome: 'João da Silva',
    status: CultoStatus.aberto,
    competencia: '2026-09',
    ativo: true,
    janelaConfiguracaoAberta: true,
    temRelatorio: false,
  ),
  Culto(
    id: 'culto-7',
    igrejaId: 'i1',
    categoriaCultoId: 'cat2',
    categoriaCultoTitulo: 'Sábado jovem',
    titulo: 'Culto jovem',
    tema: null,
    data: '2026-09-19',
    horaInicio: '19:30:00',
    horaFim: '21:30:00',
    pregadorId: 'p2',
    pregadorNome: 'João da Silva',
    status: CultoStatus.agendado,
    competencia: '2026-09',
    ativo: true,
    janelaConfiguracaoAberta: true,
    temRelatorio: false,
  ),
  Culto(
    id: 'culto-8',
    igrejaId: 'i1',
    categoriaCultoId: 'cat2',
    categoriaCultoTitulo: 'Sábado jovem',
    titulo: 'Culto jovem',
    tema: null,
    data: '2026-09-26',
    horaInicio: '19:30:00',
    horaFim: '21:30:00',
    pregadorId: 'p3',
    pregadorNome: 'Maria Oliveira',
    status: CultoStatus.agendado,
    competencia: '2026-09',
    ativo: true,
    janelaConfiguracaoAberta: false,
    temRelatorio: false,
  ),
  Culto(
    id: 'culto-9',
    igrejaId: 'i2',
    categoriaCultoId: 'cat3',
    categoriaCultoTitulo: 'Domingo Zona Sul',
    titulo: 'Culto de domingo',
    tema: 'Renascer',
    data: '2026-09-06',
    horaInicio: '18:00:00',
    horaFim: '19:30:00',
    pregadorId: 'p8',
    pregadorNome: 'Pedro Alves',
    status: CultoStatus.realizado,
    competencia: '2026-09',
    ativo: true,
    janelaConfiguracaoAberta: true,
    temRelatorio: true,
  ),
  Culto(
    id: 'culto-10',
    igrejaId: 'i2',
    categoriaCultoId: 'cat3',
    categoriaCultoTitulo: 'Domingo Zona Sul',
    titulo: 'Culto de domingo',
    tema: null,
    data: '2026-09-13',
    horaInicio: '18:00:00',
    horaFim: '19:30:00',
    pregadorId: 'p8',
    pregadorNome: 'Pedro Alves',
    status: CultoStatus.aberto,
    competencia: '2026-09',
    ativo: true,
    janelaConfiguracaoAberta: true,
    temRelatorio: false,
  ),
];

final mockCultosConteudos = <CultoConteudo>[
  const CultoConteudo(
    cultoId: 'culto-1',
    textoPregacao: 'Isaías 61 — Conforto aos destravados.',
    louvor: '1. Bondade de Deus\n2. Teu Santo Nome\n3. Ao único',
    tema: 'Destravados: Conforto',
    pregadorId: 'p1',
    pregadorNome: 'Ana Costa',
  ),
  const CultoConteudo(
    cultoId: 'culto-2',
    textoPregacao: 'Mateus 11:28 — Vinde a mim.',
    louvor: '1. Vem, esta é a hora\n2. Gratidão',
    tema: 'Vinde a mim',
    pregadorId: 'p1',
    pregadorNome: 'Ana Costa',
  ),
  const CultoConteudo(
    cultoId: 'culto-5',
    textoPregacao: 'Gênesis 1 — Somos imagem de Deus.',
    louvor: '1. Me Ama\n2. A alegria do Senhor',
    tema: 'Identidade',
    pregadorId: 'p2',
    pregadorNome: 'João da Silva',
  ),
];

final mockCultosRelatorios = <CultoRelatorio>[
  const CultoRelatorio(
    cultoId: 'culto-1',
    adultos: 19,
    criancas: 2,
    conversoes: 2,
    reconciliacoes: 1,
    aliancas: 3,
    carros: 7,
    motos: 4,
    bicicletas: 0,
    observacoes: 'Culto de celebração com batismos.',
  ),
  const CultoRelatorio(
    cultoId: 'culto-5',
    adultos: 25,
    criancas: 5,
    conversoes: 1,
    reconciliacoes: 0,
    aliancas: 0,
    carros: 5,
    motos: 2,
    bicicletas: 1,
    observacoes: 'Culto jovem.',
  ),
  const CultoRelatorio(
    cultoId: 'culto-9',
    adultos: 12,
    criancas: 1,
    conversoes: 0,
    reconciliacoes: 0,
    aliancas: 1,
    carros: 4,
    motos: 1,
    bicicletas: 0,
    observacoes: null,
  ),
];

final mockEscalas = <Escala>[
  Escala(
    id: 'e-sup',
    titulo: 'Supervisores — agosto',
    competencia: '2026-08',
    tipo: EscalaTipo.supervisor,
    igrejaId: 'i1',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    pregadorPessoaId: 'p1',
    pregadorNome: 'Ana Costa',
    status: EscalaStatus.emAndamento,
    dataLancamento: '2026-08-01T10:00:00',
    ativo: true,
    voluntarios: const [
      EscalaVoluntario(id: 'vs1', pessoaId: 'p1', pessoaNome: 'Ana Costa', servicoNome: 'Supervisão', data: '2026-08-02', status: EscalaItemStatus.confirmado),
      EscalaVoluntario(id: 'vs2', pessoaId: 'p7', pessoaNome: 'Carlos Lima', servicoNome: 'Supervisão', data: '2026-08-16', status: EscalaItemStatus.pendente),
    ],
  ),
  Escala(
    id: 'e-preg',
    titulo: 'Pregadores — agosto',
    competencia: '2026-08',
    tipo: EscalaTipo.pregador,
    igrejaId: 'i1',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    pregadorPessoaId: 'p1',
    pregadorNome: 'Ana Costa',
    status: EscalaStatus.emAndamento,
    dataLancamento: '2026-08-01T10:05:00',
    ativo: true,
    voluntarios: const [
      EscalaVoluntario(id: 'vp1', pessoaId: 'p1', pessoaNome: 'Ana Costa', servicoNome: 'Pregação', data: '2026-08-02', status: EscalaItemStatus.confirmado),
      EscalaVoluntario(id: 'vp2', pessoaId: 'p1', pessoaNome: 'Ana Costa', servicoNome: 'Pregação', data: '2026-08-09', status: EscalaItemStatus.confirmado),
      EscalaVoluntario(id: 'vp3', pessoaId: 'p8', pessoaNome: 'Pedro Alves', servicoNome: 'Pregação', data: '2026-08-23', status: EscalaItemStatus.pendente),
    ],
  ),
  Escala(
    id: 'e-culto',
    titulo: 'Escala de culto — agosto',
    competencia: '2026-08',
    tipo: EscalaTipo.culto,
    igrejaId: 'i1',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    pregadorPessoaId: 'p1',
    pregadorNome: 'Ana Costa',
    status: EscalaStatus.finalizada,
    dataLancamento: '2026-08-01T10:10:00',
    dataFinalizacao: '2026-08-05T18:00:00',
    dataEvento: '2026-08-09',
    horaInicio: '18:00:00',
    horaFim: '20:00:00',
    ativo: true,
    servicos: const [
      EscalaServico(id: 'sv1', servicoId: 's1b', servicoNome: 'Violão', quantidadeNecessaria: 1),
      EscalaServico(id: 'sv2', servicoId: 's2a', servicoNome: 'Projeção', quantidadeNecessaria: 1),
      EscalaServico(id: 'sv3', servicoId: 's2b', servicoNome: 'Som', quantidadeNecessaria: 1),
    ],
    voluntarios: const [
      EscalaVoluntario(id: 'vc1', pessoaId: 'p2', pessoaNome: 'João da Silva', servicoId: 's1b', servicoNome: 'Violão', data: '2026-08-09', status: EscalaItemStatus.confirmado),
      EscalaVoluntario(id: 'vc2', pessoaId: 'p7', pessoaNome: 'Carlos Lima', servicoId: 's2a', servicoNome: 'Projeção', data: '2026-08-09', status: EscalaItemStatus.confirmado),
      EscalaVoluntario(id: 'vc3', pessoaId: 'p3', pessoaNome: 'Maria Oliveira', servicoId: 's2b', servicoNome: 'Som', data: '2026-08-09', status: EscalaItemStatus.confirmado),
    ],
  ),
  Escala(
    id: 'e-louvor',
    titulo: 'Louvor — agosto',
    competencia: '2026-08',
    tipo: EscalaTipo.ministerio,
    igrejaId: 'i1',
    ministerioId: 'm1',
    ministerioNome: 'Louvor',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    status: EscalaStatus.editando,
    dataEvento: '2026-08-09',
    horaInicio: '18:00:00',
    horaFim: '20:00:00',
    ativo: true,
    servicos: const [
      EscalaServico(id: 'sl1', servicoId: 's1a', servicoNome: 'Vocal', quantidadeNecessaria: 2),
      EscalaServico(id: 'sl2', servicoId: 's1b', servicoNome: 'Violão', quantidadeNecessaria: 1),
    ],
    voluntarios: const [
      EscalaVoluntario(id: 'vl1', pessoaId: 'p3', pessoaNome: 'Maria Oliveira', servicoId: 's1a', servicoNome: 'Vocal', data: '2026-08-09', status: EscalaItemStatus.pendente),
      EscalaVoluntario(id: 'vl2', pessoaId: 'p2', pessoaNome: 'João da Silva', servicoId: 's1b', servicoNome: 'Violão', data: '2026-08-09', status: EscalaItemStatus.confirmado, confirmadoPeloVoluntario: true),
    ],
  ),
  Escala(
    id: 'e-culto-set-lancado',
    titulo: 'Escala de culto — setembro (lançada)',
    competencia: '2026-09',
    tipo: EscalaTipo.culto,
    igrejaId: 'i1',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    status: EscalaStatus.emAndamento,
    dataLancamento: '2026-09-01T10:10:00',
    dataEvento: '2026-09-13',
    horaInicio: '18:00:00',
    horaFim: '20:00:00',
    ativo: true,
    servicos: const [
      EscalaServico(id: 'sla1', servicoId: 's1b', servicoNome: 'Violão', quantidadeNecessaria: 1),
      EscalaServico(id: 'sla2', servicoId: 's2b', servicoNome: 'Som', quantidadeNecessaria: 1),
    ],
    voluntarios: const [
      EscalaVoluntario(id: 'sla-v1', pessoaId: 'p3', pessoaNome: 'Maria Oliveira', servicoId: 's1b', servicoNome: 'Violão', data: '2026-09-13', status: EscalaItemStatus.pendente),
      EscalaVoluntario(id: 'sla-v2', pessoaId: 'p7', pessoaNome: 'Carlos Lima', servicoId: 's2b', servicoNome: 'Som', data: '2026-09-13', status: EscalaItemStatus.pendente),
    ],
  ),
  Escala(
    id: 'e-culto-set',
    titulo: 'Escala de culto — setembro',
    competencia: '2026-09',
    tipo: EscalaTipo.culto,
    igrejaId: 'i1',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    status: EscalaStatus.sugerida,
    dataEvento: '2026-09-06',
    horaInicio: '18:00:00',
    horaFim: '20:00:00',
    ativo: true,
    servicos: const [
      EscalaServico(id: 'ss1', servicoId: 's1a', servicoNome: 'Vocal', quantidadeNecessaria: 2),
      EscalaServico(id: 'ss2', servicoId: 's1b', servicoNome: 'Violão', quantidadeNecessaria: 1),
      EscalaServico(id: 'ss3', servicoId: 's2a', servicoNome: 'Projeção', quantidadeNecessaria: 1),
      EscalaServico(id: 'ss4', servicoId: 's2b', servicoNome: 'Som', quantidadeNecessaria: 1),
    ],
    voluntarios: const [
      EscalaVoluntario(id: 'se1', pessoaId: 'p2', pessoaNome: 'João da Silva', servicoId: 's1a', servicoNome: 'Vocal', data: '2026-09-06', status: EscalaItemStatus.pendente),
      EscalaVoluntario(id: 'se2', pessoaId: 'p7', pessoaNome: 'Carlos Lima', servicoId: 's2a', servicoNome: 'Projeção', data: '2026-09-06', status: EscalaItemStatus.pendente),
    ],
  ),
  Escala(
    id: 'e-louvor-set',
    titulo: 'Louvor — setembro',
    competencia: '2026-09',
    tipo: EscalaTipo.ministerio,
    igrejaId: 'i1',
    ministerioId: 'm1',
    ministerioNome: 'Louvor',
    supervisorPessoaId: 'p1',
    supervisorNome: 'Ana Costa',
    status: EscalaStatus.sugerida,
    dataEvento: '2026-09-06',
    horaInicio: '18:00:00',
    horaFim: '20:00:00',
    ativo: true,
    servicos: const [
      EscalaServico(id: 'sl1s', servicoId: 's1a', servicoNome: 'Vocal', quantidadeNecessaria: 2),
      EscalaServico(id: 'sl2s', servicoId: 's1b', servicoNome: 'Violão', quantidadeNecessaria: 1),
    ],
    voluntarios: const [
      EscalaVoluntario(id: 'sl1s-v', pessoaId: 'p3', pessoaNome: 'Maria Oliveira', servicoId: 's1a', servicoNome: 'Vocal', data: '2026-09-06', status: EscalaItemStatus.pendente),
    ],
  ),
  Escala(
    id: 'e-zs',
    titulo: 'Escala de culto — agosto',
    competencia: '2026-08',
    tipo: EscalaTipo.culto,
    igrejaId: 'i2',
    supervisorPessoaId: 'p8',
    supervisorNome: 'Pedro Alves',
    pregadorPessoaId: 'p8',
    pregadorNome: 'Pedro Alves',
    status: EscalaStatus.editando,
    dataEvento: '2026-08-02',
    horaInicio: '18:00:00',
    horaFim: '20:00:00',
    ativo: true,
    servicos: const [
      EscalaServico(id: 'sz1', servicoId: 's5a', servicoNome: 'Vocal', quantidadeNecessaria: 2),
    ],
    voluntarios: const [
      EscalaVoluntario(id: 'vz1', pessoaId: 'p10', pessoaNome: 'Rafael Souza', servicoId: 's5a', servicoNome: 'Vocal', data: '2026-08-02', status: EscalaItemStatus.pendente),
    ],
  ),
];

final mockSmallGroups = <SmallGroup>[
  SmallGroup(
    id: 'cl1',
    nome: 'Pequeno grupo Vila Madalena',
    igrejaId: 'i1',
    diaSemana: DiaSemana.quarta,
    horario: '19:30',
    liderPessoaId: 'p2',
    liderNome: 'João da Silva',
    ativo: true,
    nota: 4,
    encontros: const [
      SmallGroupEncontro(
        id: 'ce1',
        smallGroupId: 'cl1',
        data: '2026-08-05',
        anfitriaoPessoaId: 'p2',
        anfitriaoNome: 'João da Silva',
        compareceram: [
          SmallGroupParticipante(pessoaId: 'p2', pessoaNome: 'João da Silva'),
          SmallGroupParticipante(pessoaId: 'p3', pessoaNome: 'Maria Oliveira'),
          SmallGroupParticipante(pessoaId: 'p4', pessoaNome: 'Bruno Santos'),
        ],
        anotacoes: 'Boa reunião, estudo de João 15.',
      ),
      SmallGroupEncontro(
        id: 'ce2',
        smallGroupId: 'cl1',
        data: '2026-08-12',
        anfitriaoPessoaId: 'p3',
        anfitriaoNome: 'Maria Oliveira',
        compareceram: [
          SmallGroupParticipante(pessoaId: 'p2', pessoaNome: 'João da Silva'),
          SmallGroupParticipante(pessoaId: 'p3', pessoaNome: 'Maria Oliveira'),
        ],
        anotacoes: 'Grupo menor, convidar novos.',
      ),
    ],
  ),
  SmallGroup(
    id: 'cl2',
    nome: 'Pequeno grupo Pinheiros',
    igrejaId: 'i1',
    diaSemana: DiaSemana.quinta,
    horario: '20:00',
    liderPessoaId: 'p7',
    liderNome: 'Carlos Lima',
    ativo: true,
    nota: 5,
    encontros: const [
      SmallGroupEncontro(
        id: 'ce3',
        smallGroupId: 'cl2',
        data: '2026-08-06',
        anfitriaoPessoaId: 'p7',
        anfitriaoNome: 'Carlos Lima',
        compareceram: [
          SmallGroupParticipante(pessoaId: 'p7', pessoaNome: 'Carlos Lima'),
          SmallGroupParticipante(pessoaId: 'p4', pessoaNome: 'Bruno Santos'),
          SmallGroupParticipante(pessoaId: 'p5', pessoaNome: 'Fernanda Dias'),
        ],
      ),
    ],
  ),
  SmallGroup(
    id: 'cl3',
    nome: 'Pequeno grupo Zona Sul',
    igrejaId: 'i2',
    diaSemana: DiaSemana.terca,
    horario: '19:00',
    liderPessoaId: 'p10',
    liderNome: 'Rafael Souza',
    ativo: true,
    nota: 0,
  ),
];

final mockDisponibilidades = <String, DisponibilidadePessoa>{
  'p2': DisponibilidadePessoa(
    pessoaId: 'p2',
    semanal: [
      const IndisponibilidadeSemanal(dia: DiaSemana.segunda, manha: true, tarde: true, noite: true),
      const IndisponibilidadeSemanal(dia: DiaSemana.terca, noite: true),
    ],
    datas: [
      const IndisponibilidadeData(id: 'd1', pessoaId: 'p2', data: '2026-08-01', motivo: 'Viagem'),
      const IndisponibilidadeData(id: 'd2', pessoaId: 'p2', data: '2026-11-02', motivo: 'Compromisso familiar'),
    ],
  ),
  'p3': DisponibilidadePessoa(
    pessoaId: 'p3',
    semanal: [
      const IndisponibilidadeSemanal(dia: DiaSemana.quarta, tarde: true),
    ],
    datas: [
      const IndisponibilidadeData(id: 'd3', pessoaId: 'p3', data: '2026-08-15'),
    ],
  ),
};

final mockMensagensAniversario = <String, MensagemAniversario>{
  'i1': const MensagemAniversario(
    id: 'ma1',
    igrejaId: 'i1',
    mensagem: 'Feliz aniversário, [Nome]! 🎉\n'
        'Desejamos um dia muito especial e que Deus continue abençoando sua vida, '
        'sua família e sua caminhada. 🙏🎂',
  ),
  'i2': const MensagemAniversario(
    id: 'ma2',
    igrejaId: 'i2',
    mensagem: 'Feliz aniversário, [Nome]! Que o Senhor abençoe abundantly o seu '
        'novo ano de vida. 🎉',
  ),
};

const mockDashboard = DashboardStats(
  totalPessoas: 248,
  totalMembros: 183,
  totalVoluntarios: 74,
  totalLideres: 31,
  escalasPendentes: 12,
  visitantesRecentes: 8,
  proximasEscalas: [
    EscalaResumo(
      id: 'e-louvor',
      data: '2026-08-09',
      horario: '18:00',
      ministerio: 'Louvor',
      totalVoluntarios: 2,
      confirmados: 1,
      pendentes: 1,
    ),
  ],
  jornada: JornadaIndicadores(
    novosVisitantes: 14,
    aceitaramJesus: 6,
    batizados: 4,
    trilhaBase: 9,
    novosMembros: 5,
  ),
);

int _weekdayNumber(DiaSemana dia) {
  switch (dia) {
    case DiaSemana.domingo:
      return 7;
    case DiaSemana.segunda:
      return 1;
    case DiaSemana.terca:
      return 2;
    case DiaSemana.quarta:
      return 3;
    case DiaSemana.quinta:
      return 4;
    case DiaSemana.sexta:
      return 5;
    case DiaSemana.sabado:
      return 6;
  }
}

String _somaDuracao(String hora, int duracao) {
  final parts = hora.split(':');
  if (parts.length < 2) return hora;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  final total = h * 60 + m + duracao;
  final hh = ((total ~/ 60) % 24).toString().padLeft(2, '0');
  final mm = (total % 60).toString().padLeft(2, '0');
  return '$hh:$mm:00';
}

bool janelaConfiguracaoAbertaMock(String dataIso) {
  final hoje = DateTime.now();
  final data = DateTime.tryParse(dataIso);
  if (data == null) return false;
  final hojeInicio = DateTime(hoje.year, hoje.month, hoje.day);
  return !data.isAfter(hojeInicio.add(const Duration(days: 8)));
}

String competenciaProximoMes() {
  final hoje = DateTime.now();
  return '${hoje.year}-${(hoje.month + 1).toString().padLeft(2, '0')}';
}

List<String> datasDaCompetencia(DiaSemana dia, String competencia) {
  final parts = competencia.split('-');
  if (parts.length != 2) return [];
  final year = int.tryParse(parts[0]) ?? DateTime.now().year;
  final month = int.tryParse(parts[1]) ?? DateTime.now().month;
  final target = _weekdayNumber(dia);
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final dates = <String>[];
  for (var day = 1; day <= daysInMonth; day++) {
    final date = DateTime(year, month, day);
    if (date.weekday == target) dates.add(isoDate(date));
  }
  return dates;
}

List<Culto> gerarCultosCategoriaMock(CategoriaCulto categoria, String competencia) {
  final dates = datasDaCompetencia(categoria.diaSemana, competencia);
  final created = <Culto>[];
  for (final dataIso in dates) {
    final exists = mockCultos.any(
      (c) => c.categoriaCultoId == categoria.id && c.data == dataIso,
    );
    if (exists) continue;
    final culto = Culto(
      id: 'culto-ger-${DateTime.now().millisecondsSinceEpoch}-$dataIso',
      igrejaId: categoria.igrejaId,
      categoriaCultoId: categoria.id,
      categoriaCultoTitulo: categoria.titulo,
      titulo: categoria.titulo,
      data: dataIso,
      horaInicio: categoria.horaInicio,
      horaFim: _somaDuracao(categoria.horaInicio, categoria.duracaoMinutos),
      pregadorId: categoria.pregadorPadraoId,
      pregadorNome: categoria.pregadorPadraoNome,
      status: CultoStatus.agendado,
      competencia: competencia,
      ativo: true,
      janelaConfiguracaoAberta: janelaConfiguracaoAbertaMock(dataIso),
      temRelatorio: false,
    );
    mockCultos.add(culto);
    created.add(culto);
  }
  return created;
}

CategoriaCulto? categoriaCultoById(String id) {
  for (final c in mockCategoriasCulto) {
    if (c.id == id) return c;
  }
  return null;
}

Future<T> mockDelay<T>(T value, [int ms = 280]) =>
    Future.delayed(Duration(milliseconds: ms), () => value);

PageResponse<T> paginate<T>(List<T> items, {int page = 0, int size = 20}) {
  final start = page * size;
  final content = items.skip(start).take(size).toList();
  return PageResponse(
    content: content,
    totalElements: items.length,
    totalPages: (items.length / size).ceil().clamp(1, 999),
    page: page,
    size: size,
  );
}

Igreja? igrejaById(String id) {
  for (final i in mockIgrejas) {
    if (i.id == id) return i;
  }
  return null;
}

Pessoa? pessoaById(String id) {
  for (final p in mockPessoas) {
    if (p.id == id) return p;
  }
  return null;
}

List<Pessoa> pessoasDaIgreja(String? igrejaId) {
  if (igrejaId == null || igrejaId.isEmpty) return [];
  return mockPessoas.where((p) => p.igrejaId == igrejaId).toList();
}

List<Ministerio> ministeriosDaIgreja(String? igrejaId) {
  if (igrejaId == null || igrejaId.isEmpty) return [];
  return mockMinisterios.where((m) => m.igrejaId == igrejaId).toList();
}

List<BaseMinisterial> basesMinisteriaisDaIgreja(String? igrejaId) {
  return List.of(mockBasesMinisteriais);
}

List<EscalaCandidato> mockCandidatos(
  String? igrejaId, {
  String? servicoNome,
  String? data,
}) {
  final ministerios = ministeriosDaIgreja(igrejaId);
  final pessoas = mockPessoas.where(
    (p) =>
        p.igrejaId == igrejaId &&
        p.status == PessoaStatus.ativo &&
        p.tipos.contains(PessoaTipo.voluntario),
  );
  final result = <EscalaCandidato>[];
  for (final p in pessoas) {
    final servicosQueServe = <String>[];
    for (final m in ministerios) {
      if (!p.ministerios.contains(m.nome)) continue;
      for (final s in m.servicos) {
        if (!s.ficcao) servicosQueServe.add(s.nome);
      }
    }
    if (servicosQueServe.isEmpty) continue;
    if (servicoNome != null && !servicosQueServe.contains(servicoNome)) continue;
    result.add(
      EscalaCandidato(
        pessoaId: p.id,
        pessoaNome: p.nome,
        servicoNome: servicosQueServe.first,
        servicosQueServe: servicosQueServe,
        diasDisponiveis: const [
          DiaDisponivel(diaSemana: DiaSemana.domingo, horaInicio: '18:00:00', horaFim: '21:00:00', disponivel: true),
        ],
        analiseDia: data == null ? null : _analiseDiaCandidato(p, igrejaId, data),
      ),
    );
  }
  return result;
}

AnaliseDiaCandidato _analiseDiaCandidato(Pessoa p, String? igrejaId, String data) {
  final motivos = <String>[];
  final conflitos = <ConflitoEscala>[];
  for (final e in mockEscalas) {
    if (e.igrejaId != igrejaId) continue;
    for (final v in e.voluntarios) {
      if (v.pessoaId == p.id && v.data == data) {
        conflitos.add(
          ConflitoEscala(
            escalaId: e.id,
            escalaTitulo: e.titulo,
            ministerioNome: e.ministerioNome,
            servicoNome: v.servicoNome,
            data: v.data,
            horario: '18:00:00',
          ),
        );
      }
    }
  }
  if (conflitos.isNotEmpty) {
    motivos.add('Conflito com outra escala no mesmo dia/horário');
  }
  final disp = mockDisponibilidades[p.id];
  if (disp != null) {
    for (final d in disp.datas) {
      if (d.data == data) {
        motivos.add(d.motivo ?? 'Indisponibilidade pontual');
      }
    }
    final weekday = DateTime.tryParse(data)?.weekday;
    if (weekday != null) {
      final dia = switch (weekday) {
        1 => DiaSemana.segunda,
        2 => DiaSemana.terca,
        3 => DiaSemana.quarta,
        4 => DiaSemana.quinta,
        5 => DiaSemana.sexta,
        6 => DiaSemana.sabado,
        _ => DiaSemana.domingo,
      };
      for (final semanal in disp.semanal) {
        if (semanal.dia == dia && semanal.marcado) {
          motivos.add('Indisponibilidade semanal');
        }
      }
    }
  }
  return AnaliseDiaCandidato(
    data: data,
    disponivel: motivos.isEmpty,
    motivosIndisponibilidade: motivos,
    conflitos: conflitos,
  );
}

List<VisaoMensalEscala> mockVisaoMensal({
  String? igrejaId,
  String? competencia,
  String? ministerioId,
  String? pessoaId,
  bool administrador = false,
}) {
  if (igrejaId == null || igrejaId.isEmpty) return [];
  final mes = competencia == null || competencia.isEmpty
      ? competenciaFrom(DateTime.now())
      : competencia;

  final visiveis = ministeriosDaIgreja(igrejaId).where((m) {
    if (administrador) return true;
    return m.liderPessoaId == pessoaId || m.coordenadorPessoaId == pessoaId;
  }).toList();
  if (ministerioId != null && ministerioId.isNotEmpty) {
    final alvo = visiveis.where((m) => m.id == ministerioId).toList();
    if (alvo.isEmpty) return [];
    visiveis
      ..clear()
      ..addAll(alvo);
  }
  if (visiveis.isEmpty) return [];

  final cultos = mockCultos
      .where((c) => c.igrejaId == igrejaId && c.ativo && _mesDaData(c.data) == mes)
      .toList();
  final eventos = mockEventos
      .where(
        (e) => e.igrejaId == igrejaId && e.ativo && _mesDaData(e.data) == mes,
      )
      .toList();

  final resultado = <VisaoMensalEscala>[];
  for (final m in visiveis) {
    Escala? mensal;
    for (final e in mockEscalas) {
      if (e.igrejaId == igrejaId &&
          e.competencia == mes &&
          e.ativo &&
          e.tipo == EscalaTipo.ministerio &&
          e.ministerioId == m.id &&
          e.eventoId == null) {
        mensal = e;
        break;
      }
    }
    final designacoes = mensal?.voluntarios ?? const <EscalaVoluntario>[];

    final itens = <ItemVisaoMensal>[
      for (final culto in cultos)
        ItemVisaoMensal(
          origem: 'CULTO',
          id: culto.id,
          titulo: culto.titulo,
          data: culto.data,
          horaInicio: culto.horaInicio,
          horaFim: culto.horaFim,
          localEvento: null,
          servicos: _montarServicosVisao(
            mensal,
            designacoes.where((v) => v.data == culto.data).toList(),
          ),
        ),
      for (final evento in eventos)
        ItemVisaoMensal(
          origem: 'EVENTO',
          id: evento.id,
          titulo: evento.titulo,
          data: evento.data,
          horaInicio: evento.horaInicio,
          horaFim: evento.horaFim,
          localEvento: evento.localEvento,
          servicos: _montarServicosVisao(
            mensal,
            designacoes.where((v) => v.eventoId == evento.id).toList(),
          ),
        ),
    ];
    itens.sort((a, b) {
      final byData = a.data.compareTo(b.data);
      if (byData != 0) return byData;
      final byHora = (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
      if (byHora != 0) return byHora;
      return a.origem.compareTo(b.origem);
    });

    resultado.add(
      VisaoMensalEscala(
        competencia: mes,
        igrejaId: igrejaId,
        ministerioId: m.id,
        ministerioNome: m.nome,
        escalaId: mensal?.id,
        escalaTitulo: mensal?.titulo,
        escalaStatus: mensal?.status,
        itens: itens,
      ),
    );
  }
  return resultado;
}

List<ServicoVisaoMensal> _montarServicosVisao(
  Escala? mensal,
  List<EscalaVoluntario> designacoes,
) {
  final necessidades = <String, int>{};
  if (mensal != null) {
    for (final s in mensal.servicos) {
      if (s.servicoId != null) {
        necessidades[s.servicoId!] = s.quantidadeNecessaria;
      }
    }
  }
  final nomes = <String, String>{
    for (final s in mensal?.servicos ?? const <EscalaServico>[])
      if (s.servicoId != null) s.servicoId!: s.servicoNome ?? s.servicoId!,
  };

  final agrupadas = <String, List<EscalaVoluntario>>{};
  for (final d in designacoes) {
    if (d.servicoId == null) continue;
    agrupadas.putIfAbsent(d.servicoId!, () => []).add(d);
    if (!nomes.containsKey(d.servicoId)) {
      nomes[d.servicoId!] = d.servicoNome ?? d.servicoId!;
    }
  }

  final servicoIds = <String>{...necessidades.keys, ...agrupadas.keys};
  final servicos = <ServicoVisaoMensal>[];
  for (final servicoId in servicoIds.toList()
    ..sort((a, b) => nomes[a]!.compareTo(nomes[b]!))) {
    final unicos = <String, EscalaVoluntario>{};
    for (final d in agrupadas[servicoId] ?? const <EscalaVoluntario>[]) {
      unicos.putIfAbsent(d.pessoaId ?? '', () => d);
    }
    final designados = unicos.values.toList()
      ..sort((a, b) => (a.pessoaNome ?? '').compareTo(b.pessoaNome ?? ''));
    final qtd = necessidades[servicoId];
    servicos.add(
      ServicoVisaoMensal(
        servicoId: servicoId,
        servicoNome: nomes[servicoId] ?? servicoId,
        quantidadeNecessaria: qtd ?? designados.length,
        designados: designados
            .map(
              (v) => DesignadoVisao(
                designacaoId: v.id,
                pessoaId: v.pessoaId,
                pessoaNome: v.pessoaNome ?? '—',
                status: v.status,
                confirmadoPeloVoluntario: v.confirmadoPeloVoluntario,
                observacoes: v.observacoes,
              ),
            )
            .toList(),
      ),
    );
  }
  return servicos;
}

String _mesDaData(String data) => data.length >= 7 ? data.substring(0, 7) : '';
