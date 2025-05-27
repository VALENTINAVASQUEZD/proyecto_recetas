import 'package:hive/hive.dart';

part 'ingredient.g.dart';

@HiveType(typeId: 3)
class Ingredient extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  bool isSelected;
  
  @HiveField(3)
  bool isAIGenerated;

  Ingredient({
    required this.id,
    required this.name,
    this.isSelected = false,
    this.isAIGenerated = false,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isSelected': isSelected,
      'isAIGenerated': isAIGenerated,
    };
  }
  
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      isSelected: json['isSelected'] ?? false,
      isAIGenerated: json['isAIGenerated'] ?? false,
    );
  }
}
