import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'infrastructure/services/background_sync_service.dart';
import 'presentation/dashboard/dashboard_screen.dart';
import 'presentation/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_AR', null);
  await BackgroundSyncService.initialize();
  runApp(const ProviderScope(child: ControlGastosApp()));
}

class ControlGastosApp extends ConsumerWidget {
  const ControlGastosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);

    return MaterialApp(
      title: 'Control Gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: isSignedIn.when(
        data: (signed) => signed ? const DashboardScreen() : const LoginScreen(),
        loading: () => const _SplashScreen(),
        error: (_, _) => const LoginScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF1565C0)),
              const SizedBox(height: 24),
              Text(
                'Control Gastos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Conectá tu Gmail para importar\ntus gastos automáticamente',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(gmailServiceProvider).signIn();
                    ref.invalidate(isSignedInProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Conectar con Gmail'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

