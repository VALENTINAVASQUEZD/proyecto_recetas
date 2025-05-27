import 'package:flutter/material.dart';


class AppwriteConstants {
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = '68363bfe000210ecc4f3';
  static const String databaseId = '68363c61002bcb6bc029';
  static const String recipesCollectionId = 'recipes';
  static const String usersCollectionId = 'users';
  static const String storageId = 'recipe-images';
}


class MLConstants {
  static const String geminiApiKey = 'AIzaSyBf4o59T0-8-fVOjtvLE2uYQpGjwEAsp_I';
}


class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFF8BC34A);
  static const Color accent = Color(0xFFFF9800);
  static const Color background = Color(0xFFF5F5F5);
  static const Color text = Color(0xFF333333);
  static const Color textLight = Color(0xFF757575);
}

class ColombiaRegions {
  static const List<String> regions = [
    'Región Andina',
    'Región Caribe',
    'Región Pacífica',
    'Región Orinoquía',
    'Región Amazonía',
    'Región Insular',
  ];
}

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String myRecipes = '/my-recipes';
  static const String camera = '/camera';
  static const String recipeEdit = '/recipe-edit';
  static const String recipeDetail = '/recipe-detail';
  static const String profile = '/profile';
  static const String statistics = '/statistics';
}
