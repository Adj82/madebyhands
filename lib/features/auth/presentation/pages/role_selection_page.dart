import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/auth/presentation/widgets/auth_button.dart';

class RoleSelectionPage extends StatelessWidget {
  final UserEntity tempUser;
  const RoleSelectionPage({super.key, required this.tempUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join MADEBYHANDS')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome, how would you like to join us?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            AuthButton(
              text: 'I want to Buy (Consumer)',
              onPressed: () {
                context.read<AuthBloc>().add(
                      AuthSignUpWithRoleRequested(
                        uid: tempUser.uid,
                        email: tempUser.email,
                        name: tempUser.name,
                        role: 'buyer',
                      ),
                    );
              },
            ),
            const SizedBox(height: 20),
            AuthButton(
              text: 'I want to Create (Artisan)',
              onPressed: () {
                context.read<AuthBloc>().add(
                      AuthSignUpWithRoleRequested(
                        uid: tempUser.uid,
                        email: tempUser.email,
                        name: tempUser.name,
                        role: 'creator',
                      ),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}
