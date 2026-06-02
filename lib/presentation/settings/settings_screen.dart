import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEmail = ref.watch(userEmailProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cuenta Gmail
        Card(
          child: ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Cuenta Gmail'),
            subtitle: userEmail.when(
              data: (email) => Text(email ?? 'No conectado'),
              loading: () => const Text('Cargando...'),
              error: (_, _) => const Text('Error'),
            ),
            trailing: TextButton(
              onPressed: () async {
                await ref.read(gmailServiceProvider).signOut();
                ref.invalidate(isSignedInProvider);
                ref.invalidate(userEmailProvider);
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
              child: const Text('Cerrar sesión'),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Export CSV
        Card(
          child: ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Exportar CSV'),
            subtitle: const Text('Gastos del mes actual'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final now = DateTime.now();
              try {
                await ref.read(exportCsvUseCaseProvider).execute(
                      from: DateTime(now.year, now.month, 1),
                      to: DateTime(now.year, now.month + 1, 1)
                          .subtract(const Duration(seconds: 1)),
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al exportar: $e')),
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // Gestión de categorías
        Card(
          child: ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categorías'),
            subtitle: const Text('Ver y editar categorías'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _CategoriesScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoriesScreen extends ConsumerWidget {
  const _CategoriesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: categories.when(
        data: (cats) => ListView.builder(
          itemCount: cats.length,
          itemBuilder: (ctx, i) {
            final cat = cats[i];
            final color = Color(
                int.parse('FF${cat.colorHex.replaceFirst('#', '')}', radix: 16));
            return ListTile(
              leading: CircleAvatar(backgroundColor: color, radius: 16),
              title: Text(cat.name),
              subtitle: Text(cat.keywords.take(3).join(', ')),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
