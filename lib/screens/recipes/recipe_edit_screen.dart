import 'dart:io';
import 'package:flutter/material.dart';
import 'package:proyecto_recetas/models/ingredient.dart';
import 'package:proyecto_recetas/models/recipe.dart';
import 'package:proyecto_recetas/models/user.dart';
import 'package:proyecto_recetas/services/ai_service.dart';
import 'package:proyecto_recetas/services/local_db_service.dart';
import 'package:proyecto_recetas/services/constants.dart';
import 'package:proyecto_recetas/widgets/custom_button.dart';
import 'package:proyecto_recetas/widgets/ingredient_item.dart';
import 'package:uuid/uuid.dart';

class RecipeEditScreen extends StatefulWidget {
  final UserModel user;
  final String imagePath;
  final Recipe? recipe;

  const RecipeEditScreen({
    Key? key,
    required this.user,
    required this.imagePath,
    this.recipe,
  }) : super(key: key);

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _preparationController = TextEditingController();
  final _newIngredientController = TextEditingController();

  List<Ingredient> _ingredients = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.recipe != null) {
      _titleController.text = widget.recipe!.title;
      _preparationController.text = widget.recipe!.preparation;
      _ingredients = List.from(widget.recipe!.ingredients);
      setState(() {
        _isLoading = false;
      });
    } else {
      _analyzeImage();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _preparationController.dispose();
    _newIngredientController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage() async {
    try {
      final recipeInfo = await AIService().analyzeRecipeImage(
        widget.imagePath,
        widget.user.region,
      );

      setState(() {
        _ingredients = recipeInfo['ingredients'] as List<Ingredient>;
        _preparationController.text = recipeInfo['preparation'] as String;
        _titleController.text = 'Nueva Receta';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al analizar la imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _ingredients = [];
          _preparationController.text = '';
          _titleController.text = 'Nueva Receta';
        });
      }
    }
  }

  void _toggleIngredient(Ingredient ingredient) {
    setState(() {
      final index = _ingredients.indexWhere((i) => i.id == ingredient.id);
      if (index != -1) {
        _ingredients[index] = Ingredient(
          id: ingredient.id,
          name: ingredient.name,
          isSelected: !ingredient.isSelected,
          isAIGenerated: ingredient.isAIGenerated,
        );
      }
    });
  }

  void _addIngredient() {
    if (_newIngredientController.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(
          Ingredient(
            id: const Uuid().v4(),
            name: _newIngredientController.text.trim(),
            isSelected: true,
            isAIGenerated: false,
          ),
        );
        _newIngredientController.clear();
      });
    }
  }

  void _removeIngredient(Ingredient ingredient) {
    setState(() {
      _ingredients.removeWhere((i) => i.id == ingredient.id);
    });
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final selectedIngredients =
            _ingredients.where((i) => i.isSelected).toList();

        if (selectedIngredients.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debes seleccionar al menos un ingrediente'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }

        if (widget.recipe != null) {
          // Actualiza receta existente
          final updatedRecipe = Recipe(
            id: widget.recipe!.id,
            title: _titleController.text,
            imagePath: widget.imagePath,
            ingredients: _ingredients,
            preparation: _preparationController.text,
            createdAt: widget.recipe!.createdAt,
            userId: widget.user.id,
            appwriteId: widget.recipe!.appwriteId,
            isSynced: widget.recipe!.isSynced,
          );

          await LocalDBService().updateRecipe(updatedRecipe);
        } else {
          // Crear nueva receta
          await LocalDBService().createRecipe(
            title: _titleController.text,
            imagePath: widget.imagePath,
            ingredients: _ingredients,
            preparation: _preparationController.text,
            userId: widget.user.id,
          );
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar la receta: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe != null ? 'Editar Receta' : 'Nueva Receta'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título de la receta',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ingredientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        return IngredientItem(
                          ingredient: ingredient,
                          onToggle: () => _toggleIngredient(ingredient),
                          onDelete: () => _removeIngredient(ingredient),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newIngredientController,
                            decoration: const InputDecoration(
                              labelText: 'Agregar ingrediente',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addIngredient(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addIngredient,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Preparación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _preparationController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe los pasos de preparación...',
                      ),
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la preparación';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Guardar Receta',
                      isLoading: _isSaving,
                      onPressed: _saveRecipe,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
