import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madebyhands/core/constants/image_upload.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class CreatorOnboardingPage extends StatefulWidget {
  final UserEntity user;
  final CreatorProfile? existingProfile;

  const CreatorOnboardingPage({
    super.key,
    required this.user,
    this.existingProfile,
  });

  @override
  State<CreatorOnboardingPage> createState() => _CreatorOnboardingPageState();
}

class _CreatorOnboardingPageState extends State<CreatorOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _socialController = TextEditingController();
  final _storyController = TextEditingController();

  File? _profileImage;
  final List<File> _portfolioImages = [];
  final List<String> _existingPortfolioUrls = [];
  final List<String> _socialLinks = [];
  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _nameController.text = p?.name ?? widget.user.name;
    _bioController.text = p?.bio ?? '';
    _locationController.text = p?.location ?? '';
    _storyController.text = p?.story ?? '';

    if (p != null) {
      _socialLinks.addAll(p.socialLinks);
      _existingPortfolioUrls.addAll(p.portfolio);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _socialController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: kImageQuality,
      maxWidth: kProfileImageMaxSide,
      maxHeight: kProfileImageMaxSide,
    );
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> _pickPortfolioImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: kImageQuality,
      maxWidth: kProfileImageMaxSide,
      maxHeight: kProfileImageMaxSide,
    );
    if (pickedFile != null) {
      setState(() => _portfolioImages.add(File(pickedFile.path)));
    }
  }

  static final RegExp _domainPattern = RegExp(
    r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)+$',
  );

  /// True only for something that is actually a link (a real domain, with or
  /// without a scheme/path) — not arbitrary free text.
  bool _isValidLink(String raw) {
    if (raw.contains(' ')) return false;
    final candidate = raw.contains('://') ? raw : 'https://$raw';
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.isEmpty) return false;
    return _domainPattern.hasMatch(uri.host);
  }

  void _addSocialLink() {
    final raw = _socialController.text.trim();
    if (raw.isEmpty) return;
    if (!_isValidLink(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid link, e.g. instagram.com/yourshop'),
        ),
      );
      return;
    }
    final normalized = raw.contains('://') ? raw : 'https://$raw';
    if (_socialLinks.contains(normalized)) {
      _socialController.clear();
      return;
    }
    setState(() {
      _socialLinks.add(normalized);
      _socialController.clear();
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      context.read<CreatorBloc>().add(
            CreatorSubmitOnboarding(
              uid: widget.user.uid,
              name: _nameController.text.trim(),
              profileImageFile: _profileImage,
              bio: _bioController.text.trim(),
              location: _locationController.text.trim(),
              socialLinks: List.of(_socialLinks),
              portfolioImageFiles: List.of(_portfolioImages),
              story: _storyController.text.trim(),
              existingProfileImageUrl: widget.existingProfile?.profileImage,
              existingPortfolioUrls: List.of(_existingPortfolioUrls),
            ),
          );
    }
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profileImage != null) {
      if (kIsWeb) {
        return NetworkImage(_profileImage!.path);
      } else {
        return FileImage(_profileImage!);
      }
    }
    if (widget.existingProfile != null && widget.existingProfile!.profileImage.isNotEmpty) {
      return NetworkImage(widget.existingProfile!.profileImage);
    }
    return null;
  }

  Widget _buildFileImageWidget(File file, {required double width, required double height}) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingProfile != null;

    return BuyerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            isEditMode ? 'Edit Creator Profile' : 'Creator Onboarding',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B261D),
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF8B261D)),
          actions: [
            if (!isEditMode)
              IconButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthLogoutRequested()),
                icon: const Icon(Icons.logout, color: Color(0xFF8B261D)),
              ),
          ],
        ),
      body: BlocConsumer<CreatorBloc, CreatorState>(
        listenWhen: (previous, current) =>
            previous.actionId != current.actionId &&
            current.action == CreatorAction.saveProfile &&
            current.actionStatus != CreatorActionStatus.inProgress,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.actionStatus == CreatorActionStatus.failure) {
            messenger.showSnackBar(
              SnackBar(content: Text(state.actionMessage ?? 'Could not save your profile.')),
            );
            return;
          }
          messenger.showSnackBar(
            SnackBar(
              content: Text(isEditMode ? 'Profile updated.' : 'Welcome to MadeByHands!'),
            ),
          );
          if (isEditMode) Navigator.pop(context);
        },
        buildWhen: (previous, current) =>
            previous.isRunning(CreatorAction.saveProfile) !=
            current.isRunning(CreatorAction.saveProfile),
        builder: (context, state) {
          final saving = state.isRunning(CreatorAction.saveProfile);
          return AbsorbPointer(
            absorbing: saving,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24.0,
                16.0,
                24.0,
                MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OnboardingHeader(isEditMode: isEditMode),
                    const SizedBox(height: 30),
                    _buildProfileImagePicker(),
                    const SizedBox(height: 30),
                    _buildFormFields(),
                    const SizedBox(height: 30),
                    _buildSocialLinksSection(),
                    const SizedBox(height: 30),
                    _buildPortfolioSection(),
                    const SizedBox(height: 50),
                    FilledButton(
                      onPressed: saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B261D),
                        foregroundColor: Colors.white,
                      ),
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditMode ? 'Save profile changes' : 'Launch my studio'),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildProfileImagePicker() {
    final hasImage = _profileImage != null ||
        (widget.existingProfile != null && widget.existingProfile!.profileImage.isNotEmpty);

    return Column(
      children: [
        const Center(
          child: Text(
            'Profile Picture',
            style: TextStyle(color: Color(0xFF8A8F82), fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF8B261D).withValues(alpha: 0.1),
                backgroundImage: _getProfileImageProvider(),
                child: !hasImage ? const Icon(Icons.person, size: 60, color: Color(0xFF8B261D)) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF8B261D),
                  radius: 20,
                  child: IconButton(
                    onPressed: _pickProfileImage,
                    icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Artisan/Studio Name *', prefixIcon: Icon(Icons.storefront)),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(labelText: 'Location *', hintText: 'City, Country', prefixIcon: Icon(Icons.location_on_outlined)),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(labelText: 'Short Bio *', alignLabelWithHint: true),
          maxLines: 3,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _storyController,
          decoration: const InputDecoration(labelText: 'Your Creator Story *', hintText: 'Tell us your inspiration...', alignLabelWithHint: true),
          maxLines: 5,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Social Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B261D))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _socialController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'e.g. instagram.com/yourshop',
                  prefixIcon: Icon(Icons.link),
                ),
                onFieldSubmitted: (_) => _addSocialLink(),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _addSocialLink,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF8B261D)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _socialLinks.map((link) => Chip(
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(link, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ),
            onDeleted: () => setState(() => _socialLinks.remove(link)),
            deleteIconColor: Colors.red,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B261D))),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddPortfolioButton(),
              ..._existingPortfolioUrls.asMap().entries.map(
                    (e) => _buildExistingPortfolioItem(e.key, e.value),
                  ),
              ..._portfolioImages.asMap().entries.map(
                    (e) => _buildPortfolioItem(e.key, e.value),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddPortfolioButton() {
    return GestureDetector(
      onTap: _pickPortfolioImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6EE),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF8B261D).withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF8A8F82)),
      ),
    );
  }

  Widget _buildExistingPortfolioItem(int index, String url) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              url,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              cacheWidth: 360,
              errorBuilder: (_, _, _) => Container(
                width: 120,
                height: 120,
                color: const Color(0xFFEAE7DC),
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () => setState(() => _existingPortfolioUrls.removeAt(index)),
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioItem(int index, File file) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildFileImageWidget(file, width: 120, height: 120),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () => setState(() => _portfolioImages.removeAt(index)),
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  final bool isEditMode;

  const _OnboardingHeader({this.isEditMode = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditMode ? 'Update Your Studio Profile' : 'Complete your Artisan Profile',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF8B261D)),
        ),
        const SizedBox(height: 8),
        Text(
          isEditMode
              ? 'Keep your craft story, links, and portfolio up to date.'
              : 'Tell the world about your craft and story.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF8A8F82)),
        ),
      ],
    );
  }
}
