import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';

class AddProductPage extends StatefulWidget {
  final CreatorProfile profile;
  final CreatorProduct? initialProduct;
  const AddProductPage({super.key, required this.profile, this.initialProduct});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  
  // General Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  
  // Optional Product Details
  late final TextEditingController _materialsController;
  late final TextEditingController _dimensionsController;
  late final TextEditingController _weightController;
  late final TextEditingController _shippingController;

  final List<File> _imageFiles = [];
  final List<String> _existingImageUrls = [];

  // Customization
  bool _isCustomizable = false;
  final List<_CustomizationControllers> _customizationList = [];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    _nameController = TextEditingController(text: p?.name);
    _descriptionController = TextEditingController(text: p?.description);
    _categoryController = TextEditingController(text: p?.category);
    _priceController = TextEditingController(text: p?.price.toString());
    _stockController = TextEditingController(text: p?.stock.toString());
    _materialsController = TextEditingController(text: p?.materials);
    _dimensionsController = TextEditingController(text: p?.dimensions);
    _weightController = TextEditingController(text: p?.weight);
    _shippingController = TextEditingController(text: p?.shippingInfo);

    if (p != null) {
      _existingImageUrls.addAll(p.images);
      _isCustomizable = p.isCustomizable;
      for (var c in p.customizations) {
        final controllers = _CustomizationControllers();
        controllers.nameController.text = c.name;
        controllers.descController.text = c.description;
        controllers.priceController.text = c.additionalPrice.toString();
        controllers.isMultipleSelection = c.isMultipleSelection;
        controllers.hasSubOptions = c.options.isNotEmpty;
        controllers.existingImageUrls.addAll(c.images);
        if (c.options.isNotEmpty) {
           controllers.options.clear();
           for (var opt in c.options) {
             controllers.options.add(TextEditingController(text: opt));
           }
        }
        _customizationList.add(controllers);
      }
    } else {
      _addCustomizationBlock();
    }
  }

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
    for (var c in _customizationList) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCustomizationBlock() {
    if (_customizationList.length < 5) {
      setState(() {
        _customizationList.add(_CustomizationControllers());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 customization categories allowed.')),
      );
    }
  }

  void _removeCustomizationBlock(int index) {
    setState(() {
      _customizationList[index].dispose();
      _customizationList.removeAt(index);
    });
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
      final List<CustomizationInput> customizations = [];
      if (_isCustomizable) {
        for (var c in _customizationList) {
          customizations.add(CustomizationInput(
            name: c.nameController.text,
            description: c.descController.text,
            additionalPrice: double.tryParse(c.priceController.text) ?? 0.0,
            imageFiles: c.imageFiles,
            isMultipleSelection: c.isMultipleSelection,
            options: c.hasSubOptions 
              ? c.options.map((opt) => opt.text).where((s) => s.isNotEmpty).toList()
              : [],
          ));
        }
      }

      if (widget.initialProduct != null) {
        // Edit mode: Check for changes
        final p = widget.initialProduct!;
        bool hasChanges = p.name != _nameController.text ||
            p.description != _descriptionController.text ||
            p.category != _categoryController.text ||
            p.price != (double.tryParse(_priceController.text) ?? 0.0) ||
            p.stock != (int.tryParse(_stockController.text) ?? 0) ||
            p.materials != _materialsController.text ||
            p.dimensions != _dimensionsController.text ||
            p.weight != _weightController.text ||
            p.shippingInfo != _shippingController.text ||
            p.isCustomizable != _isCustomizable ||
            _imageFiles.isNotEmpty ||
            _existingImageUrls.length != p.images.length;

        if (!hasChanges) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No changes detected.')));
          return;
        }

        context.read<CreatorBloc>().add(
              CreatorUpdateProduct(
                productId: widget.initialProduct!.id,
                name: _nameController.text,
                description: _descriptionController.text,
                newImageFiles: _imageFiles,
                existingImageUrls: _existingImageUrls,
                category: _categoryController.text,
                price: double.tryParse(_priceController.text) ?? 0.0,
                stock: int.tryParse(_stockController.text) ?? 0,
                materials: _materialsController.text,
                dimensions: _dimensionsController.text,
                weight: _weightController.text,
                shippingInfo: _shippingController.text,
                creatorUid: widget.profile.uid,
                creatorName: widget.profile.name,
                isCustomizable: _isCustomizable,
                customizations: customizations,
                hasChanges: hasChanges,
              ),
            );
      } else {
        // Add mode
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
                isCustomizable: _isCustomizable,
                customizations: customizations,
              ),
            );
      }
    }
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product submitted for review successfully!')),
            );
            // Refresh listings before going back
            context.read<CreatorBloc>().add(CreatorFetchCreatorProducts(widget.profile.uid));
            Navigator.pop(context);
          } else if (state is CreatorFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is CreatorLoading) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24.0,
              24.0,
              24.0,
              MediaQuery.of(context).viewInsets.bottom + 24.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Product Images (Optional)'),
                  const SizedBox(height: 10),
                  _buildProductImagePicker(),
                  const SizedBox(height: 30),
                  
                  _buildSectionTitle('General Information'),
                  const SizedBox(height: 15),
                  _buildGeneralInfoFields(),
                  const SizedBox(height: 30),

                  _buildCustomizationToggle(),
                  if (_isCustomizable) ...[
                    const SizedBox(height: 20),
                    _buildCustomizationSection(),
                  ],

                  const SizedBox(height: 30),
                  _buildSectionTitle('Product Details (Optional)'),
                  const SizedBox(height: 15),
                  _buildProductDetailsFields(),

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

  Widget _buildProductImagePicker() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAddImageButton(_pickImages),
          ..._existingImageUrls.asMap().entries.map((e) => _buildExistingImageItem(e.key, e.value, (idx) => setState(() => _existingImageUrls.removeAt(idx)))),
          ..._imageFiles.asMap().entries.map((e) => _buildImageItem(e.key, e.value, (idx) => setState(() => _imageFiles.removeAt(idx)))),
        ],
      ),
    );
  }

  Widget _buildExistingImageItem(int index, String url, Function(int) onRemove) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(url, width: 120, height: 120, fit: BoxFit.cover)),
        ),
        Positioned(
          top: 5, right: 5,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120, height: 120,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.outline)),
        child: const Icon(Icons.add_a_photo_outlined, color: AppColors.mutedText),
      ),
    );
  }

  Widget _buildImageItem(int index, File file, Function(int) onRemove) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: kIsWeb
                ? Image.network(file.path, width: 120, height: 120, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey))
                : Image.file(file, width: 120, height: 120, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
        Positioned(
          top: 5, right: 5,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralInfoFields() {
    return Column(
      children: [
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
                decoration: const InputDecoration(labelText: 'Base Price (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
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
      ],
    );
  }

  Widget _buildCustomizationToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Product Customization *'),
        const SizedBox(height: 5),
        const Text('Is this product customizable?', style: TextStyle(fontSize: 14, color: AppColors.mutedText)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ChoiceChip(
                label: 'No',
                isSelected: !_isCustomizable,
                onSelected: (v) => setState(() {
                  _isCustomizable = false;
                  _customizationList.clear();
                }),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _ChoiceChip(
                label: 'Yes',
                isSelected: _isCustomizable,
                onSelected: (v) => setState(() {
                  _isCustomizable = true;
                  if (_customizationList.isEmpty) _addCustomizationBlock();
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Define Customizations (Max 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _customizationList.length,
          separatorBuilder: (_, _) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            return _CustomizationBlock(
              controllers: _customizationList[index],
              onDelete: () => _removeCustomizationBlock(index),
              showDelete: true,
            );
          },
        ),
        const SizedBox(height: 15),
        if (_customizationList.length < 5)
          OutlinedButton.icon(
            onPressed: _addCustomizationBlock,
            icon: const Icon(Icons.add),
            label: const Text('Add More Customizations'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
          ),
      ],
    );
  }

  Widget _buildProductDetailsFields() {
    return Column(
      children: [
        TextFormField(controller: _materialsController, decoration: const InputDecoration(labelText: 'Materials', prefixIcon: Icon(Icons.layers_outlined))),
        const SizedBox(height: 15),
        TextFormField(controller: _dimensionsController, decoration: const InputDecoration(labelText: 'Dimensions (LxWxH)', prefixIcon: Icon(Icons.straighten))),
        const SizedBox(height: 15),
        TextFormField(controller: _weightController, decoration: const InputDecoration(labelText: 'Weight', prefixIcon: Icon(Icons.monitor_weight_outlined))),
        const SizedBox(height: 15),
        TextFormField(controller: _shippingController, decoration: const InputDecoration(labelText: 'Shipping Information', prefixIcon: Icon(Icons.local_shipping_outlined))),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _ChoiceChip({required this.label, required this.isSelected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelected(true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.outline),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.text, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _CustomizationBlock extends StatefulWidget {
  final _CustomizationControllers controllers;
  final VoidCallback onDelete;
  final bool showDelete;

  const _CustomizationBlock({required this.controllers, required this.onDelete, required this.showDelete});

  @override
  State<_CustomizationBlock> createState() => _CustomizationBlockState();
}

class _CustomizationBlockState extends State<_CustomizationBlock> {
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        widget.controllers.imageFiles.addAll(pickedFiles.take(4 - widget.controllers.imageFiles.length).map((f) => File(f.path)));
      });
    }
  }

  void _addOption() {
    if (widget.controllers.options.length < 5) {
      setState(() {
        widget.controllers.options.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    setState(() {
      widget.controllers.options[index].dispose();
      widget.controllers.options.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Customization Block', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
              if (widget.showDelete) IconButton(onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: widget.controllers.nameController,
            decoration: const InputDecoration(labelText: 'Customization Name *', hintText: 'Enter Name'),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.controllers.descController,
            decoration: const InputDecoration(labelText: 'Short Description *'),
            maxLines: 2,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.controllers.priceController,
            decoration: const InputDecoration(labelText: 'Base Additional Price (₹) *', prefixIcon: Icon(Icons.add)),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          const Text('Add options (subcustomizations) for this category?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChoiceChip(
                  label: 'No',
                  isSelected: !widget.controllers.hasSubOptions,
                  onSelected: (v) => setState(() => widget.controllers.hasSubOptions = false),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _ChoiceChip(
                  label: 'Yes',
                  isSelected: widget.controllers.hasSubOptions,
                  onSelected: (v) => setState(() => widget.controllers.hasSubOptions = true),
                ),
              ),
            ],
          ),
          if (widget.controllers.hasSubOptions) ...[
            const SizedBox(height: 20),
            const Text('Selection Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 20,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<bool>(
                      value: false, 
                      groupValue: widget.controllers.isMultipleSelection, 
                      onChanged: (v) => setState(() => widget.controllers.isMultipleSelection = v!),
                    ),
                    const Text('Single Selection'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<bool>(
                      value: true, 
                      groupValue: widget.controllers.isMultipleSelection, 
                      onChanged: (v) => setState(() => widget.controllers.isMultipleSelection = v!),
                    ),
                    const Text('Multiple Selection'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text('Options (Subcustomizations) - Max 5', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.controllers.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: widget.controllers.options[index],
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    IconButton(onPressed: () => _removeOption(index), icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20)),
                  ],
                );
              },
            ),
            if (widget.controllers.options.length < 5)
              TextButton.icon(onPressed: _addOption, icon: const Icon(Icons.add, size: 18), label: const Text('Add Option')),
          ],
          const SizedBox(height: 15),
          const Text('Category Images (Max 4, Optional)', style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (widget.controllers.imageFiles.length + widget.controllers.existingImageUrls.length < 4)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.outline)),
                      child: const Icon(Icons.add_a_photo_outlined, size: 20, color: AppColors.mutedText),
                    ),
                  ),
                ...widget.controllers.existingImageUrls.asMap().entries.map((e) => _buildExistingMiniImage(e.key, e.value)),
                ...widget.controllers.imageFiles.asMap().entries.map((e) => _buildMiniImage(e.key, e.value)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingMiniImage(int index, String url) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover)),
        ),
        Positioned(
          top: 2, right: 2,
          child: GestureDetector(
            onTap: () => setState(() => widget.controllers.existingImageUrls.removeAt(index)),
            child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniImage(int index, File file) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: kIsWeb
                ? Image.network(file.path, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey))
                : Image.file(file, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
        Positioned(
          top: 2, right: 2,
          child: GestureDetector(
            onTap: () => setState(() => widget.controllers.imageFiles.removeAt(index)),
            child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _CustomizationControllers {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  bool hasSubOptions = false;
  bool isMultipleSelection = false;
  final List<TextEditingController> options = [];
  final List<File> imageFiles = [];
  final List<String> existingImageUrls = [];

  _CustomizationControllers() {
    options.add(TextEditingController());
  }

  void dispose() {
    nameController.dispose();
    descController.dispose();
    priceController.dispose();
    for (var o in options) {
      o.dispose();
    }
  }
}
