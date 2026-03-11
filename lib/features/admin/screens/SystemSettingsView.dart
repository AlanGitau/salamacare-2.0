import 'package:flutter/material.dart';
import 'package:signup/features/admin/admin_theme.dart';
import 'package:signup/features/admin/services/settings_service.dart';

class SystemSettingsView extends StatefulWidget {
  const SystemSettingsView({super.key});

  @override
  State<SystemSettingsView> createState() => _SystemSettingsViewState();
}

class _SystemSettingsViewState extends State<SystemSettingsView> {
  final _settingsService = SettingsService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  final _clinicNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _openingTimeController = TextEditingController();
  final _closingTimeController = TextEditingController();
  final _cancellationPolicyController = TextEditingController();

  int _slotDuration = 30;
  int _maxAdvanceBookingDays = 90;
  bool _onlineBookingEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  List<String> _operatingDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  final List<String> _allDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _cancellationPolicyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _settingsService.getClinicSettings();

      if (mounted) {
        setState(() {
          if (settings != null) {
            _clinicNameController.text = settings['clinic_name'] ?? '';
            _addressController.text = settings['address'] ?? '';
            _phoneController.text = settings['phone'] ?? '';
            _emailController.text = settings['email'] ?? '';
            _openingTimeController.text = settings['opening_time'] ?? '08:00';
            _closingTimeController.text = settings['closing_time'] ?? '18:00';
            _cancellationPolicyController.text = settings['cancellation_policy'] ?? '';
            _slotDuration = settings['default_slot_duration'] ?? 30;
            _maxAdvanceBookingDays = settings['max_advance_booking_days'] ?? 90;
            _onlineBookingEnabled = settings['online_booking_enabled'] ?? true;
            if (settings['operating_days'] != null) {
              _operatingDays = List<String>.from(settings['operating_days']);
            }
            final notifications = settings['notification_settings'] ?? {};
            _emailNotifications = notifications['email'] ?? true;
            _smsNotifications = notifications['sms'] ?? false;
            _pushNotifications = notifications['push'] ?? true;
          } else {
            final defaults = _settingsService.getDefaultSettings();
            _clinicNameController.text = defaults['clinic_name'];
            _openingTimeController.text = defaults['opening_time'];
            _closingTimeController.text = defaults['closing_time'];
            _cancellationPolicyController.text = defaults['cancellation_policy'];
          }
          _isLoading = false;
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e',
                style: adminBodyText().copyWith(color: Colors.white)),
            backgroundColor: adminDanger,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final result = await _settingsService.updateClinicSettings({
        'clinic_name': _clinicNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'opening_time': _openingTimeController.text.trim(),
        'closing_time': _closingTimeController.text.trim(),
        'operating_days': _operatingDays,
        'default_slot_duration': _slotDuration,
        'max_advance_booking_days': _maxAdvanceBookingDays,
        'online_booking_enabled': _onlineBookingEnabled,
        'cancellation_policy': _cancellationPolicyController.text.trim(),
        'notification_settings': {
          'email': _emailNotifications,
          'sms': _smsNotifications,
          'push': _pushNotifications,
        },
      });

      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'],
                style: adminBodyText().copyWith(color: Colors.white)),
            backgroundColor: result['success'] ? adminSuccess : adminDanger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e',
                style: adminBodyText().copyWith(color: Colors.white)),
            backgroundColor: adminDanger,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: adminBgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: adminBorderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset to Defaults', style: adminSectionHeading()),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to reset all settings to their default values?',
                  style: adminBodyText(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    adminSecondaryButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context, false),
                    ),
                    const SizedBox(width: 8),
                    adminDangerButton(
                      label: 'Reset',
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      final result = await _settingsService.resetToDefaults();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'],
                style: adminBodyText().copyWith(color: Colors.white)),
            backgroundColor: result['success'] ? adminSuccess : adminDanger,
          ),
        );
        if (result['success']) _loadSettings();
      }
    }
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final initial = TimeOfDay(
      hour: int.tryParse(controller.text.split(':')[0]) ?? 8,
      minute: int.tryParse(controller.text.split(':')[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: adminAccent),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (controller == _closingTimeController) {
        final openParts = _openingTimeController.text.split(':');
        final openMinutes = (int.tryParse(openParts[0]) ?? 0) * 60 +
            (int.tryParse(openParts.length > 1 ? openParts[1] : '0') ?? 0);
        if (picked.hour * 60 + picked.minute <= openMinutes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Closing time must be after opening time',
                    style: adminBodyText().copyWith(color: Colors.white)),
                backgroundColor: adminDanger,
              ),
            );
          }
          return;
        }
      } else if (controller == _openingTimeController) {
        final closeParts = _closingTimeController.text.split(':');
        final closeMinutes = (int.tryParse(closeParts[0]) ?? 23) * 60 +
            (int.tryParse(closeParts.length > 1 ? closeParts[1] : '0') ?? 0);
        if (picked.hour * 60 + picked.minute >= closeMinutes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening time must be before closing time',
                    style: adminBodyText().copyWith(color: Colors.white)),
                backgroundColor: adminDanger,
              ),
            );
          }
          return;
        }
      }

      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _markChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: adminBgCanvas,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: adminAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                onChanged: _markChanged,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildClinicInfoSection(),
                              const SizedBox(height: 24),
                              _buildOperatingHoursSection(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              _buildBookingSettingsSection(),
                              const SizedBox(height: 24),
                              _buildNotificationSettingsSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildCancellationPolicySection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('System Settings', style: adminPageTitle()),
        const Spacer(),
        if (_hasChanges) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: adminWarningTint,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: adminWarning.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_outlined, size: 14, color: adminWarning),
                const SizedBox(width: 4),
                Text('Unsaved changes',
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: adminWarning)),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
        adminSecondaryButton(
          label: 'Reset to Defaults',
          icon: Icons.restore_outlined,
          onTap: _resetToDefaults,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isSaving ? null : _saveSettings,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _isSaving ? adminBorderLight : adminAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSaving)
                  const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                else
                  const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  _isSaving ? 'Saving...' : 'Save Settings',
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
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
          Row(
            children: [
              Icon(icon, size: 18, color: adminAccent),
              const SizedBox(width: 8),
              Text(title, style: adminSectionHeading()),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildClinicInfoSection() {
    return _sectionCard(
      title: 'Clinic Information',
      icon: Icons.business_outlined,
      child: Column(
        children: [
          _adminTextField(
            controller: _clinicNameController,
            label: 'Clinic Name',
            icon: Icons.local_hospital_outlined,
            validator: (v) => v == null || v.isEmpty ? 'Please enter clinic name' : null,
          ),
          const SizedBox(height: 16),
          _adminTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _adminTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _adminTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHoursSection() {
    return _sectionCard(
      title: 'Operating Hours',
      icon: Icons.schedule_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _adminTextField(
                  controller: _openingTimeController,
                  label: 'Opening Time',
                  icon: Icons.access_time_outlined,
                  readOnly: true,
                  onTap: () => _selectTime(_openingTimeController),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _adminTextField(
                  controller: _closingTimeController,
                  label: 'Closing Time',
                  icon: Icons.access_time_outlined,
                  readOnly: true,
                  onTap: () => _selectTime(_closingTimeController),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Operating Days',
              style: adminBodyText().copyWith(fontWeight: FontWeight.w600, color: adminTextHeading)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allDays.map((day) {
              final isSelected = _operatingDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _operatingDays.remove(day);
                    } else {
                      _operatingDays.add(day);
                      _operatingDays.sort(
                          (a, b) => _allDays.indexOf(a).compareTo(_allDays.indexOf(b)));
                    }
                  });
                  _markChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? adminAccentTint : adminBgSubtle,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: isSelected ? adminAccent : adminBorderLight),
                  ),
                  child: Text(
                    day.substring(0, 3),
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? adminAccent : adminTextBody,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSettingsSection() {
    return _sectionCard(
      title: 'Booking Settings',
      icon: Icons.event_available_outlined,
      child: Column(
        children: [
          _adminSwitch(
            title: 'Online Booking',
            subtitle: 'Allow patients to book appointments online',
            value: _onlineBookingEnabled,
            onChanged: (v) {
              setState(() => _onlineBookingEnabled = v);
              _markChanged();
            },
          ),
          const Divider(color: adminBorderLight, height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Default Slot Duration', style: adminBodyText().copyWith(fontWeight: FontWeight.w600)),
                    Text('Minutes per appointment', style: adminMetadata()),
                  ],
                ),
              ),
              _adminInlineDropdown<int>(
                value: _slotDuration,
                items: [15, 20, 30, 45, 60]
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d min', style: adminBodyText())))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _slotDuration = v);
                    _markChanged();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Max Advance Booking', style: adminBodyText().copyWith(fontWeight: FontWeight.w600)),
                    Text('Days patients can book ahead', style: adminMetadata()),
                  ],
                ),
              ),
              _adminInlineDropdown<int>(
                value: _maxAdvanceBookingDays,
                items: [30, 60, 90, 120, 180]
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d days', style: adminBodyText())))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _maxAdvanceBookingDays = v);
                    _markChanged();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsSection() {
    return _sectionCard(
      title: 'Notification Preferences',
      icon: Icons.notifications_outlined,
      child: Column(
        children: [
          _adminSwitch(
            title: 'Email Notifications',
            subtitle: 'Send appointment reminders via email',
            value: _emailNotifications,
            onChanged: (v) {
              setState(() => _emailNotifications = v);
              _markChanged();
            },
          ),
          const Divider(color: adminBorderLight, height: 24),
          _adminSwitch(
            title: 'SMS Notifications',
            subtitle: 'Send appointment reminders via SMS',
            value: _smsNotifications,
            onChanged: (v) {
              setState(() => _smsNotifications = v);
              _markChanged();
            },
          ),
          const Divider(color: adminBorderLight, height: 24),
          _adminSwitch(
            title: 'Push Notifications',
            subtitle: 'Send in-app push notifications',
            value: _pushNotifications,
            onChanged: (v) {
              setState(() => _pushNotifications = v);
              _markChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationPolicySection() {
    return _sectionCard(
      title: 'Cancellation Policy',
      icon: Icons.policy_outlined,
      child: TextFormField(
        controller: _cancellationPolicyController,
        style: adminBodyText(),
        maxLines: 4,
        decoration: InputDecoration(
          hintText: "Enter your clinic's cancellation policy...",
          hintStyle: adminBodyText().copyWith(color: adminTextMuted),
          filled: true,
          fillColor: adminBgSubtle,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: adminBorderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: adminBorderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: adminAccent),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  // ── Reusable field helpers ────────────────────────────────────────────────

  Widget _adminTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      style: adminBodyText(),
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: adminBodyText(),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: adminTextBody) : null,
        filled: true,
        fillColor: adminBgSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: adminBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: adminBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: adminAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: adminDanger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _adminSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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

  Widget _adminInlineDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
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
          style: adminBodyText(),
          dropdownColor: adminBgSurface,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: adminTextBody),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
