import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';

part 'creator_event.dart';
part 'creator_state.dart';

class CreatorBloc extends Bloc<CreatorEvent, CreatorState> {
  final CreatorRepository _creatorRepository;

  CreatorBloc({
    required CreatorRepository creatorRepository,
  })  : _creatorRepository = creatorRepository,
        super(CreatorInitial()) {
    on<CreatorCheckProfileExists>(_onCheckProfileExists);
    on<CreatorSubmitOnboarding>(_onSubmitOnboarding);
  }

  void _onCheckProfileExists(
    CreatorCheckProfileExists event,
    Emitter<CreatorState> emit,
  ) async {
    emit(CreatorLoading());
    final res = await _creatorRepository.getCreatorProfile(event.uid);
    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) {
        if (r == null) {
          emit(CreatorProfileNotFound());
        } else {
          emit(CreatorProfileLoaded(r));
        }
      },
    );
  }

  void _onSubmitOnboarding(
    CreatorSubmitOnboarding event,
    Emitter<CreatorState> emit,
  ) async {
    emit(CreatorLoading());
    final res = await _creatorRepository.saveCreatorProfile(
      uid: event.uid,
      name: event.name,
      profileImageFile: event.profileImageFile,
      bio: event.bio,
      category: event.category,
      location: event.location,
      socialLinks: event.socialLinks,
      portfolioImageFiles: event.portfolioImageFiles,
      story: event.story,
    );

    res.fold(
      (l) => emit(CreatorFailure(l.message)),
      (r) => emit(CreatorOnboardingSuccess()),
    );
  }
}
