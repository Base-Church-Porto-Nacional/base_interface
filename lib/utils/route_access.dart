import '../models/models.dart';
import 'permissions.dart';

bool _temCap(AuthUser? user, Capacidade c) => user?.permissoes.tem(c) ?? false;

bool _veTodasOuLidera(AuthUser user) =>
    isGestao(user) || user.permissoes.lideraAlgo;

bool _acessaVoluntariado(AuthUser user) =>
    _veTodasOuLidera(user) ||
    user.permissoes.ehVoluntario ||
    user.permissoes.tem(Capacidade.escalasGerir);

/// Fail-closed: se a rota não for reconhecida, bloqueia. As decisões vêm das
/// permissões calculadas pelo servidor (`GET /api/me`).
bool canAccessPath(AuthUser? user, String path) {
  if (user == null) return false;

  if (path == '/login' || path == '/acesso-negado') return true;
  if (path == '/dashboard' || path == '/perfil') return true;

  if (path.startsWith('/igrejas')) {
    return _temCap(user, Capacidade.filialCriar) || isGestao(user);
  }
  if (path.startsWith('/usuarios')) {
    return _temCap(user, Capacidade.contasGerir);
  }

  if (path.startsWith('/membros/pessoa/')) {
    final id = path.substring('/membros/pessoa/'.length).split('/').first;
    return _veTodasOuLidera(user) || user.pessoaId == id;
  }
  if (path == '/membros' || path.startsWith('/membros/')) {
    return _veTodasOuLidera(user);
  }

  if (path.startsWith('/pequenos-grupos')) return _veTodasOuLidera(user);

  if (path.startsWith('/voluntariado/relatorios')) {
    return _temCap(user, Capacidade.relatoriosVer);
  }
  if (path.startsWith('/voluntariado')) return _acessaVoluntariado(user);

  if (path.startsWith('/cultos')) return true;

  if (path.startsWith('/meu-servico') ||
      path.startsWith('/perfil/disponibilidade')) {
    return true;
  }

  if (path == '/aniversariantes/envios') {
    return _temCap(user, Capacidade.configurar);
  }
  if (path.startsWith('/aniversariantes')) return podeVerAniversarios(user);

  if (path.startsWith('/configuracoes')) {
    return _temCap(user, Capacidade.configurar);
  }

  return false;
}

bool canMutatePessoas(AuthUser? user) => _temCap(user, Capacidade.pessoasGerir);

bool canCreateMinisterio(AuthUser? user) =>
    _temCap(user, Capacidade.ministeriosGerir);

bool canCreateBaseMinisterial(AuthUser? user) =>
    _temCap(user, Capacidade.ministeriosGerir);

bool canCreateUsuario(AuthUser? user) => _temCap(user, Capacidade.contasGerir);

bool canCreateCronograma(AuthUser? user) => isGestao(user);

bool canEditMensagemAniversario(AuthUser? user) =>
    _temCap(user, Capacidade.configurar);
