import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recipe_app/screens/auth/login_screen.dart';
import 'package:recipe_app/services/appwrite_service.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/models/ingredient.dart';
import 'package:recipe_app/models/user.dart';
import 'package:recipe_app/utils/constants.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error al inicializar cámaras: ${e.description}');
  }

  await Hive.initFlutter();
  

  Hive.registerAdapter(RecipeAdapter());
  Hive.registerAdapter(IngredientAdapter());
  Hive.registerAdapter(UserAdapter());

  await Hive.openBox<Recipe>('recipes');
  await Hive.openBox<Ingredient>('ingredients');
  await Hive.openBox<UserModel>('users');
  await Hive.openBox('settings');
  
  AppwriteService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recetas IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
