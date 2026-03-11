import 'package:flutter/material.dart';
import 'package:signup/core/services/app_notification_service.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/admin_service.dart';
import 'package:signup/features/admin/services/user_management_service.dart';
import 'package:signup/features/admin/screens/DoctorDetailView.dart';

// ─── module-level helpers ────────────────────────────────────────────────────

Widget _th(String label, {double? width}) => SizedBox(
      width: width,
      child: Text(label, style: adminTableHeader()),
    );

Widget _searchBar(String hint, ValueChanged<String> onChanged) => SizedBox(
      height: 38,
      child: TextField(
        onChanged: onChanged,
        style: adminBodyText(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: adminMetadata(),
          prefixIcon: const Icon(Icons.search, size: 16, color: adminTextMuted),
          filled: true,
          fillColor: adminBgSubtle,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: adminBorderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: adminAccent),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );

Widget _dropFilter<T>({
  required T? value,
  required String hint,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) =>
    SizedBox(
      height: 38,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        onChanged: onChanged,
        style: adminBodyText(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: adminMetadata(),
          filled: true,
          fillColor: adminBgSubtle,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: adminBorderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: adminAccent),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        items: items,
      ),
    );

Widget _verificationBadge(String status) {
  Color bg, fg;
  IconData ic;
  switch (status) {
    case 'verified':
      bg = adminSuccessTint;
      fg = adminSuccess;
      ic = Icons.verified_outlined;
      break;
    case 'rejected':
      bg = adminDangerTint;
      fg = adminDanger;
      ic = Icons.cancel_outlined;
      break;
    default:
      bg = adminWarningTint;
      fg = adminWarning;
      ic = Icons.schedule_outlined;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ic, size: 12, color: fg),
        const SizedBox(width: 4),
        Text(
          status.toUpperCase(),
          style: TextStyle(fontFamily: 'DM Sans', 
              fontSize: 11, fontWeight: FontWeight.w600, color: fg),
        ),
      ],
    ),
  );
}

Widget _acceptingChip(bool accepting) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accepting ? adminSuccessTint : adminDangerTint,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        accepting ? 'Accepting' : 'Closed',
        style: TextStyle(fontFamily: 'DM Sans', 
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accepting ? adminSuccess : adminDanger,
        ),
      ),
    );

Widget _tableBtn(
  String label,
  VoidCallback onTap, {
  Color color = adminAccent,
  Color? bg,
}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg ?? color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'DM Sans', 
              fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );

Widget _iconActionBtn(IconData icon, VoidCallback onTap,
        {Color color = adminTextMuted}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: adminBgSubtle,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: adminBorderLight),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );

// ─── main widget ─────────────────────────────────────────────────────────────

class DoctorListView extends StatefulWidget {
  const DoctorListView({super.key});

  @override
  State<DoctorListView> createState() => _DoctorListViewState();
}

class _DoctorListViewState extends State<DoctorListView> {
  final _adminService = AdminService();

  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _specialties = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 0;
  static const int _pageSize = 50;

  String _searchQuery = '';
  String? _specialtyFilter;
  String? _verificationFilter;
  bool? _acceptingPatientsFilter;

  final List<String> _verificationStatuses = ['verified', 'pending', 'rejected'];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _loadSpecialties();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _doctors = [];
    });

    try {
      final doctors =
          await _adminService.getAllDoctors(page: 0, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _hasMore = doctors.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading doctors: $e'),
              backgroundColor: adminDanger),
        );
      }
    }
  }

  Future<void> _loadMoreDoctors() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final doctors = await _adminService.getAllDoctors(
          page: nextPage, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _doctors.addAll(doctors);
          _currentPage = nextPage;
          _hasMore = doctors.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading more: $e'),
              backgroundColor: adminDanger),
        );
      }
    }
  }

  Future<void> _loadSpecialties() async {
    try {
      final specialties = await _adminService.getAllSpecialties();
      if (mounted) setState(() => _specialties = specialties);
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    var filtered = _doctors;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doctor) {
        final name =
            'Dr. ${doctor['first_name']} ${doctor['last_name']}'.toLowerCase();
        final email =
            doctor['users']?['email']?.toString().toLowerCase() ?? '';
        final license =
            doctor['license_number']?.toString().toLowerCase() ?? '';
        final id = doctor['id']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            license.contains(query) ||
            id.contains(query);
      }).toList();
    }

    if (_specialtyFilter != null && _specialtyFilter!.isNotEmpty) {
      filtered = filtered.where((doctor) {
        final specialties = doctor['doctor_specialties'] as List?;
        if (specialties == null) return false;
        return specialties.any((s) =>
            s['specialties']?['name']?.toString() == _specialtyFilter);
      }).toList();
    }

    if (_verificationFilter != null && _verificationFilter!.isNotEmpty) {
      filtered = filtered
          .where((d) =>
              d['verification_status']?.toString() == _verificationFilter)
          .toList();
    }

    if (_acceptingPatientsFilter != null) {
      filtered = filtered
          .where((d) => d['is_accepting_patients'] == _acceptingPatientsFilter)
          .toList();
    }

    return filtered;
  }

  String _getPrimarySpecialty(Map<String, dynamic> doctor) {
    final specialties = doctor['doctor_specialties'] as List?;
    if (specialties == null || specialties.isEmpty) return 'General Practice';
    final primary = specialties.firstWhere(
      (s) => s['is_primary'] == true,
      orElse: () => specialties.first,
    );
    return primary['specialties']?['name'] ?? 'General Practice';
  }

  @override
  Widget build(BuildContext context) {
    final doctors = _filteredDoctors;
    return Scaffold(
      backgroundColor: adminBgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── page header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: adminBgSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Doctor Management', style: adminPageTitle()),
                          const SizedBox(height: 2),
                          Text('${doctors.length} doctors',
                              style: adminMetadata()),
                        ],
                      ),
                    ),
                    _tableBtn('Export CSV', _exportToCsv),
                    const SizedBox(width: 8),
                    _tableBtn(
                      'Add Doctor',
                      _showAddDoctorDialog,
                      color: adminSuccess,
                      bg: adminSuccessTint,
                    ),
                    const SizedBox(width: 8),
                    _tableBtn('Refresh', _loadDoctors),
                  ],
                ),
                const SizedBox(height: 14),
                // ── filter bar ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _searchBar(
                        'Search by name, email, license…',
                        (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropFilter<String>(
                        value: _specialtyFilter,
                        hint: 'All Specialties',
                        onChanged: (v) =>
                            setState(() => _specialtyFilter = v),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Specialties')),
                          ..._specialties.map((s) => DropdownMenuItem(
                                value: s['name'] as String,
                                child: Text(s['name'] as String),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropFilter<String>(
                        value: _verificationFilter,
                        hint: 'All Verification',
                        onChanged: (v) =>
                            setState(() => _verificationFilter = v),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Verification')),
                          ..._verificationStatuses.map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                    s[0].toUpperCase() + s.substring(1)),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropFilter<bool?>(
                        value: _acceptingPatientsFilter,
                        hint: 'All Doctors',
                        onChanged: (v) =>
                            setState(() => _acceptingPatientsFilter = v),
                        items: const [
                          DropdownMenuItem(
                              value: null, child: Text('All Doctors')),
                          DropdownMenuItem(
                              value: true, child: Text('Accepting')),
                          DropdownMenuItem(
                              value: false, child: Text('Not Accepting')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: adminBorderLight),

          // ── table header ─────────────────────────────────────────
          Container(
            color: adminBgSubtle,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: [
                _th('DOCTOR', width: 220),
                _th('SPECIALTY', width: 150),
                _th('LICENSE', width: 120),
                _th('EXP', width: 60),
                _th('FEE', width: 70),
                _th('VERIFICATION', width: 120),
                _th('STATUS', width: 100),
                const Spacer(),
                _th('ACTIONS', width: 160),
              ],
            ),
          ),
          const Divider(height: 1, color: adminBorderLight),

          // ── table body ───────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: adminAccent, strokeWidth: 2))
                : doctors.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: doctors.length +
                            (_hasMore && _searchQuery.isEmpty ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: adminBorderLight),
                        itemBuilder: (context, index) {
                          if (index == doctors.length) {
                            return _buildLoadMoreRow();
                          }
                          return _doctorRow(doctors[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _doctorRow(Map<String, dynamic> doctor) {
    final name =
        'Dr. ${doctor['first_name']} ${doctor['last_name']}';
    final email = doctor['users']?['email'] ?? 'N/A';
    final license = doctor['license_number'] ?? 'N/A';
    final specialty = _getPrimarySpecialty(doctor);
    final experience = doctor['years_of_experience'] ?? 0;
    final fee = doctor['consultation_fee'] ?? 0;
    final isAccepting = doctor['is_accepting_patients'] ?? false;
    final verificationStatus =
        doctor['verification_status'] ?? 'pending';

    return Container(
      color: adminBgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: adminBodyText(), overflow: TextOverflow.ellipsis),
                Text(email, style: adminMetadata(), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(specialty, style: adminBodyText(),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 120,
            child: Text(
              license,
              style: TextStyle(fontFamily: 'IBM Plex Mono', 
                  fontSize: 12, color: adminTextBody),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '$experience yr',
              style: TextStyle(fontFamily: 'IBM Plex Mono', 
                  fontSize: 12, color: adminTextBody),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '\$$fee',
              style: TextStyle(fontFamily: 'IBM Plex Mono', 
                  fontSize: 12,
                  color: adminSuccess,
                  fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: 120, child: _verificationBadge(verificationStatus)),
          SizedBox(width: 100, child: _acceptingChip(isAccepting)),
          const Spacer(),
          SizedBox(
            width: verificationStatus == 'pending' ? 210 : 160,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (verificationStatus == 'pending')
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _tableBtn(
                      'Verify',
                      () => _verifyDoctor(doctor),
                      color: adminSuccess,
                      bg: adminSuccessTint,
                    ),
                  ),
                _tableBtn('Details', () => _showDoctorDetails(doctor)),
                const SizedBox(width: 6),
                _iconActionBtn(
                  isAccepting ? Icons.block : Icons.check_circle_outline,
                  () => _toggleDoctorStatus(doctor['id'], isAccepting),
                  color: isAccepting ? adminDanger : adminSuccess,
                ),
                const SizedBox(width: 6),
                _iconActionBtn(
                  Icons.notifications_outlined,
                  () => _sendNotification(doctor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreRow() {
    return Container(
      color: adminBgSubtle,
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: adminAccent, strokeWidth: 2))
          : GestureDetector(
              onTap: _loadMoreDoctors,
              child: Text(
                'Load more doctors',
                style: adminBodyText().copyWith(
                  color: adminAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital_outlined,
                size: 48, color: adminBorderLight),
            const SizedBox(height: 12),
            Text('No doctors found', style: adminSectionHeading()),
            const SizedBox(height: 4),
            Text('Try adjusting your search or filters',
                style: adminMetadata()),
          ],
        ),
      );

  // ── dialogs / actions ───────────────────────────────────────────────────

  void _showDoctorDetails(Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (ctx) => _DoctorDetailsDialog(doctor: doctor),
    );
  }

  Future<void> _verifyDoctor(Map<String, dynamic> doctor) async {
    final name =
        'Dr. ${doctor['first_name']} ${doctor['last_name']}';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 400,
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
              Text('Verify Doctor', style: adminSectionHeading()),
              const SizedBox(height: 12),
              Text(
                  'Verify $name and grant access to the platform?',
                  style: adminBodyText()),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  adminSecondaryButton(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                  const SizedBox(width: 10),
                  _tableBtn(
                    'Verify',
                    () => Navigator.pop(ctx, true),
                    color: adminSuccess,
                    bg: adminSuccessTint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final result =
          await _adminService.verifyDoctor(doctor['id'] as String);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] as String),
          backgroundColor:
              result['success'] == true ? adminSuccess : adminDanger,
        ));
        if (result['success'] == true) _loadDoctors();
      }
    }
  }

  Future<void> _toggleDoctorStatus(
      String doctorId, bool currentStatus) async {
    final result =
        await _adminService.updateDoctorStatus(doctorId, !currentStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? adminSuccess : adminDanger,
      ));
      if (result['success']) _loadDoctors();
    }
  }

  void _sendNotification(Map<String, dynamic> doctor) {
    final msgCtrl = TextEditingController();
    final name =
        'Dr. ${doctor['first_name']} ${doctor['last_name']}';

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 460,
          decoration: BoxDecoration(
            color: adminBgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminBorderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: adminBgSubtle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border:
                      Border(bottom: BorderSide(color: adminBorderLight)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Send Notification',
                          style: adminSectionHeading()),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: const Icon(Icons.close,
                          size: 18, color: adminTextMuted),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recipient: $name', style: adminBodyText()),
                    const SizedBox(height: 14),
                    TextField(
                      controller: msgCtrl,
                      maxLines: 4,
                      style: adminBodyText(),
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter message…',
                        hintStyle: adminMetadata(),
                        filled: true,
                        fillColor: adminBgSubtle,
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: adminBorderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: adminAccent),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        adminSecondaryButton(
                          label: 'Cancel',
                          onTap: () {
                            msgCtrl.dispose();
                            Navigator.pop(dialogCtx);
                          },
                        ),
                        const SizedBox(width: 10),
                        adminPrimaryButton(
                          label: 'Send',
                          onTap: () async {
                            final message = msgCtrl.text.trim();
                            if (message.isEmpty) return;
                            final doctorUserId =
                                doctor['user_id'] as String?;
                            Navigator.pop(dialogCtx);
                            msgCtrl.dispose();

                            if (doctorUserId == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text(
                                      'Could not find doctor user account'),
                                  backgroundColor: adminDanger,
                                ));
                              }
                              return;
                            }

                            final result = await AppNotificationService()
                                .createNotification(
                              userId: doctorUserId,
                              notificationType: 'admin_message',
                              title: 'Message from Admin',
                              message: message,
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(result['success'] == true
                                    ? 'Notification sent successfully'
                                    : result['message'] as String? ??
                                        'Failed to send'),
                                backgroundColor:
                                    result['success'] == true
                                        ? adminSuccess
                                        : adminDanger,
                              ));
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDoctorDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AddDoctorDialog(specialties: _specialties),
    );
    if (result == true) _loadDoctors();
  }

  Future<void> _exportToCsv() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Exporting ${_filteredDoctors.length} doctors to CSV…')),
    );
  }
}

// ─── Doctor Details Dialog ────────────────────────────────────────────────────

class _DoctorDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _DoctorDetailsDialog({required this.doctor});

  String _getPrimarySpecialty() {
    final specialties = doctor['doctor_specialties'] as List?;
    if (specialties == null || specialties.isEmpty) return 'General Practice';
    final primary = specialties.firstWhere(
      (s) => s['is_primary'] == true,
      orElse: () => specialties.first,
    );
    return primary['specialties']?['name'] ?? 'General Practice';
  }

  @override
  Widget build(BuildContext context) {
    final name = 'Dr. ${doctor['first_name']} ${doctor['last_name']}';
    final email = doctor['users']?['email'] ?? 'N/A';
    final license = doctor['license_number'] ?? 'N/A';
    final specialty = _getPrimarySpecialty();
    final experience = doctor['years_of_experience'] ?? 0;
    final fee = doctor['consultation_fee'] ?? 0;
    final education = doctor['education'] ?? 'N/A';
    final languages = doctor['languages'] ?? 'N/A';
    final bio = doctor['bio'] ?? 'No bio available';
    final isAccepting = doctor['is_accepting_patients'] ?? false;
    final verificationStatus = doctor['verification_status'] ?? 'pending';

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: adminBgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: adminBorderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: adminBgSubtle,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border:
                    Border(bottom: BorderSide(color: adminBorderLight)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: adminAccentTint,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.local_hospital,
                        size: 22, color: adminAccent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: adminSectionHeading()),
                        Text(specialty, style: adminMetadata()),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        size: 18, color: adminTextMuted),
                  ),
                ],
              ),
            ),

            // body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('PROFESSIONAL', [
                      _row('License Number', license, mono: true),
                      _row('Education', education),
                      _row('Experience', '$experience years'),
                      _row('Languages', languages),
                      _row('Consultation Fee', '\$$fee', mono: true),
                    ]),
                    const SizedBox(height: 16),
                    _section('CONTACT', [
                      _row('Email', email),
                    ]),
                    const SizedBox(height: 16),
                    _section('STATUS', [
                      Row(
                        children: [
                          SizedBox(
                              width: 160,
                              child: Text('Verification',
                                  style: adminMetadata())),
                          _verificationBadge(verificationStatus),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                              width: 160,
                              child: Text('Accepting Patients',
                                  style: adminMetadata())),
                          _acceptingChip(isAccepting),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _section('BIO', [
                      Text(bio, style: adminBodyText()),
                    ]),
                  ],
                ),
              ),
            ),

            // footer
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: adminBgSubtle,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(top: BorderSide(color: adminBorderLight)),
              ),
              child: Row(
                children: [
                  adminSecondaryButton(
                    label: 'Close',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  adminPrimaryButton(
                    label: 'Full Details & Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DoctorDetailView(doctor: doctor),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: adminTableHeader()),
          const SizedBox(height: 10),
          ...children,
        ],
      );

  Widget _row(String label, String value, {bool mono = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
                width: 160,
                child: Text(label, style: adminMetadata())),
            Expanded(
              child: Text(
                value,
                style: mono
                    ? TextStyle(fontFamily: 'IBM Plex Mono', 
                        fontSize: 13, color: adminTextBody)
                    : adminBodyText(),
              ),
            ),
          ],
        ),
      );
}

// ─── Add Doctor Dialog ────────────────────────────────────────────────────────

class _AddDoctorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> specialties;
  const _AddDoctorDialog({required this.specialties});

  @override
  State<_AddDoctorDialog> createState() => _AddDoctorDialogState();
}

class _AddDoctorDialogState extends State<_AddDoctorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userManagementService = UserManagementService();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _expCtrl = TextEditingController();

  String? _selectedSpecialtyId;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _feeCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final result = await _userManagementService.createDoctorAccount(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      licenseNumber: _licenseCtrl.text.trim(),
      specialtyId: _selectedSpecialtyId,
      consultationFee: _feeCtrl.text.isNotEmpty
          ? double.tryParse(_feeCtrl.text.trim())
          : null,
      yearsOfExperience: _expCtrl.text.isNotEmpty
          ? int.tryParse(_expCtrl.text.trim())
          : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? adminSuccess : adminDanger,
      ));
      if (result['success']) Navigator.pop(context, true);
    }
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: adminMetadata(),
        filled: true,
        fillColor: adminBgSubtle,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: adminBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: adminAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: adminDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: adminDanger),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: adminBgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: adminBorderLight),
        ),
        child: Column(
          children: [
            // ── header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: adminBgSubtle,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border:
                    Border(bottom: BorderSide(color: adminBorderLight)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_outlined,
                      size: 18, color: adminAccent),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text('Add New Doctor',
                          style: adminSectionHeading())),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        size: 18, color: adminTextMuted),
                  ),
                ],
              ),
            ),

            // ── form ──────────────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameCtrl,
                              style: adminBodyText(),
                              decoration: _inputDec('First Name *'),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameCtrl,
                              style: adminBodyText(),
                              decoration: _inputDec('Last Name *'),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        style: adminBodyText(),
                        decoration: _inputDec('Email Address *'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        style: adminBodyText(),
                        obscureText: _obscurePassword,
                        decoration: _inputDec('Password *').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: adminTextMuted,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              style: adminBodyText(),
                              decoration: _inputDec('Phone'),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _licenseCtrl,
                              style: adminBodyText(),
                              decoration: _inputDec('License Number'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSpecialtyId,
                        style: adminBodyText(),
                        decoration: _inputDec('Specialty'),
                        items: [
                          const DropdownMenuItem(
                              value: null,
                              child: Text('Select specialty')),
                          ...widget.specialties.map((s) =>
                              DropdownMenuItem(
                                value: s['id'] as String,
                                child: Text(s['name'] as String),
                              )),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedSpecialtyId = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _feeCtrl,
                              style: adminBodyText(),
                              decoration:
                                  _inputDec('Consultation Fee'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _expCtrl,
                              style: adminBodyText(),
                              decoration:
                                  _inputDec('Years of Experience'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── footer ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: adminBgSubtle,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border:
                    Border(top: BorderSide(color: adminBorderLight)),
              ),
              child: Row(
                children: [
                  adminSecondaryButton(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (_isSubmitting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: adminAccent, strokeWidth: 2),
                    )
                  else
                    _tableBtn(
                      'Create Doctor',
                      _submit,
                      color: adminSuccess,
                      bg: adminSuccessTint,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
