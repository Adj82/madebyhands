import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/presentation/theme/buyer_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/domain/repositories/auth_repository.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_heading.dart';

class BuyerAccountPage extends StatelessWidget {
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
  Widget build(BuildContext context) =>
      BuyerBackground(child: _BuyerAccountBody(page: this));
}

/// Holds the page state below [BuyerBackground], so dialogs and sheets opened
/// from the state's own context inherit the buyer theme.
class _BuyerAccountBody extends StatefulWidget {
  final BuyerAccountPage page;

  const _BuyerAccountBody({required this.page});

  @override
  State<_BuyerAccountBody> createState() => _BuyerAccountPageState();
}

class _BuyerAccountPageState extends State<_BuyerAccountBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.page.user.name,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.page.user.phone,
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
    final result = await widget.page.repository.updateProfile(
      uid: widget.page.user.uid,
      name: _name.text,
      phone: _phone.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold((failure) => _message(failure.message), (user) {
      widget.page.onProfileUpdated(user);
      _message('Profile updated.');
    });
  }

  Future<void> _confirmAccountDeletion() async {
    final reasonController = TextEditingController();
    final reasonFormKey = GlobalKey<FormState>();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Permanently Delete Account?',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Form(
          key: reasonFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to permanently delete your buyer account? Your saved addresses, favorite items, and account details will be immediately and permanently deleted. This action cannot be undone.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Why are you leaving? *',
                  hintText: 'Help us improve MadeByHands',
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Please tell us why' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!reasonFormKey.currentState!.validate()) return;
              Navigator.pop(context, reasonController.text.trim());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      context.read<AuthBloc>().add(
        AuthDeleteAccountRequested(widget.page.user.uid, reason: reason),
      );
      Navigator.pop(context); // Close account settings page
    }
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const BuyerHeading('Your details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline, size: 20),
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
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
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
              initialValue: widget.page.user.email,
              enabled: false,
              style: const TextStyle(color: BuyerColors.muted),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save profile'),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text(
                  'Permanently delete your account and profile data.',
                ),
                onTap: _confirmAccountDeletion,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
