import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/dtr_record.dart';
import '../theme/app_theme.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _db = DatabaseHelper();
  List<DtrRecord> _records = [];
  double _totalHours = 0;
  int _requiredHours = 600;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await _db.getAllRecords();
    final total = await _db.getTotalHours();
    final profile = await _db.getProfile();
    setState(() {
      _records = all;
      _totalHours = total;
      _requiredHours = profile?.requiredHours ?? 500;
    });
  }

  Future<void> _showEditRequiredHoursDialog() async {
    final ctrl = TextEditingController(text: _requiredHours.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.timer_outlined, color: AppTheme.secondary, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Required Hours',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set the total required OJT hours for your program.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '500',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                suffixText: 'hrs',
                suffixStyle: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null) {
      final profile = await _db.getProfile();
      if (profile != null) {
        await _db.updateProfile(profile.copyWith(requiredHours: result));
        await _loadData();
      } else {
        setState(() => _requiredHours = result);
      }
    }
  }

  List<DtrRecord> _getThisWeekRecords() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _records.where((r) {
      final d = DateTime.parse(r.date);
      return d.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             d.isBefore(startOfWeek.add(const Duration(days: 7)));
    }).toList();
  }

  Map<String, double> _getLast6MonthsHours() {
    final result = <String, double>{};
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final label = DateFormat('MMM').format(month);
      final monthRecords = _records.where((r) {
        final d = DateTime.parse(r.date);
        return d.year == month.year && d.month == month.month;
      });
      result[label] = monthRecords.fold(0, (s, r) => s + (r.hoursWorked ?? 0));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final weekRecords = _getThisWeekRecords();
    final weekHours = weekRecords.fold(0.0, (s, r) => s + (r.hoursWorked ?? 0));
    final monthlyData = _getLast6MonthsHours();
    final progress = _requiredHours > 0 ? (_totalHours / _requiredHours).clamp(0.0, 1.0) : 0.0;
    final completedCount = _records.where((r) => r.hoursWorked != null).length;
    final avgDaily = completedCount > 0 ? _totalHours / completedCount : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.secondary,
        backgroundColor: AppTheme.cardBg,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // OJT Completion Donut
            _buildDonutCard(progress).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 16),

            // Quick Stats
            Row(children: [
              Expanded(child: _buildStatTile('This Week', '${weekHours.toStringAsFixed(1)}h', Icons.date_range, AppTheme.secondary).animate().fadeIn(delay: 100.ms)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatTile('Avg/Day', '${avgDaily.toStringAsFixed(1)}h', Icons.trending_up, AppTheme.accent).animate().fadeIn(delay: 200.ms)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildStatTile('Total Days', '${_records.length}', Icons.calendar_today, AppTheme.warning).animate().fadeIn(delay: 300.ms)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatTile('Present', '${_records.where((r) => r.status == 'present').length}', Icons.check_circle_outline, AppTheme.success).animate().fadeIn(delay: 400.ms)),
            ]),
            const SizedBox(height: 20),

            // Bar chart
            _buildBarChart(monthlyData).animate().fadeIn(duration: 500.ms, delay: 300.ms),
            const SizedBox(height: 20),

            // Weekly breakdown
            if (weekRecords.isNotEmpty)
              _buildWeeklyCard(weekRecords).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 35,
                    sections: [
                      PieChartSectionData(
                        value: progress * 100,
                        color: progress >= 1.0 ? AppTheme.success : AppTheme.secondary,
                        radius: 14,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (1 - progress) * 100,
                        color: AppTheme.divider,
                        radius: 12,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OJT Completion', style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                _buildProgressRow('Completed', '${_totalHours.toStringAsFixed(1)}h', AppTheme.secondary),
                GestureDetector(
                  onTap: _showEditRequiredHoursDialog,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Required', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${_requiredHours}h',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined, size: 11, color: AppTheme.secondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _buildProgressRow('Remaining', '${(_requiredHours - _totalHours).clamp(0, double.infinity).toStringAsFixed(1)}h', AppTheme.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text(value, style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> data) {
    final maxY = data.values.isEmpty ? 10.0 : data.values.reduce((a, b) => a > b ? a : b) * 1.3;
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hours per Month', style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 10 : maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= entries.length) return const SizedBox();
                        return Text(entries[idx].key,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11));
                      },
                    ),
                  ),
                ),
                barGroups: entries.asMap().entries.map((e) =>
                  BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: AppTheme.secondary,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true, toY: maxY == 0 ? 10 : maxY, color: AppTheme.divider.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(List<DtrRecord> weekRecords) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week', style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          ...weekRecords.map((r) {
            final date = DateTime.parse(r.date);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _getStatusColor(r.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(DateFormat('EEE').format(date).substring(0, 2),
                      style: TextStyle(color: _getStatusColor(r.status), fontSize: 11, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(DateFormat('MMMM dd').format(date),
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                  if (r.hoursWorked != null)
                    Text('${r.hoursWorked!.toStringAsFixed(1)}h',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.secondary, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return AppTheme.success;
      case 'absent': return AppTheme.error;
      case 'half-day': return AppTheme.warning;
      default: return AppTheme.secondary;
    }
  }
}
