import 'package:journaling_app_rewrite/data/model/app_user.dart';

abstract class AuthService {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  bool get isConfigured;

  String? get configurationMessage;

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithApple();

  Future<void> signOut();

  void dispose() {}
}

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthFailure($code): $message';
}

class DisabledAuthService implements AuthService {
  DisabledAuthService(this.configurationMessage);

  @override
  final String configurationMessage;

  @override
  Stream<AppUser?> get authStateChanges => Stream<AppUser?>.value(null);

  @override
  AppUser? get currentUser => null;

  @override
  bool get isConfigured => false;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw AuthFailure(configurationMessage, code: 'not-configured');
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    throw AuthFailure(configurationMessage, code: 'not-configured');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    throw AuthFailure(configurationMessage, code: 'not-configured');
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    throw AuthFailure(configurationMessage, code: 'not-configured');
  }

  @override
  Future<AppUser> signInWithApple() async {
    throw AuthFailure(configurationMessage, code: 'not-configured');
  }

  @override
  Future<void> signOut() async {}

  @override
  void dispose() {}
}
