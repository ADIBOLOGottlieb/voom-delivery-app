import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;

  AuthService() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      _token = await _storage.read(key: 'auth_token');
      final userJson = await _storage.read(key: 'user_data');
      
      if (_token != null && userJson != null) {
        _user = User.fromJson(json.decode(userJson));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String roleName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'password_confirmation': confirmPassword,
          'role_name': roleName,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _user = User.fromJson(data['user']);
        
        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(key: 'user_data', value: json.encode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Registration error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = User.fromJson(data['user']);
        
        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(key: 'user_data', value: json.encode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _token = null;
      _user = null;
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'user_data');
      notifyListeners();
    }
  }
}

