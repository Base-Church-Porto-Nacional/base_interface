import 'package:base_church/mocks/mock_data.dart';
import 'package:base_church/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os serviços em modo mock mutam listas globais de `mock_data.dart`.
/// Capture com [MockState.capture] em `setUp` e restaure em `tearDown`.
class MockState {
  MockState()
    : cultos = List<Culto>.of(mockCultos),
      cultosConteudos = List<CultoConteudo>.of(mockCultosConteudos),
      cultosRelatorios = List<CultoRelatorio>.of(mockCultosRelatorios),
      categoriasCulto = List<CategoriaCulto>.of(mockCategoriasCulto),
      escalas = List<Escala>.of(mockEscalas),
      eventos = List<CultoEvento>.of(mockEventos),
      conteudosCulto = List<ConteudoCulto>.of(mockConteudosCulto),
      disponibilidades = Map<String, DisponibilidadePessoa>.of(
        mockDisponibilidades,
      ),
      mensagensAniversario = Map<String, MensagemAniversario>.of(
        mockMensagensAniversario,
      );

  MockState.capture() : this();

  final List<Culto> cultos;
  final List<CultoConteudo> cultosConteudos;
  final List<CultoRelatorio> cultosRelatorios;
  final List<CategoriaCulto> categoriasCulto;
  final List<Escala> escalas;
  final List<CultoEvento> eventos;
  final List<ConteudoCulto> conteudosCulto;
  final Map<String, DisponibilidadePessoa> disponibilidades;
  final Map<String, MensagemAniversario> mensagensAniversario;

  void restore() {
    _reset(mockCultos, cultos);
    _reset(mockCultosConteudos, cultosConteudos);
    _reset(mockCultosRelatorios, cultosRelatorios);
    _reset(mockCategoriasCulto, categoriasCulto);
    _reset(mockEscalas, escalas);
    _reset(mockEventos, eventos);
    _reset(mockConteudosCulto, conteudosCulto);
    mockDisponibilidades
      ..clear()
      ..addAll(disponibilidades);
    mockMensagensAniversario
      ..clear()
      ..addAll(mensagensAniversario);
  }
}

void _reset<T>(List<T> target, List<T> snapshot) {
  target
    ..clear()
    ..addAll(snapshot);
}

Matcher throwsWithMessage(String message) => throwsA(
  predicate<Object>(
    (e) => e.toString().contains(message),
    'Exception contendo "$message"',
  ),
);