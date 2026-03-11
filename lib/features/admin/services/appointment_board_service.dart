import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for Real-Time Appointment Board operations
///
/// Provides methods for:
/// - Fetching today's appointments across all doctors
/// - Updating appointment status in real-time
/// - Quick check-in functionality
/// - Appointment statistics for today
class AppointmentBoardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all appointments for today across all doctors
  Future<List<Map<String, dynamic>>> getTodayAppointments() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final appointments = await _supabase
          .from('appointments')
          .select('''
            id,
            appointment_date,
            duration,
            status,
            patient_notes,
            created_at,
            patients(
              id,
              first_name,
              last_name,
              phone,
              date_of_birth,
              gender,
              blood_group,
              allergies
            ),
            doctors(
              id,
              first_name,
              last_name,
              consultation_fee,
              doctor_specialties(
                is_primary,
                specialties(name)
              )
            )
          ''')
          .gte('appointment_date', todayStart.toIso8601String())
          .lt('appointment_date', todayEnd.toIso8601String())
          .order('appointment_date', ascending: true);

      return List<Map<String, dynamic>>.from(appointments);
    } catch (e) {
      debugPrint('Error fetching today appointments: $e');
      return [];
    }
  }

  /// Get appointments for a specific date
  Future<List<Map<String, dynamic>>> getAppointmentsByDate(DateTime date) async {
    try {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final appointments = await _supabase
          .from('appointments')
          .select('''
            id,
            appointment_date,
            duration,
            status,
            patient_notes,
            created_at,
            patients(
              id,
              first_name,
              last_name,
              phone,
              date_of_birth,
              gender,
              blood_group,
              allergies
            ),
            doctors(
              id,
              first_name,
              last_name,
              consultation_fee,
              doctor_specialties(
                is_primary,
                specialties(name)
              )
            )
          ''')
          .gte('appointment_date', dayStart.toIso8601String())
          .lt('appointment_date', dayEnd.toIso8601String())
          .order('appointment_date', ascending: true);

      return List<Map<String, dynamic>>.from(appointments);
    } catch (e) {
      debugPrint('Error fetching appointments by date: $e');
      return [];
    }
  }

  /// Get appointments grouped by doctor for today
  Future<Map<String, List<Map<String, dynamic>>>> getAppointmentsByDoctor() async {
    try {
      final appointments = await getTodayAppointments();
      final Map<String, List<Map<String, dynamic>>> groupedAppointments = {};

      for (var appointment in appointments) {
        final doctor = appointment['doctors'];
        if (doctor == null) continue;

        final doctorId = doctor['id'] as String;
        if (!groupedAppointments.containsKey(doctorId)) {
          groupedAppointments[doctorId] = [];
        }
        groupedAppointments[doctorId]!.add(appointment);
      }

      return groupedAppointments;
    } catch (e) {
      debugPrint('Error grouping appointments by doctor: $e');
      return {};
    }
  }

  /// Update appointment status
  Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String newStatus,
  }) async {
    try {
      // Fetch patient_id BEFORE the update so the counter always increments
      // even if a subsequent query were to fail.
      String? patientId;
      if (newStatus == 'no_show') {
        final appointment = await _supabase
            .from('appointments')
            .select('patient_id')
            .eq('id', appointmentId)
            .single();
        patientId = appointment['patient_id'] as String?;
      }

      await _supabase
          .from('appointments')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', appointmentId);

      if (newStatus == 'no_show' && patientId != null) {
        await _supabase.rpc('increment_no_show_count', params: {
          'patient_id': patientId,
        });
      }

      return {
        'success': true,
        'message': 'Appointment status updated to ${newStatus.toUpperCase()}'
      };
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return {
        'success': false,
        'message': 'Failed to update appointment status: $e'
      };
    }
  }

  /// Quick check-in for appointment
  Future<Map<String, dynamic>> checkInAppointment(String appointmentId) async {
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      newStatus: 'checked_in',
    );
  }

  /// Start appointment (mark as in-progress)
  Future<Map<String, dynamic>> startAppointment(String appointmentId) async {
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      newStatus: 'in_progress',
    );
  }

  /// Complete appointment
  Future<Map<String, dynamic>> completeAppointment(String appointmentId) async {
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      newStatus: 'completed',
    );
  }

  /// Cancel appointment
  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      newStatus: 'cancelled',
    );
  }

  /// Mark as no-show
  Future<Map<String, dynamic>> markAsNoShow(String appointmentId) async {
    return await updateAppointmentStatus(
      appointmentId: appointmentId,
      newStatus: 'no_show',
    );
  }

  /// Get today's appointment statistics
  Future<Map<String, dynamic>> getTodayStats() async {
    try {
      final appointments = await getTodayAppointments();

      final total = appointments.length;
      final scheduled = appointments.where((a) => a['status'] == 'scheduled').length;
      final confirmed = appointments.where((a) => a['status'] == 'confirmed').length;
      final checkedIn = appointments.where((a) => a['status'] == 'checked_in').length;
      final inProgress = appointments.where((a) => a['status'] == 'in_progress').length;
      final completed = appointments.where((a) => a['status'] == 'completed').length;
      final cancelled = appointments.where((a) => a['status'] == 'cancelled').length;
      final noShow = appointments.where((a) => a['status'] == 'no_show').length;

      // Calculate completion rate
      final completionRate = total > 0 ? (completed / total * 100).toDouble() : 0.0;

      // Calculate no-show rate
      final noShowRate = total > 0 ? (noShow / total * 100).toDouble() : 0.0;

      // Estimate revenue (completed appointments only)
      double estimatedRevenue = 0;
      for (var appointment in appointments) {
        if (appointment['status'] == 'completed') {
          final fee = appointment['doctors']?['consultation_fee'] ?? 0;
          estimatedRevenue += (fee as num).toDouble();
        }
      }

      return {
        'total': total,
        'scheduled': scheduled,
        'confirmed': confirmed,
        'checked_in': checkedIn,
        'in_progress': inProgress,
        'completed': completed,
        'cancelled': cancelled,
        'no_show': noShow,
        'completion_rate': completionRate,
        'no_show_rate': noShowRate,
        'estimated_revenue': estimatedRevenue,
      };
    } catch (e) {
      debugPrint('Error fetching today stats: $e');
      return {
        'total': 0,
        'scheduled': 0,
        'confirmed': 0,
        'checked_in': 0,
        'in_progress': 0,
        'completed': 0,
        'cancelled': 0,
        'no_show': 0,
        'completion_rate': 0.0,
        'no_show_rate': 0.0,
        'estimated_revenue': 0.0,
      };
    }
  }

  /// Get upcoming appointments (next 2 hours)
  Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    try {
      final now = DateTime.now();
      final twoHoursLater = now.add(const Duration(hours: 2));

      final appointments = await _supabase
          .from('appointments')
          .select('''
            id,
            appointment_date,
            duration,
            status,
            patients(
              first_name,
              last_name,
              phone
            ),
            doctors(
              first_name,
              last_name
            )
          ''')
          .gte('appointment_date', now.toIso8601String())
          .lte('appointment_date', twoHoursLater.toIso8601String())
          .inFilter('status', ['scheduled', 'confirmed'])
          .order('appointment_date', ascending: true)
          .limit(10);

      return List<Map<String, dynamic>>.from(appointments);
    } catch (e) {
      debugPrint('Error fetching upcoming appointments: $e');
      return [];
    }
  }

  /// Get all active doctors for today
  Future<List<Map<String, dynamic>>> getActiveDoctorsToday() async {
    try {
      final appointments = await getTodayAppointments();
      final Map<String, Map<String, dynamic>> doctorsMap = {};

      for (var appointment in appointments) {
        final doctor = appointment['doctors'];
        if (doctor == null) continue;

        final doctorId = doctor['id'] as String;
        if (!doctorsMap.containsKey(doctorId)) {
          doctorsMap[doctorId] = {
            'id': doctorId,
            'first_name': doctor['first_name'],
            'last_name': doctor['last_name'],
            'specialty': _getPrimarySpecialty(doctor),
            'appointment_count': 0,
          };
        }
        doctorsMap[doctorId]!['appointment_count'] =
          (doctorsMap[doctorId]!['appointment_count'] as int) + 1;
      }

      return doctorsMap.values.toList();
    } catch (e) {
      debugPrint('Error fetching active doctors: $e');
      return [];
    }
  }

  /// Helper method to get primary specialty
  String _getPrimarySpecialty(Map<String, dynamic> doctor) {
    final specialties = doctor['doctor_specialties'] as List?;
    if (specialties == null || specialties.isEmpty) return 'General Practice';

    final primary = specialties.firstWhere(
      (s) => s['is_primary'] == true,
      orElse: () => specialties.first,
    );
    return primary['specialties']?['name'] ?? 'General Practice';
  }

  /// Search appointments by patient name or ID
  Future<List<Map<String, dynamic>>> searchTodayAppointments(String query) async {
    try {
      final appointments = await getTodayAppointments();

      if (query.isEmpty) return appointments;

      final lowerQuery = query.toLowerCase();
      return appointments.where((appointment) {
        final patient = appointment['patients'];
        if (patient == null) return false;

        final name = '${patient['first_name']} ${patient['last_name']}'.toLowerCase();
        final id = appointment['id'].toString().toLowerCase();

        return name.contains(lowerQuery) || id.contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching appointments: $e');
      return [];
    }
  }
}
