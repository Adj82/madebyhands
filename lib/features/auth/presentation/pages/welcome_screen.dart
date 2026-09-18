import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Authentication Error', 
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Text(state.message, style: const TextStyle(color: AppColors.text)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Top illustration section (Primary Theme Color)
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: constraints.maxWidth * 0.8,
                                height: constraints.maxHeight * 0.8,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark.withAlpha(100),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white54,
                                    size: 80,
                                  ),
                                ),
                              ),
                              const Positioned(
                                bottom: 20,
                                child: Text(
                                  'CREATING ARTISANS',
                                  style: TextStyle(
                                    color: Colors.white70, 
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom beige section with rounded top (Theme Background)
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.elliptical(300, 100),
                      topRight: Radius.elliptical(300, 100),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      const Text(
                        'Ready, Set, Save!',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Google Sign-In Button
                      InkWell(
                        onTap: state is AuthLoading
                            ? null
                            : () {
                                context.read<AuthBloc>().add(AuthGoogleSignInRequested());
                              },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.outline,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: state is AuthLoading
                                ? const CircularProgressIndicator(color: AppColors.primary)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/icon_google.png',
                                        height: 28,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.g_mobiledata, size: 40, color: Colors.blue),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Sign in with Google',
                                        style: TextStyle(
                                          color: AppColors.text,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Column(
                          children: [
                            const Text(
                              'By continuing you agree MadeByHands',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              'Terms of services & Privacy Policy',
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
