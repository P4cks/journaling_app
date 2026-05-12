import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journaling_app_rewrite/data/model/app_user.dart';
import 'package:journaling_app_rewrite/data/repositories/auth_repository.dart';
import 'package:journaling_app_rewrite/data/services/auth_service.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/profile_auth_card.dart';

void main() {
  testWidgets('shows optional sign-in actions when signed out', (tester) async {
    final repository = AuthRepository(_FakeAuthService());
    addTearDown(repository.dispose);

    await tester.pumpWidget(_Harness(repository: repository));

    expect(find.text('Optional account'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
  });

  testWidgets('shows profile identity when signed in', (tester) async {
    final repository = AuthRepository(_FakeAuthService(initialUser: _user));
    addTearDown(repository.dispose);

    await tester.pumpWidget(_Harness(repository: repository));

    expect(find.text('A User'), findsOneWidget);
    expect(find.text('Signed in with Google'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.repository});

  final AuthRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: ProfileAuthCard(authRepository: repository)),
    );
  }
}

const _user = AppUser(
  uid: 'uid-1',
  email: 'a@example.com',
  displayName: 'A User',
  photoUrl: null,
  providerIds: ['google.com'],
  emailVerified: true,
);

class _FakeAuthService implements AuthService {
  _FakeAuthService({AppUser? initialUser}) : _currentUser = initialUser;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

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
    _currentUser = _user;
    _controller.add(_user);
    return _user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUser> signInWithApple() async {
    _currentUser = _user;
    _controller.add(_user);
    return _user;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _currentUser = _user;
    _controller.add(_user);
    return _user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    _currentUser = _user;
    _controller.add(_user);
    return _user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
