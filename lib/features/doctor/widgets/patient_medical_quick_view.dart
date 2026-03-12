import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signup/core/constants/colors.dart';
import 'package:signup/features/doctor/services/patient_medical_records_service.dart';

/// Comprehensive Patient Medical Records Quick View Widget
///
/// Displays complete patient medical information for doctors during consultations:
/// - Patient demographics and critical alerts
/// - Allergies and chronic conditions
/// - Current medications
/// - Medical history timeline
/// - Previous appointments and notes
/// - Emergency contacts
/// - Insurance information
class PatientMedicalQuickView extends StatefulWidget {
  final String patientId;
  final bool showFullDetails;

  const PatientMedicalQuickView({
    super.key,
    required this.patientId,
    this.showFullDetails = true,
  });

  @override
  State<PatientMedicalQuickView> createState() => _PatientMedicalQuickViewState();
}

class _PatientMedicalQuickViewState extends State<PatientMedicalQuickView> {
  final PatientMedicalRecordsService _recordsService = PatientMedicalRecordsService();

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _patientSummary;
  List<Map<String, String>>? _criticalAlerts;
  Map<String, dynamic>? _fullRecord;
  List<Map<String, dynamic>>? _timeline;

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _recordsService.getPatientSummary(widget.patientId),
        _recordsService.getCriticalAlerts(widget.patientId),
        if (widget.showFullDetails) _recordsService.getPatientMedicalRecord(widget.patientId),
        if (widget.showFullDetails) _recordsService.getPatientTimeline(widget.patientId),
      ]);

      if (!mounted) return;

      setState(() {
        _patientSummary = results[0] as Map<String, dynamic>;
        _criticalAlerts = results[1] as List<Map<String, String>>;
        if (widget.showFullDetails && results.length > 2) {
          _fullRecord = results[2] as Map<String, dynamic>;
          _timeline = results[3] as List<Map<String, dynamic>>;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load patient data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatientData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return widget.showFullDetails ? _buildFullView() : _buildSummaryView();
  }

  Widget _buildFullView() {
    return Column(
      children: [
        // Critical Alerts Banner
        if (_criticalAlerts != null && _criticalAlerts!.isNotEmpty)
          _buildCriticalAlertsBanner(),

        // Patient Summary Header
        _buildPatientHeader(),

        const SizedBox(height: 16),

        // Tab Navigation
        _buildTabNavigation(),

        const SizedBox(height: 16),

        // Tab Content
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildSummaryView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Critical Alerts
        if (_criticalAlerts != null && _criticalAlerts!.isNotEmpty)
          _buildCriticalAlertsBanner(),

        // Patient Summary Card
        _buildPatientSummaryCard(),
      ],
    );
  }

  Widget _buildCriticalAlertsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'CRITICAL ALERTS',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._criticalAlerts!.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  alert['type'] == 'allergy' ? Icons.error : Icons.info_outline,
                  color: alert['severity'] == 'critical' ? Colors.red : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert['message'] ?? '',
                    style: TextStyle(
                      color: alert['severity'] == 'critical' ? Colors.red.shade900 : Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPatientHeader() {
    if (_patientSummary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Patient Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              _patientSummary!['name'].toString().split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).take(2).join().toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Patient Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientSummary!['name'] ?? 'Unknown Patient',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_patientSummary!['age']} years • ${_patientSummary!['gender']} • ${_patientSummary!['blood_group']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(Icons.phone, _patientSummary!['phone']),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.email, _patientSummary!['email']),
                  ],
                ),
              ],
            ),
          ),

          // Patient Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatBadge('Recent Visits', _patientSummary!['recent_visits'].toString()),
              const SizedBox(height: 8),
              if (_patientSummary!['no_show_count'] > 0)
                _buildStatBadge('No-Shows', _patientSummary!['no_show_count'].toString(), isWarning: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red.shade700 : AppColors.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isWarning ? Colors.red.shade600 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSummaryCard() {
    if (_patientSummary == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _patientSummary!['name'] ?? 'Unknown Patient',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${_patientSummary!['age']} years • ${_patientSummary!['gender']} • ${_patientSummary!['blood_group']}'),
            const Divider(height: 24),

            // Allergies
            if (_patientSummary!['has_allergies'] == true) ...[
              _buildSectionHeader('⚠️ Allergies', Colors.red),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_patientSummary!['allergies'] as List<String>)
                    .map((allergy) => Chip(
                          label: Text(allergy),
                          backgroundColor: Colors.red.shade50,
                          labelStyle: TextStyle(color: Colors.red.shade700),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Chronic Conditions
            if (_patientSummary!['has_chronic_conditions'] == true) ...[
              _buildSectionHeader('📋 Chronic Conditions', Colors.orange),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_patientSummary!['chronic_conditions'] as List<String>)
                    .map((condition) => Chip(
                          label: Text(condition),
                          backgroundColor: Colors.orange.shade50,
                          labelStyle: TextStyle(color: Colors.orange.shade700),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Medications
            if (_patientSummary!['medications'] != null && (_patientSummary!['medications'] as List).isNotEmpty) ...[
              _buildSectionHeader('💊 Current Medications', Colors.blue),
              const SizedBox(height: 4),
              ...(_patientSummary!['medications'] as List<String>).map((med) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(med),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    final tabs = ['Overview', 'History', 'Timeline', 'Documents', 'Contacts'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = _selectedTabIndex == index;

          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildHistoryTab();
      case 2:
        return _buildTimelineTab();
      case 3:
        return _buildDocumentsTab();
      case 4:
        return _buildContactsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab() {
    if (_patientSummary == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Allergies',
                  _patientSummary!['has_allergies'] == true
                      ? (_patientSummary!['allergies'] as List).length.toString()
                      : '0',
                  Icons.warning_amber,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Conditions',
                  _patientSummary!['has_chronic_conditions'] == true
                      ? (_patientSummary!['chronic_conditions'] as List).length.toString()
                      : '0',
                  Icons.local_hospital,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Medications',
                  (_patientSummary!['medications'] as List? ?? []).length.toString(),
                  Icons.medication,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Detailed Lists
          if (_patientSummary!['has_allergies'] == true) ...[
            _buildSectionHeader('⚠️ Allergies', Colors.red),
            const SizedBox(height: 8),
            ..._buildListItems(_patientSummary!['allergies'] as List<String>, Colors.red),
            const SizedBox(height: 16),
          ],

          if (_patientSummary!['has_chronic_conditions'] == true) ...[
            _buildSectionHeader('📋 Chronic Conditions', Colors.orange),
            const SizedBox(height: 8),
            ..._buildListItems(_patientSummary!['chronic_conditions'] as List<String>, Colors.orange),
            const SizedBox(height: 16),
          ],

          if (_patientSummary!['medications'] != null && (_patientSummary!['medications'] as List).isNotEmpty) ...[
            _buildSectionHeader('💊 Current Medications', Colors.blue),
            const SizedBox(height: 8),
            ..._buildListItems(_patientSummary!['medications'] as List<String>, Colors.blue),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildListItems(List<String> items, Color color) {
    return items.map((item) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(item)),
        ],
      ),
    )).toList();
  }

  Widget _buildHistoryTab() {
    final medicalHistory = _fullRecord?['medical_history'] as List<Map<String, dynamic>>? ?? [];

    if (medicalHistory.isEmpty) {
      return const Center(child: Text('No medical history recorded'));
    }

    return ListView.builder(
      itemCount: medicalHistory.length,
      itemBuilder: (context, index) {
        final history = medicalHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (history['chronic_conditions'] != null && history['chronic_conditions'].toString().isNotEmpty) ...[
                  const Text('Chronic Conditions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(history['chronic_conditions']),
                  const SizedBox(height: 12),
                ],
                if (history['current_medications'] != null && history['current_medications'].toString().isNotEmpty) ...[
                  const Text('Current Medications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(history['current_medications']),
                  const SizedBox(height: 12),
                ],
                if (history['past_surgeries'] != null && history['past_surgeries'].toString().isNotEmpty) ...[
                  const Text('Past Surgeries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(history['past_surgeries']),
                  const SizedBox(height: 12),
                ],
                if (history['family_history'] != null && history['family_history'].toString().isNotEmpty) ...[
                  const Text('Family History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(history['family_history']),
                  const SizedBox(height: 12),
                ],
                if (history['lifestyle_habits'] != null && history['lifestyle_habits'].toString().isNotEmpty) ...[
                  const Text('Lifestyle Habits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(history['lifestyle_habits']),
                ],
                if (history['updated_at'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Updated: ${_formatDate(history['updated_at'])}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineTab() {
    if (_timeline == null || _timeline!.isEmpty) {
      return const Center(child: Text('No timeline data available'));
    }

    return ListView.builder(
      itemCount: _timeline!.length,
      itemBuilder: (context, index) {
        final item = _timeline![index];
        final isAppointment = item['type'] == 'appointment';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAppointment ? AppColors.primary : Colors.orange,
                    child: Icon(
                      isAppointment ? Icons.event : Icons.medical_services,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  if (index < _timeline!.length - 1)
                    Container(
                      width: 2,
                      height: 60,
                      color: Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Timeline content
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatDate(item['date']),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item['description'] ?? ''),
                        if (item['notes'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Notes: ${item['notes']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (isAppointment && item['doctor'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Doctor: ${item['doctor']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentsTab() {
    final documents = _fullRecord?['documents'] as List<Map<String, dynamic>>? ?? [];

    if (documents.isEmpty) {
      return const Center(child: Text('No documents uploaded'));
    }

    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Icon(Icons.description, color: AppColors.primary),
            ),
            title: Text(doc['file_name'] ?? 'Unknown Document'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${doc['document_type'] ?? 'Unknown'}'),
                Text('Uploaded: ${_formatDate(doc['created_at'])}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                // TODO: Implement document viewer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document viewer not yet implemented')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactsTab() {
    final basicInfo = _fullRecord?['basic_info'] as Map<String, dynamic>?;
    final emergencyContacts = _fullRecord?['emergency_contacts'] as List<Map<String, dynamic>>? ?? [];
    final insurance = _fullRecord?['insurance'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Contact
          _buildSectionHeader('Patient Contact', AppColors.primary),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildContactRow(Icons.phone, 'Phone', basicInfo?['phone'] ?? 'N/A'),
                  const Divider(),
                  _buildContactRow(Icons.email, 'Email', basicInfo?['users']?['email'] ?? 'N/A'),
                  const Divider(),
                  _buildContactRow(Icons.location_on, 'Address', basicInfo?['address'] ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Emergency Contacts
          _buildSectionHeader('Emergency Contacts', Colors.red),
          const SizedBox(height: 8),
          if (emergencyContacts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No emergency contacts registered'),
              ),
            )
          else
            ...emergencyContacts.map((contact) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          contact['contact_name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (contact['is_primary'] == true)
                          Chip(
                            label: const Text('PRIMARY', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.red.shade100,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildContactRow(Icons.family_restroom, 'Relationship', contact['relationship'] ?? 'N/A'),
                    const Divider(),
                    _buildContactRow(Icons.phone, 'Phone', contact['phone'] ?? 'N/A'),
                    if (contact['email'] != null) ...[
                      const Divider(),
                      _buildContactRow(Icons.email, 'Email', contact['email']),
                    ],
                  ],
                ),
              ),
            )),
          const SizedBox(height: 20),

          // Insurance
          _buildSectionHeader('Insurance Information', Colors.blue),
          const SizedBox(height: 8),
          if (insurance == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No insurance information on file'),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildContactRow(Icons.business, 'Provider', insurance['provider_name'] ?? 'N/A'),
                    const Divider(),
                    _buildContactRow(Icons.badge, 'Policy Number', insurance['policy_number'] ?? 'N/A'),
                    const Divider(),
                    _buildContactRow(Icons.group, 'Group Number', insurance['group_number'] ?? 'N/A'),
                    const Divider(),
                    _buildContactRow(Icons.category, 'Coverage Type', insurance['coverage_type'] ?? 'N/A'),
                    const Divider(),
                    _buildContactRow(
                      Icons.calendar_today,
                      'Expiry Date',
                      insurance['expiry_date'] != null ? _formatDate(insurance['expiry_date']) : 'N/A',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
