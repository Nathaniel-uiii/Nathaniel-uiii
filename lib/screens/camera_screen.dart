import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/bread_classifier.dart';
import '../services/records_service.dart';
import '../services/firebase_service.dart';
import '../models/classification_record.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  final BreadClassifier _classifier = BreadClassifier();
  final RecordsService _recordsService = RecordsService();
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find the default/back camera (preferred for object classification)
        CameraDescription? defaultCamera;
        
        // First, try to find back camera (default camera for most devices)
        for (var camera in _cameras!) {
          if (camera.lensDirection == CameraLensDirection.back) {
            defaultCamera = camera;
            break;
          }
        }
        
        // If no back camera found, use the first available camera
        defaultCamera ??= _cameras![0];
        
        print('Using camera: ${defaultCamera.name} (${defaultCamera.lensDirection})');
        
        _controller = CameraController(
          defaultCamera,
          ResolutionPreset.high,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available on this device')),
          );
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _loadModel() async {
    // IMPORTANT: Set preprocessing to match your training!
    // Try these in order if accuracy is low:
    // 1. _classifier.setPreprocessingPreset("imagenet");  // Most common (MobileNet, EfficientNet, ResNet)
    // 2. _classifier.setPreprocessingPreset("simple");   // Custom models with [0,1] normalization
    // 3. _classifier.setPreprocessingPreset("bgr");      // OpenCV-trained models
    // 4. _classifier.setPreprocessingPreset("imagenet_bgr"); // ImageNet + BGR
    
    // Default: Try ImageNet first (most models use this)
    // If Spanish Bread is not recognized, try "simple" preset
    _classifier.setPreprocessingPreset("imagenet");
    
    await _classifier.loadModel();
  }
  
  void _showPreprocessingSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preprocessing Presets:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'If Pan de Leche, Pandesal, Pan de Coco, or Spanish Bread are not recognized correctly, try different presets:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildPresetButton('imagenet', 'ImageNet (Default)', 'Most common - try this first'),
              _buildPresetButton('simple', 'Simple Normalization', 'For custom models'),
              _buildPresetButton('bgr', 'BGR Color Order', 'For OpenCV-trained models'),
              _buildPresetButton('imagenet_bgr', 'ImageNet + BGR', 'ImageNet with BGR channels'),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Accuracy Enhancements:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Image Enhancement'),
                subtitle: const Text('Auto-adjust brightness/contrast'),
                value: _classifier.enableImageEnhancement,
                onChanged: (value) {
                  setState(() {
                    _classifier.enableImageEnhancement = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Ensemble Prediction'),
                subtitle: const Text('More accurate but slower (3x)'),
                value: _classifier.enableEnsemblePrediction,
                onChanged: (value) {
                  setState(() {
                    _classifier.enableEnsemblePrediction = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Sharpening'),
                subtitle: const Text('Enhance image sharpness'),
                value: _classifier.enableSharpening,
                onChanged: (value) {
                  setState(() {
                    _classifier.enableSharpening = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              const Text(
                '💡 Tip: Image Enhancement is ON by default. Ensemble is more accurate but 3x slower.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPresetButton(String preset, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          _classifier.setPreprocessingPreset(preset);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Changed to: $title. Take a new photo to test.'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF57C00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (!_isInitialized || _controller == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller!.takePicture();
      await _classifyImage(File(image.path));
    } catch (e) {
      print('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error taking picture')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        await _classifyImage(File(image.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking image')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    try {
      // Ensure model is loaded
      if (!_classifier.isLoaded) {
        print('Model not loaded, loading now...');
        await _classifier.loadModel();
        if (!_classifier.isLoaded) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to load model. Please restart the app.')),
            );
          }
          return;
        }
      }
      
      final result = await _classifier.classifyImage(imageFile);
      
      if (result != null && mounted) {
        setState(() {
          _lastResult = result;
        });

        // Save to local records
        final record = ClassificationRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          breadType: result['label'] as String,
          confidence: result['confidence'] as double,
          timestamp: DateTime.now(),
          imagePath: imageFile.path,
        );
        await _recordsService.addRecord(record);

        // Save to Firebase (data only, no image)
        try {
          await _firebaseService.saveClassification(
            breadType: result['label'] as String,
            confidence: result['confidence'] as double,
            timestamp: DateTime.now(),
            allPredictions: result['allPredictions'] as List<Map<String, dynamic>>,
          );
        } catch (e) {
          print('Error saving to Firebase: $e');
          // Don't show error to user, just log it
          // Firebase save failure shouldn't block the user experience
        }

        // Show result dialog
        _showResultDialog(result);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to classify image. Check console for details.')),
        );
      }
    } catch (e) {
      print('Error in _classifyImage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classification error: ${e.toString()}')),
        );
      }
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Classification Result'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bread Type: ${result['label']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Center(
                child: _buildConfidenceGraph(result['confidence'] as double),
              ),
              const SizedBox(height: 12),
              const Text(
                'All Classes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...((result['allPredictions'] as List<dynamic>).map((prediction) {
                final label = prediction['label'] as String;
                final confidence = prediction['confidence'] as double;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${confidence.toStringAsFixed(2)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: confidence / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            confidence >= 70
                                ? Colors.green
                                : confidence >= 40
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/analytics');
            },
            child: const Text('View Analytics'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceGraph(double confidence) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: (confidence / 100).clamp(0.0, 1.0),
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                confidence >= 70
                    ? Colors.green
                    : confidence >= 40
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${confidence.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Match',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: const Color(0xFFF57C00), // warm orange like home
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Preprocessing Settings',
            onPressed: _showPreprocessingSettings,
          ),
        ],
      ),
      body: _isInitialized && _controller != null
          ? Stack(
              children: [
                CameraPreview(_controller!),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      FloatingActionButton(
                        heroTag: 'gallery',
                        onPressed: _isProcessing ? null : _pickImageFromGallery,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.photo_library, color: Color(0xFFF57C00)),
                      ),
                      // Capture button
                      FloatingActionButton(
                        heroTag: 'capture',
                        onPressed: _isProcessing ? null : _takePicture,
                        backgroundColor: Colors.white,
                        child: _isProcessing
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.camera_alt, color: Color(0xFFF57C00), size: 30),
                      ),
                    ],
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

