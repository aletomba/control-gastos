# control_gastos — AGENTS.md

App Flutter que importa gastos desde emails de Santander Argentina y Mercado Pago vía Gmail API.

## Stack
- Flutter 3.44+ / Dart SDK ^3.12.0
- Riverpod (state management), Drift (SQLite ORM), Google Sign-In + Gmail API, WorkManager (background sync)

## Arquitectura
```
domain/entities/     → Transaction, Category, TransactionSource enum
domain/repositories/ → interfaces (I prefix)
application/use_cases/ → SyncEmails, CategorizeTransaction, GetTransactions, etc.
infrastructure/      → parsers, database, services (Gmail, background sync)
presentation/        → dashboard, transactions, charts, settings screens + providers
```

Entrypoint: `lib/main.dart` — inicializa locale `es_AR`, background sync, luego `MaterialApp` con `ProviderScope`.

Providers: `lib/presentation/providers.dart` (manual wiring, sin riverpod_generator annotations por ahora).

DB generada por Drift: `lib/infrastructure/database/app_database.dart` + `app_database.g.dart`.

## Comandos exactos

```bash
# Instalar dependencias
flutter pub get

# Generar código (Drift)
dart run build_runner build --delete-conflicting-outputs

# Correr en dispositivo/emulador
flutter run

# Análisis estático
dart analyze

# Tests
flutter test

# Build APK release (requiere google-services.json)
flutter build apk --release
```

**Orden requerido en CI:** `dart analyze` → `dart run build_runner build --delete-conflicting-outputs` → `flutter test` → (opcional) `flutter build apk --release`

## CI/CD
GitHub Actions en `.github/workflows/ci.yml`:
- Corre en push/PR a `main`
- Los pasos de build APK requieren el secret `GOOGLE_SERVICES_JSON` (que escribe `android/app/google-services.json`)
- También decodifica `KEYSTORE_BASE64` si está presente

## Secrets / no commiteados
- `android/app/google-services.json` — OAuth creds (ignorado)
- `android/app/release.jks` — keystore de firma (ignorado)
- `**/GoogleService-Info.plist` — iOS (ignorado)

## Tests
3 suites:
- `test/parsers/santander_parser_test.dart`
- `test/parsers/mercado_pago_parser_test.dart`
- `test/widget_test.dart` — smoke test de LoginScreen

Sin tests de integración ni snapshot tests. Parsean emails con formato argentino (`.` para miles, `,` para decimales).

## Background sync
- `lib/infrastructure/services/background_sync_service.dart`
- Se registra en `main()` cada 6 horas vía WorkManager
- Callback entrypoint anotado con `@pragma('vm:entry-point')` en `callbackDispatcher()`
- Pull-to-refresh puede disparar `BackgroundSyncService.triggerNow()`

## Convenciones de estilo
- `flutter_lints` con defaults (`package:flutter_lints/flutter.yaml`)
- Sin reglas personalizadas en `analysis_options.yaml`
- Nombres de archivo: snake_case (`sync_emails_use_case.dart`)
- Nombres de clase: PascalCase
- Comentarios en español (equipo argentino)
- Traducciones/strings en español directamente en código (sin .arb)
