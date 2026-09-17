import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/auth/presentation/widgets/auth_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'MADEBYHANDS',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(107, 142, 35, 1),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Handmade for you, by you.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 50),
                AuthButton(
                  text: 'Sign in with Google',
                  icon: const Icon(Icons.login),
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthGoogleSignInRequested());
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
