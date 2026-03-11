import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/appointment_board_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentBoardView extends StatefulWidget {
  const AppointmentBoardView({super.key});

  @override
  State<AppointmentBoardView> createState() => _AppointmentBoardViewState();
}

class _AppointmentBoardViewState extends State<AppointmentBoardView> {
  final _service = AppointmentBoardService();

  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _appointments = [];
  Map<String, dynamic> _stats = {};
  String _searchQuery = '';
  String? _statusFilter;
  String? _doctorFilter;
  Timer? _refreshTimer;
  RealtimeChannel? _realtimeChannel;

  final List<String> _statusOptions = [
    'scheduled', 'confirmed', 'checked_in',
    'in_progress', 'completed', 'cancelled', 'no_show',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
    _setupRealtime();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  void _setupRealtime() {
    _realtimeChannel = Supabase.instance.client
        .channel('admin_appointment_board')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          callback: (_) { if (mounted) _loadData(silent: true); },
        )
        .subscribe();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getAppointmentsByDate(_selectedDate),
        _service.getTodayStats(),
      ]);
      if (mounted) {
        setState(() {
          _appointments = results[0] as List<Map<String, dynamic>>;
          _stats = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading appointments: $e'),
          backgroundColor: adminDanger,
        ));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    var filtered = _appointments;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        final patient = a['patients'];
        if (patient == null) return false;
        final name = '${patient['first_name']} ${patient['last_name']}'.toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((a) => a['status'] == _statusFilter).toList();
    }
    if (_doctorFilter != null && _doctorFilter!.isNotEmpty) {
      filtered = filtered.where((a) {
        final doctor = a['doctors'];
        return doctor != null && doctor['id'] == _doctorFilter;
      }).toList();
    }
    return filtered;
  }

  Map<String, List<Map<String, dynamic>>> get _appointmentsByDoctor {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var a in _filteredAppointments) {
      final doctor = a['doctors'];
      if (doctor == null) continue;
      final doctorId = doctor['id'] as String;
      grouped.putIfAbsent(doctorId, () => []).add(a);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: adminBgCanvas,
      child: Column(
        children: [
          _buildPageHeader(),
          _buildFiltersBar(),
          _buildKpiRow(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent))
                : _filteredAppointments.isEmpty
                    ? _buildEmptyState()
                    : _buildBoard(),
          ),
        ],
      ),
    );
  }

  // ─── Page header ──────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final dateStr = isToday
        ? "Today's Schedule"
        : DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate);

    return Container(
      color: adminBgCanvas,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appointment Board', style: adminPageTitle()),
              const SizedBox(height: 2),
              Text(dateStr, style: adminBodyText()),
            ],
          ),
          const Spacer(),

          // Date navigator
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: adminBgSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: adminBorderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dateNavBtn(Icons.chevron_left, () {
                  setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                  _loadData();
                }),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(primary: adminAccent),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      _loadData();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      DateFormat('MMM dd').format(_selectedDate),
                      style: TextStyle(fontFamily: 'IBM Plex Mono', 
                          fontSize: 12, fontWeight: FontWeight.w500, color: adminTextHeading),
                    ),
                  ),
                ),
                _dateNavBtn(Icons.chevron_right, () {
                  setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                  _loadData();
                }),
              ],
            ),
          ),
          const SizedBox(width: 12),

          if (!isToday)
            adminSecondaryButton(
              label: 'Today',
              onTap: () {
                setState(() => _selectedDate = DateTime.now());
                _loadData();
              },
            ),
          if (!isToday) const SizedBox(width: 12),

          adminSecondaryButton(
            label: 'Refresh',
            icon: Icons.refresh,
            onTap: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _dateNavBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: adminTextBody),
      ),
    );
  }

  // ─── KPI stat row ─────────────────────────────────────────────────────────

  Widget _buildKpiRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Expanded(child: _miniKpi('Total', '${_stats['total'] ?? 0}', Icons.calendar_today_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _miniKpi('Completed', '${_stats['completed'] ?? 0}', Icons.check_circle_outline)),
          const SizedBox(width: 12),
          Expanded(child: _miniKpi('In Progress', '${_stats['in_progress'] ?? 0}', Icons.play_circle_outline)),
          const SizedBox(width: 12),
          Expanded(child: _miniKpi('Checked In', '${_stats['checked_in'] ?? 0}', Icons.login_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _miniKpi('No Show', '${_stats['no_show'] ?? 0}', Icons.person_off_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _miniKpi('Revenue', 'KES ${(_stats['estimated_revenue'] ?? 0).toStringAsFixed(0)}', Icons.attach_money_outlined)),
        ],
      ),
    );
  }

  Widget _miniKpi(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: adminAccent),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontFamily: 'IBM Plex Mono', 
              fontSize: 20, fontWeight: FontWeight.w600, color: adminTextHeading)),
          const SizedBox(height: 2),
          Text(label, style: adminBodyText()),
        ],
      ),
    );
  }

  // ─── Filters bar ──────────────────────────────────────────────────────────

  Widget _buildFiltersBar() {
    final Set<Map<String, String>> doctors = {};
    for (var a in _appointments) {
      final doctor = a['doctors'];
      if (doctor != null) {
        doctors.add({
          'id': doctor['id'],
          'name': 'Dr. ${doctor['first_name']} ${doctor['last_name']}',
        });
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 240,
            height: 34,
            child: Container(
              decoration: BoxDecoration(
                color: adminBgSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: adminBorderLight),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search, size: 15, color: adminTextMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextHeading),
                      decoration: InputDecoration(
                        hintText: 'Search patients...',
                        hintStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status filter
          _filterDropdown<String?>(
            value: _statusFilter,
            hint: 'All Statuses',
            items: [
              const DropdownMenuItem(value: null, child: Text('All Statuses')),
              ..._statusOptions.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(_capitalize(s)),
                  )),
            ],
            onChanged: (v) => setState(() => _statusFilter = v),
          ),
          const SizedBox(width: 12),

          // Doctor filter
          _filterDropdown<String?>(
            value: _doctorFilter,
            hint: 'All Doctors',
            items: [
              const DropdownMenuItem(value: null, child: Text('All Doctors')),
              ...doctors.map((d) => DropdownMenuItem(
                    value: d['id'],
                    child: Text(d['name']!),
                  )),
            ],
            onChanged: (v) => setState(() => _doctorFilter = v),
          ),
          const Spacer(),
          Text('${_filteredAppointments.length} appointments', style: adminBodyText()),
        ],
      ),
    );
  }

  Widget _filterDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: adminBorderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: adminTextHeading),
          icon: Icon(Icons.keyboard_arrow_down, size: 16, color: adminTextMuted),
        ),
      ),
    );
  }

  // ─── Board ────────────────────────────────────────────────────────────────

  Widget _buildBoard() {
    final grouped = _appointmentsByDoctor;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: grouped.length,
      itemBuilder: (_, i) {
        final doctorId = grouped.keys.elementAt(i);
        final appts = grouped[doctorId]!;
        return _buildDoctorSection(appts.first['doctors'], appts);
      },
    );
  }

  Widget _buildDoctorSection(
      Map<String, dynamic> doctor, List<Map<String, dynamic>> appointments) {
    final doctorName = 'Dr. ${doctor['first_name']} ${doctor['last_name']}';
    final completedCount = appointments.where((a) => a['status'] == 'completed').length;
    final initial = doctor['first_name']?[0]?.toUpperCase() ?? 'D';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: adminBgSubtle,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: adminBorderLight)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: adminAccentTint,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(fontFamily: 'DM Sans', 
                        fontSize: 14, fontWeight: FontWeight.w600, color: adminAccent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctorName,
                          style: TextStyle(fontFamily: 'DM Sans', 
                              fontSize: 14, fontWeight: FontWeight.w600, color: adminTextHeading)),
                      Text('${appointments.length} appointments',
                          style: adminBodyText()),
                    ],
                  ),
                ),
                // Progress chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: adminAccentTint,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: adminAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$completedCount/${appointments.length} Done',
                    style: TextStyle(fontFamily: 'DM Sans', 
                        fontSize: 12, fontWeight: FontWeight.w500, color: adminAccent),
                  ),
                ),
              ],
            ),
          ),

          // Appointments
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: appointments
                  .map((a) => _buildAppointmentCard(a))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final patient = appointment['patients'];
    final status = appointment['status'] as String;
    final time = DateTime.parse(appointment['appointment_date']);
    final duration = appointment['duration'] ?? 30;
    final patientName = patient != null
        ? '${patient['first_name']} ${patient['last_name']}'
        : 'Unknown';
    final initial = patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: adminBorderLight),
      ),
      child: Row(
        children: [
          // Time chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: adminBgSubtle,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: adminBorderLight),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('h:mm').format(time),
                  style: TextStyle(fontFamily: 'IBM Plex Mono', 
                      fontSize: 13, fontWeight: FontWeight.w600, color: adminTextHeading),
                ),
                Text(
                  DateFormat('a').format(time),
                  style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 10, color: adminTextMuted),
                ),
                Text(
                  '${duration}m',
                  style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 10, color: adminTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Patient avatar + name
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
                  fontSize: 13, fontWeight: FontWeight.w600, color: adminAccent),
            ),
          ),
          const SizedBox(width: 10),

          // Patient info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: TextStyle(fontFamily: 'DM Sans', 
                      fontSize: 13, fontWeight: FontWeight.w500, color: adminTextHeading),
                ),
                if (patient?['phone'] != null)
                  Text(patient['phone'],
                      style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 11, color: adminTextMuted)),
              ],
            ),
          ),

          // Notes badge
          if (appointment['patient_notes'] != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: appointment['patient_notes'],
                child: Icon(Icons.notes_outlined, size: 16, color: adminTextMuted),
              ),
            ),

          // Status badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: adminStatusBadge(status),
          ),

          // Quick actions
          _buildQuickActions(appointment),

          // Details icon
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showPatientDetails(appointment),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: adminBgSubtle,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: adminBorderLight),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.info_outline, size: 15, color: adminTextBody),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Map<String, dynamic> appointment) {
    final status = appointment['status'] as String;
    final id = appointment['id'] as String;
    final actions = <Widget>[];

    if (status == 'scheduled' || status == 'confirmed') {
      actions.add(_actionBtn('Check In', Icons.login_outlined, adminAccent,
          () => _updateStatus(id, 'checked_in')));
    }
    if (status == 'checked_in') {
      actions.add(_actionBtn('Start', Icons.play_arrow_outlined, adminWarning,
          () => _updateStatus(id, 'in_progress')));
    }
    if (status == 'in_progress') {
      actions.add(_actionBtn('Complete', Icons.check_outlined, adminSuccess,
          () => _updateStatus(id, 'completed')));
    }
    if (status != 'completed' && status != 'cancelled' && status != 'no_show') {
      actions.add(_actionBtn('Cancel', Icons.close, adminDanger,
          () => _updateStatus(id, 'cancelled')));
      if (status != 'in_progress') {
        actions.add(_actionBtn('No Show', Icons.person_off_outlined, adminDanger,
            () => _updateStatus(id, 'no_show')));
      }
    }

    return Row(children: actions);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 11, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 56, color: adminBorderLight),
          const SizedBox(height: 16),
          Text('No appointments scheduled', style: adminBodyText()),
          const SizedBox(height: 4),
          Text('Adjust your date or filters to see results',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: adminTextMuted)),
        ],
      ),
    );
  }

  // ─── Patient details dialog ───────────────────────────────────────────────

  void _showPatientDetails(Map<String, dynamic> appointment) {
    final patient = appointment['patients'];
    final doctor = appointment['doctors'];
    final time = DateTime.parse(appointment['appointment_date']);
    final duration = appointment['duration'] ?? 30;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 480,
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
                  Text('Appointment Details',
                      style: TextStyle(fontFamily: 'DM Sans', 
                          fontSize: 16, fontWeight: FontWeight.w600, color: adminTextHeading)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close, size: 20, color: adminTextMuted),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow('Patient', '${patient?['first_name']} ${patient?['last_name']}'),
              _detailRow('Phone', patient?['phone'] ?? 'N/A'),
              if (patient?['blood_group'] != null)
                _detailRow('Blood Group', patient['blood_group']),
              _detailRow('Doctor',
                  'Dr. ${doctor?['first_name']} ${doctor?['last_name']}'),
              _detailRow('Date', DateFormat('MMM dd, yyyy').format(time)),
              _detailRow('Time', DateFormat('h:mm a').format(time)),
              _detailRow('Duration', '$duration minutes'),
              _detailRow('Status', appointment['status'] ?? ''),
              if (appointment['patient_notes'] != null) ...[
                const SizedBox(height: 12),
                Text('Reason', style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 11, fontWeight: FontWeight.w600, color: adminTextMuted)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: adminBgSubtle,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: adminBorderLight),
                  ),
                  child: Text(appointment['patient_notes'],
                      style: adminBodyText()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: adminBodyText()),
          ),
          Text('·  ', style: TextStyle(fontFamily: 'IBM Plex Mono', fontSize: 11, color: adminTextMuted)),
          Expanded(
            child: Text(value,
                style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 13, fontWeight: FontWeight.w500, color: adminTextHeading)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String appointmentId, String newStatus) async {
    final result = await _service.updateAppointmentStatus(
      appointmentId: appointmentId,
      newStatus: newStatus,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? adminSuccess : adminDanger,
      ));
      if (result['success']) _loadData(silent: true);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _capitalize(String s) => s.isEmpty
      ? s
      : s.replaceAll('_', ' ').split(' ').map((w) =>
          w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}
