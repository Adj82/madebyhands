import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/init_dependencies.dart';

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
  late String _existingPhotoUrl = widget.profile.latestPhoto;
  late String _existingIdCardUrl = widget.profile.idCard;
  bool _documentsMissing = false;

  @override
  void initState() {
    super.initState();
    _creatorNameController = TextEditingController(text: widget.profile.name);
    _businessNameController = TextEditingController(text: widget.profile.businessName);
    _addressController = TextEditingController(text: widget.profile.address);
    _loadPreviousSubmission();
  }

  Future<void> _loadPreviousSubmission() async {
    try {
      final result = await serviceLocator<CreatorRepository>().getVerificationDocuments(
        widget.profile.uid,
      );
      final documents = result.getRight().toNullable();
      if (!mounted || documents == null) return;
      setState(() {
        if (_businessNameController.text.trim().isEmpty) {
          _businessNameController.text = documents.businessName;
        }
        if (_addressController.text.trim().isEmpty) {
          _addressController.text = documents.address;
        }
        if (documents.latestPhotoUrl.isNotEmpty) _existingPhotoUrl = documents.latestPhotoUrl;
        if (documents.idCardUrl.isNotEmpty) _existingIdCardUrl = documents.idCardUrl;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _creatorNameController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<File?> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 2000,
      );
      return picked == null ? null : File(picked.path);
    } catch (_) {
      return null;
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final hasPhoto = _latestPhotoFile != null || _existingPhotoUrl.isNotEmpty;
    final hasId = _idCardFile != null || _existingIdCardUrl.isNotEmpty;
    setState(() => _documentsMissing = !hasPhoto || !hasId);
    if (!_formKey.currentState!.validate() || _documentsMissing) return;
    context.read<CreatorBloc>().add(
      CreatorSubmitVerification(
        uid: widget.profile.uid,
        creatorName: _creatorNameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        address: _addressController.text.trim(),
        latestPhotoFile: _latestPhotoFile,
        idCardFile: _idCardFile,
        existingLatestPhotoUrl: _existingPhotoUrl,
        existingIdCardUrl: _existingIdCardUrl,
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Request submitted'),
        content: const Text(
          'Our team will review your documents shortly. You can follow the status on your dashboard.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back to studio'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile.isVerified) {
      // Verified creators can only view what was submitted. Letting them
      // resubmit would reset verificationStatus back to 'In-Process' and
      // block them from listing products until an admin re-approves.
      return _VerifiedDocumentsView(
        profile: widget.profile,
        businessName: _businessNameController.text,
        address: _addressController.text,
        photoUrl: _existingPhotoUrl,
        idCardUrl: _existingIdCardUrl,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Get verified', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocConsumer<CreatorBloc, CreatorState>(
        listenWhen: (previous, current) =>
            previous.actionId != current.actionId &&
            current.action == CreatorAction.submitVerification &&
            current.actionStatus != CreatorActionStatus.inProgress,
        listener: (context, state) {
          if (state.actionStatus == CreatorActionStatus.success) {
            _showSuccessDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionMessage ?? 'Could not submit. Please try again.')),
            );
          }
        },
        builder: (context, state) {
          final submitting = state.isRunning(CreatorAction.submitVerification);
          return AbsorbPointer(
            absorbing: submitting,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Creator verification',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verified creators can list products. Your documents are only visible to the MadeByHands team.',
                      style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                    ),
                    if (widget.profile.isVerificationRejected &&
                        widget.profile.verificationNote.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Previous request was not approved: ${widget.profile.verificationNote}',
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _creatorNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name (as on your ID) *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Business / storefront name *',
                        helperText: 'Shown to buyers on your storefront.',
                        prefixIcon: Icon(Icons.storefront),
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Documents *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    _FilePickerTile(
                      title: 'Recent photo of you',
                      subtitle: 'Clear, well-lit portrait',
                      hasNewFile: _latestPhotoFile != null,
                      hasExisting: _existingPhotoUrl.isNotEmpty,
                      onTap: () async {
                        final file = await _pickImage();
                        if (file != null) setState(() => _latestPhotoFile = file);
                      },
                    ),
                    const SizedBox(height: 15),
                    _FilePickerTile(
                      title: 'PAN card / government ID',
                      subtitle: 'Photo of an official ID',
                      hasNewFile: _idCardFile != null,
                      hasExisting: _existingIdCardUrl.isNotEmpty,
                      onTap: () async {
                        final file = await _pickImage();
                        if (file != null) setState(() => _idCardFile = file);
                      },
                    ),
                    if (_documentsMissing)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Please add both documents.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 40),
                    FilledButton(
                      onPressed: submitting ? null : _submit,
                      child: submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit for verification'),
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
}

class _VerifiedDocumentsView extends StatelessWidget {
  final CreatorProfile profile;
  final String businessName;
  final String address;
  final String photoUrl;
  final String idCardUrl;

  const _VerifiedDocumentsView({
    required this.profile,
    required this.businessName,
    required this.address,
    required this.photoUrl,
    required this.idCardUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Verification documents', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You're a verified creator. Your documents are on file "
                      'with the MadeByHands team.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              businessName.isEmpty ? profile.businessName : businessName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              address.isEmpty ? profile.address : address,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 24),
            const Text('Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _SubmittedDocumentTile(
              title: 'Recent photo of you',
              uploaded: photoUrl.isNotEmpty,
            ),
            const SizedBox(height: 15),
            _SubmittedDocumentTile(
              title: 'PAN card / government ID',
              uploaded: idCardUrl.isNotEmpty,
            ),
            const SizedBox(height: 24),
            const Text(
              'To update these documents, please contact the MadeByHands team.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmittedDocumentTile extends StatelessWidget {
  final String title;
  final bool uploaded;

  const _SubmittedDocumentTile({required this.title, required this.uploaded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(
            uploaded ? Icons.check_circle : Icons.error_outline,
            color: uploaded ? Colors.green : AppColors.mutedText,
            size: 30,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Text(
            uploaded ? 'On file' : 'Not on file',
            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool hasNewFile;
  final bool hasExisting;
  final VoidCallback onTap;

  const _FilePickerTile({
    required this.title,
    required this.subtitle,
    required this.hasNewFile,
    required this.hasExisting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = hasNewFile || hasExisting;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(
            hasFile ? Icons.check_circle : Icons.upload_file,
            color: hasFile ? Colors.green : AppColors.mutedText,
            size: 30,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  hasNewFile
                      ? 'New file selected'
                      : (hasExisting ? 'Previously uploaded' : subtitle),
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onTap,
            // The app-wide OutlinedButtonTheme sets minimumSize to
            // Size.fromHeight(56), i.e. an infinite minimum width, meant for
            // full-width buttons stretched in a Column. Inside this Row that
            // infinite minimum conflicts with the Row's loose width
            // constraint and crashes layout, so override it with a compact
            // bounded size for this button only.
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 36)),
            child: Text(hasFile ? 'Change' : 'Select'),
          ),
        ],
      ),
    );
  }
}
