import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/student_profile.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  StudentProfile? _profile;

  final _nameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _supervisorCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  String _startDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _studentIdCtrl.dispose(); _schoolCtrl.dispose();
    _courseCtrl.dispose(); _companyCtrl.dispose(); _supervisorCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final p = await _db.getProfile();
    setState(() {
      _profile = p;
      if (p != null) {
        _nameCtrl.text = p.fullName;
        _studentIdCtrl.text = p.studentId;
        _schoolCtrl.text = p.school;
        _courseCtrl.text = p.course;
        _companyCtrl.text = p.company;
        _supervisorCtrl.text = p.supervisor;
        _hoursCtrl.text = p.requiredHours.toString();
        _startDate = p.startDate;
      } else {
        _editing = true;
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = StudentProfile(
      id: _profile?.id,
      fullName: _nameCtrl.text.trim(),
      studentId: _studentIdCtrl.text.trim(),
      school: _schoolCtrl.text.trim(),
      course: _courseCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      supervisor: _supervisorCtrl.text.trim(),
      requiredHours: int.tryParse(_hoursCtrl.text) ?? 500,
      startDate: _startDate,
    );
    if (_profile == null) {
      await _db.insertProfile(profile);
    } else {
      await _db.updateProfile(profile);
    }
    await _loadProfile();
    setState(() => _editing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile saved!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_startDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.secondary, surface: AppTheme.cardBg),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _startDate = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_editing && _profile != null)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.secondary),
              label: const Text('Edit', style: TextStyle(color: AppTheme.secondary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _editing ? _buildForm() : _buildView(),
      ),
    );
  }

  Widget _buildView() {
    if (_profile == null) return const SizedBox();
    return Column(
      children: [
        // Avatar
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.secondary, Color(0xFF0098C7)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              _profile!.fullName.isNotEmpty ? _profile!.fullName[0].toUpperCase() : '?',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ).animate().scale(duration: 400.ms),
        const SizedBox(height: 12),
        Text(_profile!.fullName,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 100.ms),
        Text(_profile!.studentId,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 24),

        _buildInfoCard('Academic Information', [
          _buildInfoRow(Icons.school_outlined, 'School', _profile!.school),
          _buildInfoRow(Icons.book_outlined, 'Course', _profile!.course),
        ]).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        _buildInfoCard('OJT Details', [
          _buildInfoRow(Icons.business_outlined, 'Company', _profile!.company),
          _buildInfoRow(Icons.person_outlined, 'Supervisor', _profile!.supervisor),
          _buildInfoRow(Icons.timer_outlined, 'Required Hours', '${_profile!.requiredHours}h'),
          _buildInfoRow(Icons.calendar_today_outlined, 'Start Date',
            DateFormat('MMMM dd, yyyy').format(DateTime.parse(_profile!.startDate))),
        ]).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(
            color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionLabel('Personal Info'),
          _buildField(_nameCtrl, 'Full Name', Icons.person_outline, required: true),
          _buildField(_studentIdCtrl, 'Student ID', Icons.badge_outlined, required: true),

          _buildSectionLabel('Academic Info'),
          _buildField(_schoolCtrl, 'School / University', Icons.school_outlined, required: true),
          _buildField(_courseCtrl, 'Course / Program', Icons.book_outlined, required: true),

          _buildSectionLabel('OJT Info'),
          _buildField(_companyCtrl, 'Company / Organization', Icons.business_outlined, required: true),
          _buildField(_supervisorCtrl, 'Supervisor Name', Icons.person_pin_outlined, required: true),
          _buildField(_hoursCtrl, 'Required Hours', Icons.timer_outlined,
            keyboardType: TextInputType.number, required: true),

          // Start Date
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary, size: 18),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OJT Start Date', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text(DateFormat('MMMM dd, yyyy').format(DateTime.parse(_startDate)),
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              if (_profile != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() { _editing = false; _loadProfile(); }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.divider),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(label, style: const TextStyle(
        color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
    {TextInputType? keyboardType, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
        ),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
      ),
    );
  }
}
