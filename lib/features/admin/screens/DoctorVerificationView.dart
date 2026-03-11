import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/verification_service.dart';
import 'package:intl/intl.dart';

class DoctorVerificationView extends StatefulWidget {
  const DoctorVerificationView({super.key});

  @override
  State<DoctorVerificationView> createState() => _DoctorVerificationViewState();
}

class _DoctorVerificationViewState extends State<DoctorVerificationView>
    with SingleTickerProviderStateMixin {
  final _verificationService = VerificationService();
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingDoctors = [];
  List<Map<String, dynamic>> _verifiedDoctors = [];
  List<Map<String, dynamic>> _rejectedDoctors = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _verificationService.getPendingDoctors(),
        _verificationService.getVerifiedDoctors(),
        _verificationService.getRejectedDoctors(),
        _verificationService.getVerificationStats(),
      ]);
      if (mounted) {
        setState(() {
          _pendingDoctors  = results[0] as List<Map<String, dynamic>>;
          _verifiedDoctors = results[1] as List<Map<String, dynamic>>;
          _rejectedDoctors = results[2] as List<Map<String, dynamic>>;
          _stats           = results[3] as Map<String, int>;
          _isLoading       = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: adminDanger),
        );
      }
    }
  }

  Future<void> _verifyDoctor(String doctorId) async {
    final confirm = await _showConfirmDialog(
      title: 'Verify Doctor',
      body: 'This doctor will be able to accept patients after verification.',
      confirmLabel: 'Verify',
      confirmColor: adminSuccess,
    );
    if (confirm == true) {
      final result = await _verificationService.verifyDoctor(doctorId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? adminSuccess : adminDanger,
        ));
        if (result['success']) _loadData();
      }
    }
  }

  Future<void> _rejectDoctor(String doctorId) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
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
              Row(children: [
                Text('Reject Doctor', style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 16, fontWeight: FontWeight.w600, color: adminTextHeading)),
                const Spacer(),
                GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close, size: 20, color: adminTextMuted)),
              ]),
              const SizedBox(height: 8),
              Text('Provide a reason for rejection:', style: adminBodyText()),
              const SizedBox(height: 16),
              _inputField(controller: reasonController, hint: 'e.g. Invalid license number', maxLines: 3),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  adminSecondaryButton(label: 'Cancel', onTap: () => Navigator.pop(ctx)),
                  const SizedBox(width: 12),
                  adminDangerButton(
                    label: 'Reject',
                    onTap: () {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Please provide a reason'),
                              backgroundColor: adminDanger),
                        );
                        return;
                      }
                      Navigator.pop(ctx, reasonController.text.trim());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (reason != null) {
      final result = await _verificationService.rejectDoctor(doctorId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? adminSuccess : adminDanger,
        ));
        if (result['success']) _loadData();
      }
    }
  }

  Future<void> _reinstateDoctor(String doctorId) async {
    final confirm = await _showConfirmDialog(
      title: 'Reinstate Doctor',
      body: "Reset this doctor's status to pending for re-review?",
      confirmLabel: 'Reinstate',
      confirmColor: adminAccent,
    );
    if (confirm == true) {
      final result = await _verificationService.reinstateDoctor(doctorId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? adminSuccess : adminDanger,
        ));
        if (result['success']) _loadData();
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
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
              Text(title, style: TextStyle(fontFamily: 'DM Sans', 
                  fontSize: 16, fontWeight: FontWeight.w600, color: adminTextHeading)),
              const SizedBox(height: 8),
              Text(body, style: adminBodyText()),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  adminSecondaryButton(label: 'Cancel', onTap: () => Navigator.pop(ctx, false)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: confirmColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(confirmLabel,
                          style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoctorDetails(Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (ctx) => _DoctorDetailsDialog(
        doctor: doctor,
        onVerify: () { Navigator.pop(ctx); _verifyDoctor(doctor['id']); },
        onReject: () { Navigator.pop(ctx); _rejectDoctor(doctor['id']); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: adminBgCanvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          Container(
            color: adminBgCanvas,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Doctor Verification', style: adminPageTitle()),
                        const SizedBox(height: 2),
                        Text('Review and approve new doctor registrations', style: adminBodyText()),
                      ],
                    ),
                    const Spacer(),
                    // Stat chips
                    _statChip('Pending', _stats['pending'] ?? 0, adminWarning, adminWarningTint),
                    const SizedBox(width: 8),
                    _statChip('Verified', _stats['verified'] ?? 0, adminSuccess, adminSuccessTint),
                    const SizedBox(width: 8),
                    _statChip('Rejected', _stats['rejected'] ?? 0, adminDanger, adminDangerTint),
                    const SizedBox(width: 16),
                    adminSecondaryButton(label: 'Refresh', icon: Icons.refresh, onTap: _loadData),
                  ],
                ),
                const SizedBox(height: 20),

                // Tab bar
                TabBar(
                  controller: _tabController,
                  labelColor: adminSidebarActive,
                  unselectedLabelColor: adminSidebarLabel,
                  indicatorColor: adminSidebarActive,
                  indicatorWeight: 2,
                  labelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w500),
                  unselectedLabelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w400),
                  tabs: [
                    Tab(text: 'Pending (${_pendingDoctors.length})'),
                    Tab(text: 'Verified (${_verifiedDoctors.length})'),
                    Tab(text: 'Rejected (${_rejectedDoctors.length})'),
                  ],
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDoctorList(_pendingDoctors, 'pending'),
                      _buildDoctorList(_verifiedDoctors, 'verified'),
                      _buildDoctorList(_rejectedDoctors, 'rejected'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(fontFamily: 'IBM Plex Mono', 
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildDoctorList(List<Map<String, dynamic>> doctors, String status) {
    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'pending' ? Icons.hourglass_empty_outlined
                  : status == 'verified' ? Icons.check_circle_outline
                  : Icons.block_outlined,
              size: 48,
              color: adminBorderLight,
            ),
            const SizedBox(height: 12),
            Text('No $status doctors', style: adminBodyText()),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: doctors.length,
      itemBuilder: (_, i) => _buildDoctorRow(doctors[i], status),
    );
  }

  Widget _buildDoctorRow(Map<String, dynamic> doctor, String status) {
    final name = 'Dr. ${doctor['first_name']} ${doctor['last_name']}';
    final email = doctor['users']?['email'] ?? 'N/A';
    final license = doctor['license_number'] ?? 'N/A';
    final initial = doctor['first_name']?.substring(0, 1).toUpperCase() ?? 'D';
    final createdAt = doctor['created_at'] != null
        ? DateTime.parse(doctor['created_at'])
        : null;

    String specialty = 'General Practice';
    if (doctor['doctor_specialties'] != null) {
      final specialties = doctor['doctor_specialties'] as List;
      final primary = specialties.firstWhere(
        (s) => s['is_primary'] == true,
        orElse: () => specialties.isNotEmpty ? specialties.first : null,
      );
      if (primary != null) specialty = primary['specialties']?['name'] ?? specialty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: adminAccentTint, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(initial,
                style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 16, fontWeight: FontWeight.w600, color: adminAccent)),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(fontFamily: 'DM Sans', 
                        fontSize: 14, fontWeight: FontWeight.w600, color: adminTextHeading)),
                const SizedBox(height: 2),
                Text(specialty, style: adminBodyText()),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 12, color: adminTextMuted),
                    const SizedBox(width: 4),
                    Text(email, style: adminMetadata()),
                    const SizedBox(width: 16),
                    Icon(Icons.badge_outlined, size: 12, color: adminTextMuted),
                    const SizedBox(width: 4),
                    Text(license, style: adminMetadata()),
                    if (createdAt != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Registered ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                        style: adminMetadata(),
                      ),
                    ],
                  ],
                ),
                if (status == 'rejected' && doctor['rejection_reason'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: adminDangerTint,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: adminDanger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 13, color: adminDanger),
                        const SizedBox(width: 6),
                        Text(
                          'Reason: ${doctor['rejection_reason']}',
                          style: TextStyle(fontFamily: 'DM Sans', 
                              fontSize: 12, color: adminDanger),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == 'pending') ...[
                _rowActionBtn('Verify', Icons.check_outlined, adminSuccess,
                    () => _verifyDoctor(doctor['id'])),
                const SizedBox(width: 8),
                _rowActionBtn('Reject', Icons.close, adminDanger,
                    () => _rejectDoctor(doctor['id'])),
                const SizedBox(width: 8),
              ] else if (status == 'rejected') ...[
                _rowActionBtn('Reinstate', Icons.refresh_outlined, adminWarning,
                    () => _reinstateDoctor(doctor['id'])),
                const SizedBox(width: 8),
              ],
              _rowActionBtn('Details', Icons.visibility_outlined, adminTextBody,
                  () => _showDoctorDetails(doctor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rowActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

// ─── Doctor details dialog ─────────────────────────────────────────────────

class _DoctorDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  const _DoctorDetailsDialog({
    required this.doctor,
    required this.onVerify,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = doctor['verification_status'] ?? 'pending';
    final initial = doctor['first_name']?.substring(0, 1).toUpperCase() ?? 'D';

    return Dialog(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: adminBgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: adminBorderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: adminAccentTint, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: TextStyle(fontFamily: 'DM Sans', 
                          fontSize: 20, fontWeight: FontWeight.w600, color: adminAccent)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${doctor['first_name']} ${doctor['last_name']}',
                        style: TextStyle(fontFamily: 'DM Sans', 
                            fontSize: 16, fontWeight: FontWeight.w600, color: adminTextHeading),
                      ),
                      Text(doctor['users']?['email'] ?? '',
                          style: adminBodyText()),
                    ],
                  ),
                ),
                adminStatusBadge(status),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 20, color: adminTextMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: adminBorderLight, height: 1),
            const SizedBox(height: 16),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('Professional Information', [
                      _row('License Number', doctor['license_number']?.toString() ?? 'N/A'),
                      _row('Years of Experience', '${doctor['years_of_experience'] ?? 0} years'),
                      _row('Consultation Fee', 'KES ${doctor['consultation_fee'] ?? 0}'),
                      _row('Education', doctor['education']?.toString() ?? 'N/A'),
                      _row('Languages', doctor['languages']?.toString() ?? 'N/A'),
                    ]),
                    const SizedBox(height: 16),
                    _section('Account Status', [
                      _row('Accepting Patients',
                          doctor['is_accepting_patients'] == true ? 'Yes' : 'No'),
                      if (doctor['verification_date'] != null)
                        _row('Verified On',
                            DateFormat('MMM dd, yyyy').format(
                                DateTime.parse(doctor['verification_date']))),
                      if (doctor['rejection_reason'] != null)
                        _row('Rejection Reason', doctor['rejection_reason']),
                    ]),
                    if (doctor['bio'] != null &&
                        doctor['bio'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _section('Bio', [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: adminBgSubtle,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: adminBorderLight),
                          ),
                          child: Text(doctor['bio'], style: adminBodyText()),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),

            if (status == 'pending') ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  adminDangerButton(label: 'Reject', onTap: onReject),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onVerify,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: adminSuccess,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text('Verify Doctor',
                          style: TextStyle(fontFamily: 'DM Sans', 
                              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontFamily: 'DM Sans', 
                fontSize: 11, fontWeight: FontWeight.w600,
                color: adminTextMuted, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: adminBodyText()),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 13, fontWeight: FontWeight.w500, color: adminTextHeading)),
          ),
        ],
      ),
    );
  }
}
