import 'package:flutter/material.dart';
import 'package:signup/core/constants/colors.dart';
import 'package:signup/features/admin/services/admin_service.dart';
import 'package:intl/intl.dart';

class DoctorDetailView extends StatefulWidget {
  final Map<String, dynamic> doctor;
  const DoctorDetailView({super.key, required this.doctor});

  @override
  State<DoctorDetailView> createState() => _DoctorDetailViewState();
}

class _DoctorDetailViewState extends State<DoctorDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = 'Dr. ${widget.doctor['first_name']} ${widget.doctor['last_name']}';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Schedule & Leave'),
            Tab(text: 'Performance'),
            Tab(text: 'Appointments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProfileTab(doctor: widget.doctor, adminService: _adminService),
          _ScheduleLeaveTab(doctor: widget.doctor, adminService: _adminService),
          _PerformanceTab(doctor: widget.doctor, adminService: _adminService),
          _AppointmentsTab(doctor: widget.doctor, adminService: _adminService),
        ],
      ),
    );
  }
}

// ─── Profile Tab ───

class _ProfileTab extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final AdminService adminService;
  const _ProfileTab({required this.doctor, required this.adminService});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _licenseController;
  late TextEditingController _bioController;
  late TextEditingController _educationController;
  late TextEditingController _languagesController;
  late TextEditingController _experienceController;
  late TextEditingController _feeController;
  bool _isAccepting = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    _firstNameController = TextEditingController(text: d['first_name'] ?? '');
    _lastNameController = TextEditingController(text: d['last_name'] ?? '');
    _phoneController = TextEditingController(text: d['phone'] ?? '');
    _licenseController = TextEditingController(text: d['license_number'] ?? '');
    _bioController = TextEditingController(text: d['bio'] ?? '');
    _educationController = TextEditingController(text: d['education'] ?? '');
    _languagesController = TextEditingController(text: d['languages'] ?? '');
    _experienceController = TextEditingController(text: (d['years_of_experience'] ?? '').toString());
    _feeController = TextEditingController(text: (d['consultation_fee'] ?? '').toString());
    _isAccepting = d['is_accepting_patients'] ?? true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _bioController.dispose();
    _educationController.dispose();
    _languagesController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final result = await widget.adminService.updateDoctorProfile(widget.doctor['id'], {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'license_number': _licenseController.text.trim(),
      'bio': _bioController.text.trim(),
      'education': _educationController.text.trim(),
      'languages': _languagesController.text.trim(),
      'years_of_experience': int.tryParse(_experienceController.text) ?? 0,
      'consultation_fee': double.tryParse(_feeController.text) ?? 0,
      'is_accepting_patients': _isAccepting,
    });

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (result['success']) _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() => _hasChanges = true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Text('You have unsaved changes'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          // Personal info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField('First Name', _firstNameController)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Last Name', _lastNameController)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildField('Phone', _phoneController, keyboardType: TextInputType.phone)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('License Number', _licenseController)),
                    ],
                  ),
                  Text(
                    'Email: ${widget.doctor['users']?['email'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Professional info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Professional Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildField('Bio', _bioController, maxLines: 3),
                  _buildField('Education', _educationController),
                  _buildField('Languages', _languagesController),
                  Row(
                    children: [
                      Expanded(child: _buildField('Years of Experience', _experienceController, keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Consultation Fee (KES)', _feeController, keyboardType: TextInputType.number)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Accepting Patients', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Switch(
                        value: _isAccepting,
                        onChanged: (v) => setState(() {
                          _isAccepting = v;
                          _hasChanges = true;
                        }),
                        activeThumbColor: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Specialties
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Specialties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (widget.doctor['doctor_specialties'] != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (widget.doctor['doctor_specialties'] as List).map((s) {
                        return Chip(
                          label: Text(s['specialties']?['name'] ?? ''),
                          backgroundColor: s['is_primary'] == true ? AppColors.primary : Colors.grey[300],
                          labelStyle: TextStyle(color: s['is_primary'] == true ? Colors.white : Colors.black87),
                        );
                      }).toList(),
                    )
                  else
                    const Text('No specialties assigned'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Profile', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule & Leave Tab ───

class _ScheduleLeaveTab extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final AdminService adminService;
  const _ScheduleLeaveTab({required this.doctor, required this.adminService});

  @override
  State<_ScheduleLeaveTab> createState() => _ScheduleLeaveTabState();
}

class _ScheduleLeaveTabState extends State<_ScheduleLeaveTab> {
  List<Map<String, dynamic>> _availability = [];
  List<Map<String, dynamic>> _leaves = [];
  bool _isLoading = true;

  final _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      widget.adminService.getDoctorAvailability(widget.doctor['id']),
      widget.adminService.getDoctorLeaveHistory(widget.doctor['id']),
    ]);
    if (mounted) {
      setState(() {
        _availability = results[0];
        _leaves = results[1];
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddLeaveDialog() async {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Leave / Vacation'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (date != null) setDialogState(() => startDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder()),
                    child: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: endDate, firstDate: startDate, lastDate: DateTime(2030));
                    if (date != null) setDialogState(() => endDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder()),
                    child: Text(DateFormat('MMM dd, yyyy').format(endDate)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reason')));
                  return;
                }
                final res = await widget.adminService.createDoctorLeave(
                  widget.doctor['id'],
                  startDate,
                  endDate,
                  reasonController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context, res['success']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message']), backgroundColor: res['success'] ? Colors.green : Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Add Leave'),
            ),
          ],
        ),
      ),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Schedule
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_availability.isEmpty)
                    const Text('No availability configured', style: TextStyle(color: Colors.grey))
                  else
                    ..._days.map((day) {
                      final daySlots = _availability.where((a) => a['day_of_week']?.toString() == day || _dayIndex(day) == a['day_of_week']).toList();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(day, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            if (daySlots.isEmpty || daySlots.every((s) => s['is_available'] == false))
                              Text('Off', style: TextStyle(color: Colors.grey[400]))
                            else
                              ...daySlots.where((s) => s['is_available'] != false).map((slot) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${slot['start_time']} - ${slot['end_time']}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.primary),
                                ),
                              )),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Leave/Vacation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Leave / Vacation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: _showAddLeaveDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Leave'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_leaves.isEmpty)
                    const Text('No leave records', style: TextStyle(color: Colors.grey))
                  else
                    ..._leaves.map((leave) {
                      final start = DateTime.tryParse(leave['start_time'] ?? '');
                      final end = DateTime.tryParse(leave['end_time'] ?? '');
                      final isPast = end != null && end.isBefore(DateTime.now());

                      return Card(
                        color: isPast ? Colors.grey[50] : null,
                        child: ListTile(
                          leading: Icon(
                            isPast ? Icons.history : Icons.event_busy,
                            color: isPast ? Colors.grey : Colors.orange,
                          ),
                          title: Text(leave['reason'] ?? 'No reason'),
                          subtitle: Text(
                            '${start != null ? DateFormat('MMM dd, yyyy').format(start) : ''} - ${end != null ? DateFormat('MMM dd, yyyy').format(end) : ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Leave'),
                                  content: const Text('Remove this leave record?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await widget.adminService.deleteDoctorLeave(leave['id']);
                                _loadData();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int? _dayIndex(String day) {
    const map = {'Monday': 0, 'Tuesday': 1, 'Wednesday': 2, 'Thursday': 3, 'Friday': 4, 'Saturday': 5, 'Sunday': 6};
    return map[day];
  }
}

// ─── Performance Tab ───

class _PerformanceTab extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final AdminService adminService;
  const _PerformanceTab({required this.doctor, required this.adminService});

  @override
  State<_PerformanceTab> createState() => _PerformanceTabState();
}

class _PerformanceTabState extends State<_PerformanceTab> {
  Map<String, dynamic> _performance = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformance();
  }

  Future<void> _loadPerformance() async {
    setState(() => _isLoading = true);
    final perf = await widget.adminService.getDoctorDetailedPerformance(widget.doctor['id']);
    if (mounted) {
      setState(() {
        _performance = perf;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance (Last 90 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Appointments', '${_performance['total_appointments']}', Icons.calendar_today, const Color(0xFF2196F3))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Completed', '${_performance['completed']}', Icons.check_circle, const Color(0xFF4CAF50))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Cancelled', '${_performance['cancelled']}', Icons.cancel, const Color(0xFFF44336))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('No-Shows', '${_performance['no_show']}', Icons.person_off, const Color(0xFFFF9800))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Completion Rate', '${_performance['completion_rate']}%', Icons.trending_up, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Unique Patients', '${_performance['unique_patients']}', Icons.people, const Color(0xFF9C27B0))),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 24),
          // Recent appointment status breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Appointment Status Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildStatusBar('Completed', _performance['completed'] ?? 0, _performance['total_appointments'] ?? 1, const Color(0xFF4CAF50)),
                  const SizedBox(height: 8),
                  _buildStatusBar('Cancelled', _performance['cancelled'] ?? 0, _performance['total_appointments'] ?? 1, const Color(0xFFF44336)),
                  const SizedBox(height: 8),
                  _buildStatusBar('No-Show', _performance['no_show'] ?? 0, _performance['total_appointments'] ?? 1, const Color(0xFFFF9800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: Text('$count (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}

// ─── Appointments Tab ───

class _AppointmentsTab extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final AdminService adminService;
  const _AppointmentsTab({required this.doctor, required this.adminService});

  @override
  State<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<_AppointmentsTab> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    final appointments = await widget.adminService.getDoctorAppointments(
      widget.doctor['id'],
      status: _statusFilter,
    );
    if (mounted) {
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'scheduled': return const Color(0xFF2196F3);
      case 'confirmed': return const Color(0xFF4CAF50);
      case 'completed': return const Color(0xFF9C27B0);
      case 'cancelled': return const Color(0xFFF44336);
      case 'no_show': return const Color(0xFFFF9800);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('${_appointments.length} appointments', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const Spacer(),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                    DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    DropdownMenuItem(value: 'no_show', child: Text('No Show')),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    _loadAppointments();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAppointments, tooltip: 'Refresh'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _appointments.isEmpty
                  ? const Center(child: Text('No appointments found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        final appt = _appointments[index];
                        final patient = appt['patients'];
                        final status = appt['status'] ?? 'scheduled';
                        final date = DateTime.tryParse(appt['appointment_date'] ?? '');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(status),
                              radius: 18,
                              child: Icon(_getStatusIcon(status), color: Colors.white, size: 18),
                            ),
                            title: Text(
                              '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: date != null
                                ? Text(DateFormat('MMM dd, yyyy - h:mm a').format(date))
                                : null,
                            trailing: Chip(
                              label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                              backgroundColor: _getStatusColor(status),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled': return Icons.schedule;
      case 'confirmed': return Icons.check_circle;
      case 'completed': return Icons.task_alt;
      case 'cancelled': return Icons.cancel;
      case 'no_show': return Icons.person_off;
      default: return Icons.help;
    }
  }
}
