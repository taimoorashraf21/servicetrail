import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _userIdKey = 'current_user_id';

  AppUser? _currentUser;
  bool _initialized = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get initialized => _initialized;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    if (userId != null) {
      _currentUser = await DatabaseService.instance.getUser(userId);
    }
    _initialized = true;
    notifyListeners();
  }

  /// Demo login: no password, pick a seeded demo account.
  Future<void> loginAs(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    _currentUser = null;
    notifyListeners();
  }
}
