import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/dtr_record.dart';
import '../theme/app_theme.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _db = DatabaseHelper();
  List<DtrRecord> _records = [];
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _db.getRecordsByMonth(_selectedMonth.year, _selectedMonth.month);
    setState(() => _records = records);
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadRecords();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) return;
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadRecords();
  }

  Future<void> _showAddRecordSheet() async {
    String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    TimeOfDay? timeIn;
    TimeOfDay? timeOut;
    String status = 'present';
    final remarksCtrl = TextEditingController();

    String formatTOD(TimeOfDay? t) {
      if (t == null) return '--:--';
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return DateFormat('hh:mm a').format(DateFormat('HH:mm').parse('$h:$m'));
    }

    String todTo24(TimeOfDay t) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m:00';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A2332),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_circle_outline, color: AppTheme.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Add Past Record',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 20),

                // Date Picker Row
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.parse(selectedDate),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (c, child) => Theme(
                        data: Theme.of(c).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.secondary, surface: Color(0xFF1A2332)),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setSheet(() => selectedDate = DateFormat('yyyy-MM-dd').format(picked));
                  },
                  child: _sheetTile(
                    Icons.calendar_today_outlined, 'Date',
                    DateFormat('MMMM dd, yyyy').format(DateTime.parse(selectedDate)),
                    AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 10),

                // Time In / Time Out Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: timeIn ?? const TimeOfDay(hour: 8, minute: 0),
                            builder: (c, child) => Theme(
                              data: Theme.of(c).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.success, surface: Color(0xFF1A2332)),
                              ),
                              child: child!,
                            ),
                          );
                          if (t != null) setSheet(() => timeIn = t);
                        },
                        child: _sheetTile(Icons.login, 'Time In', formatTOD(timeIn), AppTheme.success),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: timeOut ?? const TimeOfDay(hour: 17, minute: 0),
                            builder: (c, child) => Theme(
                              data: Theme.of(c).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.accent, surface: Color(0xFF1A2332)),
                              ),
                              child: child!,
                            ),
                          );
                          if (t != null) setSheet(() => timeOut = t);
                        },
                        child: _sheetTile(Icons.logout, 'Time Out', formatTOD(timeOut), AppTheme.accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Status Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: status,
                      dropdownColor: AppTheme.cardBg2,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      items: [
                        _statusItem('present', '✅  Present', AppTheme.success),
                        _statusItem('absent', '❌  Absent', AppTheme.error),
                        _statusItem('half-day', '🕐  Half-Day', AppTheme.warning),
                        _statusItem('leave', '📋  Leave', AppTheme.secondary),
                      ],
                      onChanged: (v) { if (v != null) setSheet(() => status = v); },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Remarks
                TextField(
                  controller: remarksCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Remarks (optional)',
                    prefixIcon: const Icon(Icons.notes_outlined, size: 18, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.cardBg,
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                ElevatedButton.icon(
                  onPressed: () async {
                    double? hours;
                    String? timeInStr;
                    String? timeOutStr;
                    if (timeIn != null) timeInStr = todTo24(timeIn!);
                    if (timeOut != null) {
                      timeOutStr = todTo24(timeOut!);
                      if (timeIn != null) {
                        final inMin = timeIn!.hour * 60 + timeIn!.minute;
                        final outMin = timeOut!.hour * 60 + timeOut!.minute;
                        hours = (outMin - inMin) / 60.0;
                        if (hours < 0) hours += 24; // overnight shift
                      }
                    }
                    final record = DtrRecord(
                      date: selectedDate,
                      timeIn: timeInStr,
                      timeOut: timeOutStr,
                      hoursWorked: hours,
                      status: status,
                      remarks: remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim(),
                    );
                    await _db.insertRecord(record);
                    await _loadRecords();
                    remarksCtrl.dispose();
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Record added for ${DateFormat('MMM dd, yyyy').format(DateTime.parse(selectedDate))}'),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ));
                    }
                  },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Record'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Icon(Icons.chevron_right, size: 16, color: color.withOpacity(0.6)),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _statusItem(String value, String label, Color color) {
    return DropdownMenuItem(value: value, child: Text(label, style: TextStyle(color: color)));
  }

  Future<void> _showEditDialog(DtrRecord record) async {
    final remarksCtrl = TextEditingController(text: record.remarks ?? '');
    String? newStatus = record.status;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Record', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.parse(record.date))}',
              style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: newStatus,
              dropdownColor: AppTheme.cardBg2,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Status'),
              items: ['present', 'absent', 'half-day', 'leave'].map((s) =>
                DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
              onChanged: (v) => newStatus = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Remarks'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = record.copyWith(status: newStatus, remarks: remarksCtrl.text);
              await _db.updateRecord(updated);
              await _loadRecords();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(DtrRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Record?', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('This will permanently delete the record for ${DateFormat('MMMM dd, yyyy').format(DateTime.parse(record.date))}.',
          style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteRecord(record.id!);
      await _loadRecords();
    }
  }

  double get _monthTotalHours =>
    _records.fold(0, (sum, r) => sum + (r.hoursWorked ?? 0));

  int get _presentDays =>
    _records.where((r) => r.status == 'present').map((r) => r.date).toSet().length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRecordSheet,
        backgroundColor: AppTheme.secondary,
        foregroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: Text('Add Record', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
      appBar: AppBar(
        title: const Text('DTR Records'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_monthTotalHours.toStringAsFixed(1)}h this month',
                style: const TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
                ),
                Column(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$_presentDays days present',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(Icons.chevron_right,
                    color: (_selectedMonth.year == DateTime.now().year && _selectedMonth.month == DateTime.now().month)
                        ? AppTheme.divider : AppTheme.textPrimary),
                ),
              ],
            ),
          ),

          Expanded(
            child: _records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text('No records for this month',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (ctx, i) {
                      final r = _records[i];
                      return _buildRecordCard(r, i)
                        .animate()
                        .fadeIn(duration: 300.ms, delay: (i * 50).ms)
                        .slideX(begin: 0.05);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(DtrRecord record, int index) {
    final date = DateTime.parse(record.date);
    final statusColor = _getStatusColor(record.status);
    final timeIn = record.timeIn != null
        ? DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(record.timeIn!))
        : '--:--';
    final timeOut = record.timeOut != null
        ? DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(record.timeOut!))
        : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showEditDialog(record),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd').format(date),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      DateFormat('EEE').format(date).toUpperCase(),
                      style: TextStyle(color: statusColor.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTimePill(Icons.login, timeIn, AppTheme.success),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        _buildTimePill(Icons.logout, timeOut, AppTheme.accent),
                      ],
                    ),
                    if (record.remarks != null && record.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(record.remarks!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (record.hoursWorked != null)
                    Text(
                      '${record.hoursWorked!.toStringAsFixed(1)}h',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      record.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 18),
                onPressed: () => _confirmDelete(record),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePill(IconData icon, String time, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(time, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return AppTheme.success;
      case 'absent': return AppTheme.error;
      case 'half-day': return AppTheme.warning;
      case 'leave': return AppTheme.secondary;
      default: return AppTheme.textSecondary;
    }
  }
}
