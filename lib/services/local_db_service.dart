import 'package:hive_flutter/hive_flutter.dart';
import 'package:proyecto_recetas/models/recipe.dart';
import 'package:proyecto_recetas/models/ingredient.dart';
import 'package:proyecto_recetas/models/user.dart';
import 'package:uuid/uuid.dart';

class LocalDBService {
  static final LocalDBService _instance = LocalDBService._internal();

  factory LocalDBService() {
    return _instance;
  }

  LocalDBService._internal();

  final _recipesBox = Hive.box<Recipe>('recipes');
  final _ingredientsBox = Hive.box<Ingredient>('ingredients');
  final _usersBox = Hive.box<UserModel>('users');
  final _settingsBox = Hive.box('settings');

  Future<UserModel> createUser(
      String username, String password, String region) async {
    final user = UserModel(
      id: const Uuid().v4(),
      username: username,
      password: password,
      region: region,
    );

    await _usersBox.put(user.id, user);
    return user;
  }

  UserModel? getUserByUsername(String username) {
    final users = _usersBox.values.where((user) => user.username == username);
    return users.isNotEmpty ? users.first : null;
  }

  Future<void> updateUser(UserModel user) async {
    await _usersBox.put(user.id, user);
  }

  Future<void> deleteUser(String userId) async {
    await _usersBox.delete(userId);
  }

  Future<Recipe> createRecipe({
    required String title,
    required String imagePath,
    required List<Ingredient> ingredients,
    required String preparation,
    required String userId,
  }) async {
    final recipe = Recipe(
      id: const Uuid().v4(),
      title: title,
      imagePath: imagePath,
      ingredients: ingredients,
      preparation: preparation,
      createdAt: DateTime.now(),
      userId: userId,
    );

    await _recipesBox.put(recipe.id, recipe);
    return recipe;
  }

  List<Recipe> getUserRecipes(String userId) {
    return _recipesBox.values
        .where((recipe) => recipe.userId == userId)
        .toList();
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _recipesBox.put(recipe.id, recipe);
  }

  Future<void> deleteRecipe(String recipeId) async {
    await _recipesBox.delete(recipeId);
  }

  Future<Ingredient> createIngredient(String name,
      {bool isAIGenerated = false}) async {
    final ingredient = Ingredient(
      id: const Uuid().v4(),
      name: name,
      isAIGenerated: isAIGenerated,
    );

    await _ingredientsBox.put(ingredient.id, ingredient);
    return ingredient;
  }

  List<Ingredient> getMostUsedIngredients(String userId, {int limit = 10}) {
    final userRecipes = getUserRecipes(userId);
    final Map<String, int> ingredientCount = {};

    for (final recipe in userRecipes) {
      for (final ingredient in recipe.ingredients) {
        if (ingredient.isSelected) {
          if (ingredientCount.containsKey(ingredient.name)) {
            ingredientCount[ingredient.name] =
                (ingredientCount[ingredient.name] ?? 0) + 1;
          } else {
            ingredientCount[ingredient.name] = 1;
          }
        }
      }
    }

    final sortedIngredients = ingredientCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topIngredients = sortedIngredients.take(limit).map((entry) {
      return Ingredient(
        id: const Uuid().v4(),
        name: entry.key,
        isSelected: true,
      );
    }).toList();

    return topIngredients;
  }

  Map<String, int> getWeeklyRecipeCount(String userId) {
    final userRecipes = getUserRecipes(userId);
    final Map<String, int> weekdayCounts = {
      'Lunes': 0,
      'Martes': 0,
      'Miércoles': 0,
      'Jueves': 0,
      'Viernes': 0,
      'Sábado': 0,
      'Domingo': 0,
    };

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (final recipe in userRecipes) {
      if (recipe.createdAt.isAfter(startOfWeek)) {
        final weekday = _getWeekdayName(recipe.createdAt.weekday);
        weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
      }
    }

    return weekdayCounts;
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }

  Future<void> saveCurrentUser(String userId) async {
    await _settingsBox.put('currentUserId', userId);
  }

  String? getCurrentUserId() {
    return _settingsBox.get('currentUserId');
  }

  Future<void> clearCurrentUser() async {
    await _settingsBox.delete('currentUserId');
  }
}
