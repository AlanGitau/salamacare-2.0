import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/admin_service.dart';
import 'package:signup/features/admin/services/patient_export_service.dart';

// ─── module-level helpers ─────────────────────────────────────────────────────

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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
        value: value,
        onChanged: onChanged,
        style: adminBodyText(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: adminMetadata(),
          filled: true,
          fillColor: adminBgSubtle,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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

Widget _riskBadge(String level) {
  Color bg, fg;
  switch (level) {
    case 'high':
      bg = adminDangerTint;
      fg = adminDanger;
      break;
    case 'medium':
      bg = adminWarningTint;
      fg = adminWarning;
      break;
    default:
      bg = adminSuccessTint;
      fg = adminSuccess;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
    child: Text(
      '${level.toUpperCase()} RISK',
      style: TextStyle(fontFamily: 'DM Sans', 
          fontSize: 11, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}

// ─── main widget ──────────────────────────────────────────────────────────────

class PatientListView extends StatefulWidget {
  const PatientListView({super.key});

  @override
  State<PatientListView> createState() => _PatientListViewState();
}

class _PatientListViewState extends State<PatientListView> {
  final _adminService = AdminService();
  final _exportService = PatientExportService();

  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 0;
  static const int _pageSize = 50;

  String _searchQuery = '';
  String? _bloodGroupFilter;
  String? _genderFilter;
  String? _ageRangeFilter;
  String? _riskLevelFilter;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];
  final List<String> _genders = ['male', 'female', 'other'];
  final List<String> _ageRanges = ['0-17', '18-30', '31-45', '46-60', '60+'];
  final List<String> _riskLevels = ['high', 'medium', 'low'];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _patients = [];
    });

    try {
      final patients =
          await _adminService.getAllPatients(page: 0, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _patients = patients;
          _hasMore = patients.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading patients: $e'),
              backgroundColor: adminDanger),
        );
      }
    }
  }

  Future<void> _loadMorePatients() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final patients = await _adminService.getAllPatients(
          page: nextPage, pageSize: _pageSize);
      if (mounted) {
        setState(() {
          _patients.addAll(patients);
          _currentPage = nextPage;
          _hasMore = patients.length == _pageSize;
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

  List<Map<String, dynamic>> get _filteredPatients {
    var filtered = _patients;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final name =
            '${p['first_name']} ${p['last_name']}'.toLowerCase();
        final email =
            p['users']?['email']?.toString().toLowerCase() ?? '';
        final phone = p['phone']?.toString().toLowerCase() ?? '';
        final id = p['id']?.toString().toLowerCase() ?? '';
        final q = _searchQuery.toLowerCase();
        return name.contains(q) ||
            email.contains(q) ||
            phone.contains(q) ||
            id.contains(q);
      }).toList();
    }

    if (_bloodGroupFilter != null && _bloodGroupFilter!.isNotEmpty) {
      filtered = filtered
          .where((p) => p['blood_group']?.toString() == _bloodGroupFilter)
          .toList();
    }

    if (_genderFilter != null && _genderFilter!.isNotEmpty) {
      filtered = filtered
          .where((p) => p['gender']?.toString() == _genderFilter)
          .toList();
    }

    if (_ageRangeFilter != null && _ageRangeFilter!.isNotEmpty) {
      filtered = filtered.where((p) {
        final age = _calculateAge(p['date_of_birth']);
        switch (_ageRangeFilter) {
          case '0-17':
            return age >= 0 && age <= 17;
          case '18-30':
            return age >= 18 && age <= 30;
          case '31-45':
            return age >= 31 && age <= 45;
          case '46-60':
            return age >= 46 && age <= 60;
          case '60+':
            return age > 60;
          default:
            return true;
        }
      }).toList();
    }

    if (_riskLevelFilter != null && _riskLevelFilter!.isNotEmpty) {
      filtered = filtered.where((p) {
        return _getRiskLevel(p['no_show_count'] ?? 0) == _riskLevelFilter;
      }).toList();
    }

    return filtered;
  }

  int _calculateAge(String? dob) {
    if (dob == null) return 0;
    try {
      final birth = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  String _getRiskLevel(int noShowCount) {
    if (noShowCount >= 3) return 'high';
    if (noShowCount >= 2) return 'medium';
    return 'low';
  }

  @override
  Widget build(BuildContext context) {
    final patients = _filteredPatients;
    return Scaffold(
      backgroundColor: adminBgCanvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── page header ──────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          Text('Patient Management',
                              style: adminPageTitle()),
                          const SizedBox(height: 2),
                          Text('${patients.length} patients',
                              style: adminMetadata()),
                        ],
                      ),
                    ),
                    _tableBtn('Export CSV', _exportToCsv),
                    const SizedBox(width: 8),
                    _tableBtn(
                      'Export PDF',
                      _exportToPdf,
                      color: adminDanger,
                      bg: adminDangerTint,
                    ),
                    const SizedBox(width: 8),
                    _tableBtn(
                      'Find Duplicates',
                      _showDuplicatesDialog,
                      color: adminWarning,
                      bg: adminWarningTint,
                    ),
                    const SizedBox(width: 8),
                    _tableBtn('Refresh', _loadPatients),
                  ],
                ),
                const SizedBox(height: 14),
                // ── filter bar ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _searchBar(
                        'Search by name, email, phone, or ID…',
                        (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropFilter<String>(
                        value: _bloodGroupFilter,
                        hint: 'Blood Group',
                        onChanged: (v) =>
                            setState(() => _bloodGroupFilter = v),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Groups')),
                          ..._bloodGroups.map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropFilter<String>(
                        value: _genderFilter,
                        hint: 'Gender',
                        onChanged: (v) =>
                            setState(() => _genderFilter = v),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Genders')),
                          ..._genders.map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(
                                    g[0].toUpperCase() + g.substring(1)),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropFilter<String>(
                        value: _ageRangeFilter,
                        hint: 'Age Range',
                        onChanged: (v) =>
                            setState(() => _ageRangeFilter = v),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Ages')),
                          ..._ageRanges.map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropFilter<String>(
                        value: _riskLevelFilter,
                        hint: 'Risk Level',
                        onChanged: (v) =>
                            setState(() => _riskLevelFilter = v),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Risk')),
                          ..._riskLevels.map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                    r[0].toUpperCase() + r.substring(1)),
                              )),
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
                _th('PATIENT', width: 200),
                _th('CONTACT', width: 190),
                _th('AGE', width: 50),
                _th('GENDER', width: 80),
                _th('BLOOD', width: 60),
                _th('NO-SHOWS', width: 90),
                _th('RISK', width: 110),
                const Spacer(),
                _th('ACTIONS', width: 150),
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
                : patients.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: patients.length +
                            (_hasMore && _searchQuery.isEmpty ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: adminBorderLight),
                        itemBuilder: (context, index) {
                          if (index == patients.length) {
                            return _buildLoadMoreRow();
                          }
                          return _patientRow(patients[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _patientRow(Map<String, dynamic> patient) {
    final name =
        '${patient['first_name']} ${patient['last_name']}';
    final email = patient['users']?['email'] ?? 'N/A';
    final phone = patient['phone'] ?? 'N/A';
    final age = _calculateAge(patient['date_of_birth']);
    final gender = patient['gender']?.toString() ?? 'N/A';
    final bloodGroup = patient['blood_group'] ?? '—';
    final noShowCount = patient['no_show_count'] ?? 0;
    final riskLevel = _getRiskLevel(noShowCount);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      color: adminBgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 56,
      child: Row(
        children: [
          // Patient name + avatar initial
          SizedBox(
            width: 200,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: adminAccentTint,
                    borderRadius: BorderRadius.circular(15),
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
                Expanded(
                  child: Text(name,
                      style: adminBodyText(),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          // Contact
          SizedBox(
            width: 190,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email,
                    style: adminMetadata(), overflow: TextOverflow.ellipsis),
                Text(phone,
                    style: adminMetadata(), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '$age',
              style: TextStyle(fontFamily: 'IBM Plex Mono', 
                  fontSize: 13, color: adminTextBody),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              gender[0].toUpperCase() + gender.substring(1),
              style: adminBodyText(),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              bloodGroup,
              style: TextStyle(fontFamily: 'IBM Plex Mono', 
                  fontSize: 13,
                  color: adminDanger,
                  fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              '$noShowCount',
              style: TextStyle(fontFamily: 'IBM Plex Mono', 
                fontSize: 13,
                color: noShowCount > 0 ? adminDanger : adminSuccess,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 110, child: _riskBadge(riskLevel)),
          const Spacer(),
          SizedBox(
            width: 150,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tableBtn('Details', () => _showPatientDetails(patient)),
                const SizedBox(width: 6),
                _iconActionBtn(
                  Icons.calendar_today_outlined,
                  () => _showAppointmentHistory(patient),
                ),
                const SizedBox(width: 6),
                _iconActionBtn(
                  Icons.notifications_outlined,
                  () => _sendNotification(patient),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreRow() => Container(
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
                onTap: _loadMorePatients,
                child: Text(
                  'Load more patients',
                  style: adminBodyText().copyWith(
                    color: adminAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: adminBorderLight),
            const SizedBox(height: 12),
            Text('No patients found', style: adminSectionHeading()),
            const SizedBox(height: 4),
            Text('Try adjusting your search or filters',
                style: adminMetadata()),
          ],
        ),
      );

  // ── dialogs / actions ──────────────────────────────────────────────────

  void _showPatientDetails(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (ctx) => _PatientDetailsDialog(patient: patient),
    );
  }

  void _showAppointmentHistory(Map<String, dynamic> patient) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Appointment history for ${patient['first_name']} ${patient['last_name']}'),
      action: SnackBarAction(label: 'View', onPressed: () {}),
    ));
  }

  void _sendNotification(Map<String, dynamic> patient) {
    final msgCtrl = TextEditingController();
    final name =
        '${patient['first_name']} ${patient['last_name']}';

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 460,
          decoration: BoxDecoration(
            color: adminBgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminBorderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                          borderSide: const BorderSide(color: adminAccent),
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
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            msgCtrl.dispose();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Notification sent!')),
                              );
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

  Future<void> _exportToPdf() async {
    try {
      await _exportService.generatePatientListPdf(_filteredPatients);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF export failed: $e'),
              backgroundColor: adminDanger),
        );
      }
    }
  }

  Future<void> _showDuplicatesDialog() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: adminBgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminBorderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: adminAccent, strokeWidth: 2),
              const SizedBox(height: 16),
              Text('Finding duplicates…', style: adminBodyText()),
            ],
          ),
        ),
      ),
    );

    final duplicates = await _adminService.findPotentialDuplicates();
    if (!mounted) return;
    Navigator.pop(context); // close loading

    if (duplicates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No duplicate patients found'),
        backgroundColor: adminSuccess,
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 640,
          constraints: const BoxConstraints(maxHeight: 560),
          decoration: BoxDecoration(
            color: adminBgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: adminBorderLight),
          ),
          child: Column(
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
                  border: Border(bottom: BorderSide(color: adminBorderLight)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${duplicates.length} Potential Duplicate Groups',
                        style: adminSectionHeading(),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: const Icon(Icons.close,
                          size: 18, color: adminTextMuted),
                    ),
                  ],
                ),
              ),

              // list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: duplicates.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (ctx, groupIndex) {
                    final group = duplicates[groupIndex];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: adminBgSurface,
                        border: Border.all(color: adminBorderLight),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group ${groupIndex + 1} — ${group.length} records',
                            style: adminBodyText().copyWith(
                                fontWeight: FontWeight.w600,
                                color: adminTextHeading),
                          ),
                          const SizedBox(height: 8),
                          ...group.map((p) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${p['first_name']} ${p['last_name']}',
                                        style: adminBodyText(),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        p['users']?['email'] ?? '',
                                        style: adminMetadata(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      p['date_of_birth'] ?? '',
                                      style: adminMetadata(),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _tableBtn(
                              'Merge into ${group[0]['first_name']}',
                              () => _confirmMerge(
                                  dialogCtx, group),
                              color: adminWarning,
                              bg: adminWarningTint,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                alignment: Alignment.centerRight,
                child: adminSecondaryButton(
                  label: 'Close',
                  onTap: () => Navigator.pop(dialogCtx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmMerge(
      BuildContext dialogCtx, List<dynamic> group) async {
    final primaryName =
        '${group[0]['first_name']} ${group[0]['last_name']}';
    final confirm = await showDialog<bool>(
      context: dialogCtx,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 420,
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
              Text('Confirm Merge', style: adminSectionHeading()),
              const SizedBox(height: 12),
              Text(
                'Merge ${group.length - 1} duplicate record(s) into $primaryName?\n\n'
                'All appointments and linked data will be transferred to the primary record. '
                'This cannot be undone.',
                style: adminBodyText(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  adminSecondaryButton(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                  const SizedBox(width: 10),
                  adminDangerButton(
                    label: 'Merge',
                    onTap: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    final primaryId = group[0]['id'];
    for (int i = 1; i < group.length; i++) {
      final result =
          await _adminService.mergePatients(primaryId, group[i]['id']);
      if (!result['success']) {
        if (dialogCtx.mounted) {
          ScaffoldMessenger.of(dialogCtx).showSnackBar(SnackBar(
            content: Text(result['message']),
            backgroundColor: adminDanger,
          ));
        }
        return;
      }
    }

    if (dialogCtx.mounted) {
      Navigator.pop(dialogCtx);
      ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(
        content: Text('Patients merged successfully'),
        backgroundColor: adminSuccess,
      ));
    }
    _loadPatients();
  }

  Future<void> _exportToCsv() async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text('Exporting ${_filteredPatients.length} patients to CSV…'),
    ));
  }
}

// ─── Patient Details Dialog ───────────────────────────────────────────────────

class _PatientDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _PatientDetailsDialog({required this.patient});

  @override
  Widget build(BuildContext context) {
    final name =
        '${patient['first_name']} ${patient['last_name']}';
    final email = patient['users']?['email'] ?? 'N/A';
    final phone = patient['phone'] ?? 'N/A';
    final dob = patient['date_of_birth'] != null
        ? DateFormat('MMM dd, yyyy')
            .format(DateTime.parse(patient['date_of_birth']))
        : 'N/A';
    final gender = patient['gender']?.toString() ?? 'N/A';
    final bloodGroup = patient['blood_group'] ?? 'N/A';
    final address = patient['address'] ?? 'N/A';
    final allergies = patient['allergies'] ?? 'None';
    final chronicConditions = patient['chronic_conditions'] ?? 'None';
    final currentMedications = patient['current_medications'] ?? 'None';
    final noShowCount = patient['no_show_count'] ?? 0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

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
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: TextStyle(fontFamily: 'DM Sans', 
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: adminAccent),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: adminSectionHeading()),
                        Text(
                          'ID: ${patient['id']}',
                          style: TextStyle(fontFamily: 'IBM Plex Mono', 
                              fontSize: 11, color: adminTextMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    _section('CONTACT', [
                      _row('Email', email),
                      _row('Phone', phone),
                      _row('Address', address),
                    ]),
                    const SizedBox(height: 16),
                    _section('PERSONAL', [
                      _row('Date of Birth', dob),
                      _row('Gender',
                          gender[0].toUpperCase() + gender.substring(1)),
                      _row('Blood Group', bloodGroup, mono: true),
                    ]),
                    const SizedBox(height: 16),
                    _section('MEDICAL', [
                      _row('Allergies', allergies,
                          highlight: allergies != 'None'),
                      _row('Chronic Conditions', chronicConditions,
                          highlight: chronicConditions != 'None'),
                      _row('Current Medications', currentMedications),
                    ]),
                    const SizedBox(height: 16),
                    _section('STATISTICS', [
                      Row(
                        children: [
                          SizedBox(
                              width: 160,
                              child:
                                  Text('No-Shows', style: adminMetadata())),
                          Text(
                            '$noShowCount',
                            style: TextStyle(fontFamily: 'IBM Plex Mono', 
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: noShowCount > 0
                                  ? adminDanger
                                  : adminSuccess,
                            ),
                          ),
                        ],
                      ),
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
              alignment: Alignment.centerRight,
              child: adminSecondaryButton(
                label: 'Close',
                onTap: () => Navigator.pop(context),
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

  Widget _row(String label, String value,
      {bool mono = false, bool highlight = false}) =>
      Padding(
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
                        fontSize: 13,
                        color: adminTextBody,
                        fontWeight: FontWeight.w600)
                    : adminBodyText().copyWith(
                        color: highlight ? adminWarning : null),
              ),
            ),
          ],
        ),
      );
}
