import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/presentation/pages/login_page.dart';
import 'package:madebyhands/features/auth/presentation/pages/role_selection_page.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
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
          if (state is AuthSuccess) {
            // Check role and return appropriate dashboard
            if (state.user.role == 'admin') {
              return const Scaffold(body: Center(child: Text('Admin Dashboard')));
            } else if (state.user.role == 'creator') {
              return const Scaffold(body: Center(child: Text('Creator Dashboard')));
            } else {
              return const Scaffold(body: Center(child: Text('Buyer Dashboard')));
            }
          }
          
          if (state is AuthNeedsRoleSelection) {
            return RoleSelectionPage(tempUser: state.tempUser);
          }

          return const LoginPage();
        },
      ),
    );
  }
}
