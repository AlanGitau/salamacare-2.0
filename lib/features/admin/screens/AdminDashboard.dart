import 'package:flutter/material.dart';

import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/admin_service.dart';
import 'package:signup/features/admin/services/verification_service.dart';
import 'package:signup/features/admin/screens/AnalyticsDashboardView.dart';
import 'package:signup/features/admin/screens/NoShowAnalyticsView.dart';
import 'package:signup/features/admin/screens/DoctorVerificationView.dart';
import 'package:signup/features/admin/screens/SystemSettingsView.dart';
import 'package:signup/features/admin/screens/ReportsView.dart';
import 'package:signup/features/admin/screens/PatientListView.dart';
import 'package:signup/features/admin/screens/DoctorListView.dart';
import 'package:signup/features/admin/screens/AppointmentBoardView.dart';
import 'package:signup/features/admin/screens/AppointmentConfigView.dart';
import 'package:signup/features/admin/screens/UserManagementView.dart';
import 'package:signup/features/admin/screens/ScheduleManagementView.dart';
import 'package:signup/features/admin/screens/WaitlistManagementView.dart';
import 'package:signup/features/authentication/services/supabase_auth_service.dart';
import 'package:signup/features/authentication/screens/loginScreen.dart';
import 'package:intl/intl.dart';

// ─── Nav entry model ──────────────────────────────────────────────────────────

class _NavEntry {
  final IconData icon;
  final String label;
  final int index;
  final bool hasBadge;

  const _NavEntry({
    required this.icon,
    required this.label,
    required this.index,
    this.hasBadge = false,
  });
}

const _menuItems = [
  _NavEntry(icon: Icons.grid_view_rounded, label: 'Dashboard', index: 0),
  _NavEntry(icon: Icons.view_timeline_outlined, label: 'Appointment Board', index: 1),
  _NavEntry(icon: Icons.bar_chart_rounded, label: 'Analytics', index: 2),
  _NavEntry(icon: Icons.person_off_outlined, label: 'No-Show Analytics', index: 3),
];

const _adminItems = [
  _NavEntry(icon: Icons.verified_user_outlined, label: 'Verification', index: 4, hasBadge: true),
  _NavEntry(icon: Icons.manage_accounts_outlined, label: 'Users', index: 5),
  _NavEntry(icon: Icons.local_hospital_outlined, label: 'Doctors', index: 6),
  _NavEntry(icon: Icons.person_outline, label: 'Patients', index: 7),
  _NavEntry(icon: Icons.calendar_month_outlined, label: 'Appointments', index: 8),
  _NavEntry(icon: Icons.category_outlined, label: 'Specialties', index: 9),
  _NavEntry(icon: Icons.schedule_outlined, label: 'Schedule', index: 10),
  _NavEntry(icon: Icons.hourglass_top_outlined, label: 'Waitlist', index: 11),
  _NavEntry(icon: Icons.assessment_outlined, label: 'Reports', index: 12),
  _NavEntry(icon: Icons.settings_outlined, label: 'Settings', index: 13),
];

const _pageTitles = [
  'Dashboard',
  'Appointment Board',
  'Analytics',
  'No-Show Analytics',
  'Doctor Verification',
  'User Management',
  'Doctors',
  'Patients',
  'Appointments',
  'Specialties',
  'Schedule Management',
  'Waitlist',
  'Reports',
  'System Settings',
];

// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _adminService = AdminService();
  final _authService = SupabaseAuthService();
  final _verificationService = VerificationService();

  int _selectedIndex = 0;
  int _hoveredNavIndex = -1;
  bool _isLoading = true;
  int _pendingVerificationCount = 0;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _adminService.getDashboardStats(),
        _adminService.getRecentActivity(),
        _verificationService.getPendingCount(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _recentActivity = results[1] as List<Map<String, dynamic>>;
          _pendingVerificationCount = results[2] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: adminDanger),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: adminBgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminBorderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confirm sign out',
                  style: TextStyle(fontFamily: 'DM Sans', 
                      fontSize: 16, fontWeight: FontWeight.w600, color: adminTextHeading)),
              const SizedBox(height: 8),
              Text('Are you sure you want to sign out of the admin panel?',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextBody)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  adminSecondaryButton(label: 'Cancel', onTap: () => Navigator.pop(ctx, false)),
                  const SizedBox(width: 12),
                  adminDangerButton(label: 'Sign out', onTap: () => Navigator.pop(ctx, true)),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Loginscreen()),
        );
      }
    }
  }

  // ─── Root layout ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminBgCanvas,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar ─────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: adminBgSurface,
        border: Border(right: BorderSide(color: adminBorderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo row — same height as topbar so they align
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: adminBorderLight)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: adminAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  'SalamaCare',
                  style: TextStyle(fontFamily: 'DM Sans', 
                      fontSize: 16, fontWeight: FontWeight.w700, color: adminTextHeading),
                ),
              ],
            ),
          ),

          // Scrollable nav
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('MENU'),
                  const SizedBox(height: 4),
                  for (final e in _menuItems) _buildNavItem(e),
                  const SizedBox(height: 20),
                  _sectionLabel('ADMIN'),
                  const SizedBox(height: 4),
                  for (final e in _adminItems) _buildNavItem(e),
                ],
              ),
            ),
          ),

          // Logout pinned at bottom
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: adminBorderLight)),
            ),
            padding: const EdgeInsets.all(8),
            child: _buildLogoutItem(),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'DM Sans', 
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: adminTextMuted,
            letterSpacing: 0.9),
      ),
    );
  }

  Widget _buildNavItem(_NavEntry entry) {
    final isSelected = _selectedIndex == entry.index;
    final isHovered = _hoveredNavIndex == entry.index;
    final showBadge = entry.hasBadge && _pendingVerificationCount > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredNavIndex = entry.index),
      onExit: (_) => setState(() => _hoveredNavIndex = -1),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = entry.index),
        child: Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? adminSidebarActiveBg
                : (isHovered ? adminBgSubtle : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                entry.icon,
                size: 18,
                color: isSelected ? adminSidebarActive : adminTextBody,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.label,
                  style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? adminSidebarActive : adminSidebarLabel,
                  ),
                ),
              ),
              if (showBadge)
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: adminAccent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _pendingVerificationCount > 99
                        ? '99+'
                        : '$_pendingVerificationCount',
                    style: TextStyle(fontFamily: 'DM Sans', 
                        fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem() {
    final isHovered = _hoveredNavIndex == -99;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredNavIndex = -99),
      onExit: (_) => setState(() => _hoveredNavIndex = -1),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleLogout,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isHovered ? adminDangerTint : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_outlined,
                size: 18,
                color: isHovered ? adminDanger : adminTextBody,
              ),
              const SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(fontFamily: 'DM Sans', 
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isHovered ? adminDanger : adminSidebarLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final title = _selectedIndex < _pageTitles.length
        ? _pageTitles[_selectedIndex]
        : 'Dashboard';
    final dateStr = DateFormat('EEE, MMM d').format(DateTime.now());

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: adminBgSurface,
        border: Border(bottom: BorderSide(color: adminBorderLight)),
      ),
      child: Row(
        children: [
          // Breadcrumb
          Text(
            title,
            style: TextStyle(fontFamily: 'DM Sans', 
                fontSize: 14, fontWeight: FontWeight.w600, color: adminTextHeading),
          ),

          const Spacer(),

          // Search bar
          Container(
            width: 340,
            height: 34,
            decoration: BoxDecoration(
              color: adminBgSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: adminBorderLight),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.search, size: 16, color: adminTextMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextHeading),
                    decoration: InputDecoration(
                      hintText: 'Search patients, doctors...',
                      hintStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),

          const Spacer(),

          // Date
          Text(
            dateStr,
            style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 12, color: adminTextMuted),
          ),
          const SizedBox(width: 16),

          // Notification bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: adminBgSubtle,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: adminBorderLight),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.notifications_outlined, size: 18, color: adminTextBody),
              ),
              if (_pendingVerificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: adminDanger, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Admin avatar chip
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: adminBgSubtle,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: adminBorderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: adminAccentTint,
                  child: Text(
                    'A',
                    style: TextStyle(fontFamily: 'DM Sans', 
                        fontSize: 11, fontWeight: FontWeight.w600, color: adminAccent),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Admin',
                  style: TextStyle(fontFamily: 'DM Sans', 
                      fontSize: 13, fontWeight: FontWeight.w500, color: adminTextHeading),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: adminTextMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Content router ───────────────────────────────────────────────────────

  Widget _buildContent() {
    if (_isLoading && _selectedIndex == 0) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: adminAccent,
        ),
      );
    }
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView();
      case 1:
        return const AppointmentBoardView();
      case 2:
        return const AnalyticsDashboardView();
      case 3:
        return const NoShowAnalyticsView();
      case 4:
        return const DoctorVerificationView();
      case 5:
        return const UserManagementView();
      case 6:
        return const DoctorListView();
      case 7:
        return const PatientListView();
      case 8:
        return const AppointmentConfigView();
      case 9:
        return _SpecialtiesManagementView();
      case 10:
        return const ScheduleManagementView();
      case 11:
        return const WaitlistManagementView();
      case 12:
        return const ReportsView();
      case 13:
        return const SystemSettingsView();
      default:
        return _buildDashboardView();
    }
  }

  // ─── Dashboard view ───────────────────────────────────────────────────────

  Widget _buildDashboardView() {
    return Container(
      color: adminBgCanvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: adminPageTitle()),
                    const SizedBox(height: 2),
                    Text("Here's what's happening today", style: adminBodyText()),
                  ],
                ),
                const Spacer(),
                adminSecondaryButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  onTap: _loadDashboardData,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KPI row — 4 flat bordered cards
            Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    icon: Icons.people_outline,
                    value: '${_stats['total_patients'] ?? 0}',
                    label: 'Total Patients',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _kpiCard(
                    icon: Icons.local_hospital_outlined,
                    value: '${_stats['total_doctors'] ?? 0}',
                    label: 'Total Doctors',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _kpiCard(
                    icon: Icons.calendar_month_outlined,
                    value: '${_stats['total_appointments'] ?? 0}',
                    label: 'All Appointments',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _kpiCard(
                    icon: Icons.today_outlined,
                    value: '${_stats['today_appointments'] ?? 0}',
                    label: "Today's Appointments",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent appointments table
            _recentAppointmentsTable(),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
        // NO boxShadow — the bgCanvas provides enough contrast
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: adminAccent),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: adminKpiNumber()),
          const SizedBox(height: 4),
          Text(label, style: adminBodyText()),
        ],
      ),
    );
  }

  Widget _recentAppointmentsTable() {
    return Container(
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                Text('Recent Appointments', style: adminSectionHeading()),
                const Spacer(),
                Text('${_recentActivity.length} records', style: adminMetadata()),
              ],
            ),
          ),

          // Column headers
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: adminBgSubtle,
              border: Border.symmetric(
                horizontal: BorderSide(color: adminBorderLight),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: _th('PATIENT')),
                Expanded(flex: 3, child: _th('DOCTOR')),
                Expanded(flex: 2, child: _th('STATUS')),
                SizedBox(
                  width: 170,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _th('DATE & TIME'),
                  ),
                ),
              ],
            ),
          ),

          // Data rows
          if (_recentActivity.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('No recent activity', style: adminBodyText()),
              ),
            )
          else
            for (int i = 0; i < _recentActivity.length; i++)
              _appointmentRow(
                _recentActivity[i],
                isLast: i == _recentActivity.length - 1,
              ),
        ],
      ),
    );
  }

  Widget _th(String text) {
    return Text(text, style: adminTableHeader());
  }

  Widget _appointmentRow(Map<String, dynamic> activity, {bool isLast = false}) {
    final patient = activity['patients'];
    final doctor = activity['doctors'];
    final status = activity['status'] ?? 'scheduled';
    final appointmentDate = DateTime.parse(activity['appointment_date']);

    final patientName =
        '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}'.trim();
    final doctorName =
        'Dr. ${doctor?['first_name'] ?? ''} ${doctor?['last_name'] ?? ''}'.trim();
    final initial =
        patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P';

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: adminBorderLight))),
      child: Row(
        children: [
          // Patient cell with avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: adminAccentTint,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(fontFamily: 'DM Sans', 
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: adminAccent),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    patientName.isEmpty ? 'Unknown Patient' : patientName,
                    style: TextStyle(fontFamily: 'DM Sans', 
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: adminTextHeading),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Doctor cell
          Expanded(
            flex: 3,
            child: Text(
              doctorName,
              style: adminBodyText(),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status badge
          Expanded(flex: 2, child: adminStatusBadge(status)),

          // Date & time right-aligned
          SizedBox(
            width: 170,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(appointmentDate),
                  style: adminMetadata(),
                ),
                Text(
                  DateFormat('h:mm a').format(appointmentDate),
                  style: adminMetadata(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Specialties Management View ──────────────────────────────────────────────

class _SpecialtiesManagementView extends StatefulWidget {
  @override
  State<_SpecialtiesManagementView> createState() =>
      _SpecialtiesManagementViewState();
}

class _SpecialtiesManagementViewState
    extends State<_SpecialtiesManagementView> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _specialties = [];
  bool _isLoading = true;

  static const _specialtyIcons = <String, IconData>{
    'general practice': Icons.medical_services_outlined,
    'cardiology': Icons.favorite_outline,
    'pediatrics': Icons.child_care_outlined,
    'orthopedics': Icons.accessibility_outlined,
    'dermatology': Icons.face_retouching_natural_outlined,
    'neurology': Icons.psychology_outlined,
    'gynecology': Icons.pregnant_woman_outlined,
  };

  IconData _iconFor(String name) =>
      _specialtyIcons[name.toLowerCase()] ?? Icons.local_hospital_outlined;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    setState(() => _isLoading = true);
    try {
      final specialties = await _adminService.getAllSpecialties();
      if (mounted) {
        setState(() {
          _specialties = specialties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: adminBgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminBorderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Add Specialty',
                      style: TextStyle(fontFamily: 'DM Sans', 
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: adminTextHeading)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close, size: 20, color: adminTextMuted),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _fieldLabel('Name'),
              const SizedBox(height: 6),
              _inputField(controller: nameCtrl, hint: 'e.g. Orthopedics'),
              const SizedBox(height: 16),
              _fieldLabel('Description'),
              const SizedBox(height: 6),
              _inputField(
                  controller: descCtrl,
                  hint: 'Brief description (optional)',
                  maxLines: 3),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  adminSecondaryButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(ctx, false)),
                  const SizedBox(width: 12),
                  adminPrimaryButton(
                    label: 'Add Specialty',
                    onTap: () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Please enter a name'),
                            backgroundColor: adminDanger));
                        return;
                      }
                      final res = await _adminService.addSpecialty(
                        nameCtrl.text.trim(),
                        descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx, res['success']);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(res['message']),
                            backgroundColor:
                                res['success'] ? adminSuccess : adminDanger));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) _loadSpecialties();
  }

  Future<void> _deleteSpecialty(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: adminBgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminBorderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete Specialty',
                  style: TextStyle(fontFamily: 'DM Sans', 
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: adminTextHeading)),
              const SizedBox(height: 8),
              Text(
                  'Delete "$name"? This cannot be undone and will affect doctors assigned to this specialty.',
                  style: adminBodyText()),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  adminSecondaryButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(ctx, false)),
                  const SizedBox(width: 12),
                  adminDangerButton(
                      label: 'Delete',
                      onTap: () => Navigator.pop(ctx, true)),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final result = await _adminService.deleteSpecialty(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['message']),
            backgroundColor:
                result['success'] ? adminSuccess : adminDanger));
        if (result['success']) _loadSpecialties();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: adminBgCanvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Specialties', style: adminPageTitle()),
                    const SizedBox(height: 2),
                    Text('Manage medical specialties available in the clinic',
                        style: adminBodyText()),
                  ],
                ),
                const Spacer(),
                adminPrimaryButton(
                  label: 'Add Specialty',
                  icon: Icons.add,
                  onTap: _showAddDialog,
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: adminAccent))
                : _specialties.isEmpty
                    ? Center(
                        child: Text('No specialties found',
                            style: adminBodyText()))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.8,
                        ),
                        itemCount: _specialties.length,
                        itemBuilder: (_, i) =>
                            _specialtyCard(_specialties[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _specialtyCard(Map<String, dynamic> specialty) {
    final name = specialty['name'] ?? 'Unknown';
    final description = specialty['description'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_iconFor(name), size: 20, color: adminAccent),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _deleteSpecialty(specialty['id'], name),
                  child: Icon(Icons.delete_outline,
                      size: 18, color: adminTextMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(name,
              style: TextStyle(fontFamily: 'DM Sans', 
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: adminTextHeading)),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(description,
                style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 12, color: adminTextBody),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // Form helpers
  Widget _fieldLabel(String text) => Text(text,
      style: TextStyle(fontFamily: 'DM Sans', 
          fontSize: 12, fontWeight: FontWeight.w600, color: adminTextBody));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextHeading),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextMuted),
        filled: true,
        fillColor: adminBgSubtle,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: adminBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: adminBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: adminAccent),
        ),
      ),
    );
  }
}
