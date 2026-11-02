import '../models/models.dart';

bool _tem(AuthUser? user, Capacidade c) => user?.permissoes.tem(c) ?? false;

/// Gestão = enxerga todas as pessoas da igreja (pastor, secretaria...).
/// Substitui `isPastorOuAdmin`; a decisão vem do servidor.
bool isGestao(AuthUser? user) => _tem(user, Capacidade.pessoasVerTodas);

bool podeLancarContagem(AuthUser? user) => _tem(user, Capacidade.cultoContagem);

bool isLiderDoMinisterio(AuthUser? user, Ministerio ministerio) {
  if (user?.pessoaId == null) return false;
  return ministerio.liderPessoaId == user!.pessoaId;
}

bool isCoordenadorDoMinisterio(AuthUser? user, Ministerio ministerio) {
  if (user?.pessoaId == null) return false;
  return ministerio.coordenadorPessoaId == user!.pessoaId;
}

bool podeGerenciarMinisterio(
  AuthUser? user,
  Ministerio ministerio, {
  BaseMinisterial? base,
}) {
  if (user == null) return false;
  if (isGestao(user)) return true;
  if (user.permissoes.ministeriosLiderados.contains(ministerio.id)) return true;
  return base != null && podeGerenciarBaseMinisterial(user, base);
}

bool isLiderDaBase(AuthUser? user, BaseMinisterial base) {
  if (user?.pessoaId == null) return false;
  return base.liderPessoaId == user!.pessoaId;
}

bool isCoordenadorDaBase(AuthUser? user, BaseMinisterial base) {
  if (user?.pessoaId == null) return false;
  return base.coordenadorPessoaId == user!.pessoaId;
}

bool podeGerenciarBaseMinisterial(AuthUser? user, BaseMinisterial base) {
  if (user == null) return false;
  if (isGestao(user)) return true;
  return user.permissoes.basesLideradas.contains(base.id);
}

bool pertenceAoMinisterioTipo(
  AuthUser? user,
  List<Ministerio> ministerios,
  MinisterioTipo tipo,
) {
  if (user == null) return false;
  return ministerios.any(
    (m) =>
        m.tipo == tipo && user.permissoes.ministeriosLiderados.contains(m.id),
  );
}

bool isSupervisorNoMes({
  required AuthUser? user,
  required List<Escala> escalas,
  required String competencia,
  required String igrejaId,
}) {
  if (user?.pessoaId == null) return false;
  if (_tem(user, Capacidade.escalasGerir)) return true;
  return escalas.any(
    (e) =>
        e.tipo == EscalaTipo.supervisor &&
        e.competencia == competencia &&
        e.igrejaId == igrejaId &&
        (e.supervisorPessoaId == user!.pessoaId ||
            e.voluntarios.any((v) => v.pessoaId == user.pessoaId)),
  );
}

/// `escalasGerir`: qualquer tipo. Supervisor do mês: culto e ministério.
/// Líder/coordenador: só o próprio ministério.
bool podeCriarTipoEscala({
  required AuthUser? user,
  required EscalaTipo tipo,
  required List<Ministerio> ministerios,
  required List<Escala> escalas,
  required String competencia,
  required String igrejaId,
}) {
  if (user == null) return false;
  if (_tem(user, Capacidade.escalasGerir)) return true;

  final supervisor = isSupervisorNoMes(
    user: user,
    escalas: escalas,
    competencia: competencia,
    igrejaId: igrejaId,
  );

  switch (tipo) {
    case EscalaTipo.supervisor:
    case EscalaTipo.pregador:
      return false;
    case EscalaTipo.culto:
      return supervisor;
    case EscalaTipo.ministerio:
      return supervisor ||
          ministerios.any((m) => podeGerenciarMinisterio(user, m));
  }
}

bool podeEditarTextoCulto(AuthUser? user, {String? pregadorPessoaId}) {
  if (user == null) return false;
  if (_tem(user, Capacidade.cultoConteudoEditar)) return true;
  return pregadorPessoaId != null && pregadorPessoaId == user.pessoaId;
}

bool podeEditarLouvor(AuthUser? user, List<Ministerio> ministerios) {
  if (user == null) return false;
  if (_tem(user, Capacidade.cultoConteudoEditar)) return true;
  return pertenceAoMinisterioTipo(user, ministerios, MinisterioTipo.musica);
}

bool podeVerConteudoMidia(AuthUser? user, List<Ministerio> ministerios) {
  if (user == null) return false;
  if (_tem(user, Capacidade.cultoConteudoEditar)) return true;
  return pertenceAoMinisterioTipo(user, ministerios, MinisterioTipo.midia);
}

bool soLeituraConteudoCulto(AuthUser? user, List<Ministerio> ministerios) {
  if (podeEditarTextoCulto(user) || podeEditarLouvor(user, ministerios)) {
    return false;
  }
  return podeVerConteudoMidia(user, ministerios);
}

bool canCreateSmallGroup(AuthUser? user) => isGestao(user);

bool podeGerenciarSmallGroup(AuthUser? user, SmallGroup group) {
  if (user == null) return false;
  if (isGestao(user)) return true;
  if (user.permissoes.gruposLiderados.contains(group.id)) return true;
  final ministerioId = group.ministerioId;
  return ministerioId != null &&
      user.permissoes.ministeriosLiderados.contains(ministerioId);
}

bool podeReportarSmallGroup(AuthUser? user, SmallGroup group) =>
    podeGerenciarSmallGroup(user, group);

/// GET /aniversarios/aniversariantes é leitura e fica aberto a qualquer papel
/// logado. POST /aniversarios/enviar e GET /aniversarios/envios usam
/// exigem a capacidade `configurar` no back-end, então o front esconde o botão
/// e o histórico para quem não a tem.
bool podeVerAniversarios(AuthUser? user) => user != null;

bool podeEnviarAniversarios(AuthUser? user) =>
    _tem(user, Capacidade.configurar);
