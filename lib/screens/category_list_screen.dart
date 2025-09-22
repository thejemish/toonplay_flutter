import 'package:flutter/material.dart';
import 'package:toonplay/widgets/custom_app_bar.dart';
import 'package:toonplay/widgets/custom_bottom_bar.dart';

class CategoryListScreen extends StatelessWidget{
  const CategoryListScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      bottomNavigationBar: CustomBottomBar(),
      body: Center(
        child: Text('This is category list page $slug'),
      ),
    );
  }
}