import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class CreatorOnboardingPage extends StatefulWidget {
  final UserEntity user;
  const CreatorOnboardingPage({super.key, required this.user});

  @override
  State<CreatorOnboardingPage> createState() => _CreatorOnboardingPageState();
}

class _CreatorOnboardingPageState extends State<CreatorOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _socialController = TextEditingController();
  final _storyController = TextEditingController();

  File? _profileImage;
  final List<File> _portfolioImages = [];
  final List<String> _socialLinks = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _socialController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> _pickPortfolioImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _portfolioImages.add(File(pickedFile.path)));
    }
  }

  void _addSocialLink() {
    if (_socialController.text.isNotEmpty) {
      setState(() {
        _socialLinks.add(_socialController.text);
        _socialController.clear();
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<CreatorBloc>().add(
            CreatorSubmitOnboarding(
              uid: widget.user.uid,
              name: _nameController.text,
              profileImageFile: _profileImage,
              bio: _bioController.text,
              category: _categoryController.text,
              location: _locationController.text,
              socialLinks: _socialLinks,
              portfolioImageFiles: _portfolioImages,
              story: _storyController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Onboarding', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocConsumer<CreatorBloc, CreatorState>(
        listener: (context, state) {
          if (state is CreatorOnboardingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile created successfully!')));
          } else if (state is CreatorFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is CreatorLoading) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _OnboardingHeader(),
                  const SizedBox(height: 30),
                  _buildProfileImagePicker(),
                  const SizedBox(height: 30),
                  _buildFormFields(),
                  const SizedBox(height: 30),
                  _buildSocialLinksSection(),
                  const SizedBox(height: 30),
                  _buildPortfolioSection(),
                  const SizedBox(height: 50),
                  FilledButton(onPressed: _submit, child: const Text('Launch My Studio')),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Column(
      children: [
        const Center(child: Text('Profile Picture (Optional)', style: TextStyle(color: AppColors.mutedText, fontSize: 12))),
        const SizedBox(height: 10),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.outline,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: AppColors.primary,
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
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _categoryController,
          decoration: const InputDecoration(labelText: 'Primary Craft Category *', hintText: 'e.g. Pottery', prefixIcon: Icon(Icons.category_outlined)),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(labelText: 'Location *', hintText: 'City, Country', prefixIcon: Icon(Icons.location_on_outlined)),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(labelText: 'Short Bio *', alignLabelWithHint: true),
          maxLines: 3,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _storyController,
          decoration: const InputDecoration(labelText: 'Your Creator Story *', hintText: 'Tell us your inspiration...', alignLabelWithHint: true),
          maxLines: 5,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Social Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _socialController,
                decoration: const InputDecoration(hintText: 'Instagram, Website, etc.', prefixIcon: Icon(Icons.link)),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _addSocialLink,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _socialLinks.map((link) => Chip(
            label: Text(link, style: const TextStyle(fontSize: 12)),
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
        const Text('Showcase Portfolio (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddPortfolioButton(),
              ..._portfolioImages.asMap().entries.map((e) => _buildPortfolioItem(e.key, e.value)),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.outline),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: AppColors.mutedText),
      ),
    );
  }

  Widget _buildPortfolioItem(int index, File file) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(file, width: 120, height: 120, fit: BoxFit.cover),
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
  const _OnboardingHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Complete your Artisan Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        SizedBox(height: 8),
        Text('Tell the world about your craft and story.', style: TextStyle(fontSize: 14, color: AppColors.mutedText)),
      ],
    );
  }
}
