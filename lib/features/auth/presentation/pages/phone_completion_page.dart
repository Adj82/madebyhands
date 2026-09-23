import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';

class PhoneCompletionPage extends StatefulWidget {
  final UserEntity user;

  const PhoneCompletionPage({super.key, required this.user});

  @override
  State<PhoneCompletionPage> createState() => _PhoneCompletionPageState();
}

class _PhoneCompletionPageState extends State<PhoneCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.phone_android, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Add your phone number',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'It will be used for delivery and order communication.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixText: '+91 ',
              ),
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                return digits.length == 10
                    ? null
                    : 'Enter a valid 10-digit phone number';
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                context.read<AuthBloc>().add(
                  AuthSignUpWithRoleRequested(
                    uid: widget.user.uid,
                    email: widget.user.email,
                    name: widget.user.name,
                    phone: _phone.text.trim(),
                    role: widget.user.role,
                  ),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
