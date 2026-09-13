import '../models/models.dart';

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
    ativo: true,
    itens: const [
      EscalaItem(id: 'es1', data: '2026-08-02', eventoId: 'c1', pessoaId: 'p1', pessoaNome: 'Ana Costa', horario: '18:00', status: EscalaItemStatus.confirmado),
      EscalaItem(id: 'es2', data: '2026-08-09', eventoId: 'c2', pessoaId: 'p1', pessoaNome: 'Ana Costa', horario: '18:00', status: EscalaItemStatus.confirmado),
      EscalaItem(id: 'es3', data: '2026-08-16', eventoId: 'c3', pessoaId: 'p7', pessoaNome: 'Carlos Lima', horario: '18:00', status: EscalaItemStatus.pendente),
      EscalaItem(id: 'es4', data: '2026-08-23', eventoId: 'c4', pessoaId: 'p1', pessoaNome: 'Ana Costa', horario: '18:00', status: EscalaItemStatus.pendente),
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
    ativo: true,
    itens: const [
      EscalaItem(id: 'ep1', data: '2026-08-02', eventoId: 'c1', pessoaId: 'p1', pessoaNome: 'Ana Costa', horario: '18:00', status: EscalaItemStatus.confirmado),
      EscalaItem(id: 'ep2', data: '2026-08-09', eventoId: 'c2', pessoaId: 'p1', pessoaNome: 'Ana Costa', horario: '18:00', status: EscalaItemStatus.confirmado),
      EscalaItem(id: 'ep3', data: '2026-08-16', eventoId: 'c3', pessoaId: 'p1', pessoaNome: 'Ana Costa', horario: '18:00', status: EscalaItemStatus.pendente),
      EscalaItem(id: 'ep4', data: '2026-08-23', eventoId: 'c4', pessoaId: 'p8', pessoaNome: 'Pedro Alves', horario: '18:00', status: EscalaItemStatus.pendente),
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
    ativo: true,
    itens: const [
      EscalaItem(id: 'ec1', data: '2026-08-09', eventoId: 'c2', pessoaId: 'p2', pessoaNome: 'João da Silva', servicoNome: 'Vocal', horario: '18:00', status: EscalaItemStatus.confirmado),
      EscalaItem(id: 'ec2', data: '2026-08-09', eventoId: 'c2', pessoaId: 'p7', pessoaNome: 'Carlos Lima', servicoNome: 'Projeção', horario: '18:00', status: EscalaItemStatus.pendente),
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
    pregadorPessoaId: 'p1',
    pregadorNome: 'Ana Costa',
    ativo: true,
    itens: const [
      EscalaItem(id: 'el1', data: '2026-08-09', eventoId: 'c2', pessoaId: 'p2', pessoaNome: 'João da Silva', servicoNome: 'Vocal', horario: '18:00', status: EscalaItemStatus.confirmado),
      EscalaItem(id: 'el2', data: '2026-08-09', eventoId: 'c2', pessoaId: 'p3', pessoaNome: 'Maria Oliveira', servicoNome: 'Violão', horario: '18:00', status: EscalaItemStatus.pendente),
      EscalaItem(id: 'el3', data: '2026-08-16', eventoId: 'c3', pessoaId: 'p2', pessoaNome: 'João da Silva', servicoNome: 'Vocal', horario: '18:00', status: EscalaItemStatus.pendente),
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
