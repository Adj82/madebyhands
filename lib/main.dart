import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/pages/welcome_screen.dart';
import 'package:madebyhands/features/auth/presentation/pages/role_selection_page.dart';
import 'package:madebyhands/features/home/presentation/pages/admin_dashboard.dart';
import 'package:madebyhands/features/home/presentation/pages/creator_dashboard.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_dashboard_page.dart';
import 'package:madebyhands/init_dependencies.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => serviceLocator<AuthBloc>()..add(AuthIsUserLoggedIn()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MadeByHand',
      theme: AppTheme.lightThemeMode,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is AuthSuccess) {
            // Check role and return appropriate dashboard
            if (state.user.role == 'admin') {
              return const AdminDashboard();
            } else if (state.user.role == 'creator' ||
                state.user.role == 'seller') {
              return const CreatorDashboard();
            } else {
              return BuyerDashboardPage(
                user: state.user,
                onLogout: () =>
                    context.read<AuthBloc>().add(AuthLogoutRequested()),
              );
            }
          }

          if (state is AuthNeedsRoleSelection) {
            return RoleSelectionPage(tempUser: state.tempUser);
          }

          if (state is AuthFailure) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthIsUserLoggedIn());
                      },
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      },
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const WelcomeScreen();
        },
      ),
    );
  }
}
