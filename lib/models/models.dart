enum Role { admin, pastor, lider, voluntario, membro }

enum PessoaStatus { ativo, inativo }

enum PessoaTipo { visitante, membro, voluntario, lider, pastor }

enum JornadaEtapaStatus { concluido, atual, pendente }

enum IgrejaTipo { matriz, filial }

enum MinisterioTipo { geral, musica, midia }

enum EscalaTipo { supervisor, pregador, culto, ministerio }

enum TipoEvento { culto, evento, ensaio, reuniao, outro }

enum DiaSemana { domingo, segunda, terca, quarta, quinta, sexta, sabado }

enum EscalaItemStatus { pendente, confirmado, recusado, substituido }

class Igreja {
  const Igreja({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.pastorPessoaId,
    required this.pastorNome,
    required this.adminUsuarioId,
    required this.adminNome,
    required this.ativo,
    this.igrejaMatrizId,
  });

  final String id;
  final String nome;
  final IgrejaTipo tipo;
  final String? igrejaMatrizId;
  final String pastorPessoaId;
  final String pastorNome;
  final String adminUsuarioId;
  final String adminNome;
  final bool ativo;

  bool get isMatriz => tipo == IgrejaTipo.matriz;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.nome,
    required this.email,
    required this.roles,
    required this.igrejaId,
    required this.igrejaTipo,
    required this.igrejaNome,
    this.pessoaId,
    this.igrejasVisiveis = const [],
  });

  final String id;
  final String nome;
  final String email;
  final List<Role> roles;
  final String? pessoaId;
  final String igrejaId;
  final IgrejaTipo igrejaTipo;
  final String igrejaNome;
  final List<Igreja> igrejasVisiveis;

  bool get isMatriz => igrejaTipo == IgrejaTipo.matriz;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      roles: (json['roles'] as List<dynamic>)
          .map((r) => _roleFromString(r as String))
          .toList(),
      pessoaId: json['pessoaId'] as String?,
      igrejaId: json['igrejaId'] as String? ?? '',
      igrejaTipo: _igrejaTipoFromString(json['igrejaTipo'] as String? ?? 'FILIAL'),
      igrejaNome: json['igrejaNome'] as String? ?? '',
      igrejasVisiveis: (json['igrejasVisiveis'] as List<dynamic>? ?? [])
          .map((e) => _igrejaFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'roles': roles.map(_roleToString).toList(),
        'pessoaId': pessoaId,
        'igrejaId': igrejaId,
        'igrejaTipo': _igrejaTipoToString(igrejaTipo),
        'igrejaNome': igrejaNome,
        'igrejasVisiveis': igrejasVisiveis.map(_igrejaToJson).toList(),
      };
}

class JornadaEtapa {
  const JornadaEtapa({
    required this.id,
    required this.titulo,
    required this.status,
    this.data,
  });

  final String id;
  final String titulo;
  final JornadaEtapaStatus status;
  final String? data;
}

class Pessoa {
  const Pessoa({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.status,
    required this.tipos,
    required this.ministerios,
    required this.dataCadastro,
    required this.igrejaId,
    this.nascimento,
    this.jornada = const [],
    this.usuarioId,
  });

  final String id;
  final String nome;
  final String telefone;
  final String email;
  final PessoaStatus status;
  final List<PessoaTipo> tipos;
  final List<String> ministerios;
  final String dataCadastro;
  final String? nascimento;
  final List<JornadaEtapa> jornada;
  final String igrejaId;
  final String? usuarioId;

  bool get temUsuario => usuarioId != null && usuarioId!.isNotEmpty;

  Pessoa copyWith({
    String? nome,
    String? telefone,
    String? email,
    PessoaStatus? status,
    String? usuarioId,
    List<String>? ministerios,
    List<PessoaTipo>? tipos,
  }) {
    return Pessoa(
      id: id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      status: status ?? this.status,
      tipos: tipos ?? this.tipos,
      ministerios: ministerios ?? this.ministerios,
      dataCadastro: dataCadastro,
      nascimento: nascimento,
      jornada: jornada,
      igrejaId: igrejaId,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}

class PessoaHistorico {
  const PessoaHistorico({
    required this.id,
    required this.pessoaId,
    required this.descricao,
    required this.autorNome,
    required this.autorCargo,
    required this.dataRegistro,
  });

  final String id;
  final String pessoaId;
  final String descricao;
  final String autorNome;
  final String? autorCargo;
  final String dataRegistro;
}

class Servico {
  const Servico({
    required this.id,
    required this.ministerioId,
    required this.nome,
    required this.ficcao,
    required this.ativo,
    this.descricao,
  });

  final String id;
  final String ministerioId;
  final String nome;
  final bool ficcao;
  final bool ativo;
  final String? descricao;
}

class BaseMinisterial {
  const BaseMinisterial({
    required this.id,
    required this.nome,
    required this.liderNome,
    required this.ativo,
    required this.igrejaId,
    this.descricao,
    this.liderPessoaId,
    this.coordenadorPessoaId,
    this.coordenadorNome,
    this.ordem,
  });

  final String id;
  final String nome;
  final String liderNome;
  final bool ativo;
  final String? descricao;
  final String igrejaId;
  final String? liderPessoaId;
  final String? coordenadorPessoaId;
  final String? coordenadorNome;
  final String? ordem;

  BaseMinisterial copyWith({
    String? nome,
    String? descricao,
    bool? ativo,
    String? liderPessoaId,
    String? liderNome,
    String? coordenadorPessoaId,
    String? coordenadorNome,
    String? ordem,
  }) {
    return BaseMinisterial(
      id: id,
      nome: nome ?? this.nome,
      liderNome: liderNome ?? this.liderNome,
      ativo: ativo ?? this.ativo,
      descricao: descricao ?? this.descricao,
      igrejaId: igrejaId,
      liderPessoaId: liderPessoaId ?? this.liderPessoaId,
      coordenadorPessoaId: coordenadorPessoaId ?? this.coordenadorPessoaId,
      coordenadorNome: coordenadorNome ?? this.coordenadorNome,
      ordem: ordem ?? this.ordem,
    );
  }
}

class Ministerio {
  const Ministerio({
    required this.id,
    required this.nome,
    required this.liderNome,
    required this.totalVoluntarios,
    required this.totalServicos,
    required this.ativo,
    required this.igrejaId,
    required this.tipo,
    this.descricao,
    this.liderPessoaId,
    this.coordenadorPessoaId,
    this.coordenadorNome,
    this.anotacoes,
    this.ordem,
    this.baseMinisterialId,
    this.baseMinisterialNome,
    this.servicos = const [],
  });

  final String id;
  final String nome;
  final String liderNome;
  final int totalVoluntarios;
  final int totalServicos;
  final bool ativo;
  final String? descricao;
  final String igrejaId;
  final MinisterioTipo tipo;
  final String? liderPessoaId;
  final String? coordenadorPessoaId;
  final String? coordenadorNome;
  final String? anotacoes;
  final String? ordem;
  final String? baseMinisterialId;
  final String? baseMinisterialNome;
  final List<Servico> servicos;

  List<Servico> get servicosReais => servicos.where((s) => !s.ficcao).toList();

  Servico? get servicoCoordenador {
    for (final s in servicos) {
      if (s.ficcao) return s;
    }
    return null;
  }

  Ministerio copyWith({
    String? nome,
    String? descricao,
    bool? ativo,
    String? liderPessoaId,
    String? liderNome,
    String? coordenadorPessoaId,
    String? coordenadorNome,
    MinisterioTipo? tipo,
    String? anotacoes,
    String? ordem,
    String? baseMinisterialId,
    String? baseMinisterialNome,
    List<Servico>? servicos,
    int? totalVoluntarios,
    int? totalServicos,
  }) {
    return Ministerio(
      id: id,
      nome: nome ?? this.nome,
      liderNome: liderNome ?? this.liderNome,
      totalVoluntarios: totalVoluntarios ?? this.totalVoluntarios,
      totalServicos: totalServicos ?? this.totalServicos,
      ativo: ativo ?? this.ativo,
      descricao: descricao ?? this.descricao,
      igrejaId: igrejaId,
      tipo: tipo ?? this.tipo,
      liderPessoaId: liderPessoaId ?? this.liderPessoaId,
      coordenadorPessoaId: coordenadorPessoaId ?? this.coordenadorPessoaId,
      coordenadorNome: coordenadorNome ?? this.coordenadorNome,
      anotacoes: anotacoes ?? this.anotacoes,
      ordem: ordem ?? this.ordem,
      baseMinisterialId: baseMinisterialId ?? this.baseMinisterialId,
      baseMinisterialNome: baseMinisterialNome ?? this.baseMinisterialNome,
      servicos: servicos ?? this.servicos,
    );
  }
}

class UsuarioConta {
  const UsuarioConta({
    required this.id,
    required this.username,
    required this.email,
    required this.igrejaId,
    required this.igrejaNome,
    required this.papeis,
    required this.ativo,
    this.pessoaId,
    this.pessoaNome,
  });

  final String id;
  final String username;
  final String email;
  final String? pessoaId;
  final String? pessoaNome;
  final String igrejaId;
  final String igrejaNome;
  final List<Role> papeis;
  final bool ativo;
}

class EscalaItem {
  const EscalaItem({
    required this.id,
    required this.data,
    this.eventoId,
    this.pessoaId,
    this.pessoaNome,
    this.servicoId,
    this.servicoNome,
    this.horario,
    this.status = EscalaItemStatus.pendente,
  });

  final String id;
  final String data;
  final String? eventoId;
  final String? pessoaId;
  final String? pessoaNome;
  final String? servicoId;
  final String? servicoNome;
  final String? horario;
  final EscalaItemStatus status;
}

class Escala {
  const Escala({
    required this.id,
    required this.titulo,
    required this.competencia,
    required this.tipo,
    required this.igrejaId,
    required this.supervisorPessoaId,
    required this.supervisorNome,
    required this.ativo,
    this.ministerioId,
    this.ministerioNome,
    this.pregadorPessoaId,
    this.pregadorNome,
    this.itens = const [],
  });

  final String id;
  final String titulo;
  final String competencia;
  final EscalaTipo tipo;
  final String igrejaId;
  final String? ministerioId;
  final String? ministerioNome;
  final String supervisorPessoaId;
  final String supervisorNome;
  final String? pregadorPessoaId;
  final String? pregadorNome;
  final bool ativo;
  final List<EscalaItem> itens;
}

class SmallGroupParticipante {
  const SmallGroupParticipante({required this.pessoaId, required this.pessoaNome});

  final String pessoaId;
  final String pessoaNome;
}

class SmallGroupEncontro {
  const SmallGroupEncontro({
    required this.id,
    required this.smallGroupId,
    required this.data,
    required this.compareceram,
    this.anfitriaoPessoaId,
    this.anfitriaoNome,
    this.anotacoes,
  });

  final String id;
  final String smallGroupId;
  final String data;
  final String? anfitriaoPessoaId;
  final String? anfitriaoNome;
  final List<SmallGroupParticipante> compareceram;
  final String? anotacoes;

  SmallGroupEncontro copyWith({
    String? anfitriaoPessoaId,
    String? anfitriaoNome,
    List<SmallGroupParticipante>? compareceram,
    String? anotacoes,
  }) {
    return SmallGroupEncontro(
      id: id,
      smallGroupId: smallGroupId,
      data: data,
      anfitriaoPessoaId: anfitriaoPessoaId ?? this.anfitriaoPessoaId,
      anfitriaoNome: anfitriaoNome ?? this.anfitriaoNome,
      compareceram: compareceram ?? this.compareceram,
      anotacoes: anotacoes ?? this.anotacoes,
    );
  }
}

class SmallGroup {
  const SmallGroup({
    required this.id,
    required this.nome,
    required this.igrejaId,
    required this.diaSemana,
    required this.liderPessoaId,
    required this.liderNome,
    required this.ativo,
    required this.nota,
    this.horario,
    this.encontros = const [],
  });

  final String id;
  final String nome;
  final String igrejaId;
  final DiaSemana diaSemana;
  final String? horario;
  final String liderPessoaId;
  final String liderNome;
  final bool ativo;
  final int nota;
  final List<SmallGroupEncontro> encontros;

  String get notaLabel => nota == 0 ? 'Sem nota' : '$nota / 5';
}

class CultoEvento {
  const CultoEvento({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.data,
    required this.horaInicio,
    required this.igrejaId,
    required this.supervisorPessoaId,
    required this.supervisorNome,
    required this.ativo,
    this.horaFim,
    this.localEvento,
    this.descricao,
  });

  final String id;
  final String titulo;
  final TipoEvento tipo;
  final String data;
  final String horaInicio;
  final String? horaFim;
  final String? localEvento;
  final String? descricao;
  final String igrejaId;
  final String supervisorPessoaId;
  final String supervisorNome;
  final bool ativo;
}

class ConteudoCulto {
  const ConteudoCulto({
    required this.eventoId,
    required this.textoPregacao,
    required this.louvor,
    this.pregadorPessoaId,
    this.pregadorNome,
  });

  final String eventoId;
  final String textoPregacao;
  final String louvor;
  final String? pregadorPessoaId;
  final String? pregadorNome;

  ConteudoCulto copyWith({
    String? textoPregacao,
    String? louvor,
    String? pregadorPessoaId,
    String? pregadorNome,
  }) {
    return ConteudoCulto(
      eventoId: eventoId,
      textoPregacao: textoPregacao ?? this.textoPregacao,
      louvor: louvor ?? this.louvor,
      pregadorPessoaId: pregadorPessoaId ?? this.pregadorPessoaId,
      pregadorNome: pregadorNome ?? this.pregadorNome,
    );
  }
}

class IndisponibilidadeSemanal {
  const IndisponibilidadeSemanal({
    required this.dia,
    this.manha = false,
    this.tarde = false,
    this.noite = false,
  });

  final DiaSemana dia;
  final bool manha;
  final bool tarde;
  final bool noite;

  bool get marcado => manha || tarde || noite;

  IndisponibilidadeSemanal copyWith({bool? manha, bool? tarde, bool? noite}) {
    return IndisponibilidadeSemanal(
      dia: dia,
      manha: manha ?? this.manha,
      tarde: tarde ?? this.tarde,
      noite: noite ?? this.noite,
    );
  }
}

class IndisponibilidadeData {
  const IndisponibilidadeData({
    required this.id,
    required this.pessoaId,
    required this.data,
    this.motivo,
  });

  final String id;
  final String pessoaId;
  final String data;
  final String? motivo;
}

class DisponibilidadePessoa {
  const DisponibilidadePessoa({
    required this.pessoaId,
    required this.semanal,
    required this.datas,
  });

  final String pessoaId;
  final List<IndisponibilidadeSemanal> semanal;
  final List<IndisponibilidadeData> datas;
}

class DashboardStats {
  const DashboardStats({
    required this.totalPessoas,
    required this.totalMembros,
    required this.totalVoluntarios,
    required this.totalLideres,
    required this.escalasPendentes,
    required this.visitantesRecentes,
    required this.proximasEscalas,
    required this.jornada,
  });

  final int totalPessoas;
  final int totalMembros;
  final int totalVoluntarios;
  final int totalLideres;
  final int escalasPendentes;
  final int visitantesRecentes;
  final List<EscalaResumo> proximasEscalas;
  final JornadaIndicadores jornada;
}

class EscalaResumo {
  const EscalaResumo({
    required this.id,
    required this.data,
    required this.horario,
    required this.ministerio,
    required this.totalVoluntarios,
    required this.confirmados,
    required this.pendentes,
  });

  final String id;
  final String data;
  final String horario;
  final String ministerio;
  final int totalVoluntarios;
  final int confirmados;
  final int pendentes;
}

class JornadaIndicadores {
  const JornadaIndicadores({
    required this.novosVisitantes,
    required this.aceitaramJesus,
    required this.batizados,
    required this.trilhaBase,
    required this.novosMembros,
  });

  final int novosVisitantes;
  final int aceitaramJesus;
  final int batizados;
  final int trilhaBase;
  final int novosMembros;
}

class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.page,
    required this.size,
  });

  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int page;
  final int size;
}

Role _roleFromString(String value) {
  switch (value.toUpperCase()) {
    case 'ADMIN':
      return Role.admin;
    case 'PASTOR':
      return Role.pastor;
    case 'LIDER':
      return Role.lider;
    case 'VOLUNTARIO':
      return Role.voluntario;
    default:
      return Role.membro;
  }
}

String _roleToString(Role role) {
  switch (role) {
    case Role.admin:
      return 'ADMIN';
    case Role.pastor:
      return 'PASTOR';
    case Role.lider:
      return 'LIDER';
    case Role.voluntario:
      return 'VOLUNTARIO';
    case Role.membro:
      return 'MEMBRO';
  }
}

IgrejaTipo _igrejaTipoFromString(String value) {
  return value.toUpperCase() == 'MATRIZ' ? IgrejaTipo.matriz : IgrejaTipo.filial;
}

String _igrejaTipoToString(IgrejaTipo tipo) {
  return tipo == IgrejaTipo.matriz ? 'MATRIZ' : 'FILIAL';
}

Igreja _igrejaFromJson(Map<String, dynamic> json) {
  return Igreja(
    id: json['id'] as String,
    nome: json['nome'] as String,
    tipo: _igrejaTipoFromString(json['tipo'] as String? ?? 'FILIAL'),
    pastorPessoaId: json['pastorPessoaId'] as String? ?? '',
    pastorNome: json['pastorNome'] as String? ?? '',
    adminUsuarioId: json['adminUsuarioId'] as String? ?? '',
    adminNome: json['adminNome'] as String? ?? '',
    ativo: json['ativo'] as bool? ?? true,
    igrejaMatrizId: json['igrejaMatrizId'] as String?,
  );
}

Map<String, dynamic> _igrejaToJson(Igreja i) => {
      'id': i.id,
      'nome': i.nome,
      'tipo': _igrejaTipoToString(i.tipo),
      'pastorPessoaId': i.pastorPessoaId,
      'pastorNome': i.pastorNome,
      'adminUsuarioId': i.adminUsuarioId,
      'adminNome': i.adminNome,
      'ativo': i.ativo,
      'igrejaMatrizId': i.igrejaMatrizId,
    };

String pessoaStatusLabel(PessoaStatus status) =>
    status == PessoaStatus.ativo ? 'ATIVO' : 'INATIVO';

String pessoaTipoLabel(PessoaTipo tipo) => tipo.name.toUpperCase();

String igrejaTipoLabel(IgrejaTipo tipo) =>
    tipo == IgrejaTipo.matriz ? 'Matriz' : 'Filial';

String ministerioTipoLabel(MinisterioTipo tipo) {
  switch (tipo) {
    case MinisterioTipo.musica:
      return 'Música';
    case MinisterioTipo.midia:
      return 'Mídia';
    case MinisterioTipo.geral:
      return 'Geral';
  }
}

String escalaTipoLabel(EscalaTipo tipo) {
  switch (tipo) {
    case EscalaTipo.supervisor:
      return 'Supervisor';
    case EscalaTipo.pregador:
      return 'Pregador';
    case EscalaTipo.culto:
      return 'Culto';
    case EscalaTipo.ministerio:
      return 'Ministério';
  }
}

String tipoEventoLabel(TipoEvento tipo) {
  switch (tipo) {
    case TipoEvento.culto:
      return 'Culto';
    case TipoEvento.evento:
      return 'Evento';
    case TipoEvento.ensaio:
      return 'Ensaio';
    case TipoEvento.reuniao:
      return 'Reunião';
    case TipoEvento.outro:
      return 'Outro';
  }
}

String diaSemanaLabel(DiaSemana dia) {
  switch (dia) {
    case DiaSemana.domingo:
      return 'Domingo';
    case DiaSemana.segunda:
      return 'Segunda';
    case DiaSemana.terca:
      return 'Terça';
    case DiaSemana.quarta:
      return 'Quarta';
    case DiaSemana.quinta:
      return 'Quinta';
    case DiaSemana.sexta:
      return 'Sexta';
    case DiaSemana.sabado:
      return 'Sábado';
  }
}

String roleLabel(Role role) {
  switch (role) {
    case Role.admin:
      return 'Admin';
    case Role.pastor:
      return 'Pastor';
    case Role.lider:
      return 'Líder';
    case Role.voluntario:
      return 'Voluntário';
    case Role.membro:
      return 'Membro';
  }
}

Role roleFromString(String value) => _roleFromString(value);

String roleToString(Role role) => _roleToString(role);

MinisterioTipo ministerioTipoFromString(String value) {
  switch (value.toUpperCase()) {
    case 'MUSICA':
      return MinisterioTipo.musica;
    case 'MIDIA':
      return MinisterioTipo.midia;
    default:
      return MinisterioTipo.geral;
  }
}

String ministerioTipoToString(MinisterioTipo tipo) {
  switch (tipo) {
    case MinisterioTipo.musica:
      return 'MUSICA';
    case MinisterioTipo.midia:
      return 'MIDIA';
    case MinisterioTipo.geral:
      return 'GERAL';
  }
}

EscalaTipo escalaTipoFromString(String value) {
  switch (value.toUpperCase()) {
    case 'SUPERVISOR':
      return EscalaTipo.supervisor;
    case 'PREGADOR':
      return EscalaTipo.pregador;
    case 'CULTO':
      return EscalaTipo.culto;
    default:
      return EscalaTipo.ministerio;
  }
}

String escalaTipoToString(EscalaTipo tipo) {
  switch (tipo) {
    case EscalaTipo.supervisor:
      return 'SUPERVISOR';
    case EscalaTipo.pregador:
      return 'PREGADOR';
    case EscalaTipo.culto:
      return 'CULTO';
    case EscalaTipo.ministerio:
      return 'MINISTERIO';
  }
}

TipoEvento tipoEventoFromString(String value) {
  switch (value.toUpperCase()) {
    case 'CULTO':
      return TipoEvento.culto;
    case 'EVENTO':
      return TipoEvento.evento;
    case 'ENSAIO':
      return TipoEvento.ensaio;
    case 'REUNIAO':
      return TipoEvento.reuniao;
    default:
      return TipoEvento.outro;
  }
}

String tipoEventoToString(TipoEvento tipo) {
  switch (tipo) {
    case TipoEvento.culto:
      return 'CULTO';
    case TipoEvento.evento:
      return 'EVENTO';
    case TipoEvento.ensaio:
      return 'ENSAIO';
    case TipoEvento.reuniao:
      return 'REUNIAO';
    case TipoEvento.outro:
      return 'OUTRO';
  }
}
