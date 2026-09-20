import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class AddProductPage extends StatefulWidget {
  final CreatorProfile profile;
  const AddProductPage({super.key, required this.profile});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _materialsController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _weightController = TextEditingController();
  final _shippingController = TextEditingController();

  final List<File> _imageFiles = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _materialsController.dispose();
    _dimensionsController.dispose();
    _weightController.dispose();
    _shippingController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<CreatorBloc>().add(
            CreatorAddProduct(
              name: _nameController.text,
              description: _descriptionController.text,
              imageFiles: _imageFiles,
              category: _categoryController.text,
              price: double.tryParse(_priceController.text) ?? 0.0,
              stock: int.tryParse(_stockController.text) ?? 0,
              materials: _materialsController.text,
              dimensions: _dimensionsController.text,
              weight: _weightController.text,
              shippingInfo: _shippingController.text,
              creatorUid: widget.profile.uid,
              creatorName: widget.profile.name,
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
            Text('Submission Successful'),
          ],
        ),
        content: const Text(
          'Your product has been submitted and is now under review by our moderation team. You will be notified once it is approved and live.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
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
        title: const Text('Add New Product', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocConsumer<CreatorBloc, CreatorState>(
        listener: (context, state) {
          if (state is CreatorAddProductSuccess) {
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Product Images (Optional)'),
                  const SizedBox(height: 10),
                  _buildImagePicker(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('General Information'),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.shopping_bag_outlined)),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description *', alignLabelWithHint: true),
                    maxLines: 4,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Price (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: const InputDecoration(labelText: 'Stock/Quantity *', prefixIcon: Icon(Icons.inventory_2_outlined)),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category *', prefixIcon: Icon(Icons.category_outlined)),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Product Details (Optional)'),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _materialsController,
                    decoration: const InputDecoration(labelText: 'Materials (e.g. Clay, Cotton)', prefixIcon: Icon(Icons.layers_outlined)),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _dimensionsController,
                    decoration: const InputDecoration(labelText: 'Dimensions (LxWxH)', prefixIcon: Icon(Icons.straighten)),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Weight', prefixIcon: Icon(Icons.monitor_weight_outlined)),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _shippingController,
                    decoration: const InputDecoration(labelText: 'Shipping Information', prefixIcon: Icon(Icons.local_shipping_outlined)),
                  ),
                  const SizedBox(height: 50),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit & Apply for Review'),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary));
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImages,
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
          ),
          ..._imageFiles.asMap().entries.map((e) {
            final index = e.key;
            final file = e.value;
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
                    onTap: () => setState(() => _imageFiles.removeAt(index)),
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
