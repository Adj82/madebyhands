import 'package:flutter/material.dart';
import 'package:madebyhands/core/theme/app_theme.dart';

class CategoryManagementView extends StatelessWidget {
  const CategoryManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ['Pottery', 'Jewellery', 'Home Decor', 'Textiles', 'Gifts', 'Paintings', 'Digital Art'];
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
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
                  IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
