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
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<AdminBloc>().add(AdminLoadDataRequested());
            },
            child: categories.isEmpty && !state.isLoading
                ? const Center(child: Text('No categories found. Add one!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                              backgroundColor: AppColors.outline, child: Icon(Icons.category, size: 20)),
                          title: Text(category),
                          subtitle: const Text('Global marketplace category'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  context.read<AdminBloc>().add(AdminDeleteCategoryRequested(category));
                                },
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Delete Category',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Category name (e.g. Candles)',
            helperText: 'This will be visible to all users.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<AdminBloc>().add(AdminAddCategoryRequested(controller.text.trim()));
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
