import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_onboarding_page.dart';
import 'package:madebyhands/features/home/presentation/pages/creator_dashboard.dart';

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
    context.read<CreatorBloc>().add(CreatorCheckProfileExists(widget.user.uid));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreatorBloc, CreatorState>(
      builder: (context, state) {
        if (state is CreatorLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CreatorProfileLoaded || state is CreatorOnboardingSuccess) {
          return const CreatorDashboard();
        }

        if (state is CreatorProfileNotFound || state is CreatorInitial) {
          return CreatorOnboardingPage(user: widget.user);
        }

        if (state is CreatorFailure) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error checking profile: ${state.message}'),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<CreatorBloc>()
                          .add(CreatorCheckProfileExists(widget.user.uid));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
