import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final analyticsService = Provider.of<AnalyticsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Yoga Journey',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Track your progress and usage statistics',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 24),

            // Overview cards
            _buildOverviewCards(context, analyticsService),

            SizedBox(height: 24),

            // Activity chart
            _buildActivityChart(context, analyticsService),

            SizedBox(height: 24),

            // Feature usage
            _buildFeatureUsageSection(context, analyticsService),

            SizedBox(height: 24),

            // Recent sessions
            _buildRecentSessionsSection(context, analyticsService),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, AnalyticsService analyticsService) {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            context,
            'Total Sessions',
            analyticsService.totalSessions.toString(),
            Icons.fitness_center,
            AppColors.primary,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildOverviewCard(
            context,
            'Total Minutes',
            analyticsService.totalMinutes.toString(),
            Icons.timer,
            AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart(BuildContext context, AnalyticsService analyticsService) {
    final sessions = analyticsService.recentSessions;

    // Map sessions to days
    final Map<String, int> dailyMinutes = {};
    for (final session in sessions) {
      final date = DateFormat('MM/dd').format(session.date);
      dailyMinutes[date] = (dailyMinutes[date] ?? 0) + session.durationMinutes;
    }

    // Generate last 7 days dates
    final List<String> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      last7Days.add(DateFormat('MM/dd').format(date));
    }

    // Create bar data
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < last7Days.length; i++) {
      final day = last7Days[i];
      final minutes = dailyMinutes[day] ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: minutes.toDouble(),
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              width: 20,
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 60,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox();
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(value.toInt().toString()),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              last7Days[value.toInt()],
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 15,
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Minutes of Activity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureUsageSection(BuildContext context, AnalyticsService analyticsService) {
    final featureUsage = analyticsService.featureUsage;
    final mostUsedFeature = analyticsService.mostUsedFeature;

    final entries = featureUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Usage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Most used: $mostUsedFeature',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            ...entries.map((entry) => _buildFeatureUsageItem(
              context,
              entry.key,
              entry.value,
              _getFeatureIcon(entry.key),
              _getFeatureColor(entry.key),
              entries.first.value,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureUsageItem(
      BuildContext context,
      String feature,
      int count,
      IconData icon,
      Color color,
      int maxCount,
      ) {
    final percentage = maxCount > 0 ? count / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              SizedBox(width: 8),
              Text(
                feature,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Spacer(),
              Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionsSection(BuildContext context, AnalyticsService analyticsService) {
    final sessions = analyticsService.recentSessions;

    if (sessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No recent sessions',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            ...sessions.map((session) => _buildSessionItem(context, session)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, SessionData session) {
    final date = DateFormat('MMM d, yyyy').format(session.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getSessionTypeColor(session.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getSessionTypeIcon(session.type),
              color: _getSessionTypeColor(session.type),
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.type,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${session.durationMinutes} min',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getSessionTypeColor(session.type),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFeatureIcon(String feature) {
    switch (feature) {
      case 'Warm-Up Mode':
        return Icons.whatshot;
      case 'Relaxation Mode':
        return Icons.spa;
      case 'Ocean Sounds':
        return Icons.waves;
      default:
        return Icons.star;
    }
  }

  Color _getFeatureColor(String feature) {
    switch (feature) {
      case 'Warm-Up Mode':
        return AppColors.primary;
      case 'Relaxation Mode':
        return AppColors.secondary;
      case 'Ocean Sounds':
        return Colors.teal;
      default:
        return AppColors.accent;
    }
  }

  IconData _getSessionTypeIcon(String type) {
    switch (type) {
      case 'Morning Yoga':
        return Icons.wb_sunny;
      case 'Relaxation':
        return Icons.nightlight_round;
      case 'Meditation':
        return Icons.self_improvement;
      case 'Stretching':
        return Icons.accessibility_new;
      case 'Warm-Up':
        return Icons.whatshot;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getSessionTypeColor(String type) {
    switch (type) {
      case 'Morning Yoga':
        return Colors.amber;
      case 'Relaxation':
        return AppColors.secondary;
      case 'Meditation':
        return Colors.indigo;
      case 'Stretching':
        return Colors.teal;
      case 'Warm-Up':
        return AppColors.primary;
      default:
        return AppColors.accent;
    }
  }
}