import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../main.dart';
import 'recipe_edit_screen.dart';

class CameraScreen extends StatefulWidget {
  final String userId;
  
  const CameraScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  File? _imageFile;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron cámaras')),
      );
      return;
    }
    
    final camera = cameras.first;
    final controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
    _controller = controller;
    
    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al inicializar cámara: $e')),
      );
    }
  }
  
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final XFile photo = await _controller!.takePicture();
      await _saveImage(photo.path);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto: $e')),
      );
    }
  }
  
  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        await _saveImage(image.path);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }
  
  Future<void> _saveImage(String imagePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${appDir.path}/RecetasIA/Images';
      await Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await File(imagePath).copy(filePath);
      
      setState(() {
        _imageFile = File(filePath);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar imagen: $e')),
      );
    }
  }
  
  void _resetImage() {
    setState(() {
      _imageFile = null;
    });
  }
  
  void _acceptImage() {
    if (_imageFile != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RecipeEditScreen(
            imagePath: _imageFile!.path,
            userId: widget.userId,
          ),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Foto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickFromGallery,
            tooltip: 'Seleccionar de galería',
          ),
        ],
      ),
      body: _imageFile != null ? _buildImagePreview() : _buildCameraPreview(),
    );
  }
  
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        Expanded(child: CameraPreview(_controller!)),
        Container(
          height: 120,
          width: double.infinity,
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                tooltip: 'Galería',
              ),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : IconButton(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera, color: Colors.white, size: 50),
                      tooltip: 'Tomar foto',
                    ),
              const SizedBox(width: 50), // Espacio para balance visual
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildImagePreview() {
    return Column(
      children: [
        Expanded(child: Image.file(_imageFile!, fit: BoxFit.contain)),
        Container(
          height: 100,
          width: double.infinity,
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _resetImage,
                icon: const Icon(Icons.close, color: Colors.white, size: 40),
                tooltip: 'Cancelar',
              ),
              IconButton(
                onPressed: _acceptImage,
                icon: const Icon(Icons.check, color: Colors.white, size: 40),
                tooltip: 'Aceptar',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
