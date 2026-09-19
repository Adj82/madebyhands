part of 'creator_bloc.dart';

@immutable
sealed class CreatorEvent {}

final class CreatorCheckProfileExists extends CreatorEvent {
  final String uid;
  CreatorCheckProfileExists(this.uid);
}

final class CreatorSubmitOnboarding extends CreatorEvent {
  final String uid;
  final String name;
  final File? profileImageFile;
  final String bio;
  final String category;
  final String location;
  final List<String> socialLinks;
  final List<File> portfolioImageFiles;
  final String story;

  CreatorSubmitOnboarding({
    required this.uid,
    required this.name,
    this.profileImageFile,
    required this.bio,
    required this.category,
    required this.location,
    required this.socialLinks,
    required this.portfolioImageFiles,
    required this.story,
  });
}
