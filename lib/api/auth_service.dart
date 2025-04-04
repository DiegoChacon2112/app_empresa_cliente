import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  // ignore: prefer_const_constructors
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final String _tokenKey = 'auth_token';
  final String _userKey = 'user_data';

  // Login do usuário
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: ApiConfig.timeoutDuration));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Salvar token JWT
        await _secureStorage.write(key: _tokenKey, value: data['token']);
        
        // Salvar dados do usuário
        final user = User.fromJson(data['user']);
        await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));
        
        return true;
      }
      return false;
    } catch (e) {
      print('Erro no login: $e');
      return false;
    }
  }

  // Obter token armazenado
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Obter usuário logado
  Future<User?> getCurrentUser() async {
    final userData = await _secureStorage.read(key: _userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Verificar se o usuário está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Logout do usuário
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }
}