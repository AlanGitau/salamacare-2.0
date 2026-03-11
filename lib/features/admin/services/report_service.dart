import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Service class for report generation and management
class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get appointment report data
  Future<List<Map<String, dynamic>>> getAppointmentReportData({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? doctorId,
  }) async {
    try {
      var query = _supabase
          .from('appointments')
          .select('''
            id,
            appointment_date,
            status,
            patient_notes,
            patients(first_name, last_name, phone),
            doctors(first_name, last_name, consultation_fee, doctor_specialties(is_primary, specialties(name)))
          ''');

      if (startDate != null) {
        query = query.gte('appointment_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.lte('appointment_date', endOfDay.toIso8601String());
      }
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (doctorId != null && doctorId.isNotEmpty) {
        query = query.eq('doctor_id', doctorId);
      }

      final response = await query.order('appointment_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching appointment report data: $e');
      rethrow;
    }
  }

  /// Get doctor performance report data
  ///
  /// Uses 2 queries (doctors + all appointments) instead of 1+N.
  Future<List<Map<String, dynamic>>> getDoctorPerformanceReportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Query 1: all doctors with specialty info
      final doctorsResponse = await _supabase
          .from('doctors')
          .select('''
            id,
            first_name,
            last_name,
            consultation_fee,
            years_of_experience,
            verification_status,
            is_accepting_patients,
            doctor_specialties(is_primary, specialties(name))
          ''')
          .order('last_name');

      final doctors = List<Map<String, dynamic>>.from(doctorsResponse);

      // Query 2: all relevant appointments in one round-trip
      var apptQuery = _supabase
          .from('appointments')
          .select('doctor_id, status');
      if (startDate != null) {
        apptQuery = apptQuery.gte('appointment_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        apptQuery = apptQuery.lte('appointment_date', endOfDay.toIso8601String());
      }
      final apptResponse = await apptQuery;
      final allAppointments = List<Map<String, dynamic>>.from(apptResponse);

      // Group appointment counts by doctor_id in Dart
      final Map<String, Map<String, int>> apptByDoctor = {};
      for (final a in allAppointments) {
        final did = a['doctor_id'] as String? ?? '';
        apptByDoctor.putIfAbsent(did, () => {'total': 0, 'completed': 0, 'cancelled': 0, 'no_show': 0});
        apptByDoctor[did]!['total'] = apptByDoctor[did]!['total']! + 1;
        final status = a['status'] as String?;
        if (status == 'completed') apptByDoctor[did]!['completed'] = apptByDoctor[did]!['completed']! + 1;
        if (status == 'cancelled') apptByDoctor[did]!['cancelled'] = apptByDoctor[did]!['cancelled']! + 1;
        if (status == 'no_show')   apptByDoctor[did]!['no_show']   = apptByDoctor[did]!['no_show']!   + 1;
      }

      final List<Map<String, dynamic>> reportData = [];
      for (final doctor in doctors) {
        final doctorId = doctor['id'] as String;
        final counts = apptByDoctor[doctorId] ?? {'total': 0, 'completed': 0, 'cancelled': 0, 'no_show': 0};

        final total     = counts['total']!;
        final completed = counts['completed']!;
        final cancelled = counts['cancelled']!;
        final noShow    = counts['no_show']!;

        String specialty = 'General Practice';
        if (doctor['doctor_specialties'] != null) {
          final specialties = doctor['doctor_specialties'] as List;
          final primary = specialties.firstWhere(
            (s) => s['is_primary'] == true,
            orElse: () => specialties.isNotEmpty ? specialties.first : null,
          );
          if (primary != null) {
            specialty = primary['specialties']?['name'] ?? 'General Practice';
          }
        }

        final fee = doctor['consultation_fee'] ?? 0;
        final revenue = completed * (fee as num).toDouble();

        reportData.add({
          'doctor_name': 'Dr. ${doctor['first_name']} ${doctor['last_name']}',
          'specialty': specialty,
          'total_appointments': total,
          'completed': completed,
          'cancelled': cancelled,
          'no_show': noShow,
          'completion_rate': total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0',
          'revenue': revenue,
          'consultation_fee': fee,
          'years_of_experience': doctor['years_of_experience'] ?? 0,
          'verification_status': doctor['verification_status'] ?? 'pending',
          'is_accepting': doctor['is_accepting_patients'] ?? false,
        });
      }

      return reportData;
    } catch (e) {
      debugPrint('Error fetching doctor performance report: $e');
      rethrow;
    }
  }

  /// Get patient statistics report data
  Future<Map<String, dynamic>> getPatientStatisticsReportData() async {
    try {
      final patients = await _supabase
          .from('patients')
          .select('''
            id,
            first_name,
            last_name,
            gender,
            blood_group,
            date_of_birth,
            no_show_count,
            created_at
          ''');

      final patientList = List<Map<String, dynamic>>.from(patients);

      // Basic stats
      final totalPatients = patientList.length;

      // Gender distribution
      final genderDistribution = <String, int>{};
      for (var p in patientList) {
        final gender = p['gender']?.toString() ?? 'unknown';
        genderDistribution[gender] = (genderDistribution[gender] ?? 0) + 1;
      }

      // Blood group distribution
      final bloodGroupDistribution = <String, int>{};
      for (var p in patientList) {
        final bg = p['blood_group']?.toString() ?? 'unknown';
        bloodGroupDistribution[bg] = (bloodGroupDistribution[bg] ?? 0) + 1;
      }

      // Age distribution
      final ageDistribution = <String, int>{
        '0-17': 0,
        '18-30': 0,
        '31-45': 0,
        '46-60': 0,
        '60+': 0,
      };

      for (var p in patientList) {
        if (p['date_of_birth'] != null) {
          try {
            final dob = DateTime.parse(p['date_of_birth']);
            final age = DateTime.now().difference(dob).inDays ~/ 365;

            if (age < 18) {
              ageDistribution['0-17'] = ageDistribution['0-17']! + 1;
            } else if (age <= 30) {
              ageDistribution['18-30'] = ageDistribution['18-30']! + 1;
            } else if (age <= 45) {
              ageDistribution['31-45'] = ageDistribution['31-45']! + 1;
            } else if (age <= 60) {
              ageDistribution['46-60'] = ageDistribution['46-60']! + 1;
            } else {
              ageDistribution['60+'] = ageDistribution['60+']! + 1;
            }
          } catch (_) {}
        }
      }

      // No-show statistics
      final totalNoShows = patientList.fold<int>(
        0,
        (sum, p) => sum + ((p['no_show_count'] as int?) ?? 0),
      );

      // New patients this month
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final newPatientsThisMonth = patientList.where((p) {
        if (p['created_at'] == null) return false;
        final createdAt = DateTime.parse(p['created_at']);
        return createdAt.isAfter(monthStart);
      }).length;

      return {
        'total_patients': totalPatients,
        'gender_distribution': genderDistribution,
        'blood_group_distribution': bloodGroupDistribution,
        'age_distribution': ageDistribution,
        'total_no_shows': totalNoShows,
        'new_patients_this_month': newPatientsThisMonth,
        'patient_list': patientList,
      };
    } catch (e) {
      debugPrint('Error fetching patient statistics: $e');
      return {};
    }
  }

  /// Get revenue report data
  Future<Map<String, dynamic>> getRevenueReportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('appointments')
          .select('''
            id,
            appointment_date,
            status,
            doctors(first_name, last_name, consultation_fee, doctor_specialties(is_primary, specialties(name)))
          ''')
          .eq('status', 'completed');

      if (startDate != null) {
        query = query.gte('appointment_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('appointment_date', endDate.toIso8601String());
      }

      final appointments = await query.order('appointment_date', ascending: true);
      final appointmentList = List<Map<String, dynamic>>.from(appointments);

      double totalRevenue = 0;
      final revenueByDoctor = <String, double>{};
      final revenueBySpecialty = <String, double>{};
      final revenueByMonth = <String, double>{};

      for (var appointment in appointmentList) {
        final doctor = appointment['doctors'];
        final fee = (doctor?['consultation_fee'] ?? 0) as num;
        totalRevenue += fee.toDouble();

        // By doctor
        final doctorName = 'Dr. ${doctor?['first_name'] ?? ''} ${doctor?['last_name'] ?? ''}';
        revenueByDoctor[doctorName] = (revenueByDoctor[doctorName] ?? 0) + fee.toDouble();

        // By specialty
        String specialty = 'General Practice';
        if (doctor?['doctor_specialties'] != null) {
          final specialties = doctor['doctor_specialties'] as List;
          final primary = specialties.firstWhere(
            (s) => s['is_primary'] == true,
            orElse: () => specialties.isNotEmpty ? specialties.first : null,
          );
          if (primary != null) {
            specialty = primary['specialties']?['name'] ?? 'General Practice';
          }
        }
        revenueBySpecialty[specialty] = (revenueBySpecialty[specialty] ?? 0) + fee.toDouble();

        // By month
        final date = DateTime.parse(appointment['appointment_date']);
        final monthKey = DateFormat('MMM yyyy').format(date);
        revenueByMonth[monthKey] = (revenueByMonth[monthKey] ?? 0) + fee.toDouble();
      }

      return {
        'total_revenue': totalRevenue,
        'total_appointments': appointmentList.length,
        'average_per_appointment': appointmentList.isNotEmpty
            ? totalRevenue / appointmentList.length
            : 0,
        'revenue_by_doctor': revenueByDoctor,
        'revenue_by_specialty': revenueBySpecialty,
        'revenue_by_month': revenueByMonth,
      };
    } catch (e) {
      debugPrint('Error fetching revenue report: $e');
      return {};
    }
  }

  /// Save report record to database
  Future<Map<String, dynamic>> saveReportRecord({
    required String reportType,
    required String reportName,
    Map<String, dynamic>? parameters,
    String? fileUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      // Get admin ID
      final adminResponse = await _supabase
          .from('admins')
          .select('id')
          .eq('user_id', userId)
          .single();

      await _supabase.from('admin_reports').insert({
        'created_by': adminResponse['id'],
        'report_type': reportType,
        'report_name': reportName,
        'parameters': parameters,
        'file_url': fileUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Report saved successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to save report: ${e.toString()}',
      };
    }
  }

  /// Get saved reports
  Future<List<Map<String, dynamic>>> getSavedReports({
    String? reportType,
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from('admin_reports')
          .select('''
            *,
            admins(first_name, last_name)
          ''');

      if (reportType != null) {
        query = query.eq('report_type', reportType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching saved reports: $e');
      return [];
    }
  }

  /// Delete a saved report
  Future<Map<String, dynamic>> deleteReport(String reportId) async {
    try {
      await _supabase
          .from('admin_reports')
          .delete()
          .eq('id', reportId);

      return {
        'success': true,
        'message': 'Report deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete report: ${e.toString()}',
      };
    }
  }

  /// Get list of all doctors for report filters
  Future<List<Map<String, dynamic>>> getDoctorsForFilter() async {
    try {
      final response = await _supabase
          .from('doctors')
          .select('id, first_name, last_name')
          .order('last_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching doctors for filter: $e');
      return [];
    }
  }
}
