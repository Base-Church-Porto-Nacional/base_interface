enum Role { admin, pastor, lider, voluntario, membro }

enum PessoaStatus { ativo, inativo }

enum PessoaTipo { visitante, membro, voluntario, lider, pastor }

enum JornadaEtapaStatus { concluido, atual, pendente }

enum IgrejaTipo { matriz, filial }

enum MinisterioTipo { geral, musica, midia }

enum EscalaTipo { supervisor, pregador, culto, ministerio }

enum EscalaStatus { sugerida, editando, emAndamento, finalizada }

enum TipoEvento { culto, evento, ensaio, reuniao, outro }

enum DiaSemana { domingo, segunda, terca, quarta, quinta, sexta, sabado }

enum CultoStatus { agendado, aberto, realizado, cancelado }

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
    this.papeis = const [],
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
  final List<Role> papeis;

  bool get temUsuario => usuarioId != null && usuarioId!.isNotEmpty;

  List<Role> get papeisExibiveis => papeis.isNotEmpty ? papeis : _papeisDeTipos(tipos);

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
      papeis: papeis,
    );
  }
}

List<Role> _papeisDeTipos(List<PessoaTipo> tipos) {
  final papeis = <Role>[];
  for (final t in tipos) {
    switch (t) {
      case PessoaTipo.membro:
        papeis.add(Role.membro);
      case PessoaTipo.voluntario:
        papeis.add(Role.voluntario);
      case PessoaTipo.lider:
        papeis.add(Role.lider);
      case PessoaTipo.pastor:
        papeis.add(Role.pastor);
      case PessoaTipo.visitante:
        break;
    }
  }
  return papeis;
}

List<PessoaTipo> pessoaTiposDePapeis(List<Role> papeis) {
  final tipos = <PessoaTipo>[];
  for (final r in papeis) {
    switch (r) {
      case Role.pastor:
        tipos.add(PessoaTipo.pastor);
      case Role.lider:
        tipos.add(PessoaTipo.lider);
      case Role.voluntario:
        tipos.add(PessoaTipo.voluntario);
      case Role.membro:
        tipos.add(PessoaTipo.membro);
      case Role.admin:
        break;
    }
  }
  return tipos.isNotEmpty ? tipos : <PessoaTipo>[PessoaTipo.visitante];
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

class EscalaServico {
  const EscalaServico({
    required this.id,
    this.escalaId,
    this.servicoId,
    this.servicoNome,
    this.quantidadeNecessaria = 1,
  });

  final String id;
  final String? escalaId;
  final String? servicoId;
  final String? servicoNome;
  final int quantidadeNecessaria;
}

class EscalaVoluntario {
  const EscalaVoluntario({
    required this.id,
    this.escalaId,
    this.pessoaId,
    this.pessoaNome,
    this.servicoId,
    this.servicoNome,
    this.status = EscalaItemStatus.pendente,
    this.observacoes,
    this.data,
    this.eventoId,
    this.horario,
    this.confirmadoPeloVoluntario = false,
  });

  final String id;
  final String? escalaId;
  final String? pessoaId;
  final String? pessoaNome;
  final String? servicoId;
  final String? servicoNome;
  final EscalaItemStatus status;
  final String? observacoes;
  final String? data;
  final String? eventoId;
  final String? horario;
  final bool confirmadoPeloVoluntario;

  bool get aprovadoPeloVoluntario =>
      confirmadoPeloVoluntario && status == EscalaItemStatus.confirmado;
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
    this.descricao,
    this.ministerioId,
    this.ministerioNome,
    this.pregadorPessoaId,
    this.pregadorNome,
    this.status = EscalaStatus.editando,
    this.dataLancamento,
    this.dataFinalizacao,
    this.dataEvento,
    this.horaInicio,
    this.horaFim,
    this.eventoId,
    this.servicos = const [],
    this.voluntarios = const [],
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
  final String? descricao;
  final EscalaStatus status;
  final String? dataLancamento;
  final String? dataFinalizacao;
  final String? dataEvento;
  final String? horaInicio;
  final String? horaFim;
  final String? eventoId;
  final List<EscalaServico> servicos;
  final List<EscalaVoluntario> voluntarios;
  final List<EscalaItem> itens;

  bool geraAuto() => status == EscalaStatus.sugerida;

  int preenchidosDoServico(String? servicoId) => voluntarios
      .where((v) => v.servicoId == servicoId && v.status != EscalaItemStatus.recusado)
      .length;

  List<EscalaVoluntario> voluntariosDoServico(String? servicoId) => voluntarios
      .where((v) => v.servicoId == servicoId && v.status != EscalaItemStatus.recusado)
      .toList();

  Escala copyWith({
    String? titulo,
    String? descricao,
    String? competencia,
    EscalaTipo? tipo,
    String? ministerioId,
    String? ministerioNome,
    String? supervisorPessoaId,
    String? supervisorNome,
    String? pregadorPessoaId,
    String? pregadorNome,
    EscalaStatus? status,
    String? dataLancamento,
    String? dataFinalizacao,
    String? dataEvento,
    String? horaInicio,
    String? horaFim,
    String? eventoId,
    bool? ativo,
    List<EscalaServico>? servicos,
    List<EscalaVoluntario>? voluntarios,
    List<EscalaItem>? itens,
  }) {
    return Escala(
      id: id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      competencia: competencia ?? this.competencia,
      tipo: tipo ?? this.tipo,
      igrejaId: igrejaId,
      ministerioId: ministerioId ?? this.ministerioId,
      ministerioNome: ministerioNome ?? this.ministerioNome,
      supervisorPessoaId: supervisorPessoaId ?? this.supervisorPessoaId,
      supervisorNome: supervisorNome ?? this.supervisorNome,
      pregadorPessoaId: pregadorPessoaId ?? this.pregadorPessoaId,
      pregadorNome: pregadorNome ?? this.pregadorNome,
      status: status ?? this.status,
      dataLancamento: dataLancamento ?? this.dataLancamento,
      dataFinalizacao: dataFinalizacao ?? this.dataFinalizacao,
      dataEvento: dataEvento ?? this.dataEvento,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFim: horaFim ?? this.horaFim,
      eventoId: eventoId ?? this.eventoId,
      ativo: ativo ?? this.ativo,
      servicos: servicos ?? this.servicos,
      voluntarios: voluntarios ?? this.voluntarios,
      itens: itens ?? this.itens,
    );
  }
}

class VisaoMensalEscala {
  const VisaoMensalEscala({
    required this.competencia,
    required this.igrejaId,
    required this.ministerioId,
    required this.ministerioNome,
    this.escalaId,
    this.escalaTitulo,
    this.escalaStatus,
    this.itens = const [],
  });

  final String competencia;
  final String igrejaId;
  final String ministerioId;
  final String ministerioNome;
  final String? escalaId;
  final String? escalaTitulo;
  final EscalaStatus? escalaStatus;
  final List<ItemVisaoMensal> itens;
}

class ItemVisaoMensal {
  const ItemVisaoMensal({
    required this.origem,
    required this.id,
    required this.titulo,
    required this.data,
    this.horaInicio,
    this.horaFim,
    this.localEvento,
    this.servicos = const [],
  });

  final String origem;
  final String id;
  final String titulo;
  final String data;
  final String? horaInicio;
  final String? horaFim;
  final String? localEvento;
  final List<ServicoVisaoMensal> servicos;

  bool get isCulto => origem.toUpperCase() == 'CULTO';
}

class ServicoVisaoMensal {
  const ServicoVisaoMensal({
    this.servicoId,
    required this.servicoNome,
    required this.quantidadeNecessaria,
    this.designados = const [],
  });

  final String? servicoId;
  final String servicoNome;
  final int quantidadeNecessaria;
  final List<DesignadoVisao> designados;

  int get vagasEmAberto =>
      (quantidadeNecessaria - designados.length).clamp(0, quantidadeNecessaria);
}

class DesignadoVisao {
  const DesignadoVisao({
    required this.designacaoId,
    this.pessoaId,
    required this.pessoaNome,
    this.status = EscalaItemStatus.pendente,
    this.confirmadoPeloVoluntario = false,
    this.observacoes,
  });

  final String designacaoId;
  final String? pessoaId;
  final String pessoaNome;
  final EscalaItemStatus status;
  final bool confirmadoPeloVoluntario;
  final String? observacoes;
}

class EscalaCandidato {
  const EscalaCandidato({
    required this.pessoaId,
    required this.pessoaNome,
    this.servicoId,
    this.servicoNome,
    this.servicosQueServe = const [],
    this.diasDisponiveis = const [],
    this.analiseDia,
  });

  final String? servicoId;
  final String? servicoNome;
  final String pessoaId;
  final String pessoaNome;
  final List<String> servicosQueServe;
  final List<DiaDisponivel> diasDisponiveis;
  final AnaliseDiaCandidato? analiseDia;
}

class DiaDisponivel {
  const DiaDisponivel({
    required this.diaSemana,
    this.horaInicio,
    this.horaFim,
    this.disponivel = true,
  });

  final DiaSemana diaSemana;
  final String? horaInicio;
  final String? horaFim;
  final bool disponivel;
}

class AnaliseDiaCandidato {
  const AnaliseDiaCandidato({
    this.data,
    this.tituloEvento,
    this.disponivel = true,
    this.motivosIndisponibilidade = const [],
    this.conflitos = const [],
  });

  final String? data;
  final String? tituloEvento;
  final bool disponivel;
  final List<String> motivosIndisponibilidade;
  final List<ConflitoEscala> conflitos;
}

class ConflitoEscala {
  const ConflitoEscala({
    this.escalaId,
    this.escalaTitulo,
    this.ministerioNome,
    this.servicoNome,
    this.data,
    this.horario,
  });

  final String? escalaId;
  final String? escalaTitulo;
  final String? ministerioNome;
  final String? servicoNome;
  final String? data;
  final String? horario;
}

class SugestaoResultado {
  const SugestaoResultado({
    required this.escalaId,
    required this.status,
    required this.message,
    this.sugestoes = const [],
  });

  final String escalaId;
  final String status;
  final String message;
  final List<SugestaoItem> sugestoes;
}

class SugestaoItem {
  const SugestaoItem({
    this.servicoId,
    this.servicoNome,
    this.pessoaId,
    this.pessoaNome,
    this.data,
    this.eventoId,
    this.motivo,
  });

  final String? servicoId;
  final String? servicoNome;
  final String? pessoaId;
  final String? pessoaNome;
  final String? data;
  final String? eventoId;
  final String? motivo;
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

class CategoriaCulto {
  const CategoriaCulto({
    required this.id,
    required this.igrejaId,
    required this.titulo,
    required this.diaSemana,
    required this.horaInicio,
    required this.duracaoMinutos,
    required this.ativo,
    this.descricao,
    this.pregadorPadraoId,
    this.pregadorPadraoNome,
  });

  final String id;
  final String igrejaId;
  final String titulo;
  final String? descricao;
  final DiaSemana diaSemana;
  final String horaInicio;
  final int duracaoMinutos;
  final String? pregadorPadraoId;
  final String? pregadorPadraoNome;
  final bool ativo;

  CategoriaCulto copyWith({
    String? titulo,
    String? descricao,
    DiaSemana? diaSemana,
    String? horaInicio,
    int? duracaoMinutos,
    String? pregadorPadraoId,
    String? pregadorPadraoNome,
    bool? ativo,
  }) {
    return CategoriaCulto(
      id: id,
      igrejaId: igrejaId,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      diaSemana: diaSemana ?? this.diaSemana,
      horaInicio: horaInicio ?? this.horaInicio,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
      pregadorPadraoId: pregadorPadraoId ?? this.pregadorPadraoId,
      pregadorPadraoNome: pregadorPadraoNome ?? this.pregadorPadraoNome,
      ativo: ativo ?? this.ativo,
    );
  }
}

class Culto {
  const Culto({
    required this.id,
    required this.igrejaId,
    required this.categoriaCultoId,
    required this.categoriaCultoTitulo,
    required this.titulo,
    required this.data,
    required this.horaInicio,
    required this.status,
    required this.competencia,
    required this.ativo,
    required this.janelaConfiguracaoAberta,
    required this.temRelatorio,
    this.tema,
    this.horaFim,
    this.pregadorId,
    this.pregadorNome,
    this.escalaId,
  });

  final String id;
  final String igrejaId;
  final String categoriaCultoId;
  final String categoriaCultoTitulo;
  final String titulo;
  final String? tema;
  final String data;
  final String horaInicio;
  final String? horaFim;
  final String? pregadorId;
  final String? pregadorNome;
  final CultoStatus status;
  final String competencia;
  final String? escalaId;
  final bool ativo;
  final bool janelaConfiguracaoAberta;
  final bool temRelatorio;

  Culto copyWith({
    String? titulo,
    String? tema,
    String? data,
    String? horaInicio,
    String? horaFim,
    String? pregadorId,
    String? pregadorNome,
    CultoStatus? status,
    bool? ativo,
    bool? janelaConfiguracaoAberta,
    bool? temRelatorio,
  }) {
    return Culto(
      id: id,
      igrejaId: igrejaId,
      categoriaCultoId: categoriaCultoId,
      categoriaCultoTitulo: categoriaCultoTitulo,
      titulo: titulo ?? this.titulo,
      tema: tema ?? this.tema,
      data: data ?? this.data,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFim: horaFim ?? this.horaFim,
      pregadorId: pregadorId ?? this.pregadorId,
      pregadorNome: pregadorNome ?? this.pregadorNome,
      status: status ?? this.status,
      competencia: competencia,
      escalaId: escalaId,
      ativo: ativo ?? this.ativo,
      janelaConfiguracaoAberta:
          janelaConfiguracaoAberta ?? this.janelaConfiguracaoAberta,
      temRelatorio: temRelatorio ?? this.temRelatorio,
    );
  }
}

class CultoConteudo {
  const CultoConteudo({
    required this.cultoId,
    this.textoPregacao,
    this.louvor,
    this.tema,
    this.pregadorId,
    this.pregadorNome,
  });

  final String cultoId;
  final String? textoPregacao;
  final String? louvor;
  final String? tema;
  final String? pregadorId;
  final String? pregadorNome;

  CultoConteudo copyWith({
    String? textoPregacao,
    String? louvor,
    String? tema,
    String? pregadorId,
    String? pregadorNome,
  }) {
    return CultoConteudo(
      cultoId: cultoId,
      textoPregacao: textoPregacao ?? this.textoPregacao,
      louvor: louvor ?? this.louvor,
      tema: tema ?? this.tema,
      pregadorId: pregadorId ?? this.pregadorId,
      pregadorNome: pregadorNome ?? this.pregadorNome,
    );
  }
}

class CultoRelatorio {
  const CultoRelatorio({
    required this.cultoId,
    this.adultos = 0,
    this.criancas = 0,
    this.conversoes = 0,
    this.reconciliacoes = 0,
    this.aliancas = 0,
    this.carros = 0,
    this.motos = 0,
    this.bicicletas = 0,
    this.observacoes,
  });

  final String cultoId;
  final int adultos;
  final int criancas;
  final int conversoes;
  final int reconciliacoes;
  final int aliancas;
  final int carros;
  final int motos;
  final int bicicletas;
  final String? observacoes;

  int get totalPresentes => adultos + criancas;
  int get totalVeiculos => carros + motos + bicicletas;

  CultoRelatorio copyWith({
    int? adultos,
    int? criancas,
    int? conversoes,
    int? reconciliacoes,
    int? aliancas,
    int? carros,
    int? motos,
    int? bicicletas,
    String? observacoes,
  }) {
    return CultoRelatorio(
      cultoId: cultoId,
      adultos: adultos ?? this.adultos,
      criancas: criancas ?? this.criancas,
      conversoes: conversoes ?? this.conversoes,
      reconciliacoes: reconciliacoes ?? this.reconciliacoes,
      aliancas: aliancas ?? this.aliancas,
      carros: carros ?? this.carros,
      motos: motos ?? this.motos,
      bicicletas: bicicletas ?? this.bicicletas,
      observacoes: observacoes ?? this.observacoes,
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

String diaSemanaApiToString(DiaSemana dia) {
  switch (dia) {
    case DiaSemana.domingo:
      return 'DOMINGO';
    case DiaSemana.segunda:
      return 'SEGUNDA';
    case DiaSemana.terca:
      return 'TERCA';
    case DiaSemana.quarta:
      return 'QUARTA';
    case DiaSemana.quinta:
      return 'QUINTA';
    case DiaSemana.sexta:
      return 'SEXTA';
    case DiaSemana.sabado:
      return 'SABADO';
  }
}

DiaSemana diaSemanaFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'DOMINGO':
      return DiaSemana.domingo;
    case 'SEGUNDA':
      return DiaSemana.segunda;
    case 'TERCA':
      return DiaSemana.terca;
    case 'QUARTA':
      return DiaSemana.quarta;
    case 'QUINTA':
      return DiaSemana.quinta;
    case 'SEXTA':
      return DiaSemana.sexta;
    case 'SABADO':
      return DiaSemana.sabado;
    default:
      return DiaSemana.domingo;
  }
}

String cultoStatusLabel(CultoStatus status) {
  switch (status) {
    case CultoStatus.agendado:
      return 'Agendado';
    case CultoStatus.aberto:
      return 'Aberto';
    case CultoStatus.realizado:
      return 'Realizado';
    case CultoStatus.cancelado:
      return 'Cancelado';
  }
}

String cultoStatusApiToString(CultoStatus status) {
  switch (status) {
    case CultoStatus.agendado:
      return 'AGENDADO';
    case CultoStatus.aberto:
      return 'ABERTO';
    case CultoStatus.realizado:
      return 'REALIZADO';
    case CultoStatus.cancelado:
      return 'CANCELADO';
  }
}

CultoStatus cultoStatusFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'AGENDADO':
      return CultoStatus.agendado;
    case 'ABERTO':
      return CultoStatus.aberto;
    case 'REALIZADO':
      return CultoStatus.realizado;
    case 'CANCELADO':
      return CultoStatus.cancelado;
    default:
      return CultoStatus.agendado;
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

String escalaStatusLabel(EscalaStatus status) {
  switch (status) {
    case EscalaStatus.sugerida:
      return 'Sugerida';
    case EscalaStatus.editando:
      return 'Editando';
    case EscalaStatus.emAndamento:
      return 'Em andamento';
    case EscalaStatus.finalizada:
      return 'Finalizada';
  }
}

EscalaStatus escalaStatusFromString(String value) {
  switch (value.toUpperCase()) {
    case 'SUGERIDA':
      return EscalaStatus.sugerida;
    case 'EDITANDO':
      return EscalaStatus.editando;
    case 'EM_ANDAMENTO':
      return EscalaStatus.emAndamento;
    case 'FINALIZADA':
      return EscalaStatus.finalizada;
    default:
      return EscalaStatus.editando;
  }
}

String escalaStatusToString(EscalaStatus status) {
  switch (status) {
    case EscalaStatus.sugerida:
      return 'SUGERIDA';
    case EscalaStatus.editando:
      return 'EDITANDO';
    case EscalaStatus.emAndamento:
      return 'EM_ANDAMENTO';
    case EscalaStatus.finalizada:
      return 'FINALIZADA';
  }
}

bool podeTransicionarEscalaStatus(EscalaStatus de, EscalaStatus para) {
  switch (de) {
    case EscalaStatus.sugerida:
      return para == EscalaStatus.editando || para == EscalaStatus.emAndamento;
    case EscalaStatus.editando:
      return para == EscalaStatus.sugerida || para == EscalaStatus.emAndamento;
    case EscalaStatus.emAndamento:
      return para == EscalaStatus.editando || para == EscalaStatus.finalizada;
    case EscalaStatus.finalizada:
      return para == EscalaStatus.emAndamento;
  }
}

String escalaItemStatusLabel(EscalaItemStatus status) {
  switch (status) {
    case EscalaItemStatus.pendente:
      return 'Pendente';
    case EscalaItemStatus.confirmado:
      return 'Confirmado';
    case EscalaItemStatus.recusado:
      return 'Recusado';
    case EscalaItemStatus.substituido:
      return 'Substituído';
  }
}

EscalaItemStatus escalaItemStatusFromString(String value) {
  switch (value.toUpperCase()) {
    case 'CONFIRMADO':
      return EscalaItemStatus.confirmado;
    case 'RECUSADO':
      return EscalaItemStatus.recusado;
    case 'SUBSTITUIDO':
    case 'SUBSTITUÍDO':
      return EscalaItemStatus.substituido;
    default:
      return EscalaItemStatus.pendente;
  }
}

String escalaItemStatusToString(EscalaItemStatus status) {
  switch (status) {
    case EscalaItemStatus.pendente:
      return 'PENDENTE';
    case EscalaItemStatus.confirmado:
      return 'CONFIRMADO';
    case EscalaItemStatus.recusado:
      return 'RECUSADO';
    case EscalaItemStatus.substituido:
      return 'SUBSTITUIDO';
  }
}

DiaSemana diaSemanaFromString(String value) {
  switch (value.toUpperCase()) {
    case 'SEGUNDA':
      return DiaSemana.segunda;
    case 'TERCA':
      return DiaSemana.terca;
    case 'QUARTA':
      return DiaSemana.quarta;
    case 'QUINTA':
      return DiaSemana.quinta;
    case 'SEXTA':
      return DiaSemana.sexta;
    case 'SABADO':
      return DiaSemana.sabado;
    default:
      return DiaSemana.domingo;
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
