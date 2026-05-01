import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/host/repositories/host_repository.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';
import '../repositories/profile_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _startEdit() => setState(() => _editing = true);

  void _cancelEdit() {
    final user = ref.read(authStateProvider).valueOrNull;
    _firstNameCtrl.text = user?.firstName ?? '';
    _lastNameCtrl.text = user?.lastName ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await ref.read(profileRepositoryProvider).updateMe(
            firstName: _firstNameCtrl.text.trim().isEmpty
                ? null
                : _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim().isEmpty
                ? null
                : _lastNameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
          );

      // Push updated user into authStateProvider so every screen that shows
      // the user's name reflects the change immediately.
      ref.read(authStateProvider.notifier).updateUser(updated);

      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: _startEdit,
            )
          else ...[
            TextButton(
              onPressed: _saving ? null : _cancelEdit,
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: kTeal.withValues(alpha: 0.15),
              child: Text(
                _initials(user),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTeal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Full name display
          Center(
            child: Text(
              user.fullName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),

          // Role badge
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (user.isHost ? kNavy : kTeal).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isHost ? 'Host' : 'Traveler',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: user.isHost ? kNavy : kTeal,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 20),

          // Email (always read-only — backend doesn't allow changing it)
          _ReadOnlyField(label: 'Email', value: user.email),
          const SizedBox(height: 16),

          // First name
          TextFormField(
            controller: _firstNameCtrl,
            enabled: _editing,
            decoration: const InputDecoration(
              labelText: 'First name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Last name
          TextFormField(
            controller: _lastNameCtrl,
            enabled: _editing,
            decoration: const InputDecoration(
              labelText: 'Last name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Phone
          TextFormField(
            controller: _phoneCtrl,
            enabled: _editing,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
              border: OutlineInputBorder(),
            ),
          ),

          if (_editing) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save changes'),
              ),
            ),
          ],

          // Payout settings — hosts only
          if (user.isHost) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 20),
            const _PayoutSettingsCard(),
          ],

          const SizedBox(height: 32),

          // Logout
          OutlinedButton.icon(
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: Colors.red),
            label:
                const Text('Log out', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(UserModel user) {
    final first = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final last = user.lastName.isNotEmpty ? user.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}

class _PayoutSettingsCard extends ConsumerStatefulWidget {
  const _PayoutSettingsCard();

  @override
  ConsumerState<_PayoutSettingsCard> createState() =>
      _PayoutSettingsCardState();
}

class _PayoutSettingsCardState extends ConsumerState<_PayoutSettingsCard> {
  ConnectStatusModel? _status;
  bool _loading = true;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() => _loading = true);
    try {
      final status =
          await ref.read(hostRepositoryProvider).getConnectStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      // Status unavailable — show "Set up" button anyway
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openOnboarding() async {
    setState(() => _launching = true);
    try {
      final url = await ref
          .read(hostRepositoryProvider)
          .createConnectOnboarding();
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open browser')),
          );
        }
      }
      // Re-fetch status when user returns — they may have completed onboarding
      await _fetchStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start onboarding: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _status?.chargesEnabled ?? false;
    final submitted = _status?.detailsSubmitted ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payout Settings',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: kGrey.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Icon(
                        enabled
                            ? Icons.check_circle_rounded
                            : Icons.account_balance_wallet_outlined,
                        color: enabled ? Colors.green : kGrey,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enabled
                                  ? 'Payouts enabled'
                                  : submitted
                                      ? 'Verification in progress'
                                      : 'Not connected',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              enabled
                                  ? 'You will receive payouts from bookings'
                                  : submitted
                                      ? 'Stripe is reviewing your information'
                                      : 'Connect Stripe to receive payments',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: kGrey),
                            ),
                          ],
                        ),
                      ),
                      if (!enabled) ...[
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _launching ? null : _openOnboarding,
                          child: _launching
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : Text(submitted ? 'Continue' : 'Set up'),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        filled: true,
      ),
      child: Text(
        value,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: kGrey),
      ),
    );
  }
}
