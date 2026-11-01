import 'package:base_church/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Role', () {
    test('ida e volta com as siglas da API', () {
      const esperado = {
        Role.admin: 'ADMIN',
        Role.pastor: 'PASTOR',
        Role.lider: 'LIDER',
        Role.voluntario: 'VOLUNTARIO',
        Role.membro: 'MEMBRO',
        Role.contador: 'CONTADOR',
      };
      esperado.forEach((role, api) {
        expect(roleToString(role), api);
        expect(roleFromString(api), role);
        expect(roleFromString(api.toLowerCase()), role);
      });
    });

    test('valores desconhecidos viram membro', () {
      expect(roleFromString(''), Role.membro);
      expect(roleFromString('SUPERADMIN'), Role.membro);
    });

    test('rótulos', () {
      expect(Role.values.map(roleLabel).toList(), [
        'Admin',
        'Pastor',
        'Líder',
        'Voluntário',
        'Membro',
        'Contador',
      ]);
    });
  });

  group('MinisterioTipo', () {
    test('ida e volta, fallback geral e rótulos', () {
      expect(MinisterioTipo.values.map(ministerioTipoToString).toList(), [
        'GERAL',
        'MUSICA',
        'MIDIA',
      ]);
      for (final tipo in MinisterioTipo.values) {
        expect(ministerioTipoFromString(ministerioTipoToString(tipo)), tipo);
      }
      expect(ministerioTipoFromString('musica'), MinisterioTipo.musica);
      expect(ministerioTipoFromString('LOUVOR'), MinisterioTipo.geral);
      expect(MinisterioTipo.values.map(ministerioTipoLabel).toList(), [
        'Geral',
        'Música',
        'Mídia',
      ]);
    });
  });

  group('EscalaStatus', () {
    test('siglas da API, minúsculas e fallback', () {
      expect(EscalaStatus.values.map(escalaStatusToString).toList(), [
        'SUGERIDA',
        'EDITANDO',
        'EM_ANDAMENTO',
        'FINALIZADA',
      ]);
      expect(escalaStatusFromString('em_andamento'), EscalaStatus.emAndamento);
      expect(escalaStatusFromString('EMANDAMENTO'), EscalaStatus.editando);
      expect(escalaStatusFromString('finalizada'), EscalaStatus.finalizada);
      expect(escalaStatusLabel(EscalaStatus.editando), 'Editando');
    });
  });

  group('EscalaItemStatus', () {
    test('siglas, alias acentuado e rótulos', () {
      expect(EscalaItemStatus.values.map(escalaItemStatusToString).toList(), [
        'PENDENTE',
        'CONFIRMADO',
        'RECUSADO',
        'SUBSTITUIDO',
      ]);
      expect(escalaItemStatusFromString('substituído'), EscalaItemStatus.substituido);
      expect(escalaItemStatusFromString('confirmado'), EscalaItemStatus.confirmado);
      expect(escalaItemStatusFromString(''), EscalaItemStatus.pendente);
      expect(EscalaItemStatus.values.map(escalaItemStatusLabel).toList(), [
        'Pendente',
        'Confirmado',
        'Recusado',
        'Substituído',
      ]);
    });
  });

  group('AniversarioEnvioStatus', () {
    test('ida e volta e fallback pendente', () {
      for (final status in AniversarioEnvioStatus.values) {
        expect(
          aniversarioEnvioStatusFromString(aniversarioEnvioStatusLabel(status)),
          status,
        );
      }
      expect(AniversarioEnvioStatus.values.map(aniversarioEnvioStatusLabel).toList(), [
        'PENDENTE',
        'ENVIADO',
        'FALHA',
      ]);
      expect(aniversarioEnvioStatusFromString('enviado'), AniversarioEnvioStatus.enviado);
      expect(aniversarioEnvioStatusFromString('ERRO'), AniversarioEnvioStatus.pendente);
    });
  });

  group('DiaSemana', () {
    test('siglas da API e rótulos', () {
      expect(DiaSemana.values.map(diaSemanaApiToString).toList(), [
        'DOMINGO',
        'SEGUNDA',
        'TERCA',
        'QUARTA',
        'QUINTA',
        'SEXTA',
        'SABADO',
      ]);
      expect(diaSemanaFromApi('sexta'), DiaSemana.sexta);
      expect(diaSemanaFromApi('TERÇA'), DiaSemana.domingo);
      expect(DiaSemana.values.map(diaSemanaLabel).toList(), [
        'Domingo',
        'Segunda',
        'Terça',
        'Quarta',
        'Quinta',
        'Sexta',
        'Sábado',
      ]);
    });
  });

  group('rótulos simples', () {
    test('pessoaStatus, igrejaTipo, escalaTipo, cultoStatus', () {
      expect(pessoaStatusLabel(PessoaStatus.ativo), 'ATIVO');
      expect(pessoaStatusLabel(PessoaStatus.inativo), 'INATIVO');
      expect(igrejaTipoLabel(IgrejaTipo.matriz), 'Matriz');
      expect(igrejaTipoLabel(IgrejaTipo.filial), 'Filial');
      expect(escalaTipoLabel(EscalaTipo.pregador), 'Pregador');
      expect(cultoStatusLabel(CultoStatus.aberto), 'Aberto');
    });
  });

  group('AuthUser JSON', () {
    test('ida e volta preserva igrejas visíveis e papéis', () {
      final json = {
        'id': 'u1',
        'nome': 'Ana',
        'email': 'ana@x.com',
        'roles': ['PASTOR', 'contador', 'XPTO'],
        'pessoaId': 'p1',
        'igrejaId': 'i1',
        'igrejaTipo': 'matriz',
        'igrejaNome': 'Sede',
        'igrejasVisiveis': [
          {'id': 'i1', 'nome': 'Sede', 'tipo': 'MATRIZ'},
          {
            'id': 'i2',
            'nome': 'Filial',
            'tipo': 'FILIAL',
            'pastorPessoaId': 'p9',
            'pastorNome': 'Beto',
            'adminUsuarioId': 'u9',
            'adminNome': 'Carla',
            'ativo': false,
            'igrejaMatrizId': 'i1',
          },
        ],
      };
      final user = AuthUser.fromJson(json);
      expect(user.roles, [Role.pastor, Role.contador, Role.membro]);
      expect(user.isMatriz, isTrue);
      expect(user.igrejasVisiveis.first.isMatriz, isTrue);
      expect(user.igrejasVisiveis.first.ativo, isTrue);
      expect(user.igrejasVisiveis.first.pastorNome, '');
      expect(user.igrejasVisiveis.last.igrejaMatrizId, 'i1');
      expect(user.igrejasVisiveis.last.ativo, isFalse);

      final volta = AuthUser.fromJson(user.toJson());
      expect(volta.toJson(), user.toJson());
      expect(user.toJson()['roles'], ['PASTOR', 'CONTADOR', 'MEMBRO']);
      expect(user.toJson()['igrejaTipo'], 'MATRIZ');
      expect((user.toJson()['igrejasVisiveis'] as List).last, {
        'id': 'i2',
        'nome': 'Filial',
        'tipo': 'FILIAL',
        'pastorPessoaId': 'p9',
        'pastorNome': 'Beto',
        'adminUsuarioId': 'u9',
        'adminNome': 'Carla',
        'ativo': false,
        'igrejaMatrizId': 'i1',
      });
    });

    test('igrejaTipo ausente vira filial', () {
      final user = AuthUser.fromJson({
        'id': 'u1',
        'nome': 'Ana',
        'email': 'a',
        'roles': <String>[],
      });
      expect(user.igrejaTipo, IgrejaTipo.filial);
      expect(user.igrejaId, '');
      expect(user.igrejasVisiveis, isEmpty);
    });
  });
}
