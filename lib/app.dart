import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'providers/igreja_context.dart';
import 'router/app_router.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/conteudo_culto_service.dart';
import 'services/cronograma_service.dart';
import 'services/dashboard_service.dart';
import 'services/disponibilidade_service.dart';
import 'services/escala_service.dart';
import 'services/export_service.dart';
import 'services/igreja_service.dart';
import 'services/ministerio_service.dart';
import 'services/pessoa_service.dart';
import 'services/usuario_service.dart';
import 'theme/app_theme.dart';

class BaseChurchApp extends StatefulWidget {
  const BaseChurchApp({super.key});

  @override
  State<BaseChurchApp> createState() => _BaseChurchAppState();
}

class _BaseChurchAppState extends State<BaseChurchApp> {
  AuthProvider? _authProvider;
  IgrejaContext? _igrejaContext;
  GoRouter? _router;
  AppServices? _services;

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
    final ministerioService = MinisterioService(api);
    final dashboardService = DashboardService();
    final exportService = ExportService(pessoaService, dashboardService);
    final igrejaService = IgrejaService(api);
    final usuarioService = UsuarioService(api);
    final escalaService = EscalaService(api);
    final cronogramaService = CronogramaService(api);
    final disponibilidadeService = DisponibilidadeService(api);
    final conteudoCultoService = ConteudoCultoService(api);
    final authProvider = AuthProvider(authService);
    final igrejaContext = IgrejaContext(igrejaService, prefs);

    authProvider.addListener(() {
      igrejaContext.syncUser(authProvider.user);
    });
    await igrejaContext.syncUser(authProvider.user);

    if (mounted) {
      setState(() {
        _services = AppServices(
          api: api,
          authService: authService,
          pessoaService: pessoaService,
          ministerioService: ministerioService,
          dashboardService: dashboardService,
          exportService: exportService,
          igrejaService: igrejaService,
          usuarioService: usuarioService,
          escalaService: escalaService,
          cronogramaService: cronogramaService,
          disponibilidadeService: disponibilidadeService,
          conteudoCultoService: conteudoCultoService,
        );
        _authProvider = authProvider;
        _igrejaContext = igrejaContext;
        _router = createRouter(authProvider);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null ||
        _authProvider == null ||
        _igrejaContext == null ||
        _services == null) {
      return MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final services = _services!;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider!),
        ChangeNotifierProvider.value(value: _igrejaContext!),
        Provider.value(value: services.authService),
        Provider.value(value: services.pessoaService),
        Provider.value(value: services.ministerioService),
        Provider.value(value: services.dashboardService),
        Provider.value(value: services.exportService),
        Provider.value(value: services.igrejaService),
        Provider.value(value: services.usuarioService),
        Provider.value(value: services.escalaService),
        Provider.value(value: services.cronogramaService),
        Provider.value(value: services.disponibilidadeService),
        Provider.value(value: services.conteudoCultoService),
      ],
      child: MaterialApp.router(
        title: 'Base Church',
        theme: AppTheme.light,
        routerConfig: _router!,
      ),
    );
  }
}

class AppServices {
  AppServices({
    required this.api,
    required this.authService,
    required this.pessoaService,
    required this.ministerioService,
    required this.dashboardService,
    required this.exportService,
    required this.igrejaService,
    required this.usuarioService,
    required this.escalaService,
    required this.cronogramaService,
    required this.disponibilidadeService,
    required this.conteudoCultoService,
  });

  final ApiClient api;
  final AuthService authService;
  final PessoaService pessoaService;
  final MinisterioService ministerioService;
  final DashboardService dashboardService;
  final ExportService exportService;
  final IgrejaService igrejaService;
  final UsuarioService usuarioService;
  final EscalaService escalaService;
  final CronogramaService cronogramaService;
  final DisponibilidadeService disponibilidadeService;
  final ConteudoCultoService conteudoCultoService;
}
