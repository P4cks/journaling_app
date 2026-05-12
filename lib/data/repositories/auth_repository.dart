import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/app_user.dart';
import 'package:journaling_app_rewrite/data/services/auth_service.dart';

enum AuthOperation { email, register, passwordReset, google, apple, signOut }

class AuthRepository extends ChangeNotifier {
  AuthRepository(this._service) : _currentUser = _service.currentUser {
    _subscription = _service.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  final AuthService _service;
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? _currentUser;
  bool _isLoading = false;
  AuthOperation? _operation;
  String? _errorMessage;
  String? _successMessage;

  AppUser? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  bool get isConfigured => _service.isConfigured;

  String? get configurationMessage => _service.configurationMessage;

  bool get isLoading => _isLoading;

  AuthOperation? get operation => _operation;

  String? get errorMessage => _errorMessage;

  String? get successMessage => _successMessage;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _run(
    AuthOperation.email,
    () => _service.signInWithEmail(email: email, password: password),
  );

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) => _run(
    AuthOperation.register,
    () => _service.registerWithEmail(email: email, password: password),
  );

  Future<void> sendPasswordResetEmail(String email) async {
    await _run(
      AuthOperation.passwordReset,
      () => _service.sendPasswordResetEmail(email),
      successMessage: 'Password reset email sent.',
    );
  }

  Future<void> signInWithGoogle() =>
      _run(AuthOperation.google, _service.signInWithGoogle);

  Future<void> signInWithApple() =>
      _run(AuthOperation.apple, _service.signInWithApple);

  Future<void> signOut() => _run(AuthOperation.signOut, _service.signOut);

  void clearMessages() {
    if (_errorMessage == null && _successMessage == null) return;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> _run(
    AuthOperation operation,
    Future<dynamic> Function() action, {
    String? successMessage,
  }) async {
    _isLoading = true;
    _operation = operation;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await action();
      if (result is AppUser) {
        _currentUser = result;
      } else if (operation == AuthOperation.signOut) {
        _currentUser = null;
      }
      _successMessage = successMessage;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isLoading = false;
      _operation = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _service.dispose();
    super.dispose();
  }
}
