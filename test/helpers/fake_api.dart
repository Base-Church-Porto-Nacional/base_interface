import 'dart:convert';

import 'package:base_church/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Rota = (int, Object?) Function(http.Request request);

class FakeApi {
  FakeApi(this._rotas);

  final Map<String, Rota> _rotas;
  final chamadas = <http.Request>[];

  List<String> get log => chamadas
      .map((r) => '${r.method} ${r.url.path.replaceFirst('/api', '')}')
      .toList();

  Object? corpo(int i) => jsonDecode(chamadas[i].body);

  late final client = MockClient((request) async {
    chamadas.add(request);
    final path = request.url.path.replaceFirst('/api', '');
    final rota = _rotas['${request.method} $path'];
    if (rota == null) {
      return http.Response('{"message":"rota não simulada"}', 404);
    }
    final (status, body) = rota(request);
    return http.Response(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  Future<T> run<T>(Future<T> Function() call) =>
      http.runWithClient(call, () => client);
}

Future<ApiClient> apiClientDeTeste({String? token = 't'}) async {
  SharedPreferences.setMockInitialValues({'base_access_token': ?token});
  return ApiClient(await SharedPreferences.getInstance());
}
