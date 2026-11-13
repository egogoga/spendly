import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'phrase_parser.dart';

/// Связь приложения с сервером на FastAPI.
///
/// Пока сервера нет, useMock = true: вход срабатывает без проверки,
/// а фразы разбирает демо-разборщик PhraseParser прямо в приложении.
/// Когда сервер будет готов — поставьте useMock = false и укажите baseUrl.
/// Какие запросы ждёт приложение, описано в README.md.
class SpendlyApi {
  SpendlyApi._();

  static final SpendlyApi instance = SpendlyApi._();

  /// Адрес сервера:
  /// • приложение в Chrome, сервер на этом же компьютере — http://localhost:8000
  /// • эмулятор Android — http://10.0.2.2:8000
  /// • настоящий телефон — http://<IP компьютера в той же Wi-Fi сети>:8000
  static String baseUrl = 'http://localhost:8000';

  static bool useMock = true;

  String? _token;

  bool get isLoggedIn => _token != null;

  Future<void> login(String email, String password) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _token = 'demo-token';
      return;
    }
    final data = await _post('/auth/login', {'email': email, 'password': password});
    _token = data['access_token'] as String?;
  }

  Future<void> register(String name, String email, String password) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _token = 'demo-token';
      return;
    }
    final data = await _post('/auth/register', {'name': name, 'email': email, 'password': password});
    _token = data['access_token'] as String?;
  }

  /// Отправляет фразу на сервер, сервер спрашивает GigaChat и возвращает траты.
  Future<List<ParsedExpense>> parsePhrase(String text) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return PhraseParser.parse(text);
    }
    final data = await _post('/expenses/parse', {'text': text});
    final items = data['items'] as List<dynamic>? ?? const [];
    return [
      for (final item in items) ParsedExpense.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Сохраняет проверенные пользователем траты.
  Future<void> saveExpenses(List<Expense> expenses) async {
    if (useMock) return;
    await _post('/expenses', {
      'items': [for (final e in expenses) e.toJson()],
    });
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('сервер ответил ${response.statusCode}: $text');
    }
    if (text.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'data': decoded};
  }
}
