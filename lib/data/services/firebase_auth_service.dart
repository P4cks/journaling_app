import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:journaling_app_rewrite/data/model/app_user.dart';
import 'package:journaling_app_rewrite/data/services/auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInitialization;

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapUser);

  @override
  AppUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  bool get isConfigured => true;

  @override
  String? get configurationMessage => null;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) => _run(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) => _run(
    () => _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        return _run(() => _auth.signInWithProvider(GoogleAuthProvider()));
      }
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return _run(() => _auth.signInWithCredential(credential));
    } on FirebaseAuthException catch (error) {
      throw _mapFailure(error);
    } on AuthFailure {
      rethrow;
    } catch (error) {
      throw AuthFailure(
        'Google sign-in was cancelled or could not be completed.',
        code: error.runtimeType.toString(),
      );
    }
  }

  @override
  Future<AppUser> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    return _run(() => _auth.signInWithProvider(provider));
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Firebase sign-out is the source of truth; Google may have no session.
    }
  }

  @override
  void dispose() {}

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize();
  }

  Future<AppUser> _run(Future<UserCredential> Function() operation) async {
    try {
      final credential = await operation();
      final user = _mapUser(credential.user);
      if (user == null) {
        throw const AuthFailure(
          'Sign-in completed, but no user profile was returned.',
          code: 'missing-user',
        );
      }
      return user;
    } on FirebaseAuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      providerIds: user.providerData
          .map((profile) => profile.providerId)
          .toSet()
          .toList(growable: false),
      emailVerified: user.emailVerified,
    );
  }

  AuthFailure _mapFailure(FirebaseAuthException error) {
    return AuthFailure(_messageForCode(error.code), code: error.code);
  }

  String _messageForCode(String code) {
    return switch (code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account exists for that email address.',
      'wrong-password' ||
      'invalid-credential' => 'The email or password is incorrect.',
      'email-already-in-use' => 'An account already exists for that email.',
      'weak-password' => 'Use a stronger password.',
      'network-request-failed' =>
        'Check your connection and try signing in again.',
      'account-exists-with-different-credential' =>
        'That email is already linked to another sign-in method.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled in Firebase.',
      'popup-closed-by-user' || 'canceled' => 'Sign-in was cancelled.',
      _ => 'Sign-in failed. Please try again.',
    };
  }
}
