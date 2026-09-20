import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';

class CategoryManagementView extends StatelessWidget {
  const CategoryManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final categories = state.categories;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddCategoryDialog(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add),
            label: const Text('New Category'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.outline, child: Icon(Icons.category, size: 20)),
                  title: Text(categories[index]),
                  subtitle: Text('${index * 12 + 5} products listed'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
                      IconButton(
                        onPressed: () {
                          context.read<AdminBloc>().add(AdminDeleteCategoryRequested(categories[index]));
                        }, 
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent)
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Category name (e.g. Candles)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<AdminBloc>().add(AdminAddCategoryRequested(controller.text));
                Navigator.pop(dialogContext);
              }
            }, 
            child: const Text('Add')
          ),
        ],
      ),
    );
  }
}
