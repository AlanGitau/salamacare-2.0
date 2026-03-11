import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/waitlist_service.dart';
import 'package:intl/intl.dart';

class WaitlistManagementView extends StatefulWidget {
  const WaitlistManagementView({super.key});

  @override
  State<WaitlistManagementView> createState() => _WaitlistManagementViewState();
}

class _WaitlistManagementViewState extends State<WaitlistManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _waitlistService = WaitlistService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: adminBgCanvas,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            decoration: const BoxDecoration(
              color: adminBgSurface,
              border: Border(bottom: BorderSide(color: adminBorderLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Waitlist Management', style: adminPageTitle()),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: adminAccent,
                  unselectedLabelColor: adminTextBody,
                  indicatorColor: adminAccent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                      fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(
                      fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w400),
                  tabs: const [
                    Tab(text: 'Waitlist Queue'),
                    Tab(text: 'Settings'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _WaitlistQueueTab(waitlistService: _waitlistService),
                _WaitlistSettingsTab(waitlistService: _waitlistService),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Waitlist Queue Tab ───────────────────────────────────────────────────────

class _WaitlistQueueTab extends StatefulWidget {
  final WaitlistService waitlistService;
  const _WaitlistQueueTab({required this.waitlistService});

  @override
  State<_WaitlistQueueTab> createState() => _WaitlistQueueTabState();
}

class _WaitlistQueueTabState extends State<_WaitlistQueueTab> {
  List<Map<String, dynamic>> _waitlist = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      widget.waitlistService.getActiveWaitlist(status: _statusFilter),
      widget.waitlistService.getWaitlistStats(),
    ]);
    if (mounted) {
      setState(() {
        _waitlist = results[0] as List<Map<String, dynamic>>;
        _stats = results[1] as Map<String, int>;
        _isLoading = false;
      });
    }
  }

  Color _priorityColor(int? priority) {
    if (priority == null) return adminNeutral;
    if (priority <= 1) return adminDanger;
    if (priority <= 3) return adminWarning;
    return adminAccent;
  }

  String _priorityLabel(int? priority) {
    if (priority == null) return 'Normal';
    if (priority <= 1) return 'Urgent';
    if (priority <= 3) return 'High';
    return 'Normal';
  }

  Widget _statusBadge(String? status) {
    Color bg, textColor;
    switch (status) {
      case 'active':
        bg = adminAccentTint; textColor = adminAccent;
        break;
      case 'fulfilled':
        bg = adminSuccessTint; textColor = adminSuccess;
        break;
      case 'cancelled':
        bg = adminDangerTint; textColor = adminDanger;
        break;
      default:
        bg = adminBgSubtle; textColor = adminTextMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        (status ?? 'unknown').toUpperCase(),
        style: TextStyle(
            fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

    return Column(
      children: [
        // Stats + filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            color: adminBgSurface,
            border: Border(bottom: BorderSide(color: adminBorderLight)),
          ),
          child: Row(
            children: [
              _statChip('Active', _stats['active'] ?? 0, adminAccent),
              const SizedBox(width: 8),
              _statChip('Fulfilled', _stats['fulfilled'] ?? 0, adminSuccess),
              const SizedBox(width: 8),
              _statChip('Expired', _stats['expired'] ?? 0, adminNeutral),
              const SizedBox(width: 8),
              _statChip('Cancelled', _stats['cancelled'] ?? 0, adminDanger),
              const Spacer(),
              // Status filter dropdown
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: adminBgSubtle,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: adminBorderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _statusFilter,
                    style: adminBodyText(),
                    dropdownColor: adminBgSurface,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: adminTextBody),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Active')),
                      DropdownMenuItem(value: 'fulfilled', child: Text('Fulfilled')),
                      DropdownMenuItem(value: 'expired', child: Text('Expired')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      _loadData();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              adminSecondaryButton(
                label: 'Expire Old',
                icon: Icons.auto_delete_outlined,
                onTap: () async {
                  final res = await widget.waitlistService.expireOldEntries();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'],
                            style: adminBodyText().copyWith(color: Colors.white)),
                        backgroundColor: res['success'] ? adminSuccess : adminDanger,
                      ),
                    );
                    _loadData();
                  }
                },
              ),
              const SizedBox(width: 8),
              adminSecondaryButton(
                  label: 'Refresh', icon: Icons.refresh, onTap: _loadData),
            ],
          ),
        ),
        // Waitlist entries
        Expanded(
          child: _waitlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.playlist_add_check_outlined,
                          size: 52, color: adminTextMuted),
                      const SizedBox(height: 16),
                      Text('No waitlist entries', style: adminBodyText()),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _waitlist.length,
                  itemBuilder: (context, index) {
                    final entry = _waitlist[index];
                    final patient = entry['patients'];
                    final doctor = entry['doctors'];
                    final specialty = entry['specialties'];
                    final priority = entry['priority'] as int?;
                    final status = entry['status'] ?? 'active';
                    final prefStart =
                        DateTime.tryParse(entry['preferred_date_start'] ?? '');
                    final prefEnd =
                        DateTime.tryParse(entry['preferred_date_end'] ?? '');
                    final prefTime = entry['preferred_time'] ?? 'any';
                    final pc = _priorityColor(priority);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: adminBgSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: adminBorderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pc.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: pc.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'P${priority ?? '–'} ${_priorityLabel(priority)}',
                                  style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: pc),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _statusBadge(status),
                              const Spacer(),
                              if (status == 'active')
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_horiz,
                                      size: 18, color: adminTextBody),
                                  color: adminBgSurface,
                                  onSelected: (action) async {
                                    Map<String, dynamic> res;
                                    switch (action) {
                                      case 'fulfill':
                                        res = await widget.waitlistService
                                            .updateWaitlistStatus(
                                                entry['id'], 'fulfilled');
                                        break;
                                      case 'cancel':
                                        res = await widget.waitlistService
                                            .updateWaitlistStatus(
                                                entry['id'], 'cancelled');
                                        break;
                                      case 'priority_up':
                                        res = await widget.waitlistService
                                            .updateWaitlistPriority(
                                                entry['id'],
                                                (priority ?? 5) - 1);
                                        break;
                                      case 'priority_down':
                                        res = await widget.waitlistService
                                            .updateWaitlistPriority(
                                                entry['id'],
                                                (priority ?? 5) + 1);
                                        break;
                                      default:
                                        return;
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(res['message'],
                                              style: adminBodyText()
                                                  .copyWith(color: Colors.white)),
                                          backgroundColor: res['success']
                                              ? adminSuccess
                                              : adminDanger,
                                        ),
                                      );
                                      _loadData();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    _popupItem('fulfill', Icons.check_outlined,
                                        'Mark Fulfilled', adminSuccess),
                                    _popupItem('cancel', Icons.close,
                                        'Cancel', adminDanger),
                                    const PopupMenuDivider(),
                                    _popupItem('priority_up',
                                        Icons.arrow_upward_outlined,
                                        'Increase Priority', adminTextBody),
                                    _popupItem('priority_down',
                                        Icons.arrow_downward_outlined,
                                        'Decrease Priority', adminTextBody),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 14, color: adminTextMuted),
                              const SizedBox(width: 4),
                              Text(
                                  '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}',
                                  style: adminBodyText()
                                      .copyWith(fontWeight: FontWeight.w600)),
                              if (doctor != null) ...[
                                const SizedBox(width: 16),
                                const Icon(Icons.local_hospital_outlined,
                                    size: 14, color: adminTextMuted),
                                const SizedBox(width: 4),
                                Text(
                                    'Dr. ${doctor['first_name']} ${doctor['last_name']}',
                                    style: adminBodyText()),
                              ],
                              if (specialty != null) ...[
                                const SizedBox(width: 16),
                                const Icon(Icons.category_outlined,
                                    size: 14, color: adminTextMuted),
                                const SizedBox(width: 4),
                                Text(specialty['name'] ?? '',
                                    style: adminBodyText()),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.date_range_outlined,
                                  size: 14, color: adminTextMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${prefStart != null ? DateFormat('MMM dd').format(prefStart) : '?'} – ${prefEnd != null ? DateFormat('MMM dd').format(prefEnd) : '?'}',
                                style: adminMetadata(),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time_outlined,
                                  size: 14, color: adminTextMuted),
                              const SizedBox(width: 4),
                              Text(
                                prefTime[0].toUpperCase() + prefTime.substring(1),
                                style: adminMetadata(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: adminBorderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(width: 6),
          Text(label, style: adminBodyText()),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: adminBodyText().copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─── Waitlist Settings Tab ────────────────────────────────────────────────────

class _WaitlistSettingsTab extends StatefulWidget {
  final WaitlistService waitlistService;
  const _WaitlistSettingsTab({required this.waitlistService});

  @override
  State<_WaitlistSettingsTab> createState() => _WaitlistSettingsTabState();
}

class _WaitlistSettingsTabState extends State<_WaitlistSettingsTab> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  bool _enabled = true;
  bool _autoBook = false;
  bool _notificationEnabled = true;
  late TextEditingController _maxEntriesController;
  late TextEditingController _expiryDaysController;

  @override
  void initState() {
    super.initState();
    _maxEntriesController = TextEditingController();
    _expiryDaysController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _maxEntriesController.dispose();
    _expiryDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final settings = await widget.waitlistService.getWaitlistSettings();
    if (mounted) {
      setState(() {
        _enabled = settings['waitlist_enabled'] ?? true;
        _autoBook = settings['waitlist_auto_book'] ?? false;
        _notificationEnabled = settings['waitlist_notification_enabled'] ?? true;
        _maxEntriesController.text = (settings['waitlist_max_entries'] ?? 50).toString();
        _expiryDaysController.text = (settings['waitlist_expiry_days'] ?? 30).toString();
        _isLoading = false;
        _hasChanges = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final result = await widget.waitlistService.updateWaitlistSettings({
      'waitlist_enabled': _enabled,
      'waitlist_auto_book': _autoBook,
      'waitlist_notification_enabled': _notificationEnabled,
      'waitlist_max_entries': int.tryParse(_maxEntriesController.text) ?? 50,
      'waitlist_expiry_days': int.tryParse(_expiryDaysController.text) ?? 30,
    });
    if (mounted) {
      setState(() {
        _isSaving = false;
        if (result['success']) _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'],
              style: adminBodyText().copyWith(color: Colors.white)),
          backgroundColor: result['success'] ? adminSuccess : adminDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

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
                color: adminWarningTint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: adminWarning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: adminWarning, size: 18),
                  const SizedBox(width: 8),
                  Text('You have unsaved changes', style: adminBodyText()),
                  const Spacer(),
                  adminPrimaryButton(
                    label: _isSaving ? 'Saving...' : 'Save',
                    onTap: _isSaving ? () {} : _saveSettings,
                  ),
                ],
              ),
            ),
          // Settings card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: adminBgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: adminBorderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Waitlist Configuration', style: adminSectionHeading()),
                const SizedBox(height: 20),
                _settingSwitch('Enable Waitlist', 'Allow patients to join the waitlist',
                    _enabled, (v) => setState(() { _enabled = v; _hasChanges = true; })),
                const Divider(color: adminBorderLight, height: 24),
                _settingSwitch('Auto-Book from Waitlist',
                    'Automatically book appointments when slots become available',
                    _autoBook, (v) => setState(() { _autoBook = v; _hasChanges = true; })),
                const Divider(color: adminBorderLight, height: 24),
                _settingSwitch('Waitlist Notifications',
                    'Notify patients when a slot becomes available',
                    _notificationEnabled,
                    (v) => setState(() { _notificationEnabled = v; _hasChanges = true; })),
                const Divider(color: adminBorderLight, height: 24),
                _settingNumField('Maximum Waitlist Entries',
                    'Maximum number of active waitlist entries', _maxEntriesController),
                const SizedBox(height: 16),
                _settingNumField('Expiry Days',
                    'Days after which inactive entries expire', _expiryDaysController),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isSaving ? null : _saveSettings,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _isSaving ? adminBorderLight : adminAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text(
                          'Save Settings',
                          style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingSwitch(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: adminBodyText().copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: adminMetadata()),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: adminAccent,
          activeTrackColor: adminAccentTint,
          inactiveThumbColor: adminTextMuted,
          inactiveTrackColor: adminBorderLight,
        ),
      ],
    );
  }

  Widget _settingNumField(
      String title, String subtitle, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: adminBodyText().copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: adminMetadata()),
            ],
          ),
        ),
        SizedBox(
          width: 90,
          child: TextField(
            controller: controller,
            style: adminBodyText(),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _hasChanges = true),
            decoration: InputDecoration(
              filled: true,
              fillColor: adminBgSubtle,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: adminBorderLight)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: adminBorderLight)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: adminAccent)),
            ),
          ),
        ),
      ],
    );
  }
}
