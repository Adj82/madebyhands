import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickPortfolioImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _portfolioImages.add(File(pickedFile.path));
      });
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
        title: const Text('Creator Onboarding'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocConsumer<CreatorBloc, CreatorState>(
        listener: (context, state) {
          if (state is CreatorOnboardingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile created successfully!')),
            );
            // The main.dart BlocBuilder will handle navigation once state changes
            // or we might need to trigger a check.
          }
          if (state is CreatorFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is CreatorLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create your Creator Profile',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(Icons.add_a_photo, size: 40)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Creator Name *'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(labelText: 'Bio *'),
                    maxLines: 3,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryController,
                    decoration:
                        const InputDecoration(labelText: 'Primary Category * (e.g. Pottery)'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location *'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _storyController,
                    decoration: const InputDecoration(labelText: 'Your Creator Story *'),
                    maxLines: 5,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text('Social Links',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _socialController,
                          decoration:
                              const InputDecoration(hintText: 'Add a link (Instagram, etc.)'),
                        ),
                      ),
                      IconButton(
                        onPressed: _addSocialLink,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  Wrap(
                    children: _socialLinks
                        .map((link) => Chip(
                              label: Text(link),
                              onDeleted: () => setState(() => _socialLinks.remove(link)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Portfolio Images',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._portfolioImages.map((file) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
                            )),
                        GestureDetector(
                          onTap: _pickPortfolioImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Complete Profile'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
