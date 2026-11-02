import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/igreja_context.dart';
import 'router/app_router.dart';
import 'services/aniversario_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/base_ministerial_service.dart';
import 'services/categoria_culto_service.dart';
import 'services/conteudo_culto_service.dart';
import 'services/cronograma_service.dart';
import 'services/culto_service.dart';
import 'services/dashboard_service.dart';
import 'services/disponibilidade_service.dart';
import 'services/escala_service.dart';
import 'services/export_service.dart';
import 'services/igreja_service.dart';
import 'services/mensagem_aniversario_service.dart';
import 'services/ministerio_service.dart';
import 'services/pessoa_service.dart';
import 'services/small_group_service.dart';
import 'services/usuario_service.dart';
import 'theme/app_theme.dart';

class BaseChurchApp extends StatefulWidget {
  const BaseChurchApp({super.key});

  @override
  State<BaseChurchApp> createState() => _BaseChurchAppState();
}

class _BaseChurchAppState extends State<BaseChurchApp> {
  GoRouter? _router;
  List<SingleChildWidget>? _providers;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final api = ApiClient(prefs);
    final authService = AuthService(api, prefs);
    final pessoaService = PessoaService(api);
    final dashboardService = DashboardService(api, pessoaService);
    final igrejaService = IgrejaService(api);
    final authProvider = AuthProvider(authService);
    final igrejaContext = IgrejaContext(igrejaService, prefs);
    api.onUnauthorized = authProvider.expireSession;

    authProvider.addListener(() {
      igrejaContext.syncUser(authProvider.user);
    });
    await igrejaContext.syncUser(authProvider.user);

    if (!mounted) return;
    setState(() {
      _providers = [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: igrejaContext),
        Provider.value(value: authService),
        Provider.value(value: pessoaService),
        Provider.value(value: MinisterioService(api)),
        Provider.value(value: BaseMinisterialService(api)),
        Provider.value(value: dashboardService),
        Provider.value(value: ExportService(pessoaService, dashboardService)),
        Provider.value(value: igrejaService),
        Provider.value(value: UsuarioService(api)),
        Provider.value(value: EscalaService(api)),
        Provider.value(value: SmallGroupService(api)),
        Provider.value(value: CronogramaService(api)),
        Provider.value(value: DisponibilidadeService(api)),
        Provider.value(value: ConteudoCultoService(api)),
        Provider.value(value: CategoriaCultoService(api)),
        Provider.value(value: CultoService(api)),
        Provider.value(value: MensagemAniversarioService(api)),
        Provider.value(value: AniversarioService(api)),
      ];
      _router = createRouter(authProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    final providers = _providers;
    if (router == null || providers == null) {
      return MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: providers,
      child: MaterialApp.router(
        title: 'Base Church',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
