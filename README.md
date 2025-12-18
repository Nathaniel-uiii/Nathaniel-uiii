# Bread Classifier App

A Flutter mobile application that uses TensorFlow Lite to classify different types of bread from camera images.

## Features

- **Camera Access**: Take photos directly from your device camera
- **Image Classification**: Identify bread types using a pre-trained TensorFlow Lite model
- **Accuracy Display**: View detailed confidence scores and predictions
- **Records**: Keep a history of all classifications with timestamps

## Supported Bread Types

The app can identify the following bread types:
1. Binangkal
2. Pan de coco
3. Garlic Bread
4. Spanish Bread
5. Toasted Siopao
6. Pan De Leche
7. Ensaymada
8. Star Bread
9. Pandesal
10. Loaf Bread

## Setup Instructions

1. **Install Dependencies**
   ```bash
   cd bread
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

## App Structure

- `lib/main.dart` - Main app entry point with routing
- `lib/screens/` - All app screens (homepage, camera, accuracy, records)
- `lib/services/` - Business logic (classifier, records service)
- `lib/models/` - Data models
- `assets/` - TensorFlow Lite model and labels file

## Permissions

The app requires the following permissions:
- **Camera**: To take photos of bread
- **Photo Library**: To select images from gallery

These permissions are automatically requested when needed.

## Usage

1. **Homepage**: Navigate to different features
2. **Camera**: Tap the camera button to take a photo or select from gallery
3. **Accuracy**: View detailed classification results and confidence scores
4. **Records**: Browse your classification history

## Requirements

- Flutter SDK 3.10.1 or higher
- Android Studio / Xcode for building
- Physical device or emulator with camera support (for camera feature)
