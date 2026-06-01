import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/app_user.dart';
import 'package:journaling_app_rewrite/data/repositories/auth_repository.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

class ProfileAuthCard extends StatelessWidget {
  const ProfileAuthCard({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    final user = authRepository.currentUser;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: user == null
          ? _SignedOutProfile(authRepository: authRepository)
          : _SignedInProfile(authRepository: authRepository, user: user),
    );
  }
}

class _ProfileContainer extends StatelessWidget {
  const _ProfileContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SignedOutProfile extends StatelessWidget {
  const _SignedOutProfile({required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disabled = !authRepository.isConfigured || authRepository.isLoading;
    return _ProfileContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: AppIcon(HugeIcons.strokeRoundedUserCircle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optional account',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your journal stays local unless you sign in.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (authRepository.errorMessage != null ||
              authRepository.configurationMessage != null) ...[
            const SizedBox(height: 12),
            _MessageBanner(
              icon: HugeIcons.strokeRoundedAlertCircle,
              message:
                  authRepository.errorMessage ??
                  authRepository.configurationMessage!,
              isError: true,
            ),
          ],
          const SizedBox(height: 16),
          _AuthActionButton(
            icon: HugeIcons.strokeRoundedMail02,
            label: 'Continue with Email',
            isLoading:
                authRepository.operation == AuthOperation.email ||
                authRepository.operation == AuthOperation.register ||
                authRepository.operation == AuthOperation.passwordReset,
            onPressed: disabled
                ? null
                : () => showEmailAuthSheet(context, authRepository),
          ),
          const SizedBox(height: 8),
          _AuthActionButton(
            icon: HugeIcons.strokeRoundedGoogle,
            label: 'Continue with Google',
            isLoading: authRepository.operation == AuthOperation.google,
            onPressed: disabled ? null : authRepository.signInWithGoogle,
          ),
          const SizedBox(height: 8),
          _AuthActionButton(
            icon: HugeIcons.strokeRoundedApple,
            label: 'Continue with Apple',
            isLoading: authRepository.operation == AuthOperation.apple,
            onPressed: disabled ? null : authRepository.signInWithApple,
          ),
        ],
      ),
    );
  }
}

class _SignedInProfile extends StatelessWidget {
  const _SignedInProfile({required this.authRepository, required this.user});

  final AuthRepository authRepository;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _ProfileContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _UserAvatar(user: user),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.bestDisplayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _providerLabel(user.providerIds),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.email != null && !user.emailVerified) ...[
            const SizedBox(height: 12),
            _MessageBanner(
              icon: HugeIcons.strokeRoundedMail01,
              message: 'Email address not verified yet.',
              isError: false,
            ),
          ],
          if (authRepository.errorMessage != null) ...[
            const SizedBox(height: 12),
            _MessageBanner(
              icon: HugeIcons.strokeRoundedAlertCircle,
              message: authRepository.errorMessage!,
              isError: true,
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: authRepository.isLoading ? null : authRepository.signOut,
            icon: authRepository.operation == AuthOperation.signOut
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AppIcon(HugeIcons.strokeRoundedLogout01),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photoUrl = user.photoUrl;
    return CircleAvatar(
      radius: 24,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      backgroundImage: photoUrl == null || photoUrl.isEmpty
          ? null
          : NetworkImage(photoUrl),
      child: photoUrl == null || photoUrl.isEmpty ? Text(user.initials) : null,
    );
  }
}

class _AuthActionButton extends StatelessWidget {
  const _AuthActionButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final HugeIconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : AppIcon(icon),
      label: Text(label),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.message,
    required this.isError,
  });

  final HugeIconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isError
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final foreground = isError
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showEmailAuthSheet(
  BuildContext context,
  AuthRepository authRepository,
) {
  authRepository.clearMessages();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _EmailAuthSheet(authRepository: authRepository),
  );
}

class _EmailAuthSheet extends StatefulWidget {
  const _EmailAuthSheet({required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;

  AuthRepository get _auth => widget.authRepository;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRegistering) {
      await _auth.registerWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      await _auth.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
    if (mounted && _auth.errorMessage == null && _auth.currentUser != null) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _formKey.currentState!.validate();
      return;
    }
    await _auth.sendPasswordResetEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final theme = Theme.of(context);
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        final busy = _auth.isLoading;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isRegistering ? 'Create account' : 'Sign in',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: AppIcon(HugeIcons.strokeRoundedCancel01),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Sign in')),
                    ButtonSegment(value: true, label: Text('Create')),
                  ],
                  selected: {_isRegistering},
                  onSelectionChanged: busy
                      ? null
                      : (selection) {
                          setState(() => _isRegistering = selection.first);
                          _auth.clearMessages();
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: AppIcon(HugeIcons.strokeRoundedMail02),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty || !email.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  enabled: !busy,
                  obscureText: true,
                  autofillHints: [
                    _isRegistering
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: AppIcon(
                      HugeIcons.strokeRoundedSquareLockPassword,
                    ),
                  ),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.length < 6) {
                      return 'Use at least 6 characters.';
                    }
                    return null;
                  },
                ),
                if (_auth.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _MessageBanner(
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    message: _auth.errorMessage!,
                    isError: true,
                  ),
                ],
                if (_auth.successMessage != null) ...[
                  const SizedBox(height: 12),
                  _MessageBanner(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    message: _auth.successMessage!,
                    isError: false,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: busy ? null : _submit,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : AppIcon(HugeIcons.strokeRoundedArrowRight01),
                  label: Text(_isRegistering ? 'Create account' : 'Sign in'),
                ),
                TextButton(
                  onPressed: busy ? null : _sendReset,
                  child: const Text('Send password reset email'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _providerLabel(List<String> providerIds) {
  if (providerIds.isEmpty) return 'Signed in';
  final labels = providerIds.map((id) {
    return switch (id) {
      'password' => 'Email',
      'google.com' => 'Google',
      'apple.com' => 'Apple',
      _ => id,
    };
  }).toSet();
  return 'Signed in with ${labels.join(', ')}';
}
