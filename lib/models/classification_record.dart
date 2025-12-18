class ClassificationRecord {
  final String id;
  final String breadType;
  final double confidence;
  final DateTime timestamp;
  final String? imagePath;

  ClassificationRecord({
    required this.id,
    required this.breadType,
    required this.confidence,
    required this.timestamp,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'breadType': breadType,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory ClassificationRecord.fromJson(Map<String, dynamic> json) {
    return ClassificationRecord(
      id: json['id'] as String,
      breadType: json['breadType'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      imagePath: json['imagePath'] as String?,
    );
  }
}

