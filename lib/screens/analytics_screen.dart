import 'package:flutter/material.dart';
import '../services/records_service.dart';
import '../models/classification_record.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final RecordsService _recordsService = RecordsService();
  List<ClassificationRecord> _records = [];
  bool _isLoading = true;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    final records = await _recordsService.getRecords();
    
    if (mounted) {
      setState(() {
        _records = records;
        _analytics = _calculateAnalytics(records);
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateAnalytics(List<ClassificationRecord> records) {
    if (records.isEmpty) {
      return {
        'totalClassifications': 0,
        'averageConfidence': 0.0,
        'highConfidenceCount': 0,
        'mediumConfidenceCount': 0,
        'lowConfidenceCount': 0,
        'breadTypeCounts': <String, int>{},
        'breadTypeAvgConfidence': <String, double>{},
        'mostClassified': '',
        'recentActivity': <Map<String, dynamic>>[],
      };
    }

    // Calculate average confidence
    final avgConfidence = records.map((r) => r.confidence).reduce((a, b) => a + b) / records.length;

    // Count by confidence levels
    int highConfidence = 0;
    int mediumConfidence = 0;
    int lowConfidence = 0;

    // Count by bread type and calculate average confidence per type
    final breadTypeCounts = <String, int>{};
    final breadTypeConfidences = <String, List<double>>{};
    
    for (final record in records) {
      // Confidence levels
      if (record.confidence >= 70) {
        highConfidence++;
      } else if (record.confidence >= 50) {
        mediumConfidence++;
      } else {
        lowConfidence++;
      }

      // Bread type counts
      breadTypeCounts[record.breadType] = (breadTypeCounts[record.breadType] ?? 0) + 1;
      
      // Track confidences per bread type
      if (!breadTypeConfidences.containsKey(record.breadType)) {
        breadTypeConfidences[record.breadType] = [];
      }
      breadTypeConfidences[record.breadType]!.add(record.confidence);
    }
    
    // Calculate average confidence per bread type
    final breadTypeAvgConfidence = <String, double>{};
    breadTypeConfidences.forEach((type, confidences) {
      final avg = confidences.reduce((a, b) => a + b) / confidences.length;
      breadTypeAvgConfidence[type] = avg;
    });

    // Find most classified bread type
    String mostClassified = '';
    int maxCount = 0;
    breadTypeCounts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostClassified = type;
      }
    });

    // Recent activity (last 7 days)
    final now = DateTime.now();
    final recentActivity = records.where((r) {
      final daysDiff = now.difference(r.timestamp).inDays;
      return daysDiff <= 7;
    }).length;

    // Daily activity for last 7 days
    final dailyActivity = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.day}/${date.month}';
      dailyActivity[dateKey] = records.where((r) {
        return r.timestamp.year == date.year &&
               r.timestamp.month == date.month &&
               r.timestamp.day == date.day;
      }).length;
    }

    return {
      'totalClassifications': records.length,
      'averageConfidence': avgConfidence,
      'highConfidenceCount': highConfidence,
      'mediumConfidenceCount': mediumConfidence,
      'lowConfidenceCount': lowConfidence,
      'breadTypeCounts': breadTypeCounts,
      'breadTypeAvgConfidence': breadTypeAvgConfidence,
      'mostClassified': mostClassified,
      'recentActivity': recentActivity,
      'dailyActivity': dailyActivity,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: const Color(0xFFF57C00), // warm orange to match home
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null || _analytics!['totalClassifications'] == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No data available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start classifying bread to see analytics',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Cards
                        _buildOverviewCards(),
                        const SizedBox(height: 20),
                        
                        // Average Confidence
                        _buildAverageConfidenceCard(),
                        const SizedBox(height: 20),
                        
                        // Confidence Distribution
                        _buildConfidenceDistribution(),
                        const SizedBox(height: 20),
                        
                        // Most Classified Types
                        _buildBreadTypeStats(),
                        const SizedBox(height: 20),
                        
                        // Accuracy Rate by Variety
                        _buildAccuracyByVariety(),
                        const SizedBox(height: 20),
                        
                        // Daily Activity
                        _buildDailyActivity(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverviewCards() {
    final total = _analytics!['totalClassifications'] as int;
    final recent = _analytics!['recentActivity'] as int;
    final mostClassified = _analytics!['mostClassified'] as String;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            total.toString(),
            Icons.photo_camera,
            const Color(0xFFF57C00), // orange
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Last 7 Days',
            recent.toString(),
            Icons.calendar_today,
            const Color(0xFFEF6C00), // darker orange
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Most Classified',
            mostClassified.isEmpty ? 'N/A' : mostClassified.split(' ').take(2).join(' '),
            Icons.star,
            const Color(0xFF8D6E63), // warm brown
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageConfidenceCard() {
    final avgConfidence = _analytics!['averageConfidence'] as double;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.green.shade700,
            ],
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Average Confidence',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${avgConfidence.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: avgConfidence / 100,
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceDistribution() {
    final high = _analytics!['highConfidenceCount'] as int;
    final medium = _analytics!['mediumConfidenceCount'] as int;
    final low = _analytics!['lowConfidenceCount'] as int;
    final total = high + medium + low;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildDistributionBar('High (≥70%)', high, total, Colors.green),
            const SizedBox(height: 12),
            _buildDistributionBar('Medium (50-69%)', medium, total, Colors.orange),
            const SizedBox(height: 12),
            _buildDistributionBar('Low (<50%)', low, total, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBreadTypeStats() {
    final breadTypeCounts = _analytics!['breadTypeCounts'] as Map<String, int>;
    final sortedTypes = breadTypeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bread Type Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedTypes.take(5).map((entry) {
              final total = _analytics!['totalClassifications'] as int;
              final percentage = (entry.value / total * 100);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 60,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyByVariety() {
    final breadTypeAvgConfidence = _analytics!['breadTypeAvgConfidence'] as Map<String, double>;
    
    if (breadTypeAvgConfidence.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Sort by average confidence (descending)
    final sortedTypes = breadTypeAvgConfidence.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Accuracy Rate by Variety',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedTypes.map((entry) {
              final avgConfidence = entry.value;
              final count = _analytics!['breadTypeCounts'][entry.key] as int;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${avgConfidence.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getConfidenceColor(avgConfidence),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($count)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: avgConfidence / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getConfidenceColor(avgConfidence),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 70) return Colors.green;
    if (confidence >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDailyActivity() {
    final dailyActivity = _analytics!['dailyActivity'] as Map<String, int>;
    final maxActivity = dailyActivity.values.isEmpty 
        ? 1 
        : dailyActivity.values.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Activity (Last 7 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyActivity.entries.map((entry) {
                final height = maxActivity > 0 
                    ? (entry.value / maxActivity * 100).clamp(10.0, 100.0)
                    : 10.0;
                
                return Column(
                  children: [
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: entry.value > 0
                            ? Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

