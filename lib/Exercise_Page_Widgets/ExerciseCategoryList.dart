// lib/Exercise_Page_Widgets/ExerciseCategoryList.dart

import 'package:flutter/material.dart';

class ExerciseCategoryList extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Function(String) onCategoryTap;

  const ExerciseCategoryList({
    Key? key,
    required this.categories,
    required this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: Icon(category['icon'], color: Colors.black),
          title: Text(category['name']),
          onTap: () => onCategoryTap(category['name']),
        );
      },
    );
  }
}
