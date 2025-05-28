import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  late Box<UserModel> _usersBox;
  late Box<Recipe> _recipesBox;
  late Box _settingsBox;
  
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(RecipeAdapter());
    Hive.registerAdapter(IngredientAdapter());
    
    _usersBox = await Hive.openBox<UserModel>('users');
    _recipesBox = await Hive.openBox<Recipe>('recipes');
    _settingsBox = await Hive.openBox('settings');
  }
  
  Future<UserModel> createUser(String username, String password, String region) async {
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
    return _recipesBox.values.where((recipe) => recipe.userId == userId).toList();
  }
  
  Future<void> updateRecipe(Recipe recipe) async {
    await _recipesBox.put(recipe.id, recipe);
  }
  
  Future<void> deleteRecipe(String recipeId) async {
    await _recipesBox.delete(recipeId);
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
  
  Map<String, int> getMostUsedIngredients(String userId, {int limit = 10}) {
    final userRecipes = getUserRecipes(userId);
    final Map<String, int> ingredientCount = {};
    
    for (final recipe in userRecipes) {
      for (final ingredient in recipe.ingredients) {
        if (ingredient.isSelected) {
          ingredientCount[ingredient.name] = (ingredientCount[ingredient.name] ?? 0) + 1;
        }
      }
    }
    
    final sortedEntries = ingredientCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(limit));
  }
  
  Map<String, int> getWeeklyRecipeCount(String userId) {
    final userRecipes = getUserRecipes(userId);
    final Map<String, int> weekdayCounts = {
      'Lun': 0, 'Mar': 0, 'Mié': 0, 'Jue': 0, 'Vie': 0, 'Sáb': 0, 'Dom': 0,
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
      case 1: return 'Lun';
      case 2: return 'Mar';
      case 3: return 'Mié';
      case 4: return 'Jue';
      case 5: return 'Vie';
      case 6: return 'Sáb';
      case 7: return 'Dom';
      default: return '';
    }
  }
}
