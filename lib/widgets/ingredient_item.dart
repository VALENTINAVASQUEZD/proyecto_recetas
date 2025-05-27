import 'package:flutter/material.dart';
import 'package:recipe_app/models/ingredient.dart';
import 'package:recipe_app/utils/constants.dart';

class IngredientItem extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  
  const IngredientItem({
    Key? key,
    required this.ingredient,
    required this.onToggle,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.background,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: ingredient.isSelected,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Text(
                ingredient.name,
                style: TextStyle(
                  decoration: ingredient.isSelected
                      ? TextDecoration.none
                      : TextDecoration.lineThrough,
                  color: ingredient.isSelected
                      ? AppColors.text
                      : AppColors.textLight,
                ),
              ),
            ),
            if (ingredient.isAIGenerated)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'Generado por IA',
                  child: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              color: AppColors.textLight,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
