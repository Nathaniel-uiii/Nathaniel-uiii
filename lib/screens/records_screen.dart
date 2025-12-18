import 'package:flutter/material.dart';
import '../models/classification_record.dart';
import '../services/records_service.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final RecordsService _recordsService = RecordsService();
  List<ClassificationRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    final records = await _recordsService.getRecords();
    
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRecord(String id) async {
    await _recordsService.deleteRecord(id);
    _loadRecords();
  }

  Future<void> _clearAllRecords() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Records'),
        content: const Text('Are you sure you want to delete all records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _recordsService.clearAllRecords();
      _loadRecords();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 70) return Colors.green;
    if (confidence >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getBreadImagePath(String breadType) {
    // Map bread types to their image paths
    final breadTypeLower = breadType.toLowerCase();
    
    if (breadTypeLower.contains('binangkal')) {
      return 'Bread pictures/Binangkal_(sesame_seed_doughnuts).jpg';
    } else if (breadTypeLower.contains('pan de coco') || breadTypeLower.contains('pande coco')) {
      return 'Bread pictures/Pan de coco.jpg';
    } else if (breadTypeLower.contains('garlic')) {
      return 'Bread pictures/Garlic.jpg';
    } else if (breadTypeLower.contains('spanish')) {
      return 'Bread pictures/Spanish Bread.jpg';
    } else if (breadTypeLower.contains('siopao') || breadTypeLower.contains('soipao')) {
      return 'Bread pictures/Toasted Soipao.jpg';
    } else if (breadTypeLower.contains('pan de leche') || breadTypeLower.contains('pande leche')) {
      return 'Bread pictures/Pan de leche.jpg';
    } else if (breadTypeLower.contains('ensaymada') || breadTypeLower.contains('ensymada')) {
      return 'Bread pictures/ensymada.jpg';
    } else if (breadTypeLower.contains('star')) {
      return 'Bread pictures/Star.jpg';
    } else if (breadTypeLower.contains('pandesal')) {
      return 'Bread pictures/pandesal.webp';
    } else if (breadTypeLower.contains('loaf')) {
      return 'Bread pictures/Loafbird.jpg';
    }
    
    // Default fallback image
    return 'Bread pictures/Star.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        backgroundColor: const Color(0xFF8D6E63), // warm brown
        foregroundColor: Colors.white,
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllRecords,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No records yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start classifying bread to see history',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(record.confidence).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                _getBreadImagePath(record.breadType),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to icon if image fails to load
                                  return Icon(
                                    Icons.bakery_dining,
                                    color: _getConfidenceColor(record.confidence),
                                    size: 30,
                                  );
                                },
                              ),
                            ),
                          ),
                          title: Text(
                            record.breadType,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${record.confidence.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _getConfidenceColor(record.confidence),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDateTime(record.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteRecord(record.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

