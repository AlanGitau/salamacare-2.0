import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/schedule_service.dart';
import 'package:intl/intl.dart';

class ScheduleManagementView extends StatefulWidget {
  const ScheduleManagementView({super.key});

  @override
  State<ScheduleManagementView> createState() => _ScheduleManagementViewState();
}

class _ScheduleManagementViewState extends State<ScheduleManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scheduleService = ScheduleService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          // Page header + tab bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            decoration: const BoxDecoration(
              color: adminBgSurface,
              border: Border(bottom: BorderSide(color: adminBorderLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule Management', style: adminPageTitle()),
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
                    Tab(text: 'Master Calendar'),
                    Tab(text: 'Holidays'),
                    Tab(text: 'Emergency Slots'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MasterCalendarTab(scheduleService: _scheduleService),
                _HolidaysTab(scheduleService: _scheduleService),
                _EmergencySlotsTab(scheduleService: _scheduleService),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Master Calendar Tab ─────────────────────────────────────────────────────

class _MasterCalendarTab extends StatefulWidget {
  final ScheduleService scheduleService;
  const _MasterCalendarTab({required this.scheduleService});

  @override
  State<_MasterCalendarTab> createState() => _MasterCalendarTabState();
}

class _MasterCalendarTabState extends State<_MasterCalendarTab> {
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _blockedSlots = [];
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
      widget.scheduleService.getAllDoctorSchedules(),
      widget.scheduleService.getBlockedSlots(),
    ]);
    if (mounted) {
      setState(() {
        _schedules = results[0];
        _blockedSlots = results[1];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

    final Map<String, List<Map<String, dynamic>>> doctorSchedules = {};
    final Map<String, String> doctorNames = {};
    for (final s in _schedules) {
      final doctorId = s['doctor_id'] as String? ?? '';
      final doc = s['doctors'];
      doctorSchedules.putIfAbsent(doctorId, () => []);
      doctorSchedules[doctorId]!.add(s);
      if (doc != null) {
        doctorNames[doctorId] = 'Dr. ${doc['first_name']} ${doc['last_name']}';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${doctorSchedules.length} doctors with schedules', style: adminBodyText()),
              const Spacer(),
              adminSecondaryButton(label: 'Refresh', icon: Icons.refresh, onTap: _loadData),
            ],
          ),
          const SizedBox(height: 16),
          // Weekly overview table
          _flatCard(
            title: 'Weekly Overview',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      SizedBox(
                        width: 160,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text('DOCTOR', style: adminTableHeader()),
                        ),
                      ),
                      ..._days.map((d) => SizedBox(
                        width: 90,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: Text(d.substring(0, 3).toUpperCase(), style: adminTableHeader()),
                        ),
                      )),
                    ],
                  ),
                  Container(height: 1, color: adminBorderLight),
                  // Doctor rows
                  ...doctorSchedules.entries.toList().asMap().entries.map((me) {
                    final i = me.key;
                    final entry = me.value;
                    final doctorId = entry.key;
                    final slots = entry.value;
                    return Container(
                      decoration: BoxDecoration(
                        color: i.isEven ? adminBgSurface : adminBgSubtle,
                        border: const Border(bottom: BorderSide(color: adminBorderLight)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 160,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Text(doctorNames[doctorId] ?? 'Unknown',
                                  style: adminBodyText()),
                            ),
                          ),
                          ..._days.asMap().entries.map((dayEntry) {
                            final dayIndex = dayEntry.key;
                            final day = dayEntry.value;
                            final daySlots = slots
                                .where((s) =>
                                    s['day_of_week']?.toString() == day ||
                                    s['day_of_week'] == dayIndex)
                                .toList();

                            return SizedBox(
                              width: 90,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: daySlots.isEmpty
                                    ? Text('—', style: adminMetadata())
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: daySlots
                                            .map((slot) => Container(
                                                  margin: const EdgeInsets.only(bottom: 2),
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: adminAccentTint,
                                                    borderRadius: BorderRadius.circular(3),
                                                    border: Border.all(
                                                        color: adminAccent
                                                            .withValues(alpha: 0.3)),
                                                  ),
                                                  child: Text(
                                                    '${slot['start_time']?.toString().substring(0, 5) ?? ''}-${slot['end_time']?.toString().substring(0, 5) ?? ''}',
                                                    style: const TextStyle(
                                                        fontFamily: 'IBM Plex Mono',
                                                        fontSize: 10,
                                                        color: adminAccent),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Blocked time slots
          _flatCard(
            title: 'Upcoming Blocked Time',
            child: _blockedSlots.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No blocked time slots', style: adminBodyText()),
                  )
                : Column(
                    children: _blockedSlots.take(10).map((block) {
                      final doc = block['doctors'];
                      final start = DateTime.tryParse(block['start_time'] ?? '');
                      final end = DateTime.tryParse(block['end_time'] ?? '');
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: adminBorderLight)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_busy_outlined,
                                size: 16, color: adminWarning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Dr. ${doc?['first_name'] ?? ''} ${doc?['last_name'] ?? ''}',
                                      style: adminBodyText()
                                          .copyWith(fontWeight: FontWeight.w600)),
                                  if ((block['reason'] ?? '').isNotEmpty)
                                    Text(block['reason'], style: adminMetadata()),
                                ],
                              ),
                            ),
                            Text(
                              '${start != null ? DateFormat('MMM dd').format(start) : ''} – ${end != null ? DateFormat('MMM dd').format(end) : ''}',
                              style: adminMetadata(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _flatCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adminBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: adminSectionHeading()),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Holidays Tab ─────────────────────────────────────────────────────────────

class _HolidaysTab extends StatefulWidget {
  final ScheduleService scheduleService;
  const _HolidaysTab({required this.scheduleService});

  @override
  State<_HolidaysTab> createState() => _HolidaysTabState();
}

class _HolidaysTabState extends State<_HolidaysTab> {
  List<Map<String, dynamic>> _holidays = [];
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      widget.scheduleService.getClinicHolidays(year: DateTime.now().year),
      widget.scheduleService.getDoctorsForPicker(),
    ]);
    if (mounted) {
      setState(() {
        _holidays = results[0];
        _doctors = results[1];
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddHolidayDialog() async {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isRecurring = false;
    bool appliesToAll = true;
    String? selectedDoctorId;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: adminBgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: adminBorderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Holiday / Closure', style: adminSectionHeading()),
                  const SizedBox(height: 20),
                  _dialogField(
                    child: TextFormField(
                      controller: nameController,
                      style: adminBodyText(),
                      decoration: _inputDecoration('Holiday Name *', hint: 'e.g., Christmas Day'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                                colorScheme:
                                    const ColorScheme.light(primary: adminAccent)),
                            child: child!,
                          ),
                        );
                        if (date != null) setDialogState(() => selectedDate = date);
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: adminBgSubtle,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: adminBorderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range_outlined,
                                size: 16, color: adminTextBody),
                            const SizedBox(width: 8),
                            Text(DateFormat('MMM dd, yyyy').format(selectedDate),
                                style: adminBodyText()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _switchRow('Recurring Annually', isRecurring,
                      (v) => setDialogState(() => isRecurring = v)),
                  _switchRow('Applies to All Doctors', appliesToAll,
                      (v) => setDialogState(() => appliesToAll = v)),
                  if (!appliesToAll) ...[
                    const SizedBox(height: 12),
                    _dialogDropdown<String>(
                      label: 'Specific Doctor',
                      value: selectedDoctorId,
                      items: _doctors
                          .map((d) => DropdownMenuItem<String>(
                                value: d['id'] as String,
                                child: Text(
                                    'Dr. ${d['first_name']} ${d['last_name']}',
                                    style: adminBodyText()),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedDoctorId = v),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      adminSecondaryButton(
                          label: 'Cancel',
                          onTap: () => Navigator.pop(context, false)),
                      const SizedBox(width: 8),
                      adminPrimaryButton(
                        label: 'Add Holiday',
                        onTap: () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Name is required',
                                    style: adminBodyText()
                                        .copyWith(color: Colors.white)),
                                backgroundColor: adminDanger,
                              ),
                            );
                            return;
                          }
                          final res = await widget.scheduleService.createClinicHoliday(
                            name: nameController.text.trim(),
                            date: selectedDate,
                            isRecurring: isRecurring,
                            appliesToAll: appliesToAll,
                            doctorId: appliesToAll ? null : selectedDoctorId,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'],
                                    style: adminBodyText()
                                        .copyWith(color: Colors.white)),
                                backgroundColor:
                                    res['success'] ? adminSuccess : adminDanger,
                              ),
                            );
                            Navigator.pop(context, res['success']);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Text('${_holidays.length} holidays in ${DateTime.now().year}',
                  style: adminBodyText()),
              const Spacer(),
              adminPrimaryButton(
                  label: 'Add Holiday',
                  icon: Icons.add,
                  onTap: _showAddHolidayDialog),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _holidays.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.beach_access_outlined,
                            size: 52, color: adminTextMuted),
                        const SizedBox(height: 16),
                        Text('No holidays configured', style: adminBodyText()),
                        const SizedBox(height: 4),
                        Text('Add clinic holidays and closures',
                            style: adminMetadata()),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: adminBgSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: adminBorderLight),
                    ),
                    child: ListView.builder(
                      itemCount: _holidays.length,
                      itemBuilder: (context, index) {
                        final holiday = _holidays[index];
                        final date = DateTime.tryParse(holiday['date'] ?? '');
                        final isPast = date != null && date.isBefore(DateTime.now());
                        final doctor = holiday['doctors'];

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isPast ? adminBgSubtle : adminBgSurface,
                            border: const Border(
                                bottom: BorderSide(color: adminBorderLight)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                holiday['is_recurring'] == true
                                    ? Icons.repeat_outlined
                                    : Icons.event_outlined,
                                size: 18,
                                color: isPast ? adminTextMuted : adminDanger,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      holiday['name'] ?? '',
                                      style: adminBodyText().copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isPast
                                            ? adminTextMuted
                                            : adminTextHeading,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      date != null
                                          ? DateFormat('EEEE, MMM dd, yyyy')
                                              .format(date)
                                          : '',
                                      style: adminMetadata(),
                                    ),
                                    Row(
                                      children: [
                                        if (holiday['is_recurring'] == true)
                                          _miniTag('Recurring', adminAccentTint,
                                              adminAccent),
                                        if (holiday['applies_to_all_doctors'] !=
                                                true &&
                                            doctor != null)
                                          _miniTag(
                                              'Dr. ${doctor['first_name']}',
                                              adminWarningTint,
                                              adminWarning),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final confirm = await _confirmDelete(
                                      context, 'Remove "${holiday['name']}"?');
                                  if (confirm == true) {
                                    await widget.scheduleService
                                        .deleteClinicHoliday(holiday['id']);
                                    if (mounted) _loadData();
                                  }
                                },
                                child: const Icon(Icons.delete_outline,
                                    size: 18, color: adminTextMuted),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String label, Color bg, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(3)),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor)),
    );
  }
}

// ─── Emergency Slots Tab ──────────────────────────────────────────────────────

class _EmergencySlotsTab extends StatefulWidget {
  final ScheduleService scheduleService;
  const _EmergencySlotsTab({required this.scheduleService});

  @override
  State<_EmergencySlotsTab> createState() => _EmergencySlotsTabState();
}

class _EmergencySlotsTabState extends State<_EmergencySlotsTab> {
  List<Map<String, dynamic>> _availability = [];
  bool _isLoading = true;
  final Map<String, TextEditingController> _controllers = {};

  final _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await widget.scheduleService.getDoctorAvailabilityWithEmergency();
    if (mounted) {
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      for (final slot in data) {
        final id = slot['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          _controllers[id] = TextEditingController(
            text: (slot['emergency_slots_reserved'] ?? 0).toString(),
          );
        }
      }
      setState(() {
        _availability = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSlot(String slotId) async {
    final controller = _controllers[slotId];
    if (controller == null) return;
    final count = int.tryParse(controller.text) ?? 0;
    final res = await widget.scheduleService.updateEmergencySlots(slotId, count);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'],
              style: adminBodyText().copyWith(color: Colors.white)),
          backgroundColor: res['success'] ? adminSuccess : adminDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final Map<String, String> names = {};
    for (final a in _availability) {
      final dId = a['doctor_id'] as String? ?? '';
      grouped.putIfAbsent(dId, () => []);
      grouped[dId]!.add(a);
      final doc = a['doctors'];
      if (doc != null) names[dId] = 'Dr. ${doc['first_name']} ${doc['last_name']}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: adminBgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: adminBorderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: adminAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency Slot Reservations', style: adminSectionHeading()),
                      const SizedBox(height: 4),
                      Text(
                        'Reserved slots are held back from online booking and only available for walk-in emergencies.',
                        style: adminBodyText(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (grouped.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No doctor availability configured', style: adminBodyText()),
              ),
            )
          else
            ...grouped.entries.map((entry) {
              final doctorId = entry.key;
              final slots = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: adminBgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: adminBorderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(names[doctorId] ?? 'Unknown',
                        style: adminSectionHeading()),
                    const SizedBox(height: 12),
                    ...slots.map((slot) {
                      final slotId = slot['id']?.toString() ?? '';
                      final dayIdx = slot['day_of_week'];
                      final dayName = dayIdx is int && dayIdx < _dayNames.length
                          ? _dayNames[dayIdx]
                          : dayIdx?.toString() ?? '';
                      final controller = _controllers[slotId];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(dayName,
                                  style: adminBodyText()
                                      .copyWith(fontWeight: FontWeight.w600)),
                            ),
                            Text(
                              '${slot['start_time']?.toString().substring(0, 5) ?? ''} – ${slot['end_time']?.toString().substring(0, 5) ?? ''}',
                              style: adminMetadata(),
                            ),
                            const Spacer(),
                            Text('Emergency slots:', style: adminBodyText()),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                controller: controller,
                                style: adminMetadata()
                                    .copyWith(color: adminTextHeading),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: adminBgSubtle,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide:
                                        const BorderSide(color: adminBorderLight),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide:
                                        const BorderSide(color: adminBorderLight),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide:
                                        const BorderSide(color: adminAccent),
                                  ),
                                ),
                                onFieldSubmitted: (_) => _saveSlot(slotId),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _saveSlot(slotId),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: adminAccentTint,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: adminAccent.withValues(alpha: 0.3)),
                                ),
                                child: const Icon(Icons.save_outlined,
                                    size: 14, color: adminAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Shared dialog helpers ────────────────────────────────────────────────────

Widget _dialogField({required Widget child}) => child;

InputDecoration _inputDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: adminBodyText(),
    hintStyle: adminBodyText().copyWith(color: adminTextMuted),
    filled: true,
    fillColor: adminBgSubtle,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: adminBorderLight)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: adminBorderLight)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: adminAccent)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}

Widget _switchRow(String title, bool value, ValueChanged<bool> onChanged) {
  return Row(
    children: [
      Expanded(child: Text(title, style: adminBodyText())),
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

Widget _dialogDropdown<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: adminBodyText()),
      const SizedBox(height: 6),
      Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: adminBgSubtle,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: adminBorderLight),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            style: adminBodyText(),
            dropdownColor: adminBgSurface,
            icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: adminTextBody),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}

Future<bool?> _confirmDelete(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: adminBgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: adminBorderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confirm Delete', style: adminSectionHeading()),
              const SizedBox(height: 12),
              Text(message, style: adminBodyText()),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  adminSecondaryButton(
                      label: 'Cancel', onTap: () => Navigator.pop(ctx, false)),
                  const SizedBox(width: 8),
                  adminDangerButton(
                      label: 'Delete', onTap: () => Navigator.pop(ctx, true)),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
