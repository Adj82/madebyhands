import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_dashboard_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_onboarding_page.dart';

/// Shows onboarding until the creator has a profile, then the dashboard.
class CreatorFlowWrapper extends StatefulWidget {
  final UserEntity user;
  const CreatorFlowWrapper({super.key, required this.user});

  @override
  State<CreatorFlowWrapper> createState() => _CreatorFlowWrapperState();
}

class _CreatorFlowWrapperState extends State<CreatorFlowWrapper> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    context.read<CreatorBloc>().add(CreatorCheckProfileExists(widget.user.uid));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatorBloc, CreatorState>(
      // Only session changes swap the root screen; product/order writes
      // never rebuild it.
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          (previous.profile == null) != (current.profile == null),
      builder: (context, state) {
        if (state.profile != null) {
          return CreatorDashboardPage(user: widget.user);
        }
        switch (state.status) {
          case CreatorSessionStatus.notFound:
            return CreatorOnboardingPage(user: widget.user);
          case CreatorSessionStatus.failure:
            return _ErrorScreen(
              message: state.sessionError ?? 'Could not load your creator profile.',
              onRetry: _loadProfile,
            );
          case CreatorSessionStatus.initial:
          case CreatorSessionStatus.loading:
          case CreatorSessionStatus.ready:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
