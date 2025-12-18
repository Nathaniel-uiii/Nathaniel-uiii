# Bread Classification Accuracy Improvement Guide

## 🔍 Quick Diagnosis

If your model is misidentifying bread, the issue is usually one of these:

1. **Preprocessing Mismatch (90% of cases)** - Your training preprocessing ≠ inference preprocessing
2. **Insufficient Training Data** - Not enough variety or quality
3. **Model Architecture Issues** - Wrong base model or hyperparameters
4. **Overfitting** - Model memorized training data but can't generalize

---

## ✅ Step 1: Fix Preprocessing (MOST IMPORTANT!)

**The preprocessing used during training MUST match inference exactly!**

### How to Find Your Training Preprocessing

Check your training code (Python/TensorFlow/Keras) for:
- **Normalization**: ImageNet mean/std OR simple [0,1] division
- **Color order**: RGB OR BGR
- **Resizing**: Center crop OR full resize

### Try These Presets in Order:

#### Option 1: ImageNet Normalization (Most Common)
```dart
// In your app, after loading the classifier:
classifier.setPreprocessingPreset("imagenet");
```
**Use if:** You used MobileNet, EfficientNet, ResNet, or transfer learning

#### Option 2: Simple Normalization
```dart
classifier.setPreprocessingPreset("simple");
```
**Use if:** You trained a custom model from scratch with simple [0,1] normalization

#### Option 3: BGR Color Order
```dart
classifier.setPreprocessingPreset("bgr");
```
**Use if:** You used OpenCV for preprocessing during training

#### Option 4: Manual Configuration
```dart
classifier.useImageNetNormalization = true;  // or false
classifier.useBGR = false;  // or true
classifier.useCenterCrop = true;  // or false
```

### How to Test

1. Take a photo of a bread you know (e.g., "Pandesal")
2. Check the console logs - look for:
   - Top prediction confidence (should be >70% if correct)
   - All predictions list (should show correct bread in top 3)
3. If confidence is low (<50%), try a different preset
4. Repeat with different bread types

---

## 📊 Step 2: Improve Training Data

Even with 100 epochs, poor data = poor accuracy.

### Data Quality Checklist:

- [ ] **Minimum 100-200 images per class** (10 classes = 1000-2000 images total)
- [ ] **Variety in each class:**
  - Different lighting (bright, dim, natural, artificial)
  - Different angles (top, side, close-up, far)
  - Different backgrounds
  - Different stages (fresh, slightly stale)
  - Different brands/variations
- [ ] **Balanced dataset** - Each class has similar number of images
- [ ] **Clean labels** - Every image is correctly labeled
- [ ] **No duplicates** - Each image is unique

### Data Augmentation (During Training)

Use these augmentations to increase effective dataset size:
- Random rotation (±15 degrees)
- Random brightness/contrast (±20%)
- Random horizontal flip
- Random zoom (0.8x - 1.2x)
- Random crop and resize

**Example (TensorFlow/Keras):**
```python
from tensorflow.keras.preprocessing.image import ImageDataGenerator

datagen = ImageDataGenerator(
    rotation_range=15,
    brightness_range=[0.8, 1.2],
    horizontal_flip=True,
    zoom_range=0.2,
    fill_mode='nearest'
)
```

---

## 🏗️ Step 3: Model Architecture & Training

### Recommended Base Models (Transfer Learning):

1. **MobileNetV2** - Fast, good for mobile
2. **EfficientNet-B0/B1** - Best accuracy/speed balance
3. **ResNet50** - High accuracy, slower

### Training Best Practices:

```python
# Example training configuration
base_model = tf.keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights='imagenet'  # Use pre-trained weights!
)

# Add your classification head
model = tf.keras.Sequential([
    base_model,
    tf.keras.layers.GlobalAveragePooling2D(),
    tf.keras.layers.Dropout(0.2),  # Prevent overfitting
    tf.keras.layers.Dense(10, activation='softmax')  # 10 bread classes
])

# Freeze base model initially, then fine-tune
base_model.trainable = False  # First train only head
# ... train for 10-20 epochs ...

base_model.trainable = True  # Then fine-tune everything
# ... train for 20-50 more epochs ...
```

### Hyperparameters:

- **Learning Rate**: Start with 0.001, reduce by 10x if loss plateaus
- **Batch Size**: 16-32 (depends on GPU memory)
- **Epochs**: 50-100 is usually enough (use early stopping!)
- **Optimizer**: Adam or AdamW
- **Loss**: Categorical crossentropy

### Use Early Stopping:

```python
early_stopping = tf.keras.callbacks.EarlyStopping(
    monitor='val_loss',
    patience=10,  # Stop if no improvement for 10 epochs
    restore_best_weights=True
)
```

**Don't train for 100 epochs blindly!** Use early stopping to prevent overfitting.

---

## 🔧 Step 4: Verify Model Export

When converting to TFLite, ensure:

1. **No quantization errors** - Test quantized model before deploying
2. **Correct input/output shapes** - Match what your app expects
3. **Include metadata** (optional but helpful)

```python
# Export to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open('model_unquant.tflite', 'wb') as f:
    f.write(tflite_model)
```

---

## 🧪 Step 5: Testing & Validation

### Test on Validation Set:

- **Split**: 70% train, 15% validation, 15% test
- **Target accuracy**: >85% on validation set
- **Per-class accuracy**: Each bread type should be >80%

### Test in Real Conditions:

- Test with photos taken in the app (not training images)
- Test in different lighting conditions
- Test with different phone cameras
- Test edge cases (unclear images, similar breads)

---

## 🚨 Common Issues & Solutions

### Issue: Model always predicts the same class
**Solution:** 
- Check class imbalance in training data
- Use class weights during training
- Check if one class has way more images

### Issue: Low confidence on all predictions
**Solution:**
- Preprocessing mismatch (try different presets)
- Model not trained properly
- Test image is too different from training data

### Issue: High confidence but wrong prediction
**Solution:**
- Preprocessing definitely wrong (try all presets)
- Model overfitted to training data
- Need more diverse training images

### Issue: Works in training but not in app
**Solution:**
- Preprocessing mismatch (99% sure this is it!)
- Model export issue
- Input shape mismatch

---

## 📝 Quick Checklist

Before retraining:
- [ ] Check training preprocessing code
- [ ] Match preprocessing in app exactly
- [ ] Verify you have 100+ images per class
- [ ] Ensure balanced dataset
- [ ] Use data augmentation
- [ ] Use transfer learning (don't train from scratch)
- [ ] Use early stopping (don't train 100 epochs blindly)
- [ ] Validate on separate test set
- [ ] Test exported TFLite model before deploying

---

## 🎯 Expected Results

With proper setup, you should see:
- **Validation accuracy**: >85%
- **Per-class accuracy**: >80% for each bread type
- **Inference confidence**: >70% for correct predictions
- **Top-3 accuracy**: >95% (correct bread in top 3 predictions)

---

## 💡 Pro Tips

1. **Start with ImageNet preset** - Most models use this
2. **Check console logs** - They show all predictions and confidence scores
3. **Test systematically** - Try each preset with known bread types
4. **Use validation set** - Don't just look at training accuracy
5. **Monitor overfitting** - If training accuracy >> validation accuracy, you're overfitting
6. **More data > More epochs** - Better to have 200 images × 50 epochs than 50 images × 200 epochs

---

## 🆘 Still Having Issues?

1. **Check console logs** - Look at all predictions, not just top one
2. **Verify preprocessing** - This is the #1 cause of low accuracy
3. **Test with training images** - If it works on training images but not new ones, it's overfitting
4. **Compare training vs inference** - Preprocessing must match exactly!

Good luck! 🍞

