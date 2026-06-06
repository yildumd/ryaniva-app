import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String _token = '';
  bool _loading = false;
  String _error = '';

  User? get user => _user;
  String get token => _token;
  bool get loading => _loading;
  String get error => _error;
  bool get isLoggedIn => _token.isNotEmpty;

  final _storage = const FlutterSecureStorage();

  Future<void> loadFromStorage() async {
    final token = await _storage.read(key: 'token');
    final name = await _storage.read(key: 'name');
    final phone = await _storage.read(key: 'phone');
    final role = await _storage.read(key: 'role');
    final id = await _storage.read(key: 'id');

    if (token != null && id != null) {
      _token = token;
      _user = User(
          id: id,
          name: name ?? '',
          phone: phone ?? '',
          role: role ?? '');
      notifyListeners();
      _saveFcmToken();
    }
  }

  Future<bool> register(
      String name, String phone, String password, String role) async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final res = await ApiService.post('/auth/register', {
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
      });

      if (res['token'] != null) {
        await _saveSession(res);
        return true;
      } else {
        _error = res['message'] ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Check your internet.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String phone, String password) async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final res = await ApiService.post('/auth/login', {
        'phone': phone,
        'password': password,
      });

      if (res['token'] != null) {
        await _saveSession(res);
        return true;
      } else {
        _error = res['message'] ?? 'Login failed';
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Check your internet.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> res) async {
    _token = res['token'];
    _user = User.fromJson(res['user']);
    await _storage.write(key: 'token', value: _token);
    await _storage.write(key: 'id', value: _user!.id);
    await _storage.write(key: 'name', value: _user!.name);
    await _storage.write(key: 'phone', value: _user!.phone);
    await _storage.write(key: 'role', value: _user!.role);
    notifyListeners();
    _saveFcmToken();
  }

  Future<void> _saveFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final fcmToken = await messaging.getToken();
      if (fcmToken != null && _token.isNotEmpty) {
        await ApiService.patch(
          '/auth/fcm-token',
          {'fcmToken': fcmToken},
          token: _token,
        );
      }
    } catch (e) {
      // FCM token save failed silently
    }
  }

  Future<void> logout() async {
    _token = '';
    _user = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}