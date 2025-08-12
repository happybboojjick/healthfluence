import 'package:flutter/material.dart';
import '../models/category.dart';
import 'routine_list_screen.dart';

class SubCategoryScreen extends StatelessWidget {
  final Category category;

  const SubCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ListView.builder(
        itemCount: category.subCategories.length,
        itemBuilder: (context, index) {
          final subCategory = category.subCategories[index];
          return ListTile(
            title: Text(subCategory.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoutineListScreen(
                    subCategoryId: subCategory.id,
                    subCategoryName: subCategory.name,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}