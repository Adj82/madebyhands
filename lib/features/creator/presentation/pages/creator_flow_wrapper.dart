import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_dashboard_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_onboarding_page.dart';

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
    _checkProfile();
  }

  void _checkProfile() {
    context.read<CreatorBloc>().add(CreatorCheckProfileExists(widget.user.uid));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreatorBloc, CreatorState>(
      listener: (context, state) {
        if (state is CreatorOnboardingSuccess) {
          _checkProfile();
        }
      },
      builder: (context, state) {
        if (state is CreatorLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is CreatorProfileLoaded) {
          return CreatorDashboardPage(profile: state.profile);
        }

        if (state is CreatorProfileNotFound || state is CreatorInitial || state is CreatorOnboardingSuccess) {
          return CreatorOnboardingPage(user: widget.user);
        }

        if (state is CreatorFailure) {
          return _buildErrorScreen(context, state.message);
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _checkProfile, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
