import 'package:hive/hive.dart';
import 'ingredient.dart';

part 'recipe.g.dart';

@HiveType(typeId: 3)
class Recipe extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String imagePath;
  
  @HiveField(3)
  List<Ingredient> ingredients;
  
  @HiveField(4)
  String preparation;
  
  @HiveField(5)
  DateTime createdAt;
  
  @HiveField(6)
  String userId;
  
  @HiveField(7)
  String? appwriteId;
  
  @HiveField(8)
  bool isSynced;

  Recipe({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.ingredients,
    required this.preparation,
    required this.createdAt,
    required this.userId,
    this.appwriteId,
    this.isSynced = false,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imagePath': imagePath,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'preparation': preparation,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'appwriteId': appwriteId,
      'isSynced': isSynced,
    };
  }
  
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      imagePath: json['imagePath'],
      ingredients: (json['ingredients'] as List)
          .map((e) => Ingredient.fromJson(e))
          .toList(),
      preparation: json['preparation'],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
      appwriteId: json['appwriteId'],
      isSynced: json['isSynced'] ?? false,
    );
  }
}
