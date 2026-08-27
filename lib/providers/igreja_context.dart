import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/igreja_service.dart';

class IgrejaContext extends ChangeNotifier {
  IgrejaContext(this._service, this._prefs);

  final IgrejaService _service;
  final SharedPreferences _prefs;

  static const _selectedKey = 'base_igreja_selecionada';

  List<Igreja> igrejas = [];
  String? selectedIgrejaId;
  bool loading = false;
  String? error;

  Igreja? get selected {
    final id = selectedIgrejaId;
    if (id == null) return null;
    for (final i in igrejas) {
      if (i.id == id) return i;
    }
    return null;
  }

  bool canSwitch(AuthUser? user) =>
      user != null && user.isMatriz && igrejas.length > 1;

  Future<void> syncUser(AuthUser? user) async {
    if (user == null) {
      igrejas = [];
      selectedIgrejaId = null;
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      igrejas = await _service.listVisiveis(user);
      if (user.isMatriz) {
        final stored = _prefs.getString(_selectedKey);
        final exists = stored != null && igrejas.any((i) => i.id == stored);
        selectedIgrejaId = exists ? stored : user.igrejaId;
      } else {
        selectedIgrejaId = user.igrejaId;
      }
    } catch (e) {
      error = e.toString();
      igrejas = user.igrejasVisiveis;
      selectedIgrejaId = user.igrejaId;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> select(String igrejaId) async {
    selectedIgrejaId = igrejaId;
    await _prefs.setString(_selectedKey, igrejaId);
    notifyListeners();
  }

  Future<void> reload(AuthUser? user) => syncUser(user);
}
