import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/ingredient.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../services/appwrite_service.dart';

class RecipeEditScreen extends StatefulWidget {
  final String imagePath;
  final String userId;
  
  const RecipeEditScreen({Key? key, required this.imagePath, required this.userId}) : super(key: key);

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _titleController = TextEditingController();
  final _preparationController = TextEditingController();
  final _newIngredientController = TextEditingController();
  
  List<Ingredient> _ingredients = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _userRegion = 'Región Andina';
  
  @override
  void initState() {
    super.initState();
    _loadUserAndAnalyze();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _preparationController.dispose();
    _newIngredientController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserAndAnalyze() async {
    try {
      final users = DatabaseService().getAllUsers();
      final currentUser = users.firstWhere(
        (user) => user.id == widget.userId,
        orElse: () => users.first,
      );
      _userRegion = currentUser.region;
      
      final result = await AIService().analyzeRecipeImage(widget.imagePath, _userRegion);
      
      setState(() {
        _titleController.text = 'Nueva Receta';
        _ingredients = result['ingredients'] as List<Ingredient>;
        _preparationController.text = result['preparation'] as String;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al analizar imagen: $e')),
      );
    }
  }
  
  void _toggleIngredient(int index) {
    setState(() {
      _ingredients[index].isSelected = !_ingredients[index].isSelected;
    });
  }
  
  void _addIngredient() {
    if (_newIngredientController.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(Ingredient(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _newIngredientController.text.trim(),
          isSelected: true,
          isAIGenerated: false,
        ));
        _newIngredientController.clear();
      });
    }
  }
  
  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }
  
  Future<void> _saveRecipe() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un título')),
      );
      return;
    }
    
    final selectedIngredients = _ingredients.where((i) => i.isSelected).toList();
    
    if (selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un ingrediente')),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final recipe = await DatabaseService().createRecipe(
        title: _titleController.text,
        imagePath: widget.imagePath,
        ingredients: _ingredients,
        preparation: _preparationController.text,
        userId: widget.userId,
      );
      
      await AppwriteService().syncRecipe(recipe);
      
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Receta')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.imagePath),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título de la receta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Ingredientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _ingredients[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: ingredient.isSelected,
                            onChanged: (_) => _toggleIngredient(index),
                          ),
                          title: Text(ingredient.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ingredient.isAIGenerated)
                                const Icon(Icons.auto_awesome, size: 16, color: Colors.orange),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeIngredient(index),
                              ),
                            ],
                          ),
                        ),
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
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Preparación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _preparationController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Escribe los pasos de preparación...',
                    ),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveRecipe,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar Receta'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
