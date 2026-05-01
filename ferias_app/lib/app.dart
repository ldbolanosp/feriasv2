import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/feria_provider.dart';
import 'providers/factura_provider.dart';
import 'providers/inspeccion_provider.dart';
import 'providers/parqueo_provider.dart';
import 'providers/printer_provider.dart';
import 'providers/sanitario_provider.dart';
import 'providers/tarima_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<FeriaProvider>(create: (_) => FeriaProvider()),
        ChangeNotifierProvider<FacturaProvider>(
          create: (_) => FacturaProvider(),
        ),
        ChangeNotifierProvider<ParqueoProvider>(
          create: (_) => ParqueoProvider(),
        ),
        ChangeNotifierProvider<TarimaProvider>(create: (_) => TarimaProvider()),
        ChangeNotifierProvider<SanitarioProvider>(
          create: (_) => SanitarioProvider(),
        ),
        ChangeNotifierProvider<InspeccionProvider>(
          create: (_) => InspeccionProvider(),
        ),
        ChangeNotifierProvider<PrinterProvider>(
          create: (_) => PrinterProvider(),
        ),
      ],
      child: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  late final AuthProvider _authProvider;
  late final FeriaProvider _feriaProvider;
  late final PrinterProvider _printerProvider;
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _feriaProvider = context.read<FeriaProvider>();
    _printerProvider = context.read<PrinterProvider>();
    router = AppRoutes.createRouter(
      authProvider: _authProvider,
      feriaProvider: _feriaProvider,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    await _printerProvider.initialize();
    await _authProvider.checkAuth();

    if (!mounted) {
      return;
    }

    if (_authProvider.isAuthenticated) {
      await _feriaProvider.loadFerias();
    } else {
      await _feriaProvider.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Ferias del Agricultor',
      theme: AppTheme.light,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('es', 'CR'),
        Locale('es'),
        Locale('en', 'US'),
      ],
      routerConfig: router,
    );
  }
}
