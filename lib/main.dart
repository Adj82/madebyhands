import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/pages/welcome_screen.dart';
import 'package:madebyhands/features/auth/presentation/pages/role_selection_page.dart';
import 'package:madebyhands/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_flow_wrapper.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_dashboard_page.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
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
        BlocProvider(
          create: (_) => serviceLocator<CreatorBloc>(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<BuyerBloc>(),
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
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
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
                // Intelligent Routing based on User Role
                final role = state.user.role.toLowerCase();
                if (role == 'admin') {
                  return const AdminDashboardPage();
                } else if (role == 'creator' || role == 'seller') {
                  return CreatorFlowWrapper(user: state.user);
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
                        Text('Error: ${state.message}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        FilledButton(
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
      },
    );
  }
}
