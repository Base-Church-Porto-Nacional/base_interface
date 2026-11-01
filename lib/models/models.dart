enum Role { admin, pastor, lider, voluntario, membro, contador }

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

  factory Igreja.fromJson(Map<String, dynamic> json) {
    return Igreja(
      id: json['id'] as String,
      nome: json['nome'] as String,
      tipo: igrejaTipoFromString(json['tipo'] as String?),
      pastorPessoaId: json['pastorPessoaId'] as String? ?? '',
      pastorNome: json['pastorNome'] as String? ?? '',
      adminUsuarioId: json['adminUsuarioId'] as String? ?? '',
      adminNome: json['adminNome'] as String? ?? '',
      ativo: json['ativo'] as bool? ?? true,
      igrejaMatrizId: json['igrejaMatrizId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': _enumToApi(tipo),
        'pastorPessoaId': pastorPessoaId,
        'pastorNome': pastorNome,
        'adminUsuarioId': adminUsuarioId,
        'adminNome': adminNome,
        'ativo': ativo,
        'igrejaMatrizId': igrejaMatrizId,
      };
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
          .map((r) => roleFromString(r as String))
          .toList(),
      pessoaId: json['pessoaId'] as String?,
      igrejaId: json['igrejaId'] as String? ?? '',
      igrejaTipo: igrejaTipoFromString(json['igrejaTipo'] as String?),
      igrejaNome: json['igrejaNome'] as String? ?? '',
      igrejasVisiveis: (json['igrejasVisiveis'] as List<dynamic>? ?? [])
          .map((e) => Igreja.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'roles': roles.map(roleToString).toList(),
        'pessoaId': pessoaId,
        'igrejaId': igrejaId,
        'igrejaTipo': _enumToApi(igrejaTipo),
        'igrejaNome': igrejaNome,
        'igrejasVisiveis': igrejasVisiveis.map((i) => i.toJson()).toList(),
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
    this.whatsapp = '',
    this.aceitouJesus = false,
    this.batizado = false,
    this.concluiuTrilhaBase = false,
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

  /// Guardado exatamente como o usuário digitou, com máscara. Vazio significa
  /// que a pessoa não recebe mensagem de aniversário.
  final String whatsapp;
  final bool aceitouJesus;
  final bool batizado;
  final bool concluiuTrilhaBase;
  final String igrejaId;
  final String? usuarioId;
  final List<Role> papeis;

  bool get temUsuario => usuarioId != null && usuarioId!.isNotEmpty;

  bool get temWhatsapp => whatsapp.trim().isNotEmpty;
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
      case Role.contador:
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

/// Texto padrão do parabéns de aniversário. O back-end resolve as variáveis
/// por membro e decide quem recebe e quando: aqui só existe o molde.
class MensagemAniversario {
  const MensagemAniversario({
    required this.igrejaId,
    required this.mensagem,
    this.id,
  });

  final String? id;
  final String igrejaId;
  final String mensagem;

  MensagemAniversario copyWith({String? mensagem}) {
    return MensagemAniversario(
      id: id,
      igrejaId: igrejaId,
      mensagem: mensagem ?? this.mensagem,
    );
  }
}

/// Aniversariante do dia. `enviado` já vem resolvido pelo back-end, inclusive
/// para falhas: quem falhou continua com `envido == false` e mantém o reenvio.
class Aniversariante {
  const Aniversariante({
    required this.pessoaId,
    required this.nome,
    required this.dataNascimento,
    required this.idade,
    required this.mensagem,
    required this.enviado,
  });

  final String pessoaId;
  final String nome;
  final String dataNascimento;
  final int idade;
  final String mensagem;
  final bool enviado;
}

/// Resumo do POST /aniversarios/enviar.
class EnvioAniversarioResumo {
  const EnvioAniversarioResumo({
    required this.data,
    required this.enviados,
    required this.enfileirados,
    required this.ignorados,
    required this.falhas,
  });

  final String data;
  final int enviados;
  final int enfileirados;
  final int ignorados;
  final int falhas;

  /// Com Rabbit habilitado o envio responde enfileirado: quem está com
  /// `enfileirados > 0` ainda não tem resultado definitivo.
  bool get temPendencia => enfileirados > 0;

  String get resumo =>
      'Aniversariantes de $data: $enviados enviados, $enfileirados enfileirados, '
      '$ignorados ignorados, $falhas falhas.';
}

/// Status de um envio individual, conforme gravado pelo back-end.
enum AniversarioEnvioStatus { pendente, enviado, falha }

class AniversarioEnvio {
  const AniversarioEnvio({
    required this.id,
    required this.pessoaId,
    required this.igrejaId,
    required this.dataAniversario,
    required this.dataProcessamento,
    required this.mensagem,
    required this.status,
    this.erro,
  });

  final String id;
  final String pessoaId;
  final String igrejaId;
  final String dataAniversario;
  final String dataProcessamento;
  final String mensagem;
  final AniversarioEnvioStatus status;

  /// Mensagem do canal. É o que o front mostra como causa da falha.
  final String? erro;
}

/// Placeholder de personalização disponível na mensagem de aniversário.
class MensagemVariavel {
  const MensagemVariavel({
    required this.chave,
    required this.rotulo,
    required this.exemplo,
  });

  final String chave;
  final String rotulo;
  final String exemplo;

  String get placeholder => '[$chave]';
}

const mensagemAniversarioVariaveis = [
  MensagemVariavel(
    chave: 'Nome',
    rotulo: 'Nome do membro',
    exemplo: 'Gustavo',
  ),
  MensagemVariavel(
    chave: 'Nome Completo',
    rotulo: 'Nome completo do membro',
    exemplo: 'Gustavo Antunes',
  ),
  MensagemVariavel(
    chave: 'Igreja',
    rotulo: 'Nome da igreja',
    exemplo: 'Base Church',
  ),
];

bool mensagemUsaVariavel(String mensagem, String chave) =>
    mensagem.contains('[$chave]');

/// Substitui os placeholders conhecidos. Placeholders desconhecidos ficam como
/// estão, para o back-end resolver o que o front-end ainda não conhece.
String formatarMensagemAniversario(
  String mensagem, {
  Map<String, String> valores = const {},
}) {
  var resultado = mensagem;
  for (final variavel in mensagemAniversarioVariaveis) {
    resultado = resultado.replaceAll(
      variavel.placeholder,
      valores[variavel.chave] ?? variavel.exemplo,
    );
  }
  return resultado;
}

class DashboardStats {
  const DashboardStats({
    required this.totalPessoas,
    required this.totalMembros,
    required this.totalVoluntarios,
    required this.totalLideres,
    this.escalasPendentes,
    this.visitantesRecentes,
    this.proximasEscalas,
    this.jornada,
  });

  final int totalPessoas;
  final int totalMembros;
  final int totalVoluntarios;
  final int totalLideres;
  final int? escalasPendentes;
  final int? visitantesRecentes;
  final List<EscalaResumo>? proximasEscalas;
  final JornadaIndicadores? jornada;
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

String _enumToApi(Enum value) => value.name
    .replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}')
    .toUpperCase();

T _enumFromApi<T extends Enum>(List<T> values, String? value, T fallback) {
  final upper = value?.toUpperCase();
  return values.firstWhere((e) => _enumToApi(e) == upper, orElse: () => fallback);
}

IgrejaTipo igrejaTipoFromString(String? value) =>
    _enumFromApi(IgrejaTipo.values, value, IgrejaTipo.filial);

String pessoaStatusLabel(PessoaStatus status) =>
    status == PessoaStatus.ativo ? 'ATIVO' : 'INATIVO';

String igrejaTipoLabel(IgrejaTipo tipo) => switch (tipo) {
      IgrejaTipo.matriz => 'Matriz',
      IgrejaTipo.filial => 'Filial',
    };

String ministerioTipoLabel(MinisterioTipo tipo) => switch (tipo) {
      MinisterioTipo.musica => 'Música',
      MinisterioTipo.midia => 'Mídia',
      MinisterioTipo.geral => 'Geral',
    };

String escalaTipoLabel(EscalaTipo tipo) => switch (tipo) {
      EscalaTipo.supervisor => 'Supervisor',
      EscalaTipo.pregador => 'Pregador',
      EscalaTipo.culto => 'Culto',
      EscalaTipo.ministerio => 'Ministério',
    };

String tipoEventoLabel(TipoEvento tipo) => switch (tipo) {
      TipoEvento.culto => 'Culto',
      TipoEvento.evento => 'Evento',
      TipoEvento.ensaio => 'Ensaio',
      TipoEvento.reuniao => 'Reunião',
      TipoEvento.outro => 'Outro',
    };

String diaSemanaLabel(DiaSemana dia) => switch (dia) {
      DiaSemana.domingo => 'Domingo',
      DiaSemana.segunda => 'Segunda',
      DiaSemana.terca => 'Terça',
      DiaSemana.quarta => 'Quarta',
      DiaSemana.quinta => 'Quinta',
      DiaSemana.sexta => 'Sexta',
      DiaSemana.sabado => 'Sábado',
    };

String diaSemanaApiToString(DiaSemana dia) => _enumToApi(dia);

DiaSemana diaSemanaFromApi(String value) =>
    _enumFromApi(DiaSemana.values, value, DiaSemana.domingo);

String cultoStatusLabel(CultoStatus status) => switch (status) {
      CultoStatus.agendado => 'Agendado',
      CultoStatus.aberto => 'Aberto',
      CultoStatus.realizado => 'Realizado',
      CultoStatus.cancelado => 'Cancelado',
    };

String cultoStatusApiToString(CultoStatus status) => _enumToApi(status);

CultoStatus cultoStatusFromApi(String value) =>
    _enumFromApi(CultoStatus.values, value, CultoStatus.agendado);

String roleLabel(Role role) => switch (role) {
      Role.admin => 'Admin',
      Role.pastor => 'Pastor',
      Role.lider => 'Líder',
      Role.voluntario => 'Voluntário',
      Role.membro => 'Membro',
      Role.contador => 'Contador',
    };

Role roleFromString(String value) => _enumFromApi(Role.values, value, Role.membro);

String roleToString(Role role) => _enumToApi(role);

MinisterioTipo ministerioTipoFromString(String value) =>
    _enumFromApi(MinisterioTipo.values, value, MinisterioTipo.geral);

String ministerioTipoToString(MinisterioTipo tipo) => _enumToApi(tipo);

EscalaTipo escalaTipoFromString(String value) =>
    _enumFromApi(EscalaTipo.values, value, EscalaTipo.ministerio);

String escalaTipoToString(EscalaTipo tipo) => _enumToApi(tipo);

String escalaStatusLabel(EscalaStatus status) => switch (status) {
      EscalaStatus.sugerida => 'Sugerida',
      EscalaStatus.editando => 'Editando',
      EscalaStatus.emAndamento => 'Em andamento',
      EscalaStatus.finalizada => 'Finalizada',
    };

EscalaStatus escalaStatusFromString(String value) =>
    _enumFromApi(EscalaStatus.values, value, EscalaStatus.editando);

String escalaStatusToString(EscalaStatus status) => _enumToApi(status);

bool podeTransicionarEscalaStatus(EscalaStatus de, EscalaStatus para) => switch (de) {
      EscalaStatus.sugerida =>
        para == EscalaStatus.editando || para == EscalaStatus.emAndamento,
      EscalaStatus.editando =>
        para == EscalaStatus.sugerida || para == EscalaStatus.emAndamento,
      EscalaStatus.emAndamento =>
        para == EscalaStatus.editando || para == EscalaStatus.finalizada,
      EscalaStatus.finalizada => para == EscalaStatus.emAndamento,
    };

String escalaItemStatusLabel(EscalaItemStatus status) => switch (status) {
      EscalaItemStatus.pendente => 'Pendente',
      EscalaItemStatus.confirmado => 'Confirmado',
      EscalaItemStatus.recusado => 'Recusado',
      EscalaItemStatus.substituido => 'Substituído',
    };

EscalaItemStatus escalaItemStatusFromString(String value) {
  if (value.toUpperCase() == 'SUBSTITUÍDO') return EscalaItemStatus.substituido;
  return _enumFromApi(EscalaItemStatus.values, value, EscalaItemStatus.pendente);
}

String escalaItemStatusToString(EscalaItemStatus status) => _enumToApi(status);

AniversarioEnvioStatus aniversarioEnvioStatusFromString(String value) =>
    _enumFromApi(AniversarioEnvioStatus.values, value, AniversarioEnvioStatus.pendente);

String aniversarioEnvioStatusLabel(AniversarioEnvioStatus status) => switch (status) {
      AniversarioEnvioStatus.pendente => 'PENDENTE',
      AniversarioEnvioStatus.enviado => 'ENVIADO',
      AniversarioEnvioStatus.falha => 'FALHA',
    };

TipoEvento tipoEventoFromString(String value) =>
    _enumFromApi(TipoEvento.values, value, TipoEvento.outro);

String tipoEventoToString(TipoEvento tipo) => _enumToApi(tipo);
