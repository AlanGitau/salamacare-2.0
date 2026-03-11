import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/appointment_config_service.dart';
import 'package:signup/features/admin/widgets/color_picker_field.dart';
import 'package:intl/intl.dart';

// ─── File-scope helpers ───────────────────────────────────────────────────────

InputDecoration _adminInputDec(String label, {String? hint, String? suffixText, Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label.isEmpty ? null : label,
    hintText: hint,
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    labelStyle: adminMetadata(),
    hintStyle: adminMetadata(),
    filled: true,
    fillColor: adminBgSubtle,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: adminBorderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: adminBorderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: adminAccent, width: 1.5),
    ),
  );
}

Future<bool> _confirmDeleteConfig(
    BuildContext context, String title, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: adminBgSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded, color: adminDanger, size: 20),
              const SizedBox(width: 10),
              Text(title, style: adminSectionHeading()),
            ]),
            const SizedBox(height: 14),
            Text(message, style: adminBodyText()),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                adminSecondaryButton(
                    label: 'Cancel', onTap: () => Navigator.pop(ctx, false)),
                const SizedBox(width: 10),
                adminDangerButton(
                    label: 'Delete', onTap: () => Navigator.pop(ctx, true)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result == true;
}

// ─── Root widget ──────────────────────────────────────────────────────────────

class AppointmentConfigView extends StatefulWidget {
  const AppointmentConfigView({super.key});

  @override
  State<AppointmentConfigView> createState() => _AppointmentConfigViewState();
}

class _AppointmentConfigViewState extends State<AppointmentConfigView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _configService = AppointmentConfigService();

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
          // Header bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            decoration: const BoxDecoration(
              color: adminBgSurface,
              border: Border(bottom: BorderSide(color: adminBorderLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appointment Configuration', style: adminPageTitle()),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: adminAccent,
                  unselectedLabelColor: adminTextBody,
                  indicatorColor: adminAccent,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: const [
                    Tab(text: 'Appointment Types'),
                    Tab(text: 'Recurring Templates'),
                    Tab(text: 'Booking Rules'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AppointmentTypesTab(configService: _configService),
                _RecurringTemplatesTab(configService: _configService),
                _BookingRulesTab(configService: _configService),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Appointment Types Tab ────────────────────────────────────────────────────

class _AppointmentTypesTab extends StatefulWidget {
  final AppointmentConfigService configService;
  const _AppointmentTypesTab({required this.configService});

  @override
  State<_AppointmentTypesTab> createState() => _AppointmentTypesTabState();
}

class _AppointmentTypesTabState extends State<_AppointmentTypesTab> {
  List<Map<String, dynamic>> _types = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() => _isLoading = true);
    final types = await widget.configService.getAppointmentTypes();
    if (mounted) {
      setState(() {
        _types = types;
        _isLoading = false;
      });
    }
  }

  Future<void> _showTypeDialog({Map<String, dynamic>? existing}) async {
    final nameController =
        TextEditingController(text: existing?['name'] ?? '');
    final descController =
        TextEditingController(text: existing?['description'] ?? '');
    final durationController = TextEditingController(
      text: (existing?['default_duration'] ?? 30).toString(),
    );
    final priceController = TextEditingController(
      text: existing?['price']?.toString() ?? '',
    );
    Color selectedColor = existing?['color'] != null
        ? Color(int.parse(existing!['color'].replaceFirst('#', '0xFF')))
        : adminAccent;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: adminBgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: adminBorderLight)),
                  ),
                  child: Row(children: [
                    Text(
                      existing != null
                          ? 'Edit Appointment Type'
                          : 'Add Appointment Type',
                      style: adminSectionHeading(),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: const Icon(Icons.close,
                          size: 18, color: adminTextMuted),
                    ),
                  ]),
                ),
                // Dialog body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: _adminInputDec('Name *',
                              hint: 'e.g., Initial Consultation'),
                          style: adminBodyText(),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: descController,
                          decoration: _adminInputDec('Description',
                              hint:
                                  'Brief description of this appointment type'),
                          style: adminBodyText(),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: durationController,
                              decoration:
                                  _adminInputDec('Duration (minutes) *'),
                              style: adminBodyText(),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              decoration: _adminInputDec('Price (KES)'),
                              style: adminBodyText(),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        ColorPickerField(
                          selectedColor: selectedColor,
                          onColorSelected: (color) {
                            setDialogState(() => selectedColor = color);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Dialog footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: adminBorderLight)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      adminSecondaryButton(
                        label: 'Cancel',
                        onTap: () => Navigator.pop(context, false),
                      ),
                      const SizedBox(width: 10),
                      adminPrimaryButton(
                        label: existing != null ? 'Update' : 'Create',
                        onTap: () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Name is required'),
                                backgroundColor: adminDanger,
                              ),
                            );
                            return;
                          }
                          final colorHex =
                              '#${selectedColor.toARGB32().toRadixString(16).substring(2)}';
                          Map<String, dynamic> saveResult;
                          if (existing != null) {
                            saveResult = await widget.configService
                                .updateAppointmentType(existing['id'], {
                              'name': nameController.text.trim(),
                              'description':
                                  descController.text.trim().isEmpty
                                      ? null
                                      : descController.text.trim(),
                              'default_duration':
                                  int.tryParse(durationController.text) ?? 30,
                              'price':
                                  double.tryParse(priceController.text),
                              'color': colorHex,
                            });
                          } else {
                            saveResult = await widget.configService
                                .createAppointmentType(
                              name: nameController.text.trim(),
                              description:
                                  descController.text.trim().isEmpty
                                      ? null
                                      : descController.text.trim(),
                              defaultDuration:
                                  int.tryParse(durationController.text) ?? 30,
                              price: double.tryParse(priceController.text),
                              color: colorHex,
                            );
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(saveResult['message']),
                                backgroundColor: saveResult['success']
                                    ? adminSuccess
                                    : adminDanger,
                              ),
                            );
                            Navigator.pop(context, saveResult['success']);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) _loadTypes();
  }

  Future<void> _deleteType(Map<String, dynamic> type) async {
    final confirmed = await _confirmDeleteConfig(
      context,
      'Delete Appointment Type',
      'Are you sure you want to delete "${type['name']}"?',
    );
    if (confirmed) {
      final result =
          await widget.configService.deleteAppointmentType(type['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? adminSuccess : adminDanger,
          ),
        );
        if (result['success']) _loadTypes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_types.length} appointment types', style: adminMetadata()),
              adminPrimaryButton(
                label: 'Add Type',
                icon: Icons.add,
                onTap: () => _showTypeDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _types.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_note,
                            size: 48, color: adminBorderLight),
                        const SizedBox(height: 16),
                        Text('No appointment types configured',
                            style: adminBodyText()),
                        const SizedBox(height: 6),
                        Text(
                          'Add appointment types to categorize bookings',
                          style: adminMetadata(),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _types.length,
                    itemBuilder: (context, index) {
                      final type = _types[index];
                      final color = type['color'] != null
                          ? Color(int.parse(
                              type['color'].replaceFirst('#', '0xFF')))
                          : adminAccent;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: adminBgSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: adminBorderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type['name'] ?? '',
                                    style: adminBodyText().copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: adminTextHeading,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${type['default_duration'] ?? 30} min'
                                    '${type['price'] != null ? ' · KES ${type['price']}' : ''}',
                                    style: adminMetadata(),
                                  ),
                                ],
                              ),
                            ),
                            if (type['description'] != null) ...[
                              Tooltip(
                                message: type['description'],
                                child: const Icon(Icons.info_outline,
                                    size: 16, color: adminTextMuted),
                              ),
                              const SizedBox(width: 8),
                            ],
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 16, color: adminTextBody),
                              onPressed: () => _showTypeDialog(existing: type),
                              tooltip: 'Edit',
                              splashRadius: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 16, color: adminDanger),
                              onPressed: () => _deleteType(type),
                              tooltip: 'Delete',
                              splashRadius: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Recurring Templates Tab ──────────────────────────────────────────────────

class _RecurringTemplatesTab extends StatefulWidget {
  final AppointmentConfigService configService;
  const _RecurringTemplatesTab({required this.configService});

  @override
  State<_RecurringTemplatesTab> createState() => _RecurringTemplatesTabState();
}

class _RecurringTemplatesTabState extends State<_RecurringTemplatesTab> {
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _appointmentTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      widget.configService.getRecurringTemplates(),
      widget.configService.getDoctorsForPicker(),
      widget.configService.getPatientsForPicker(),
      widget.configService.getAppointmentTypes(),
    ]);
    if (mounted) {
      setState(() {
        _templates = results[0];
        _doctors = results[1];
        _patients = results[2];
        _appointmentTypes = results[3];
        _isLoading = false;
      });
    }
  }

  Future<void> _showTemplateDialog({Map<String, dynamic>? existing}) async {
    String? selectedDoctorId = existing?['doctor_id'];
    String? selectedPatientId = existing?['patient_id'];
    String? selectedTypeId = existing?['appointment_type_id'];
    String selectedDay = existing?['day_of_week'] ?? 'Monday';
    TimeOfDay selectedTime = existing?['time_of_day'] != null
        ? TimeOfDay(
            hour: int.parse(existing!['time_of_day'].split(':')[0]),
            minute: int.parse(existing['time_of_day'].split(':')[1]),
          )
        : const TimeOfDay(hour: 9, minute: 0);
    String selectedFrequency = existing?['frequency'] ?? 'weekly';
    final durationController = TextEditingController(
      text: (existing?['duration'] ?? 30).toString(),
    );
    final notesController =
        TextEditingController(text: existing?['notes'] ?? '');
    DateTime startDate = existing?['start_date'] != null
        ? DateTime.parse(existing!['start_date'])
        : DateTime.now();
    DateTime? endDate = existing?['end_date'] != null
        ? DateTime.parse(existing!['end_date'])
        : null;

    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const frequencies = ['weekly', 'biweekly', 'monthly'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            width: 540,
            constraints: const BoxConstraints(maxHeight: 640),
            decoration: BoxDecoration(
              color: adminBgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: adminBorderLight)),
                  ),
                  child: Row(children: [
                    Text(
                      existing != null
                          ? 'Edit Recurring Template'
                          : 'Add Recurring Template',
                      style: adminSectionHeading(),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: const Icon(Icons.close,
                          size: 18, color: adminTextMuted),
                    ),
                  ]),
                ),
                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedDoctorId,
                          decoration: _adminInputDec('Doctor *'),
                          style: adminBodyText(),
                          dropdownColor: adminBgSurface,
                          items: _doctors
                              .map((d) => DropdownMenuItem(
                                    value: d['id'] as String,
                                    child: Text(
                                        'Dr. ${d['first_name']} ${d['last_name']}'),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedDoctorId = v),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedPatientId,
                          decoration: _adminInputDec('Patient *'),
                          style: adminBodyText(),
                          dropdownColor: adminBgSurface,
                          items: _patients
                              .map((p) => DropdownMenuItem(
                                    value: p['id'] as String,
                                    child: Text(
                                        '${p['first_name']} ${p['last_name']}'),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedPatientId = v),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: selectedTypeId,
                          decoration: _adminInputDec('Appointment Type'),
                          style: adminBodyText(),
                          dropdownColor: adminBgSurface,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('None')),
                            ..._appointmentTypes.map((t) => DropdownMenuItem(
                                  value: t['id'] as String,
                                  child: Text(t['name']),
                                )),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => selectedTypeId = v),
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedDay,
                              decoration: _adminInputDec('Day of Week *'),
                              style: adminBodyText(),
                              dropdownColor: adminBgSurface,
                              items: days
                                  .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => selectedDay = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(
                                      colorScheme: const ColorScheme.light(
                                          primary: adminAccent),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (time != null) {
                                  setDialogState(() => selectedTime = time);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: adminBgSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: adminBorderLight),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Time *', style: adminMetadata()),
                                    Text(selectedTime.format(context),
                                        style: adminBodyText()),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedFrequency,
                              decoration: _adminInputDec('Frequency *'),
                              style: adminBodyText(),
                              dropdownColor: adminBgSurface,
                              items: frequencies
                                  .map((f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f[0].toUpperCase() +
                                            f.substring(1)),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => selectedFrequency = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: durationController,
                              decoration: _adminInputDec('Duration (min)'),
                              style: adminBodyText(),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(
                                      colorScheme: const ColorScheme.light(
                                          primary: adminAccent),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (date != null) {
                                  setDialogState(() => startDate = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: adminBgSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: adminBorderLight),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Start Date *',
                                        style: adminMetadata()),
                                    Text(
                                        DateFormat('MMM dd, yyyy')
                                            .format(startDate),
                                        style: adminBodyText()),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ??
                                      startDate
                                          .add(const Duration(days: 90)),
                                  firstDate: startDate,
                                  lastDate: DateTime(2030),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(
                                      colorScheme: const ColorScheme.light(
                                          primary: adminAccent),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (date != null) {
                                  setDialogState(() => endDate = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: adminBgSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: adminBorderLight),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('End Date', style: adminMetadata()),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          endDate != null
                                              ? DateFormat('MMM dd, yyyy')
                                                  .format(endDate!)
                                              : 'Optional',
                                          style: adminBodyText().copyWith(
                                            color: endDate != null
                                                ? adminTextBody
                                                : adminTextMuted,
                                          ),
                                        ),
                                        if (endDate != null) ...[
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () => setDialogState(
                                                () => endDate = null),
                                            child: const Icon(Icons.close,
                                                size: 14,
                                                color: adminTextMuted),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        TextField(
                          controller: notesController,
                          decoration: _adminInputDec('Notes'),
                          style: adminBodyText(),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: adminBorderLight)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      adminSecondaryButton(
                        label: 'Cancel',
                        onTap: () => Navigator.pop(context, false),
                      ),
                      const SizedBox(width: 10),
                      adminPrimaryButton(
                        label: existing != null ? 'Update' : 'Create',
                        onTap: () async {
                          if (selectedDoctorId == null ||
                              selectedPatientId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Doctor and Patient are required'),
                                backgroundColor: adminDanger,
                              ),
                            );
                            return;
                          }
                          final timeStr =
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                          Map<String, dynamic> saveResult;
                          if (existing != null) {
                            saveResult = await widget.configService
                                .updateRecurringTemplate(existing['id'], {
                              'doctor_id': selectedDoctorId,
                              'patient_id': selectedPatientId,
                              'appointment_type_id': selectedTypeId,
                              'day_of_week': selectedDay,
                              'time_of_day': timeStr,
                              'duration':
                                  int.tryParse(durationController.text) ?? 30,
                              'frequency': selectedFrequency,
                              'start_date':
                                  startDate.toIso8601String().split('T')[0],
                              'end_date':
                                  endDate?.toIso8601String().split('T')[0],
                              'notes': notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            });
                          } else {
                            saveResult = await widget.configService
                                .createRecurringTemplate(
                              doctorId: selectedDoctorId!,
                              patientId: selectedPatientId!,
                              appointmentTypeId: selectedTypeId,
                              dayOfWeek: selectedDay,
                              timeOfDay: timeStr,
                              duration:
                                  int.tryParse(durationController.text) ?? 30,
                              frequency: selectedFrequency,
                              startDate: startDate,
                              endDate: endDate,
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(saveResult['message']),
                                backgroundColor: saveResult['success']
                                    ? adminSuccess
                                    : adminDanger,
                              ),
                            );
                            Navigator.pop(context, saveResult['success']);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) _loadData();
  }

  Future<void> _deleteTemplate(Map<String, dynamic> template) async {
    final confirmed = await _confirmDeleteConfig(
      context,
      'Delete Recurring Template',
      'Are you sure you want to delete this recurring template?',
    );
    if (confirmed) {
      final result =
          await widget.configService.deleteRecurringTemplate(template['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? adminSuccess : adminDanger,
          ),
        );
        if (result['success']) _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_templates.length} recurring templates',
                  style: adminMetadata()),
              adminPrimaryButton(
                label: 'Add Template',
                icon: Icons.add,
                onTap: () => _showTemplateDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _templates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.repeat,
                            size: 48, color: adminBorderLight),
                        const SizedBox(height: 16),
                        Text('No recurring templates', style: adminBodyText()),
                        const SizedBox(height: 6),
                        Text(
                          'Create templates for patients with regular appointments',
                          style: adminMetadata(),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      final doctor = template['doctors'];
                      final patient = template['patients'];
                      final isActive = template['is_active'] ?? true;

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
                            // Top row: badges + controls
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? adminSuccessTint
                                      : adminBgSubtle,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? adminSuccess
                                        : adminTextMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: adminAccentTint,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  template['frequency']
                                          ?.toString()
                                          .toUpperCase() ??
                                      '',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: adminAccent,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: isActive,
                                onChanged: (v) async {
                                  await widget.configService
                                      .toggleTemplateActive(template['id'], v);
                                  _loadData();
                                },
                                activeColor: adminSuccess,
                                activeTrackColor: adminSuccessTint,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 16, color: adminTextBody),
                                onPressed: () =>
                                    _showTemplateDialog(existing: template),
                                tooltip: 'Edit',
                                splashRadius: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 16, color: adminDanger),
                                onPressed: () => _deleteTemplate(template),
                                tooltip: 'Delete',
                                splashRadius: 16,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            // People row
                            Row(children: [
                              const Icon(Icons.person_outline,
                                  size: 14, color: adminTextMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}',
                                style: adminBodyText()
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.local_hospital_outlined,
                                  size: 14, color: adminTextMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Dr. ${doctor?['first_name'] ?? ''} ${doctor?['last_name'] ?? ''}',
                                style: adminBodyText(),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            // Schedule row
                            Row(children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 13, color: adminTextMuted),
                              const SizedBox(width: 4),
                              Text('${template['day_of_week']}s',
                                  style: adminMetadata()),
                              const SizedBox(width: 14),
                              const Icon(Icons.access_time_outlined,
                                  size: 13, color: adminTextMuted),
                              const SizedBox(width: 4),
                              Text(template['time_of_day'] ?? '',
                                  style: adminMetadata()),
                              const SizedBox(width: 14),
                              const Icon(Icons.timer_outlined,
                                  size: 13, color: adminTextMuted),
                              const SizedBox(width: 4),
                              Text(
                                  '${template['duration'] ?? 30} min',
                                  style: adminMetadata()),
                            ]),
                            if (template['notes'] != null &&
                                template['notes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(template['notes'], style: adminMetadata()),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Booking Rules Tab ────────────────────────────────────────────────────────

class _BookingRulesTab extends StatefulWidget {
  final AppointmentConfigService configService;
  const _BookingRulesTab({required this.configService});

  @override
  State<_BookingRulesTab> createState() => _BookingRulesTabState();
}

class _BookingRulesTabState extends State<_BookingRulesTab> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  late TextEditingController _cancellationDeadlineController;
  late TextEditingController _rescheduleDeadlineController;
  late TextEditingController _maxCancellationsController;
  late TextEditingController _cancellationFeeController;
  late TextEditingController _bufferTimeController;
  late TextEditingController _maxAdvanceController;
  late TextEditingController _slotDurationController;
  bool _allowSameDayBooking = true;

  @override
  void initState() {
    super.initState();
    _cancellationDeadlineController = TextEditingController();
    _rescheduleDeadlineController = TextEditingController();
    _maxCancellationsController = TextEditingController();
    _cancellationFeeController = TextEditingController();
    _bufferTimeController = TextEditingController();
    _maxAdvanceController = TextEditingController();
    _slotDurationController = TextEditingController();
    _loadRules();
  }

  @override
  void dispose() {
    _cancellationDeadlineController.dispose();
    _rescheduleDeadlineController.dispose();
    _maxCancellationsController.dispose();
    _cancellationFeeController.dispose();
    _bufferTimeController.dispose();
    _maxAdvanceController.dispose();
    _slotDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    setState(() => _isLoading = true);
    final rules = await widget.configService.getBookingRules();
    if (mounted) {
      setState(() {
        _cancellationDeadlineController.text =
            (rules['cancellation_deadline_hours'] ?? 24).toString();
        _rescheduleDeadlineController.text =
            (rules['reschedule_deadline_hours'] ?? 12).toString();
        _maxCancellationsController.text =
            (rules['max_cancellations_per_month'] ?? 3).toString();
        _cancellationFeeController.text =
            (rules['cancellation_fee'] ?? 0).toString();
        _bufferTimeController.text =
            (rules['default_appointment_buffer'] ?? 0).toString();
        _maxAdvanceController.text =
            (rules['max_advance_booking_days'] ?? 90).toString();
        _slotDurationController.text =
            (rules['default_slot_duration'] ?? 30).toString();
        _allowSameDayBooking = rules['allow_same_day_booking'] ?? true;
        _isLoading = false;
        _hasChanges = false;
      });
    }
  }

  Future<void> _saveRules() async {
    setState(() => _isSaving = true);
    final result = await widget.configService.updateBookingRules({
      'cancellation_deadline_hours':
          int.tryParse(_cancellationDeadlineController.text) ?? 24,
      'reschedule_deadline_hours':
          int.tryParse(_rescheduleDeadlineController.text) ?? 12,
      'max_cancellations_per_month':
          int.tryParse(_maxCancellationsController.text) ?? 3,
      'cancellation_fee':
          double.tryParse(_cancellationFeeController.text) ?? 0,
      'default_appointment_buffer':
          int.tryParse(_bufferTimeController.text) ?? 0,
      'max_advance_booking_days':
          int.tryParse(_maxAdvanceController.text) ?? 90,
      'default_slot_duration':
          int.tryParse(_slotDurationController.text) ?? 30,
      'allow_same_day_booking': _allowSameDayBooking,
    });
    if (mounted) {
      setState(() {
        _isSaving = false;
        if (result['success']) _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? adminSuccess : adminDanger,
        ),
      );
    }
  }

  Widget _ruleRow({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: adminBodyText()
                        .copyWith(fontWeight: FontWeight.w600, color: adminTextHeading)),
                const SizedBox(height: 2),
                Text(hint, style: adminMetadata()),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                suffixText: suffix,
                suffixStyle: adminMetadata(),
                filled: true,
                fillColor: adminBgSubtle,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: adminBorderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: adminBorderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: adminAccent, width: 1.5),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 14,
                color: adminTextHeading,
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _hasChanges = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unsaved changes banner
          if (_hasChanges)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: adminWarningTint,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: adminWarning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: adminWarning, size: 18),
                  const SizedBox(width: 8),
                  Text('You have unsaved changes', style: adminBodyText()),
                  const Spacer(),
                  adminSecondaryButton(label: 'Discard', onTap: _loadRules),
                  const SizedBox(width: 8),
                  _isSaving
                      ? Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: adminAccent),
                          ),
                        )
                      : adminPrimaryButton(
                          label: 'Save Changes', onTap: _saveRules),
                ],
              ),
            ),

          // Scheduling section
          _sectionCard(
            'Scheduling Settings',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ruleRow(
                  label: 'Default Slot Duration',
                  hint: 'Default appointment length',
                  controller: _slotDurationController,
                  suffix: 'min',
                ),
                _ruleRow(
                  label: 'Buffer Time Between Appointments',
                  hint: 'Gap between consecutive appointments',
                  controller: _bufferTimeController,
                  suffix: 'min',
                ),
                _ruleRow(
                  label: 'Maximum Advance Booking',
                  hint: 'How far in advance patients can book',
                  controller: _maxAdvanceController,
                  suffix: 'days',
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Allow Same-Day Booking',
                                style: adminBodyText().copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: adminTextHeading)),
                            const SizedBox(height: 2),
                            Text(
                                'Let patients book appointments for today',
                                style: adminMetadata()),
                          ],
                        ),
                      ),
                      Switch(
                        value: _allowSameDayBooking,
                        onChanged: (v) => setState(() {
                          _allowSameDayBooking = v;
                          _hasChanges = true;
                        }),
                        activeColor: adminAccent,
                        activeTrackColor: adminAccentTint,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cancellation section
          _sectionCard(
            'Cancellation & Rescheduling Rules',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ruleRow(
                  label: 'Cancellation Deadline',
                  hint: 'Minimum hours before appointment to cancel',
                  controller: _cancellationDeadlineController,
                  suffix: 'hrs',
                ),
                _ruleRow(
                  label: 'Reschedule Deadline',
                  hint:
                      'Minimum hours before appointment to reschedule',
                  controller: _rescheduleDeadlineController,
                  suffix: 'hrs',
                ),
                _ruleRow(
                  label: 'Max Cancellations Per Month',
                  hint:
                      'Maximum number of cancellations per patient per month',
                  controller: _maxCancellationsController,
                ),
                _ruleRow(
                  label: 'Cancellation Fee',
                  hint: 'Fee charged for late cancellations',
                  controller: _cancellationFeeController,
                  suffix: 'KES',
                ),
              ],
            ),
          ),

          // Bottom save button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _isSaving
                ? Container(
                    decoration: BoxDecoration(
                      color: adminAccentTint,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: adminAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: adminAccent),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: _saveRules,
                    child: Container(
                      decoration: BoxDecoration(
                        color: adminAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Save Booking Rules',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
