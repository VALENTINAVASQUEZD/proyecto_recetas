import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/ingredient.dart';
import 'constants.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();
  
  Future<Map<String, dynamic>> analyzeRecipeImage(String imagePath, String region) async {
    try {
      if (AIConstants.geminiApiKey == 'AIzaSyBf4o59T0-8-fVOjtvLE2uYQpGjwEAsp_I') {
        return _getFallbackResponse(region);
      }
      
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${AIConstants.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
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
        final data = jsonDecode(response.body);
        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseGeminiResponse(generatedText, region);
      } else {
        print('Error en Gemini API: ${response.statusCode}');
        return _getFallbackResponse(region);
      }
    } catch (e) {
      print('Error al analizar imagen: $e');
      return _getFallbackResponse(region);
    }
  }
  
  String _buildPrompt(String region) {
    return '''
Analiza esta imagen de comida y proporciona información en formato JSON.
Esta receta es de la $region de Colombia.

Responde ÚNICAMENTE en formato JSON:
{
  "ingredients": ["ingrediente1", "ingrediente2", "ingrediente3", "ingrediente4", "ingrediente5"],
  "preparation": "1. Paso uno...\n2. Paso dos...\n3. Paso tres..."
}

Incluye ingredientes típicos de $region y preparación tradicional colombiana.
''';
  }
  
  Map<String, dynamic> _parseGeminiResponse(String response, String region) {
    try {
      String cleanResponse = response.trim();
      cleanResponse = cleanResponse.replaceAll('```json', '');
      cleanResponse = cleanResponse.replaceAll('```', '');
      
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
        
        return {
          'ingredients': ingredients,
          'preparation': parsedJson['preparation'] ?? _getFallbackPreparation(region),
        };
      }
    } catch (e) {
      print('Error parseando respuesta: $e');
    }
    
    return _getFallbackResponse(region);
  }
  
  Map<String, dynamic> _getFallbackResponse(String region) {
    return {
      'ingredients': _getRegionIngredients(region),
      'preparation': _getFallbackPreparation(region),
    };
  }
  
  List<Ingredient> _getRegionIngredients(String region) {
    List<String> regionIngredients = [];
    
    switch (region) {
      case 'Región Andina':
        regionIngredients = ['Papa criolla', 'Maíz amarillo', 'Fríjoles rojos', 'Aguacate', 'Sal', 'Pimienta'];
        break;
      case 'Región Caribe':
        regionIngredients = ['Pescado pargo', 'Coco', 'Plátano verde', 'Yuca', 'Suero costeño', 'Ají'];
        break;
      case 'Región Pacífica':
        regionIngredients = ['Pescado corvina', 'Camarón', 'Coco', 'Chontaduro', 'Cilantro', 'Limón'];
        break;
      case 'Región Orinoquía':
        regionIngredients = ['Carne de res', 'Yuca', 'Plátano maduro', 'Arroz', 'Ahuyama', 'Sal'];
        break;
      case 'Región Amazonía':
        regionIngredients = ['Pescado bagre', 'Yuca brava', 'Frutas exóticas', 'Palmito', 'Ají charapita', 'Sal'];
        break;
      case 'Región Insular':
        regionIngredients = ['Pescado mero', 'Coco', 'Cangrejo', 'Caracol', 'Mango', 'Limón'];
        break;
      default:
        regionIngredients = ['Arroz', 'Frijoles', 'Plátano', 'Yuca', 'Sal', 'Aceite'];
    }
    
    return regionIngredients.map((name) => Ingredient(
      id: const Uuid().v4(),
      name: name,
      isAIGenerated: true,
      isSelected: false,
    )).toList();
  }
  
  String _getFallbackPreparation(String region) {
    return '''1. Lavar y preparar todos los ingredientes cortándolos uniformemente.
2. Calentar aceite en una sartén a fuego medio.
3. Sofreír los condimentos base hasta que estén dorados.
4. Agregar los ingredientes principales y cocinar por 10 minutos.
5. Añadir especias típicas de $region al gusto.
6. Cocinar a fuego lento por 15-20 minutos más.
7. Verificar sazón y servir caliente.''';
  }
}
