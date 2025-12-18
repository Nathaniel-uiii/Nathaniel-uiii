import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/classification_record.dart';

class RecordsService {
  static const String _recordsKey = 'classification_records';

  Future<List<ClassificationRecord>> getRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList(_recordsKey) ?? [];
      
      return recordsJson
          .map((json) => ClassificationRecord.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error loading records: $e');
      return [];
    }
  }

  Future<void> addRecord(ClassificationRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await getRecords();
      records.insert(0, record);
      
      // Keep only last 100 records
      final limitedRecords = records.take(100).toList();
      
      final recordsJson = limitedRecords
          .map((record) => jsonEncode(record.toJson()))
          .toList();
      
      await prefs.setStringList(_recordsKey, recordsJson);
    } catch (e) {
      print('Error saving record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await getRecords();
      records.removeWhere((record) => record.id == id);
      
      final recordsJson = records
          .map((record) => jsonEncode(record.toJson()))
          .toList();
      
      await prefs.setStringList(_recordsKey, recordsJson);
    } catch (e) {
      print('Error deleting record: $e');
    }
  }

  Future<void> clearAllRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recordsKey);
    } catch (e) {
      print('Error clearing records: $e');
    }
  }
}

