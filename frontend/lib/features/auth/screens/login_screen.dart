import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).login(
      LoginRequest(email: _emailCtrl.text.trim(), password: _passCtrl.text),
    );
    // Error is surfaced by the listener below via SnackBar.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Listen for errors so we can show a SnackBar without rebuilding the whole tree.
    ref.listen(authStateProvider, (_, next) {
      if (next is AsyncError) {
        final ex = next.error;
        final msg = ex is ServerException ? ex.message : context.l10n.loginFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: kError),
        );
      }
    });

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Gradient hero ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kNavy, kTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 32,
              24,
              32,
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/icons/app_icon.png',
                  width: 64,
                  height: 64,
                ),
                const SizedBox(height: 12),
                const Text(
                  'KyrgyzExplore',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.logInToContinue,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── Form ──────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(labelText: context.l10n.email),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || !v.contains('@') ? context.l10n.enterValidEmail : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.password,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) =>
                        v == null || v.length < 8 ? context.l10n.passwordMinLength : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(context.l10n.login),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.goNamed('register'),
                    child: Text(context.l10n.noAccount),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(context.l10n.or,
                            style: const TextStyle(color: kGrey, fontSize: 13)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(authStateProvider.notifier)
                                  .loginWithGoogle();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(context.l10n.googleSignInFailed)),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(context.l10n.continueWithGoogle),
                  ),
                  // Apple Sign-In is required on iOS when any social login is offered
                  // (Apple App Store guideline 4.8). We hide it on Android because
                  // android users can't complete the Apple auth flow.
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: authState.isLoading
                          ? null
                          : () async {
                              try {
                                await ref
                                    .read(authStateProvider.notifier)
                                    .loginWithApple();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(context.l10n.appleSignInFailed)),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.apple, size: 18),
                      label: Text(context.l10n.continueWithApple),
                    ),
                  ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
