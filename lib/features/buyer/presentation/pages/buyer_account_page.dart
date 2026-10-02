import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/domain/repositories/auth_repository.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';

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

  Future<void> _confirmAccountDeletion() async {
    final reasonController = TextEditingController();
    final reasonFormKey = GlobalKey<FormState>();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAF6EE),
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
        AuthDeleteAccountRequested(widget.user.uid, reason: reason),
      );
      Navigator.pop(context); // Close account settings page
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => BuyerBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Account settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B261D),
              ),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
          ),
          body: AbsorbPointer(
            absorbing: _busy,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF8B261D).withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Color(0xFF8B261D),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().length < 2
                                  ? 'Enter your name.'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: Color(0xFF8B261D),
                            ),
                          ),
                          validator: (value) {
                            final digits =
                                value?.replaceAll(RegExp(r'\D'), '') ?? '';
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
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Color(0xFF8B261D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8B261D),
                          ),
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Save profile'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6EE).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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
        ),
      );
}
