import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'classifications';

  /// Save classification data to Firestore
  /// Only stores data, not the image
  Future<void> saveClassification({
    required String breadType,
    required double confidence,
    required DateTime timestamp,
    required List<Map<String, dynamic>> allPredictions,
  }) async {
    try {
      await _firestore.collection(_collectionName).add({
        'breadType': breadType,
        'confidence': confidence,
        'timestamp': Timestamp.fromDate(timestamp),
        'allPredictions': allPredictions,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Classification data saved to Firestore successfully');
    } catch (e) {
      print('Error saving classification to Firestore: $e');
      rethrow;
    }
  }

  /// Get all classifications from Firestore
  Stream<List<Map<String, dynamic>>> getClassifications() {
    return _firestore
        .collection(_collectionName)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        };
      }).toList();
    });
  }

  /// Delete a classification from Firestore
  Future<void> deleteClassification(String documentId) async {
    try {
      await _firestore.collection(_collectionName).doc(documentId).delete();
      print('Classification deleted from Firestore successfully');
    } catch (e) {
      print('Error deleting classification from Firestore: $e');
      rethrow;
    }
  }
}

