import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reelboost_ai/core/providers/app_providers.dart';
import 'package:reelboost_ai/core/theme/app_theme.dart';
import 'package:reelboost_ai/services/auth_repository.dart';
import 'package:reelboost_ai/widgets/gradient_button.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null && widget.initialToken!.trim().isNotEmpty) {
      _token.text = widget.initialToken!.trim();
    }
  }

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final msg = await ref.read(authRepositoryProvider).resetPassword(
            token: _token.text.trim(),
            newPassword: _password.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is AuthException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient(context)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Set a new password',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Paste the reset token from your email and choose a new password.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.62), height: 1.35),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _token,
                        decoration: const InputDecoration(labelText: 'Reset token'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Token is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'New password'),
                        validator: (v) =>
                            v == null || v.length < 8 ? 'Password must be at least 8 characters' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirm password'),
                        validator: (v) {
                          if (v == null || v.length < 8) return 'Confirm your password';
                          if (v != _password.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      GradientButton(
                        label: 'Reset password',
                        loading: _busy,
                        onPressed: _busy ? null : _submit,
                        icon: Icons.lock_reset_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

