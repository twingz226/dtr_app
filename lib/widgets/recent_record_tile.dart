import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/dtr_record.dart';
import '../theme/app_theme.dart';

class RecentRecordTile extends StatelessWidget {
  final DtrRecord record;
  const RecentRecordTile({super.key, required this.record});

  Color get _statusColor {
    switch (record.status) {
      case 'present': return AppTheme.success;
      case 'absent': return AppTheme.error;
      case 'half-day': return AppTheme.warning;
      default: return AppTheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(record.date);
    final timeIn = record.timeIn != null
        ? DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(record.timeIn!)) : '--';
    final timeOut = record.timeOut != null
        ? DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(record.timeOut!)) : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 40,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE, MMM dd').format(date),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('$timeIn → $timeOut',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (record.hoursWorked != null)
                Text('${record.hoursWorked!.toStringAsFixed(1)}h',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(record.status.toUpperCase(),
                  style: TextStyle(color: _statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
