import '../models/models.dart';

const _rolePermissions = <Role, List<String>>{
  Role.admin: ['*'],
  Role.pastor: ['*'],
  Role.lider: [
    'dashboard:view',
    'pessoas:view',
    'ministerios:view',
    'ministerios:manage_own',
    'voluntarios:view',
    'escalas:view',
    'escalas:manage_own',
    'disponibilidade:view',
    'cronograma:view',
    'culto:view',
    'culto:louvor',
    'meu_servico:view',
  ],
  Role.voluntario: [
    'dashboard:view',
    'escalas:own',
    'disponibilidade:*',
    'pessoas:own',
    'cronograma:view',
    'culto:view',
    'meu_servico:view',
  ],
  Role.membro: [
    'dashboard:view',
    'pessoas:own',
    'cronograma:view',
    'escalas:own',
    'disponibilidade:*',
    'culto:view',
    'meu_servico:view',
  ],
};

bool hasPermission(List<Role> roles, String permission) {
  if (roles.isEmpty) return false;
  for (final role in roles) {
    final allowed = _rolePermissions[role] ?? [];
    if (allowed.contains('*')) return true;
    if (allowed.contains(permission)) return true;
    final resource = permission.split(':').first;
    if (allowed.contains('$resource:*')) return true;
  }
  return false;
}

bool isPastorOuAdmin(AuthUser? user) {
  if (user == null) return false;
  return user.roles.contains(Role.admin) || user.roles.contains(Role.pastor);
}

bool isLiderDoMinisterio(AuthUser? user, Ministerio ministerio) {
  if (user?.pessoaId == null) return false;
  return ministerio.liderPessoaId == user!.pessoaId;
}

bool isCoordenadorDoMinisterio(AuthUser? user, Ministerio ministerio) {
  if (user?.pessoaId == null) return false;
  return ministerio.coordenadorPessoaId == user!.pessoaId;
}

bool podeGerenciarMinisterio(AuthUser? user, Ministerio ministerio) {
  if (user == null) return false;
  if (isPastorOuAdmin(user)) return true;
  return isLiderDoMinisterio(user, ministerio) ||
      isCoordenadorDoMinisterio(user, ministerio);
}

bool pertenceAoMinisterioTipo(AuthUser? user, List<Ministerio> ministerios, MinisterioTipo tipo) {
  if (user?.pessoaId == null) return false;
  return ministerios.any(
    (m) =>
        m.tipo == tipo &&
        (m.liderPessoaId == user!.pessoaId ||
            m.coordenadorPessoaId == user.pessoaId),
  );
}

bool isSupervisorNoMes({
  required AuthUser? user,
  required List<Escala> escalas,
  required String competencia,
  required String igrejaId,
}) {
  if (user?.pessoaId == null) return false;
  if (isPastorOuAdmin(user)) return true;
  return escalas.any(
    (e) =>
        e.tipo == EscalaTipo.supervisor &&
        e.competencia == competencia &&
        e.igrejaId == igrejaId &&
        e.itens.any((i) => i.pessoaId == user!.pessoaId),
  );
}

/// Pastor/admin: qualquer tipo. Supervisor do mês: culto e ministério.
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
  if (isPastorOuAdmin(user)) return true;

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
  if (user.roles.contains(Role.pastor) || user.roles.contains(Role.admin)) {
    return true;
  }
  return pregadorPessoaId != null && pregadorPessoaId == user.pessoaId;
}

bool podeEditarLouvor(AuthUser? user, List<Ministerio> ministerios) {
  if (user == null) return false;
  if (isPastorOuAdmin(user)) return true;
  return pertenceAoMinisterioTipo(user, ministerios, MinisterioTipo.musica);
}

bool podeVerConteudoMidia(AuthUser? user, List<Ministerio> ministerios) {
  if (user == null) return false;
  if (isPastorOuAdmin(user)) return true;
  return pertenceAoMinisterioTipo(user, ministerios, MinisterioTipo.midia);
}

bool soLeituraConteudoCulto(AuthUser? user, List<Ministerio> ministerios) {
  if (podeEditarTextoCulto(user) || podeEditarLouvor(user, ministerios)) {
    return false;
  }
  return podeVerConteudoMidia(user, ministerios);
}
