import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:recipe_app/models/ingredient.dart';
import 'package:recipe_app/utils/constants.dart';
import 'package:uuid/uuid.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  
  factory AIService() {
    return _instance;
  }
  
  AIService._internal();
  
  Future<Map<String, dynamic>> analyzeRecipeImage(String imagePath, String region) async {
    try {

      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      final Map<String, dynamic> recipeInfo = await _analyzeWithGemini(
        base64Image, 
        region
      );
      
      return recipeInfo;
    } catch (e) {
      debugPrint('Error al analizar la imagen: $e');
      return {
        'ingredients': _getFallbackIngredients(region),
        'preparation': _getFallbackPreparation(region),
      };
    }
  }
  
  Future<Map<String, dynamic>> _analyzeWithGemini(String base64Image, String region) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${MLConstants.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': _buildPrompt(region),
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String generatedText = data['candidates'][0]['content']['parts'][0]['text'];
        
        return _parseGeminiResponse(generatedText, region);
      } else {
        debugPrint('Error en Gemini API: ${response.statusCode} - ${response.body}');
        throw Exception('Error en la API de Gemini: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al llamar a Gemini: $e');
      rethrow;
    }
  }

  String _buildPrompt(String region) {
    return '''
Analiza esta imagen de comida y proporciona la siguiente información en formato JSON:

1. Una lista de ingredientes que puedes identificar en la imagen
2. Una receta de preparación paso a paso

Considera que esta receta es de la región: $region de Colombia, por lo que los ingredientes y la preparación deben ser acordes a la gastronomía de esta región.

Responde ÚNICAMENTE en el siguiente formato JSON (sin texto adicional):

{
  "ingredients": [
    "ingrediente1",
    "ingrediente2",
    "ingrediente3"
  ],
  "preparation": "1. Paso uno de la preparación...\n2. Paso dos de la preparación...\n3. Paso tres de la preparación..."
}

Asegúrate de incluir ingredientes típicos de $region y que la preparación sea culturalmente apropiada para esta región de Colombia.
''';
  }
  
  
  Map<String, dynamic> _parseGeminiResponse(String response, String region) {
    try {
      
      String cleanResponse = response.trim();
      
      
      int startIndex = cleanResponse.indexOf('{');
      int endIndex = cleanResponse.lastIndexOf('}') + 1;
      
      if (startIndex != -1 && endIndex != -1) {
        String jsonString = cleanResponse.substring(startIndex, endIndex);
        Map<String, dynamic> parsedJson = jsonDecode(jsonString);
        
  
        List<String> ingredientNames = List<String>.from(parsedJson['ingredients'] ?? []);
        List<Ingredient> ingredients = ingredientNames.map((name) => Ingredient(
          id: const Uuid().v4(),
          name: name.trim(),
          isAIGenerated: true,
          isSelected: false,
        )).toList();
        
     
        ingredients.addAll(_getRegionSpecificIngredients(region));
        
        return {
          'ingredients': ingredients,
          'preparation': parsedJson['preparation'] ?? _getFallbackPreparation(region),
        };
      } else {
        throw Exception('No se encontró JSON válido en la respuesta');
      }
    } catch (e) {
      debugPrint('Error al parsear respuesta de Gemini: $e');

      return {
        'ingredients': _getFallbackIngredients(region),
        'preparation': _getFallbackPreparation(region),
      };
    }
  }
  

  List<Ingredient> _getRegionSpecificIngredients(String region) {
    List<String> regionIngredients = [];
    
    switch (region) {
      case 'Región Andina':
        regionIngredients = ['Papa criolla', 'Maíz', 'Fríjoles', 'Arracacha', 'Aguacate'];
        break;
      case 'Región Caribe':
        regionIngredients = ['Pescado', 'Coco', 'Plátano verde', 'Yuca', 'Suero costeño'];
        break;
      case 'Región Pacífica':
        regionIngredients = ['Pescado fresco', 'Mariscos', 'Coco', 'Chontaduro', 'Borojó'];
        break;
      case 'Región Orinoquía':
        regionIngredients = ['Carne de res', 'Yuca', 'Plátano maduro', 'Arroz', 'Ahuyama'];
        break;
      case 'Región Amazonía':
        regionIngredients = ['Pescado de río', 'Yuca brava', 'Frutas exóticas', 'Palmito', 'Ají amazónico'];
        break;
      case 'Región Insular':
        regionIngredients = ['Pescado', 'Coco', 'Cangrejo', 'Caracol pala', 'Frutas tropicales'];
        break;
      default:
        regionIngredients = ['Arroz', 'Frijoles', 'Plátano', 'Yuca', 'Maíz'];
    }
    
    return regionIngredients.map((name) => Ingredient(
      id: const Uuid().v4(),
      name: name,
      isAIGenerated: true,
      isSelected: false,
    )).toList();
  }
  
  
  List<Ingredient> _getFallbackIngredients(String region) {
    final List<String> basicIngredients = [
      'Sal',
      'Pimienta',
      'Aceite',
      'Ajo',
      'Cebolla',
    ];
    
    final regionIngredients = _getRegionSpecificIngredients(region);
    
    final allIngredients = [
      ...basicIngredients.map((name) => Ingredient(
        id: const Uuid().v4(),
        name: name,
        isAIGenerated: false,
        isSelected: false,
      )),
      ...regionIngredients.take(3),
    ];
    
    return allIngredients;
  }
  
 
  String _getFallbackPreparation(String region) {
    return '''
1. Preparar todos los ingredientes lavándolos y cortándolos según sea necesario.
2. Calentar una sartén o olla a fuego medio con un poco de aceite.
3. Agregar los ingredientes principales y cocinar por 5-10 minutos.
4. Añadir los condimentos y especias típicas de $region.
5. Cocinar a fuego lento por 15-20 minutos más, revolviendo ocasionalmente.
6. Verificar la sazón y ajustar si es necesario.
7. Servir caliente y disfrutar de esta deliciosa receta típica de $region.

Nota: Esta es una preparación general. Para mejores resultados, tome una foto más clara de la receta.
''';
  }
  
  //  validar si la API key está configurada
  bool isConfigured() {
    return MLConstants.geminiApiKey.isNotEmpty && 
           MLConstants.geminiApiKey != 'AIzaSyBf4o59T0-8-fVOjtvLE2uYQpGjwEAsp_I';
  }
  
  // probar la conexión con la API
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=${MLConstants.geminiApiKey}'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error al probar conexión con Gemini: $e');
      return false;
    }
  }
}
