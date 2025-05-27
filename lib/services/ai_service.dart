import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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

      final localAnalysis = await _analyzeWithMLKit(imagePath);
      

      final geminiAnalysis = await _analyzeWithGemini(imagePath, region, localAnalysis);
      
      return geminiAnalysis;
    } catch (e) {
      debugPrint('Error al analizar la imagen: $e');
      return {
        'ingredients': _getFallbackIngredients(region),
        'preparation': _getFallbackPreparation(region),
      };
    }
  }
  

  Future<Map<String, dynamic>> _analyzeWithMLKit(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      

      final imageLabeler = ImageLabeler(options: ImageLabelerOptions(
        confidenceThreshold: 0.5,
      ));
      
      final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
      

      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      imageLabeler.close();
      textRecognizer.close();
      
      return {
        'labels': labels.map((label) => label.label).toList(),
        'text': recognizedText.text,
        'confidence': labels.isNotEmpty ? labels.first.confidence : 0.0,
      };
    } catch (e) {
      debugPrint('Error en ML Kit: $e');
      return {
        'labels': <String>[],
        'text': '',
        'confidence': 0.0,
      };
    }
  }
  

  Future<Map<String, dynamic>> _analyzeWithGemini(String imagePath, String region, Map<String, dynamic> localAnalysis) async {
    try {

      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
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
                  'text': _buildEnhancedPrompt(region, localAnalysis),
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
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final String generatedText = data['candidates'][0]['content']['parts'][0]['text'];
          return _parseGeminiResponse(generatedText, region);
        } else {
          throw Exception('No se recibió respuesta válida de Gemini');
        }
      } else {
        debugPrint('Error en Gemini API: ${response.statusCode} - ${response.body}');
        throw Exception('Error en la API de Gemini: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al llamar a Gemini: $e');

      return _createFallbackFromMLKit(localAnalysis, region);
    }
  }
  

  String _buildEnhancedPrompt(String region, Map<String, dynamic> localAnalysis) {
    final labels = localAnalysis['labels'] as List<String>;
    final detectedText = localAnalysis['text'] as String;
    
    String additionalContext = '';
    if (labels.isNotEmpty) {
      additionalContext += '\nElementos detectados localmente: ${labels.join(', ')}';
    }
    if (detectedText.isNotEmpty) {
      additionalContext += '\nTexto detectado en la imagen: $detectedText';
    }
    
    return '''
Eres un chef experto en gastronomía colombiana, específicamente de la $region. 

Analiza esta imagen de comida y proporciona información detallada sobre la receta.
$additionalContext

Responde ÚNICAMENTE en el siguiente formato JSON válido (sin texto adicional, sin markdown, sin explicaciones):

{
  "ingredients": [
    "ingrediente1",
    "ingrediente2",
    "ingrediente3",
    "ingrediente4",
    "ingrediente5"
  ],
  "preparation": "1. Primer paso de preparación específico para esta receta\n2. Segundo paso detallado\n3. Tercer paso\n4. Cuarto paso\n5. Paso final y presentación"
}

IMPORTANTE:
- Incluye ingredientes típicos y auténticos de la $region
- La preparación debe ser específica y detallada
- Usa técnicas culinarias tradicionales de Colombia
- Incluye al menos 5 ingredientes principales
- Los pasos deben ser claros y específicos
- Considera los sabores y condimentos típicos de la región
''';
  }
  

  Map<String, dynamic> _createFallbackFromMLKit(Map<String, dynamic> localAnalysis, String region) {
    final labels = localAnalysis['labels'] as List<String>;
    

    final foodLabels = labels.where((label) => 
      _isFoodRelated(label.toLowerCase())
    ).toList();

    List<Ingredient> ingredients = [];
    

    for (String label in foodLabels.take(3)) {
      ingredients.add(Ingredient(
        id: const Uuid().v4(),
        name: _translateToSpanish(label),
        isAIGenerated: true,
        isSelected: false,
      ));
    }
    
    ingredients.addAll(_getRegionSpecificIngredients(region));
    
    return {
      'ingredients': ingredients,
      'preparation': _getFallbackPreparation(region),
    };
  }
  
  bool _isFoodRelated(String label) {
    final foodKeywords = [
      'food', 'dish', 'meal', 'cuisine', 'ingredient', 'vegetable', 'fruit',
      'meat', 'fish', 'rice', 'bread', 'soup', 'salad', 'chicken', 'beef',
      'pork', 'seafood', 'pasta', 'cheese', 'egg', 'bean', 'corn', 'potato',
      'tomato', 'onion', 'pepper', 'spice', 'herb', 'sauce', 'oil'
    ];
    
    return foodKeywords.any((keyword) => label.contains(keyword));
  }

  String _translateToSpanish(String englishLabel) {
    final translations = {
      'food': 'Comida',
      'dish': 'Plato',
      'meat': 'Carne',
      'chicken': 'Pollo',
      'beef': 'Carne de res',
      'fish': 'Pescado',
      'rice': 'Arroz',
      'bread': 'Pan',
      'vegetable': 'Verdura',
      'fruit': 'Fruta',
      'cheese': 'Queso',
      'egg': 'Huevo',
      'potato': 'Papa',
      'tomato': 'Tomate',
      'onion': 'Cebolla',
      'pepper': 'Pimiento',
      'corn': 'Maíz',
      'bean': 'Frijol',
    };
    
    return translations[englishLabel.toLowerCase()] ?? englishLabel;
  }
  

  Map<String, dynamic> _parseGeminiResponse(String response, String region) {
    try {

      String cleanResponse = response.trim();

      cleanResponse = cleanResponse.replaceAll('\`\`\`json', '');
      cleanResponse = cleanResponse.replaceAll('\`\`\`', '');
      cleanResponse = cleanResponse.trim();
      

      int startIndex = cleanResponse.indexOf('{');
      int endIndex = cleanResponse.lastIndexOf('}') + 1;
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        String jsonString = cleanResponse.substring(startIndex, endIndex);
        Map<String, dynamic> parsedJson = jsonDecode(jsonString);
        

        if (!parsedJson.containsKey('ingredients') || !parsedJson.containsKey('preparation')) {
          throw Exception('JSON no contiene las claves requeridas');
        }

        List<dynamic> ingredientsList = parsedJson['ingredients'];
        List<Ingredient> ingredients = ingredientsList.map((ingredient) => Ingredient(
          id: const Uuid().v4(),
          name: ingredient.toString().trim(),
          isAIGenerated: true,
          isSelected: false,
        )).toList();
        

        if (ingredients.length < 3) {
          ingredients.addAll(_getRegionSpecificIngredients(region).take(3));
        }
        
        return {
          'ingredients': ingredients,
          'preparation': parsedJson['preparation'].toString(),
        };
      } else {
        throw Exception('No se encontró JSON válido en la respuesta');
      }
    } catch (e) {
      debugPrint('Error al parsear respuesta de Gemini: $e');
      debugPrint('Respuesta recibida: $response');
      

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
        regionIngredients = ['Papa criolla', 'Maíz amarillo', 'Fríjoles rojos', 'Arracacha', 'Aguacate hass'];
        break;
      case 'Región Caribe':
        regionIngredients = ['Pescado pargo', 'Coco rallado', 'Plátano verde', 'Yuca blanca', 'Suero costeño'];
        break;
      case 'Región Pacífica':
        regionIngredients = ['Pescado corvina', 'Camarón tigre', 'Coco fresco', 'Chontaduro', 'Borojó'];
        break;
      case 'Región Orinoquía':
        regionIngredients = ['Carne de res llanera', 'Yuca dulce', 'Plátano maduro', 'Arroz blanco', 'Ahuyama'];
        break;
      case 'Región Amazonía':
        regionIngredients = ['Pescado bagre', 'Yuca brava', 'Copoazú', 'Palmito', 'Ají charapita'];
        break;
      case 'Región Insular':
        regionIngredients = ['Pescado mero', 'Coco tierno', 'Cangrejo azul', 'Caracol pala', 'Mango tommy'];
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
      'Sal marina',
      'Pimienta negra',
      'Aceite de girasol',
      'Ajo fresco',
      'Cebolla blanca',
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
1. Lavar y preparar todos los ingredientes, cortándolos en trozos uniformes según la receta tradicional de $region.

2. Calentar una sartén grande o caldero a fuego medio y agregar un poco de aceite.

3. Sofreír los condimentos base (ajo, cebolla) hasta que estén dorados y aromáticos.

4. Incorporar los ingredientes principales y cocinar por 8-10 minutos, revolviendo ocasionalmente.

5. Agregar las especias y condimentos típicos de $region, ajustando la sazón al gusto.

6. Reducir el fuego y cocinar a fuego lento por 15-20 minutos más, hasta que todos los sabores se integren.

7. Verificar la cocción y el punto de sal, ajustando si es necesario.

8. Servir caliente acompañado de los contornos tradicionales de $region.

Nota: Para obtener una receta más específica, asegúrate de tomar una foto clara del plato terminado.
''';
  }
  
  // Validar configuración
  bool isConfigured() {
    return MLConstants.geminiApiKey.isNotEmpty && 
           MLConstants.geminiApiKey != 'AIzaSyBf4o59T0-8-fVOjtvLE2uYQpGjwEAsp_I';
  }
  
  // Probar conexión
  Future<bool> testConnection() async {
    if (!isConfigured()) return false;
    
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
