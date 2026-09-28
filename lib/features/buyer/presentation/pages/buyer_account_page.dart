import 'package:flutter/material.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/domain/repositories/auth_repository.dart';

class BuyerAccountPage extends StatefulWidget {
  final UserEntity user;
  final AuthRepository repository;
  final ValueChanged<UserEntity> onProfileUpdated;

  const BuyerAccountPage({
    super.key,
    required this.user,
    required this.repository,
    required this.onProfileUpdated,
  });

  @override
  State<BuyerAccountPage> createState() => _BuyerAccountPageState();
}

class _BuyerAccountPageState extends State<BuyerAccountPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.user.name,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.user.phone,
  );
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final result = await widget.repository.updateProfile(
      uid: widget.user.uid,
      name: _name.text,
      phone: _phone.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold((failure) => _message(failure.message), (user) {
      widget.onProfileUpdated(user);
      _message('Profile updated.');
    });
  }

  Future<void> _resetPassword() async {
    setState(() => _busy = true);
    final result = await widget.repository.sendPasswordReset(widget.user.email);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (failure) => _message(failure.message),
      (_) => _message('Password reset email sent to ${widget.user.email}.'),
    );
  }

  Future<void> _requestDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request account deletion?'),
        content: const Text(
          'A support request will be created for the admin. Your account will remain accessible until the request is processed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit request'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    final result = await widget.repository.requestAccountDeletion(widget.user);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (failure) => _message(failure.message),
      (_) => _message('Account deletion request submitted.'),
    );
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account settings')),
    body: AbsorbPointer(
      absorbing: _busy,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Enter your name.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                return digits.length < 10
                    ? 'Enter a valid phone number.'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: widget.user.email,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save profile'),
            ),
            const SizedBox(height: 28),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.password_outlined),
              title: const Text('Password recovery'),
              subtitle: const Text(
                'For password-based accounts. Google accounts are managed by Google.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _resetPassword,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Request account deletion',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Creates a request for the admin team.'),
              onTap: _requestDeletion,
            ),
          ],
        ),
      ),
    ),
  );
}
