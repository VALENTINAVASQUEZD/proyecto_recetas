import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'auth/login_screen.dart';
import 'recipes/my_recipes_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }
  
  Future<void> _checkCurrentUser() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final currentUserId = DatabaseService().getCurrentUserId();
    
    if (currentUserId != null) {
      final recipes = DatabaseService().getUserRecipes(currentUserId);
      if (recipes.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MyRecipesScreen(userId: currentUserId),
          ),
        );
        return;
      }
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 100, color: Colors.green),
            SizedBox(height: 24),
            Text(
              'Recetas IA',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
