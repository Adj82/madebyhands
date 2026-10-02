import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';

class CategoryManagementView extends StatelessWidget {
  const CategoryManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      buildWhen: (previous, current) =>
          previous.categories != current.categories ||
          previous.isLoading != current.isLoading,
      builder: (context, state) {
        final categories = state.categories;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('New category'),
          ),
          body: RefreshIndicator(
            onRefresh: () async =>
                context.read<AdminBloc>().add(AdminLoadDataRequested()),
            child: categories.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 160),
                      Center(
                        child: state.isLoading
                            ? const CircularProgressIndicator()
                            : const Text('No categories yet. Add one!'),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 90),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.outline,
                            child: Icon(Icons.category, size: 20),
                          ),
                          title: Text(category),
                          subtitle: const Text('Shown to creators and buyers'),
                          trailing: IconButton(
                            onPressed: () => _confirmDelete(context, category),
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: 'Delete category',
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

  Future<void> _confirmDelete(BuildContext context, String category) async {
    final adminBloc = context.read<AdminBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          '"$category" will no longer be offered to creators. Existing products keep their category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) adminBloc.add(AdminDeleteCategoryRequested(category));
  }

  void _showAddCategoryDialog(BuildContext context) {
    final adminBloc = context.read<AdminBloc>();
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            decoration: const InputDecoration(
              hintText: 'Category name (e.g. Candles)',
              helperText: 'Visible to all creators and buyers.',
            ),
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Enter at least 2 characters.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              adminBloc.add(AdminAddCategoryRequested(controller.text.trim()));
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
