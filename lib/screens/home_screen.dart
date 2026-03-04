import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/dtr_record.dart';
import '../models/student_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_record_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();
  StudentProfile? _profile;
  DtrRecord? _todayRecord;
  double _totalHours = 0;
  int _requiredHours = 500;
  List<DtrRecord> _recentRecords = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _db.getProfile();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayRecord = await _db.getRecordByDate(today);
    final total = await _db.getTotalHours();
    final all = await _db.getAllRecords();

    setState(() {
      _profile = profile;
      _todayRecord = todayRecord;
      _totalHours = total;
      _requiredHours = profile?.requiredHours ?? 500;
      _recentRecords = all.take(5).toList();
    });
  }

  Future<void> _handleTimeAction() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = DateFormat('HH:mm:ss').format(now);

    if (_todayRecord == null) {
      // Clock In
      final record = DtrRecord(date: today, timeIn: timeStr, status: 'present');
      final id = await _db.insertRecord(record);
      setState(() => _todayRecord = record.copyWith(id: id));
    } else if (_todayRecord!.isClockedIn) {
      // Clock Out
      final inTime = DateFormat('HH:mm:ss').parse(_todayRecord!.timeIn!);
      final outTime = DateFormat('HH:mm:ss').parse(timeStr);
      final diff = outTime.difference(inTime);
      final hours = diff.inMinutes / 60.0;

      final updated = _todayRecord!.copyWith(timeOut: timeStr, hoursWorked: hours);
      await _db.updateRecord(updated);
      setState(() => _todayRecord = updated);
    }

    await _loadData();
    setState(() => _loading = false);
  }

  String _formatHours(double h) {
    final hrs = h.floor();
    final mins = ((h - hrs) * 60).round();
    return '${hrs}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : now.hour < 17 ? 'Good afternoon' : 'Good evening';
    final progress = _requiredHours > 0 ? (_totalHours / _requiredHours).clamp(0.0, 1.0) : 0.0;
    final remaining = (_requiredHours - _totalHours).clamp(0.0, double.infinity);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.secondary,
        backgroundColor: AppTheme.cardBg,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D1F3C), Color(0xFF0A1628)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$greeting,',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _profile?.fullName.split(' ').first ?? 'Student',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                                ),
                                child: Text(
                                  DateFormat('MMM dd, yyyy').format(now),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.secondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time In/Out Card
                    _buildClockCard().animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 20),

                    // Progress Card
                    _buildProgressCard(progress, remaining).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2),
                    const SizedBox(height: 20),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Total Hours',
                            value: _formatHours(_totalHours),
                            icon: Icons.timer_outlined,
                            color: AppTheme.secondary,
                          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Days Logged',
                            value: '${_recentRecords.length}',
                            icon: Icons.calendar_today_outlined,
                            color: AppTheme.accent,
                          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Records
                    if (_recentRecords.isNotEmpty) ...[
                      Text(
                        'Recent Records',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                      const SizedBox(height: 12),
                      ..._recentRecords.asMap().entries.map((e) =>
                        RecentRecordTile(record: e.value)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: (400 + (e.key * 80)).ms)
                          .slideX(begin: 0.1),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockCard() {
    final isClockedIn = _todayRecord?.isClockedIn ?? false;
    final isComplete = _todayRecord?.isComplete ?? false;
    final now = DateTime.now();

    Color statusColor = AppTheme.textSecondary;
    String statusText = 'Not clocked in today';
    IconData statusIcon = Icons.radio_button_unchecked;

    if (isClockedIn) {
      statusColor = AppTheme.success;
      statusText = 'Currently working';
      statusIcon = Icons.radio_button_checked;
    } else if (isComplete) {
      statusColor = AppTheme.secondary;
      statusText = 'Shift completed';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isClockedIn
              ? [const Color(0xFF0D2E1F), const Color(0xFF111E33)]
              : [AppTheme.cardBg, AppTheme.cardBg2],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isClockedIn ? AppTheme.success.withOpacity(0.3) : AppTheme.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(statusText, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                DateFormat('EEEE').format(now),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimeBlock('TIME IN', _todayRecord?.timeIn, AppTheme.success),
              const SizedBox(width: 12),
              Container(width: 1, height: 40, color: AppTheme.divider),
              const SizedBox(width: 12),
              _buildTimeBlock('TIME OUT', _todayRecord?.timeOut, AppTheme.accent),
              const Spacer(),
              if (!isComplete)
                GestureDetector(
                  onTap: _loading ? null : _handleTimeAction,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isClockedIn ? AppTheme.accent : AppTheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isClockedIn ? AppTheme.accent : AppTheme.secondary).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isClockedIn ? Icons.logout : Icons.login,
                                color: AppTheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isClockedIn ? 'OUT' : 'IN',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlock(String label, String? time, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          time != null
              ? DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(time))
              : '--:--',
          style: GoogleFonts.plusJakartaSans(
            color: time != null ? color : AppTheme.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(double progress, double remaining) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OJT Progress',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppTheme.success : AppTheme.secondary,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat('Completed', '${_totalHours.toStringAsFixed(1)}h'),
              _buildProgressStat('Required', '${_requiredHours}h'),
              _buildProgressStat('Remaining', '${remaining.toStringAsFixed(1)}h'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(
          color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700,
        )),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}
