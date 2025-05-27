import 'dart:io';
import 'package:flutter/material.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/models/user.dart';
import 'package:recipe_app/screens/auth/login_screen.dart';
import 'package:recipe_app/screens/profile/profile_screen.dart';
import 'package:recipe_app/screens/recipes/camera_screen.dart';
import 'package:recipe_app/screens/recipes/recipe_detail_screen.dart';
import 'package:recipe_app/screens/statistics/statistics_screen.dart';
import 'package:recipe_app/services/local_db_service.dart';
import 'package:recipe_app/utils/constants.dart';
import 'package:recipe_app/widgets/recipe_card.dart';

class MyRecipesScreen extends StatefulWidget {
  final UserModel user;
  
  const MyRecipesScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }
  
  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final recipes = LocalDBService().getUserRecipes(widget.user.id);
      setState(() {
        _recipes = recipes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar recetas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteRecipe(Recipe recipe) async {
    try {
      await LocalDBService().deleteRecipe(recipe.id);
      
      // Si hay una imagen, eliminarla
      final file = File(recipe.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      setState(() {
        _recipes.removeWhere((r) => r.id == recipe.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receta eliminada correctamente'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar receta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _logout() async {
    try {
      await LocalDBService().clearCurrentUser();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Recetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StatisticsScreen(user: widget.user),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(user: widget.user),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant,
                        size: 80,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes recetas',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toma una foto para crear tu primera receta',
                        style: TextStyle(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CameraScreen(user: widget.user),
                            ),
                          );
                          
                          if (result == true) {
                            _loadRecipes();
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tomar Foto'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecipes,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _recipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                          
                          if (result == true) {
                            _loadRecipes();
                          }
                        },
                        onEdit: () async {
       
                          _loadRecipes();
                        },
                        onDelete: () => _deleteRecipe(recipe),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CameraScreen(user: widget.user),
            ),
          );
          
          if (result == true) {
            _loadRecipes();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
