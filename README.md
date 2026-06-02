# Control Gastos ??

App Flutter para controlar gastos personales con importación automática desde emails de Santander Argentina y Mercado Pago.

## Características

- **Sincronización automática** de gastos desde Gmail (Santander crédito/débito + Mercado Pago)
- **Categorización automática** por keywords (supermercados, combustible, restaurantes, etc.)
- **Dashboard mensual** con total de gastos y últimas transacciones
- **Gráficos** de torta por categoría y barras por mes
- **Carga manual** de gastos
- **Exportación CSV** compatible con Excel
- **Sincronización en background** cada 6 horas (WorkManager)

## Stack

- Flutter 3.x + Dart — Android & iOS
- Clean Architecture (domain / application / infrastructure / presentation)
- Drift (SQLite ORM) — almacenamiento local
- Riverpod — state management
- Gmail API + Google Sign-In — lectura de emails
- WorkManager — sync en background

## Setup

### Requisitos previos

1. Flutter 3.44+ instalado
2. Proyecto en Google Cloud con Gmail API habilitada
3. `android/app/google-services.json` (no incluido en el repo — ver más abajo)

### Configuración de Google Services

El archivo `google-services.json` contiene credenciales OAuth y **no se sube al repositorio**. Para ejecutar la app:

1. Crear proyecto en [Google Cloud Console](https://console.cloud.google.com)
2. Habilitar Gmail API
3. Crear credencial OAuth 2.0 para Android (`com.tomba.control_gastos`)
4. Descargar `google-services.json` y colocarlo en `android/app/`

### Correr la app

```bash
flutter pub get
dart run build_runner build
flutter run
```

### Tests

```bash
flutter test
```

## CI/CD

GitHub Actions corre en cada push a `main`:
- `dart analyze`
- `flutter test`
- Build APK (requiere el secret `GOOGLE_SERVICES_JSON` configurado en el repo)
