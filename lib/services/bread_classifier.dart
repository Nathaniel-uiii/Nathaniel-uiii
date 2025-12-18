import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class BreadClassifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;
  
  // ============================================
  // PREPROCESSING CONFIGURATION
  // ============================================
  // CRITICAL: These settings MUST match what was used during training!
  // 
  // Common presets (try these in order):
  // 1. MobileNet/EfficientNet: ImageNet norm, RGB, center crop
  // 2. Custom trained: Simple norm [0,1], RGB, no crop
  // 3. Transfer learning: ImageNet norm, RGB, center crop
  // 4. OpenCV trained: Simple norm, BGR, center crop
  // ============================================
  
  // Current preprocessing settings - CHANGE THESE to match your training!
  // Most likely issue: Your model was trained with ImageNet normalization
  bool useImageNetNormalization = true;  // Try TRUE first - most models use this!
  bool useBGR = false;  // Most models use RGB (false), but some use BGR (true)
  bool useCenterCrop = true;  // Try TRUE - most models expect square center-cropped images
  
  // ============================================
  // ACCURACY ENHANCEMENT OPTIONS
  // ============================================
  bool enableImageEnhancement = true;  // Enhance image quality before classification
  bool enableEnsemblePrediction = false;  // Run multiple predictions and average (slower but more accurate)
  double brightnessAdjustment = 1.0;  // 1.0 = no change, >1.0 = brighter, <1.0 = darker
  double contrastAdjustment = 1.0;  // 1.0 = no change, >1.0 = more contrast
  bool enableSharpening = false;  // Apply sharpening filter (can help with blurry images)
  
  // Preprocessing preset helper
  void setPreprocessingPreset(String preset) {
    switch (preset.toLowerCase()) {
      case 'imagenet':
        useImageNetNormalization = true;
        useBGR = false;
        useCenterCrop = true;
        print('Set preprocessing: ImageNet normalization, RGB, center crop');
        break;
      case 'simple':
        useImageNetNormalization = false;
        useBGR = false;
        useCenterCrop = false;
        print('Set preprocessing: Simple [0,1] normalization, RGB, no crop');
        break;
      case 'bgr':
        useImageNetNormalization = false;
        useBGR = true;
        useCenterCrop = true;
        print('Set preprocessing: Simple [0,1] normalization, BGR, center crop');
        break;
      case 'imagenet_bgr':
        useImageNetNormalization = true;
        useBGR = true;
        useCenterCrop = true;
        print('Set preprocessing: ImageNet normalization, BGR, center crop');
        break;
      default:
        print('Unknown preset. Available: imagenet, simple, bgr, imagenet_bgr');
    }
  }

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    try {
      // Load labels
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n').map((label) => label.trim()).toList();
      _labels.removeWhere((label) => label.isEmpty);

      print('Loaded ${_labels.length} labels: ${_labels.take(3).join(", ")}...');

      // Load model
      final interpreterOptions = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/model_unquant.tflite',
        options: interpreterOptions,
      );

      // Validate that model output matches number of labels
      if (_interpreter != null) {
        final outputTensor = _interpreter!.getOutputTensor(0);
        final outputShape = outputTensor.shape;
        final outputSize = outputShape.length > 1 ? outputShape[1] : outputShape[0];
        
        print('Model output size: $outputSize, Labels count: ${_labels.length}');
        
        if (outputSize != _labels.length) {
          print('WARNING: Model output size ($outputSize) does not match labels count (${_labels.length})');
        }
      }

      _isLoaded = true;
      print('Model loaded successfully');
      print('Current preprocessing: ImageNet=${useImageNetNormalization}, BGR=${useBGR}, CenterCrop=${useCenterCrop}');
      print('💡 TIP: If accuracy is low, try different preprocessing presets:');
      print('   classifier.setPreprocessingPreset("imagenet")  // Most common');
      print('   classifier.setPreprocessingPreset("simple")     // For custom models');
      print('   classifier.setPreprocessingPreset("bgr")        // For OpenCV-trained models');
    } catch (e) {
      print('Error loading model: $e');
      _isLoaded = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> classifyImage(File imageFile) async {
    if (!_isLoaded || _interpreter == null) {
      print('Model not loaded - isLoaded: $_isLoaded, interpreter: ${_interpreter != null}');
      return null;
    }

    try {
      print('Starting image classification...');
      print('Preprocessing config: ImageNet=${useImageNetNormalization}, BGR=${useBGR}, CenterCrop=${useCenterCrop}');
      
      // Read and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      print('Image bytes read: ${imageBytes.length}');
      
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        print('Failed to decode image');
        return null;
      }
      
      print('Image decoded: ${image.width}x${image.height}');

      // Get model input shape
      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape;
      print('Model input shape: $inputShape');
      print('Input tensor type: ${inputTensor.type}');
      
      final inputHeight = inputShape.length > 1 ? inputShape[1] : 224;
      final inputWidth = inputShape.length > 2 ? inputShape[2] : 224;
      
      print('Resizing to: ${inputWidth}x${inputHeight}');
      
      // Resize image with better interpolation
      img.Image processedImage = image;
      
      // Apply image enhancements if enabled
      if (enableImageEnhancement) {
        // Adjust brightness
        if (brightnessAdjustment != 1.0) {
          processedImage = img.adjustColor(
            processedImage,
            brightness: brightnessAdjustment,
          );
          print('Applied brightness adjustment: $brightnessAdjustment');
        }
        
        // Adjust contrast
        if (contrastAdjustment != 1.0) {
          processedImage = img.adjustColor(
            processedImage,
            contrast: contrastAdjustment,
          );
          print('Applied contrast adjustment: $contrastAdjustment');
        }
        
        // Apply sharpening if enabled
        if (enableSharpening) {
          processedImage = img.convolution(processedImage, filter: [
            0, -1, 0,
            -1, 5, -1,
            0, -1, 0,
          ]);
          print('Applied sharpening filter');
        }
      }
      
      // Center crop to square if enabled (some models work better with square inputs)
      if (useCenterCrop && processedImage.width != processedImage.height) {
        final size = processedImage.width < processedImage.height 
            ? processedImage.width 
            : processedImage.height;
        final offsetX = (processedImage.width - size) ~/ 2;
        final offsetY = (processedImage.height - size) ~/ 2;
        processedImage = img.copyCrop(processedImage, 
          x: offsetX, 
          y: offsetY, 
          width: size, 
          height: size
        );
        print('Center cropped to: ${processedImage.width}x${processedImage.height}');
      }
      
      // Resize with cubic interpolation for better quality (better than linear)
      final resizedImage = img.copyResize(
        processedImage, 
        width: inputWidth, 
        height: inputHeight,
        interpolation: img.Interpolation.cubic,  // Changed from linear to cubic for better quality
      );
      print('Resized image: ${resizedImage.width}x${resizedImage.height}');
      
      // Convert to Float32List - tflite_flutter prefers typed data
      final inputBuffer = Float32List(inputHeight * inputWidth * 3);
      
      // ImageNet normalization constants (common for many models)
      const meanR = 0.485;
      const meanG = 0.456;
      const meanB = 0.406;
      const stdR = 0.229;
      const stdG = 0.224;
      const stdB = 0.225;
      
      // Fill input buffer with normalized pixel values
      int bufferIndex = 0;
      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          final pixel = resizedImage.getPixel(x, y);
          
          double r, g, b;
          
          if (useImageNetNormalization) {
            // ImageNet normalization: (pixel/255 - mean) / std
            r = (pixel.r / 255.0 - meanR) / stdR;
            g = (pixel.g / 255.0 - meanG) / stdG;
            b = (pixel.b / 255.0 - meanB) / stdB;
          } else {
            // Simple normalization [0, 1]
            r = pixel.r / 255.0;
            g = pixel.g / 255.0;
            b = pixel.b / 255.0;
          }
          
          // Apply channel order (RGB or BGR)
          if (useBGR) {
            inputBuffer[bufferIndex++] = b;
            inputBuffer[bufferIndex++] = g;
            inputBuffer[bufferIndex++] = r;
          } else {
            inputBuffer[bufferIndex++] = r;
            inputBuffer[bufferIndex++] = g;
            inputBuffer[bufferIndex++] = b;
          }
        }
      }
      
      print('Input buffer created: ${inputBuffer.length} elements');

      // Get output shape
      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      print('Model output shape: $outputShape');
      print('Output tensor type: ${outputTensor.type}');
      
      // Create output in the exact shape the model expects [1, 10]
      // The output must match the tensor shape exactly
      final output = List.generate(outputShape[0] ?? 1, (_) {
        return List.filled(outputShape.length > 1 ? outputShape[1] : _labels.length, 0.0);
      });
      
      print('Output created with shape: [${output.length}, ${output[0].length}]');

      print('Running inference...');
      
      // Create input in nested format [1, height, width, 3]
      final inputNested = List.generate(1, (_) {
        return List.generate(inputHeight, (y) {
          return List.generate(inputWidth, (x) {
            final idx = (y * inputWidth + x) * 3;
            return [
              inputBuffer[idx],
              inputBuffer[idx + 1],
              inputBuffer[idx + 2],
            ];
          });
        });
      });
      
      // Run inference - use ensemble if enabled
      List<double> finalResults;
      if (enableEnsemblePrediction) {
        // Run multiple predictions with slight variations and average them
        print('Running ensemble prediction (3 variations)...');
        final ensembleResults = <List<double>>[];
        
        // Original prediction
        final output1 = List.generate(outputShape[0] ?? 1, (_) {
          return List.filled(outputShape.length > 1 ? outputShape[1] : _labels.length, 0.0);
        });
        _interpreter!.run(inputNested, output1);
        ensembleResults.add(output1[0]);
        
        // Slightly brighter version
        final brighterImage = img.adjustColor(resizedImage, brightness: 1.1);
        final brighterBuffer = _createInputBuffer(brighterImage, inputWidth, inputHeight);
        final brighterInput = _createNestedInput(brighterBuffer, inputWidth, inputHeight);
        final output2 = List.generate(outputShape[0] ?? 1, (_) {
          return List.filled(outputShape.length > 1 ? outputShape[1] : _labels.length, 0.0);
        });
        _interpreter!.run(brighterInput, output2);
        ensembleResults.add(output2[0]);
        
        // Slightly darker version
        final darkerImage = img.adjustColor(resizedImage, brightness: 0.9);
        final darkerBuffer = _createInputBuffer(darkerImage, inputWidth, inputHeight);
        final darkerInput = _createNestedInput(darkerBuffer, inputWidth, inputHeight);
        final output3 = List.generate(outputShape[0] ?? 1, (_) {
          return List.filled(outputShape.length > 1 ? outputShape[1] : _labels.length, 0.0);
        });
        _interpreter!.run(darkerInput, output3);
        ensembleResults.add(output3[0]);
        
        // Average the results
        finalResults = List.generate(_labels.length, (i) {
          double sum = 0.0;
          for (var result in ensembleResults) {
            sum += result[i];
          }
          return sum / ensembleResults.length;
        });
        print('Ensemble prediction completed (averaged ${ensembleResults.length} predictions)');
      } else {
        // Single prediction
        _interpreter!.run(inputNested, output);
        finalResults = output[0];
        print('Inference completed');
      }

      // Use final results (from ensemble or single prediction)
      final results = finalResults;
      
      print('Raw output values: ${results.take(3).toList()}...');
      
      // Check if output needs softmax
      // Logits typically have large positive/negative values and don't sum to ~1
      // Probabilities are in [0,1] and typically sum close to 1
      final sum = results.fold(0.0, (a, b) => a + b);
      final hasLargeValues = results.any((v) => v.abs() > 10.0);
      final isInRange = results.every((v) => v >= 0.0 && v <= 1.0);
      
      List<double> processedResults = results;
      
      // Apply softmax if values look like logits (large values or don't sum to ~1)
      if (hasLargeValues || (!isInRange && (sum < 0.5 || sum > 1.5))) {
        print('Applying softmax (detected logits)');
        // Apply softmax for numerical stability
        double maxLogit = results.reduce((a, b) => a > b ? a : b);
        double sumExp = 0.0;
        for (int i = 0; i < results.length; i++) {
          sumExp += math.exp(results[i] - maxLogit);
        }
        processedResults = results.map((logit) => 
          (math.exp(logit - maxLogit) / sumExp)
        ).toList();
        print('After softmax, sum: ${processedResults.fold(0.0, (a, b) => a + b)}');
      } else {
        print('Using raw output (already probabilities)');
        // Ensure values are in [0,1] range
        processedResults = results.map((v) => v.clamp(0.0, 1.0)).toList();
      }
      
      // Find top prediction and log all predictions for debugging
      double maxScore = 0.0;
      int maxIndex = 0;
      final predictions = <MapEntry<int, double>>[];
      
      for (int i = 0; i < processedResults.length; i++) {
        predictions.add(MapEntry(i, processedResults[i]));
        if (processedResults[i] > maxScore) {
          maxScore = processedResults[i];
          maxIndex = i;
        }
      }
      
      // Sort predictions for logging
      predictions.sort((a, b) => b.value.compareTo(a.value));
      
      // Log ALL predictions for debugging (helps identify if model is confused)
      print('=== ALL PREDICTIONS (sorted by confidence) ===');
      for (int i = 0; i < predictions.length; i++) {
        final idx = predictions[i].key;
        final conf = predictions[i].value * 100;
        final labelName = _labels[idx].contains(' ') 
            ? _labels[idx].split(' ').sublist(1).join(' ')
            : _labels[idx];
        final marker = i == 0 ? '>>> ' : '    ';
        print('$marker${i + 1}. $labelName: ${conf.toStringAsFixed(2)}%');
      }
      print('===============================================');
      
      // Special check for problematic bread types
      final problemBreads = ['spanish', 'pan de leche', 'pandesal', 'pan de coco'];
      final breadIndices = <String, int>{};
      final breadConfidences = <String, double>{};
      
      for (var breadName in problemBreads) {
        final index = _labels.indexWhere((label) => 
          label.toLowerCase().contains(breadName));
        if (index >= 0) {
          breadIndices[breadName] = index;
          breadConfidences[breadName] = processedResults[index] * 100;
        }
      }
      
      print('🔍 Problem Bread Types Confidence:');
      bool hasLowConfidence = false;
      for (var entry in breadConfidences.entries) {
        final breadName = entry.key.toUpperCase();
        final conf = entry.value;
        final status = conf < 20 ? '❌' : conf < 50 ? '⚠️' : '✅';
        print('   $status $breadName: ${conf.toStringAsFixed(2)}%');
        if (conf < 20) hasLowConfidence = true;
      }
      
      if (hasLowConfidence) {
        print('');
        print('⚠️  Some bread types have very low confidence!');
        print('   This usually means preprocessing mismatch.');
        print('   Try different preprocessing presets in Settings:');
        print('   1. Simple Normalization');
        print('   2. BGR Color Order');
        print('   3. ImageNet + BGR');
        print('   4. Enable Ensemble Prediction for better accuracy');
      }
      
      // Check if top prediction is one of the problem breads
      final topLabel = _labels[maxIndex].toLowerCase();
      final isProblemBread = problemBreads.any((bread) => topLabel.contains(bread));
      if (isProblemBread && maxScore < 0.5) {
        print('');
        print('⚠️  Top prediction is ${_labels[maxIndex]} but confidence is low (${(maxScore * 100).toStringAsFixed(1)}%)');
        print('   The model is uncertain. Try:');
        print('   1. Better lighting');
        print('   2. Different preprocessing preset');
        print('   3. Enable Ensemble Prediction');
      }
      
      // Check if top prediction has low confidence (indicates model uncertainty)
      if (maxScore < 0.5) {
        print('⚠️  WARNING: Low confidence (${(maxScore * 100).toStringAsFixed(1)}%). Model is uncertain.');
        print('   This suggests preprocessing mismatch or poor model training.');
      }

      // Get label (remove index prefix if present)
      String label = _labels[maxIndex];
      if (label.contains(' ')) {
        final parts = label.split(' ');
        label = parts.sublist(1).join(' ');
      }

      // Calculate confidence percentage
      final confidence = (maxScore * 100).clamp(0.0, 100.0);
      
      print('Final prediction: $label with ${confidence.toStringAsFixed(2)}% confidence');

      return {
        'label': label,
        'confidence': confidence,
        'allPredictions': processedResults.asMap().entries.map((e) => {
          'label': _labels[e.key].contains(' ') 
              ? _labels[e.key].split(' ').sublist(1).join(' ')
              : _labels[e.key],
          'confidence': (e.value * 100).clamp(0.0, 100.0),
        }).toList()
          ..sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double)),
      };
    } catch (e, stackTrace) {
      print('Error classifying image: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Helper method to create input buffer from image
  Float32List _createInputBuffer(img.Image image, int width, int height) {
    final buffer = Float32List(height * width * 3);
    const meanR = 0.485;
    const meanG = 0.456;
    const meanB = 0.406;
    const stdR = 0.229;
    const stdG = 0.224;
    const stdB = 0.225;
    
    int bufferIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        double r, g, b;
        
        if (useImageNetNormalization) {
          r = (pixel.r / 255.0 - meanR) / stdR;
          g = (pixel.g / 255.0 - meanG) / stdG;
          b = (pixel.b / 255.0 - meanB) / stdB;
        } else {
          r = pixel.r / 255.0;
          g = pixel.g / 255.0;
          b = pixel.b / 255.0;
        }
        
        if (useBGR) {
          buffer[bufferIndex++] = b;
          buffer[bufferIndex++] = g;
          buffer[bufferIndex++] = r;
        } else {
          buffer[bufferIndex++] = r;
          buffer[bufferIndex++] = g;
          buffer[bufferIndex++] = b;
        }
      }
    }
    return buffer;
  }
  
  // Helper method to create nested input from buffer
  List<List<List<List<double>>>> _createNestedInput(Float32List buffer, int width, int height) {
    return List.generate(1, (_) {
      return List.generate(height, (y) {
        return List.generate(width, (x) {
          final idx = (y * width + x) * 3;
          return [
            buffer[idx],
            buffer[idx + 1],
            buffer[idx + 2],
          ];
        });
      });
    });
  }
  
  // Method to enable/disable accuracy enhancements
  void setAccuracyEnhancements({
    bool? enableEnhancement,
    bool? enableEnsemble,
    bool? enableSharpen,
    double? brightness,
    double? contrast,
  }) {
    if (enableEnhancement != null) enableImageEnhancement = enableEnhancement;
    if (enableEnsemble != null) enableEnsemblePrediction = enableEnsemble;
    if (enableSharpen != null) enableSharpening = enableSharpen;
    if (brightness != null) brightnessAdjustment = brightness.clamp(0.5, 2.0);
    if (contrast != null) contrastAdjustment = contrast.clamp(0.5, 2.0);
    
    print('Accuracy enhancements updated:');
    print('  Image Enhancement: $enableImageEnhancement');
    print('  Ensemble Prediction: $enableEnsemblePrediction');
    print('  Sharpening: $enableSharpening');
    print('  Brightness: $brightnessAdjustment');
    print('  Contrast: $contrastAdjustment');
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}



