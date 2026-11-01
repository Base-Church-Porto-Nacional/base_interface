import '../models/models.dart';
import 'permissions.dart';

/// Fail-closed: se a rota não for reconhecida como pública para o papel, bloqueia.
bool canAccessPath(AuthUser? user, String path) {
  if (user == null) return false;

  if (path == '/dashboard' || path == '/perfil') {
    return hasPermission(user.roles, 'dashboard:view') || isPastorOuAdmin(user);
  }
  if (path == '/login' || path == '/acesso-negado') return true;

  if (path.startsWith('/igrejas')) {
    return hasPermission(user.roles, 'igrejas:manage') || isPastorOuAdmin(user);
  }
  if (path.startsWith('/usuarios')) {
    return hasPermission(user.roles, 'usuarios:view') || isPastorOuAdmin(user);
  }

  if (path.startsWith('/membros/pessoa/')) {
    final id = path.substring('/membros/pessoa/'.length).split('/').first;
    return hasPermission(user.roles, 'pessoas:view') ||
        isPastorOuAdmin(user) ||
        (hasPermission(user.roles, 'pessoas:own') && user.pessoaId == id);
  }
  if (path.startsWith('/membros/pessoas')) {
    return hasPermission(user.roles, 'pessoas:view') || isPastorOuAdmin(user);
  }
  if (path == '/membros' || path.startsWith('/membros/')) {
    return hasPermission(user.roles, 'membros:view') || isPastorOuAdmin(user);
  }

  if (path.startsWith('/pequenos-grupos')) {
    return hasPermission(user.roles, 'small_groups:view') || isPastorOuAdmin(user);
  }

  if (path.startsWith('/voluntariado/escalas/nova')) {
    return _podeAbrirCriacaoEscala(user);
  }
  if (path.startsWith('/voluntariado/escalas')) {
    return hasPermission(user.roles, 'escalas:view') ||
        hasPermission(user.roles, 'escalas:manage_own') ||
        isPastorOuAdmin(user);
  }
  if (path.startsWith('/voluntariado/ministerios')) {
    return hasPermission(user.roles, 'ministerios:view') || isPastorOuAdmin(user);
  }
  if (path.startsWith('/voluntariado/relatorios')) {
    return hasPermission(user.roles, 'relatorios:view') || isPastorOuAdmin(user);
  }
  if (path.startsWith('/voluntariado')) {
    return hasPermission(user.roles, 'voluntarios:view') || isPastorOuAdmin(user);
  }

  if (path.startsWith('/cultos/mes') ||
      path.startsWith('/cultos/categorias') ||
      path.startsWith('/cultos/culto/') ||
      path.startsWith('/cultos/conteudo')) {
    return hasPermission(user.roles, 'culto:view') || isPastorOuAdmin(user);
  }
  if (path.startsWith('/cultos')) {
    return hasPermission(user.roles, 'cronograma:view') || isPastorOuAdmin(user);
  }

  if (path.startsWith('/meu-servico')) {
    return hasPermission(user.roles, 'meu_servico:view') || isPastorOuAdmin(user);
  }
  if (path.startsWith('/perfil/disponibilidade')) {
    return hasPermission(user.roles, 'disponibilidade:view') || isPastorOuAdmin(user);
  }

  if (path == '/aniversariantes/envios') {
    return isPastorOuAdmin(user);
  }
  if (path.startsWith('/aniversariantes')) {
    return podeVerAniversarios(user);
  }

  if (path.startsWith('/configuracoes')) {
    return hasPermission(user.roles, 'mensagens:manage') || isPastorOuAdmin(user);
  }

  return false;
}

bool _podeAbrirCriacaoEscala(AuthUser user) {
  if (isPastorOuAdmin(user)) return true;
  if (hasPermission(user.roles, 'escalas:manage_own')) return true;
  // Supervisor não é papel: voluntário pode abrir o form; a tela recusa se não puder criar.
  return user.roles.contains(Role.voluntario) || user.roles.contains(Role.lider);
}

bool canMutatePessoas(AuthUser? user) {
  if (user == null) return false;
  return hasPermission(user.roles, 'pessoas:create') ||
      hasPermission(user.roles, 'pessoas:edit') ||
      isPastorOuAdmin(user);
}

bool canCreateMinisterio(AuthUser? user) {
  if (user == null) return false;
  return hasPermission(user.roles, 'ministerios:create') || isPastorOuAdmin(user);
}

bool canCreateBaseMinisterial(AuthUser? user) {
  if (user == null) return false;
  return isPastorOuAdmin(user);
}

bool canCreateUsuario(AuthUser? user) {
  if (user == null) return false;
  return hasPermission(user.roles, 'usuarios:create') || isPastorOuAdmin(user);
}

bool canCreateCronograma(AuthUser? user) {
  if (user == null) return false;
  return hasPermission(user.roles, 'cronograma:create') || isPastorOuAdmin(user);
}

bool canEditMensagemAniversario(AuthUser? user) {
  if (user == null) return false;
  return hasPermission(user.roles, 'mensagens:manage') || isPastorOuAdmin(user);
}
