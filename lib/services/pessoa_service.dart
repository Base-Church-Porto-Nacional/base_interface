import '../models/models.dart';
import '../utils/paginacao.dart';
import '../utils/pessoa_filtro.dart';
import 'api_client.dart';

class PessoaService {
  PessoaService(this._api);

  final ApiClient _api;

  Future<PageResponse<Pessoa>> list({
    int page = 0,
    int size = 20,
    String search = '',
    String filtro = 'TODOS',
    String? igrejaId,
  }) async {
    final mapped = filtrar(
      await listarTodas(igrejaId: igrejaId),
      search: search,
      filtro: filtro,
    );
    return paginate(mapped, page: page, size: size);
  }

  /// Busca (nome, e-mail, telefone) e filtro de tipo sobre uma lista já carregada.
  static List<Pessoa> filtrar(
    List<Pessoa> pessoas, {
    String search = '',
    String filtro = 'TODOS',
  }) {
    var mapped = pessoas;
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      mapped = mapped
          .where(
            (p) =>
                p.nome.toLowerCase().contains(q) ||
                p.email.toLowerCase().contains(q) ||
                p.telefone.contains(q),
          )
          .toList();
    }
    if (filtro != 'TODOS') {
      mapped = mapped.where((p) => pessoaMatchesFiltro(p, filtro)).toList();
    }
    return mapped;
  }

  /// Todas as pessoas visíveis (da igreja informada ou de toda a rede do
  /// usuário), sem paginação — para seletores com busca.
  Future<List<Pessoa>> listarTodas({String? igrejaId}) async {
    final query = igrejaId == null ? null : {'igrejaId': igrejaId};
    final list = await _api.get('/pessoas', query: query) as List<dynamic>;
    return list.map((e) => _mapPessoa(e as Map<String, dynamic>)).toList();
  }

  /// Busca leve por nome (mín. 2 caracteres, máx. 20 resultados no servidor).
  Future<List<PessoaResumo>> buscarPorNome(String termo) async {
    final list = await _api.get('/pessoas/busca', query: {'nome': termo.trim()})
        as List<dynamic>;
    return list
        .map(
          (e) => PessoaResumo(
            id: (e as Map<String, dynamic>)['id'] as String,
            nome: e['nome'] as String,
          ),
        )
        .toList();
  }

  Future<List<JornadaEtapa>> jornada(String pessoaId) async {
    final respostas = await Future.wait([
      _api.get('/pessoas/$pessoaId/jornada'),
      _api.get('/pessoas/$pessoaId/jornada/etapas'),
    ]);
    final j = respostas[0] as Map<String, dynamic>;
    final extras = (respostas[1] as List<dynamic>).cast<Map<String, dynamic>>();
    final registros = <(String, String, bool, String?)>[
      ('principal-aceitou', 'Aceitou Jesus', j['aceitouJesus'] == true, j['dataAceitouJesus'] as String?),
      ('principal-batismo', 'Batismo', j['batizado'] == true, j['dataBatismo'] as String?),
      (
        'principal-trilha',
        'Trilha da Base',
        j['concluiuTrilhaBase'] == true,
        j['dataConclusaoTrilhaBase'] as String?,
      ),
      ('principal-membro', 'Membro', j['membro'] == true, j['dataMembro'] as String?),
      for (final e in extras)
        (
          e['id'] as String,
          e['etapaNome'] as String? ?? 'Etapa',
          e['concluida'] == true,
          e['dataConclusao'] as String?,
        ),
    ];
    final atual = registros.indexWhere((r) => !r.$3);
    return [
      for (final (i, (id, titulo, concluida, data)) in registros.indexed)
        JornadaEtapa(
          id: id,
          titulo: titulo,
          data: data,
          status: concluida
              ? JornadaEtapaStatus.concluido
              : i == atual
                  ? JornadaEtapaStatus.atual
                  : JornadaEtapaStatus.pendente,
        ),
    ];
  }

  Future<Pessoa> getById(String id) async {
    final json = await _api.get('/pessoas/$id') as Map<String, dynamic>;
    return _mapPessoa(json);
  }

  Future<Pessoa> create({
    required String nome,
    String? telefone,
    String? email,
    String? whatsapp,
    String? igrejaId,
    String? servicoId,
  }) async {
    final wa = _whatsappNormalizado(whatsapp);
    final json = await _api.post('/pessoas', body: {
      'nome': nome,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (wa != null) 'whatsapp': wa,
      if (igrejaId != null) 'igrejaId': igrejaId,
      if (servicoId != null) 'servicoId': servicoId,
    }) as Map<String, dynamic>;
    return _mapPessoa(json);
  }

  /// PUT parcial: só envia os campos que o formulário edita. Campo ausente não
  /// é alterado no servidor; texto vazio limpa o campo.
  Future<Pessoa> update(
    String id, {
    String? nome,
    String? telefone,
    String? email,
    String? whatsapp,
  }) async {
    final json = await _api.put('/pessoas/$id', {
      'nome': ?nome,
      if (telefone != null) 'telefone': telefone.trim(),
      if (email != null) 'email': email.trim(),
      if (whatsapp != null) 'whatsapp': whatsapp.trim(),
    }) as Map<String, dynamic>;
    return _mapPessoa(json);
  }

  /// O banco guarda a string como o usuário digitou. Vazio vira null para
  /// signify "não recebe mensagem".
  String? _whatsappNormalizado(String? valor) {
    final texto = valor?.trim() ?? '';
    return texto.isEmpty ? null : texto;
  }

  Future<List<PessoaHistorico>> listHistorico(String pessoaId) async {
    final list = await _api.get('/pessoas/$pessoaId/historico') as List<dynamic>;
    return list
        .map(
          (e) => PessoaHistorico(
            id: e['id'] as String,
            pessoaId: e['pessoaId'] as String,
            descricao: e['descricao'] as String,
            autorNome: e['autorNome'] as String,
            autorCargo: e['autorCargo'] as String?,
            dataRegistro: e['dataRegistro'] as String,
          ),
        )
        .toList();
  }

  Pessoa _mapPessoa(Map<String, dynamic> json) {
    final papeis = (json['papeis'] as List<dynamic>? ?? const [])
        .map((r) => r as String)
        .toList();
    final funcoes = (json['funcoes'] as List<dynamic>? ?? const [])
        .map((r) => r as String)
        .toList();
    return Pessoa(
      id: json['id'] as String,
      nome: json['nome'] as String,
      telefone: json['telefone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      status: (json['ativo'] as bool? ?? true)
          ? PessoaStatus.ativo
          : PessoaStatus.inativo,
      tipos: pessoaTiposDeFuncoes(funcoes),
      ministerios: const [],
      dataCadastro: json['dataCadastro'] as String? ?? '',
      igrejaId: json['igrejaId'] as String? ?? '',
      usuarioId: json['usuarioId'] as String?,
      acessoStatus: json['acessoStatus'] as String?,
      papeis: papeis,
      aceitouJesus: json['aceitouJesus'] == true,
      batizado: json['batizado'] == true,
      concluiuTrilhaBase: json['concluiuTrilhaBase'] == true,
    );
  }
}
