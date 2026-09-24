import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class CreatorVerificationPage extends StatefulWidget {
  final CreatorProfile profile;
  const CreatorVerificationPage({super.key, required this.profile});

  @override
  State<CreatorVerificationPage> createState() => _CreatorVerificationPageState();
}

class _CreatorVerificationPageState extends State<CreatorVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _creatorNameController;
  late final TextEditingController _businessNameController;
  late final TextEditingController _addressController;

  File? _latestPhotoFile;
  File? _idCardFile;
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      context.read<CreatorBloc>().add(CreatorCheckProfileExists(widget.profile.uid));
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _creatorNameController = TextEditingController(text: widget.profile.name);
    _businessNameController = TextEditingController(text: widget.profile.businessName);
    _addressController = TextEditingController(text: widget.profile.address);
  }

  @override
  void dispose() {
    _creatorNameController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLatestPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _latestPhotoFile = File(pickedFile.path));
    }
  }

  Future<void> _pickIdCard() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _idCardFile = File(pickedFile.path));
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<CreatorBloc>().add(
            CreatorSubmitVerification(
              uid: widget.profile.uid,
              creatorName: _creatorNameController.text,
              businessName: _businessNameController.text,
              address: _addressController.text,
              latestPhotoFile: _latestPhotoFile,
              idCardFile: _idCardFile,
              existingLatestPhotoUrl: widget.profile.latestPhoto,
              existingIdCardUrl: widget.profile.idCard,
            ),
          );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Request Submitted'),
          ],
        ),
        content: const Text(
          'Your verification details have been successfully submitted for review. Our admin team will verify your documents shortly. You can check your status on the dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Trigger profile refresh to show In-Process status
              this.context.read<CreatorBloc>().add(CreatorCheckProfileExists(widget.profile.uid));
              Navigator.pop(this.context); // Back to Creator Studio
            },
            child: const Text('Back to Studio'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Verified', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocConsumer<CreatorBloc, CreatorState>(
        listener: (context, state) {
          if (state is CreatorVerificationSuccess) {
            _showSuccessDialog();
          } else if (state is CreatorFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is CreatorLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Creator Verification Request',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Provide your authentic business information to enable storefront access and product listings.',
                      style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _creatorNameController,
                      decoration: const InputDecoration(
                        labelText: "Creator's Full Name *",
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Business/Storefront Name *',
                        prefixIcon: Icon(Icons.storefront),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Current Registered Address *',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 30),
                    const Text('Documents (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _buildFilePickerTile(
                      title: 'Latest Photo',
                      subtitle: 'Clear, well-lit portrait photo',
                      file: _latestPhotoFile,
                      existingUrl: widget.profile.latestPhoto,
                      onTap: _pickLatestPhoto,
                    ),
                    const SizedBox(height: 15),
                    _buildFilePickerTile(
                      title: 'PAN Card / Identity Card',
                      subtitle: 'Official government-issued ID card',
                      file: _idCardFile,
                      existingUrl: widget.profile.idCard,
                      onTap: _pickIdCard,
                    ),
                    const SizedBox(height: 40),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(widget.profile.verificationStatus == 'Verified' ? 'Re-Submit & Await Review' : 'Submit for Verification'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilePickerTile({
    required String title,
    required String subtitle,
    required File? file,
    required String existingUrl,
    required VoidCallback onTap,
  }) {
    final hasFile = file != null || existingUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(hasFile ? Icons.check_circle : Icons.upload_file, color: hasFile ? Colors.green : AppColors.mutedText, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(file != null ? 'New file selected' : (existingUrl.isNotEmpty ? 'Previously uploaded' : subtitle), style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            child: Text(hasFile ? 'Change' : 'Select'),
          ),
        ],
      ),
    );
  }
}
