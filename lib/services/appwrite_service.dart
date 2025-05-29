import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../models/user.dart';
import '../models/recipe.dart';
import 'constants.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();
  
  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;
  
  void initialize() {
    if (AppwriteConstants.projectId == '68363bfe000210ecc4f3') {
      print('Appwrite no configurado - usando solo almacenamiento local');
      return;
    }
    
    client = Client()
        .setEndpoint(AppwriteConstants.endpoint)
        .setProject(AppwriteConstants.projectId);
    
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }
  
  Future<Document?> syncUser(UserModel user) async {
    try {
      if (AppwriteConstants.projectId == '68363bfe000210ecc4f3') return null;
      
      final document = await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: ID.unique(),
        data: user.toJson(),
      );
      return document;
    } catch (e) {
      print('Error sincronizando usuario: $e');
      return null;
    }
  }
  
  Future<Document?> syncRecipe(Recipe recipe) async {
    try {
      if (AppwriteConstants.projectId == '68363bfe000210ecc4f3') return null;
      
      final document = await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.recipesCollectionId,
        documentId: ID.unique(),
        data: recipe.toJson(),
      );
      return document;
    } catch (e) {
      print('Error sincronizando receta: $e');
      return null;
    }
  }
}
