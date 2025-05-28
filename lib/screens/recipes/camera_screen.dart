import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:proyecto_recetas/models/user.dart';
import 'package:proyecto_recetas/screens/recipes/recipe_edit_screen.dart';

class CameraScreen extends StatefulWidget {
  final UserModel user;

  const CameraScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isRearCameraSelected = true;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron cámaras disponibles'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final camera = _isRearCameraSelected
        ? cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          )
        : cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;

    try {
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar la cámara: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona una cámara primero'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (cameraController.value.isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final XFile photo = await cameraController.takePicture();

      // Guardar la imagen en un directorio temporal
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${appDir.path}/RecetasIA/Images';
      await Directory(dirPath).create(recursive: true);
      final String filePath =
          '$dirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await File(photo.path).copy(filePath);

      setState(() {
        _imageFile = File(filePath);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar la foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
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
            user: widget.user,
            imagePath: _imageFile!.path,
          ),
        ),
      );
    }
  }

  void _switchCamera() {
    setState(() {
      _isRearCameraSelected = !_isRearCameraSelected;
      _isCameraInitialized = false;
    });
    _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomar Foto'),
        actions: [
          if (_isCameraInitialized && _imageFile == null)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: _imageFile != null ? _buildImagePreview() : _buildCameraPreview(),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1 / _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),
        Container(
          height: 100,
          width: double.infinity,
          color: Colors.black,
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : IconButton(
                    onPressed: _takePicture,
                    icon: const Icon(
                      Icons.camera,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Expanded(
          child: Image.file(
            _imageFile!,
            fit: BoxFit.contain,
          ),
        ),
        Container(
          height: 100,
          width: double.infinity,
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _resetImage,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              IconButton(
                onPressed: _acceptImage,
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
