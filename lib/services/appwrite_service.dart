import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/models/user.dart';
import 'package:recipe_app/utils/constants.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  
  factory AppwriteService() {
    return _instance;
  }
  
  AppwriteService._internal();
  
  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;
  
  void initialize() {
    client = Client()
        .setEndpoint(AppwriteConstants.endpoint)
        .setProject(AppwriteConstants.projectId)
        .setSelfSigned(status: true);
    
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }

  Future<User> createAccount(String email, String password, String username) async {
    try {
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: username,
      );
      return user;
    } catch (e) {
      debugPrint('Error al crear cuenta: $e');
      rethrow;
    }
  }
  
  Future<Session> login(String email, String password) async {
    try {
      final session = await account.createEmailSession(
        email: email,
        password: password,
      );
      return session;
    } catch (e) {
      debugPrint('Error al iniciar sesión: $e');
      rethrow;
    }
  }
  
  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  Future<Document> createUser(UserModel user) async {
    try {
      final document = await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: ID.unique(),
        data: user.toJson(),
      );
      return document;
    } catch (e) {
      debugPrint('Error al crear usuario en Appwrite: $e');
      rethrow;
    }
  }
  
  Future<Document> updateUser(String documentId, UserModel user) async {
    try {
      final document = await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: documentId,
        data: user.toJson(),
      );
      return document;
    } catch (e) {
      debugPrint('Error al actualizar usuario en Appwrite: $e');
      rethrow;
    }
  }
  
  Future<Document> createRecipe(Recipe recipe) async {
    try {
      final document = await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.recipesCollectionId,
        documentId: ID.unique(),
        data: recipe.toJson(),
      );
      return document;
    } catch (e) {
      debugPrint('Error al crear receta en Appwrite: $e');
      rethrow;
    }
  }
  
  Future<Document> updateRecipe(String documentId, Recipe recipe) async {
    try {
      final document = await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.recipesCollectionId,
        documentId: documentId,
        data: recipe.toJson(),
      );
      return document;
    } catch (e) {
      debugPrint('Error al actualizar receta en Appwrite: $e');
      rethrow;
    }
  }
  
  Future<void> deleteRecipe(String documentId) async {
    try {
      await databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.recipesCollectionId,
        documentId: documentId,
      );
    } catch (e) {
      debugPrint('Error al eliminar receta en Appwrite: $e');
      rethrow;
    }
  }
  
  Future<List<Document>> getUserRecipes(String userId) async {
    try {
      final documents = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.recipesCollectionId,
        queries: [
          Query.equal('userId', userId),
        ],
      );
      return documents.documents;
    } catch (e) {
      debugPrint('Error al obtener recetas del usuario: $e');
      rethrow;
    }
  }
  

  Future<File> uploadImage(String filePath, String fileName) async {
    try {
      final file = await storage.createFile(
        bucketId: AppwriteConstants.storageId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath, filename: fileName),
      );
      return file;
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      rethrow;
    }
  }
  
  Future<void> deleteImage(String fileId) async {
    try {
      await storage.deleteFile(
        bucketId: AppwriteConstants.storageId,
        fileId: fileId,
      );
    } catch (e) {
      debugPrint('Error al eliminar imagen: $e');
      rethrow;
    }
  }
  
  String getImageUrl(String fileId) {
    return storage.getFileView(
      bucketId: AppwriteConstants.storageId,
      fileId: fileId,
    ).toString();
  }
}
