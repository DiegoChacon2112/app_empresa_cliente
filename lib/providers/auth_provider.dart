import 'package:flutter/foundation.dart';
import '../api/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Inicializar estado de autenticação ao abrir o app
  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _currentUser = await _authService.getCurrentUser();
      }
    } catch (e) {
      _error = "Falha ao carregar dados do usuário";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.login(email, password);
      if (success) {
        _currentUser = await _authService.getCurrentUser();
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = "Credenciais inválidas";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Falha na conexão com o servidor";
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
    } catch (e) {
      _error = "Falha ao realizar logout";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}



