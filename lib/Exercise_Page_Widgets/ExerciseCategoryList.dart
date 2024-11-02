//display the list of categories in 'bibliotheque'
import 'package:flutter/material.dart';

class ExerciseCategoryList extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Function(String) onCategoryTap;
  final bool isDarkMode;

  const ExerciseCategoryList({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: Icon(
            category['icon'],
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          title: Text(
            category['name'],
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          onTap: () => onCategoryTap(category['name']),
        );
      },
    );
  }
}
