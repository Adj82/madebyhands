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
            const SizedBox(height: 10),
            const Text(
              'Select a role to get started with your journey.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _RoleCard(
              title: 'I want to Buy (Consumer)',
              description: 'Discover and purchase unique, authentic handmade products directly from creators.',
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
            _RoleCard(
              title: 'I want to Create (Artisan)',
              description: 'Establish your identity, showcase your portfolio, and list your products for sale.',
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onPressed;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color.fromRGBO(107, 142, 35, 1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(107, 142, 35, 1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
