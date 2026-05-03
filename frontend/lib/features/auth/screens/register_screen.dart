import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _firstCtrl    = TextEditingController();
  final _lastCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  String _role        = 'TRAVELER';
  bool   _obscure     = true;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).register(
      RegisterRequest(
        email:     _emailCtrl.text.trim(),
        password:  _passCtrl.text,
        firstName: _firstCtrl.text.trim(),
        lastName:  _lastCtrl.text.trim(),
        role:      _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (_, next) {
      if (next is AsyncError) {
        final ex = next.error;
        final msg = ex is ServerException ? ex.message : context.l10n.registrationFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: kError),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstCtrl,
                        decoration: InputDecoration(labelText: context.l10n.firstName),
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || v.isEmpty ? context.l10n.required : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastCtrl,
                        decoration: InputDecoration(labelText: context.l10n.lastName),
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || v.isEmpty ? context.l10n.required : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                  validator: (v) => v == null || v.length < 8
                      ? context.l10n.passwordMinLength
                      : null,
                ),
                const SizedBox(height: 20),
                Text(context.l10n.role, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'TRAVELER', label: Text(context.l10n.traveler), icon: const Icon(Icons.explore)),
                    ButtonSegment(value: 'HOST',     label: Text(context.l10n.host),     icon: const Icon(Icons.home)),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
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
                      : Text(context.l10n.register),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.goNamed('login'),
                  child: Text(context.l10n.alreadyHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
