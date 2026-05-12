import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:journaling_app_rewrite/data/model/app_user.dart';
import 'package:journaling_app_rewrite/data/repositories/auth_repository.dart';
import 'package:journaling_app_rewrite/data/services/auth_service.dart';

void main() {
  test('tracks the current auth user from the service stream', () async {
    final service = _FakeAuthService();
    final repository = AuthRepository(service);
    addTearDown(repository.dispose);

    expect(repository.currentUser, isNull);

    service.emit(_user);
    await Future<void>.delayed(Duration.zero);

    expect(repository.currentUser?.uid, _user.uid);
    expect(repository.isSignedIn, isTrue);
  });

  test('stores readable auth failures and clears loading state', () async {
    final service = _FakeAuthService(
      googleFailure: const AuthFailure('Provider is disabled.'),
    );
    final repository = AuthRepository(service);
    addTearDown(repository.dispose);

    await repository.signInWithGoogle();

    expect(repository.errorMessage, 'Provider is disabled.');
    expect(repository.isLoading, isFalse);
    expect(repository.operation, isNull);
  });

  test('records password reset success without signing in', () async {
    final service = _FakeAuthService();
    final repository = AuthRepository(service);
    addTearDown(repository.dispose);

    await repository.sendPasswordResetEmail('a@example.com');

    expect(repository.currentUser, isNull);
    expect(repository.successMessage, 'Password reset email sent.');
    expect(service.lastResetEmail, 'a@example.com');
  });
}

const _user = AppUser(
  uid: 'uid-1',
  email: 'a@example.com',
  displayName: 'A User',
  photoUrl: null,
  providerIds: ['password'],
  emailVerified: true,
);

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.googleFailure});

  final AuthFailure? googleFailure;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  String? lastResetEmail;

  void emit(AppUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get isConfigured => true;

  @override
  String? get configurationMessage => null;

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    emit(_user);
    return _user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastResetEmail = email;
  }

  @override
  Future<AppUser> signInWithApple() async {
    emit(_user);
    return _user;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(_user);
    return _user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final failure = googleFailure;
    if (failure != null) throw failure;
    emit(_user);
    return _user;
  }

  @override
  Future<void> signOut() async {
    emit(null);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
