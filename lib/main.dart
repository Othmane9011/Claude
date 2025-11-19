import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';   // 👈
import 'core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise les données locales pour fr_FR (DateFormat, noms de mois/jours…)
  await initializeDateFormatting('fr_FR', null);     // 👈
  runApp(const ProviderScope(child: VetHomeApp()));
}

class VetHomeApp extends ConsumerWidget {
  const VetHomeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'VetHome',
      // Localisation
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F7A8C)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
