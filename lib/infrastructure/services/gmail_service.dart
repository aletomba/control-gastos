import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Senders conocidos de los bancos
const _santanderSender = 'mensajesyavisos@mails.santander.com.ar';
const _mercadoPagoSender = 'no-reply@mercadopago.com.ar';

const _gmailScope = 'https://www.googleapis.com/auth/gmail.readonly';
const _tokenKey = 'gmail_access_token';

class GmailService {
  GmailService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final _googleSignIn = GoogleSignIn(scopes: [_gmailScope]);

  GoogleSignInAccount? _currentUser;

  /// Inicia sesión con Google y persiste el token
  Future<void> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    if (_currentUser == null) throw Exception('Sign-in cancelado por el usuario');
    final auth = await _currentUser!.authentication;
    if (auth.accessToken != null) {
      await _storage.write(key: _tokenKey, value: auth.accessToken);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.delete(key: _tokenKey);
    _currentUser = null;
  }

  Future<bool> get isSignedIn async {
    _currentUser ??= await _googleSignIn.signInSilently();
    return _currentUser != null;
  }

  Future<String?> get userEmail async {
    _currentUser ??= await _googleSignIn.signInSilently();
    return _currentUser?.email;
  }

  /// Devuelve los emails nuevos de Santander y Mercado Pago desde [since]
  Future<List<RawEmail>> fetchExpenseEmails({DateTime? since}) async {
    final client = await _getAuthenticatedClient();
    final gmailApi = gmail.GmailApi(client);

    final results = <RawEmail>[];
    final senders = [_santanderSender, _mercadoPagoSender];

    debugPrint('[GmailService] Iniciando búsqueda, since=$since');

    for (final sender in senders) {
      String query = 'from:$sender';
      if (since != null) {
        final epoch = since.millisecondsSinceEpoch ~/ 1000;
        query += ' after:$epoch';
      }

      debugPrint('[GmailService] Query: $query');

      final listResponse = await gmailApi.users.messages.list(
        'me',
        q: query,
        maxResults: 50,
      );

      final messages = listResponse.messages ?? [];
      debugPrint('[GmailService] Encontrados ${messages.length} mensajes de $sender');

      for (final msg in messages) {
        if (msg.id == null) continue;
        final full = await gmailApi.users.messages.get('me', msg.id!,
            format: 'full');
        final body = _extractBody(full);
        final subject = _getHeader(full, 'Subject') ?? '';
        debugPrint('[GmailService] id=${msg.id} subject="$subject" bodyLen=${body?.length ?? 0}');
        final date = _parseDate(full);
        if (body != null && date != null) {
          results.add(RawEmail(
            id: msg.id!,
            sender: sender,
            subject: subject,
            body: body,
            date: date,
          ));
        }
      }
    }

    debugPrint('[GmailService] Total emails procesados: ${results.length}');
    client.close();
    return results;
  }

  // ─── Helpers privados ────────────────────────────────────────────────────

  Future<http.Client> _getAuthenticatedClient() async {
    _currentUser ??= await _googleSignIn.signInSilently();
    if (_currentUser == null) throw Exception('No hay sesión activa. Ejecutá signIn()');

    final auth = await _currentUser!.authentication;
    return _AuthenticatedClient(auth.accessToken!);
  }

  String? _extractBody(gmail.Message message) {
    // Intentar obtener HTML primero, luego texto plano
    return _extractPart(message.payload, 'text/html') ??
        _extractPart(message.payload, 'text/plain');
  }

  String? _extractPart(gmail.MessagePart? part, String mimeType) {
    if (part == null) return null;
    if (part.mimeType == mimeType) {
      final data = part.body?.data;
      if (data != null) return utf8.decode(base64Url.decode(data));
    }
    for (final child in part.parts ?? []) {
      final result = _extractPart(child, mimeType);
      if (result != null) return result;
    }
    return null;
  }

  String? _getHeader(gmail.Message message, String name) {
    return message.payload?.headers
        ?.firstWhere((h) => h.name?.toLowerCase() == name.toLowerCase(),
            orElse: () => gmail.MessagePartHeader())
        .value;
  }

  DateTime? _parseDate(gmail.Message message) {
    final raw = _getHeader(message, 'Date');
    if (raw == null) return null;

    debugPrint('[GmailService] PARSE DATE raw="$raw"');

    // Attempto 1: DateTime.parse (ISO 8601, RFC 1123 con GMT/UT)
    try {
      final result = DateTime.parse(raw);
      debugPrint('[GmailService] PARSE attempt1 OK -> $result');
      return result;
    } catch (e) {
      debugPrint('[GmailService] PARSE attempt1 FAIL: $e');
    }

    // Attempto 2: RFC 2822 con timezone numérico
    try {
      final cleaned = raw.replaceFirst(RegExp(r'\s*\([^)]*\)$'), '').trim();
      debugPrint('[GmailService] PARSE attempt2 cleaned="$cleaned"');
      final parsed = DateFormat('EEE, d MMM yyyy HH:mm:ss Z', 'en_US').parseStrict(cleaned);
      debugPrint('[GmailService] PARSE attempt2 OK -> $parsed');
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (e) {
      debugPrint('[GmailService] PARSE attempt2 FAIL: $e');
    }

    return null;
  }
}

/// Email crudo antes de parsear
class RawEmail {
  const RawEmail({
    required this.id,
    required this.sender,
    required this.subject,
    required this.body,
    required this.date,
  });

  final String id;
  final String sender;
  final String subject;
  final String body;
  final DateTime date;
}

/// Cliente HTTP que inyecta el Authorization header
class _AuthenticatedClient extends http.BaseClient {
  _AuthenticatedClient(this._token);

  final String _token;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
