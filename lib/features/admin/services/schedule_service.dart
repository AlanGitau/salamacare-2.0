import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Master Calendar ───

  Future<List<Map<String, dynamic>>> getAllDoctorSchedules() async {
    try {
      final response = await _supabase
          .from('doctor_availability')
          .select('''
            *,
            doctors(id, first_name, last_name)
          ''')
          .eq('is_available', true)
          .order('day_of_week');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching all schedules: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBlockedSlots({
    String? doctorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('blocked_time_slots')
          .select('*, doctors(id, first_name, last_name)');

      if (doctorId != null) query = query.eq('doctor_id', doctorId);
      if (startDate != null) query = query.gte('start_time', startDate.toIso8601String());
      if (endDate != null) query = query.lte('end_time', endDate.toIso8601String());

      final response = await query.order('start_time', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching blocked slots: $e');
      return [];
    }
  }

  // ─── Holidays ───

  Future<List<Map<String, dynamic>>> getClinicHolidays({int? year}) async {
    try {
      var query = _supabase
          .from('clinic_holidays')
          .select('*, doctors(first_name, last_name)');

      if (year != null) {
        query = query
            .gte('date', '$year-01-01')
            .lte('date', '$year-12-31');
      }

      final response = await query.order('date');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createClinicHoliday({
    required String name,
    required DateTime date,
    bool isRecurring = false,
    bool appliesToAll = true,
    String? doctorId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('clinic_holidays').insert({
        'name': name,
        'date': date.toIso8601String().split('T')[0],
        'is_recurring': isRecurring,
        'applies_to_all_doctors': appliesToAll,
        'doctor_id': doctorId,
        'created_by': userId,
      });
      return {'success': true, 'message': 'Holiday added successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add holiday: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteClinicHoliday(String id) async {
    try {
      await _supabase.from('clinic_holidays').delete().eq('id', id);
      return {'success': true, 'message': 'Holiday removed'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to remove holiday: $e'};
    }
  }

  // ─── Emergency Slots ───

  Future<List<Map<String, dynamic>>> getDoctorAvailabilityWithEmergency() async {
    try {
      final response = await _supabase
          .from('doctor_availability')
          .select('*, doctors(id, first_name, last_name)')
          .eq('is_available', true)
          .order('day_of_week');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching availability: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateEmergencySlots(String availabilityId, int count) async {
    try {
      await _supabase
          .from('doctor_availability')
          .update({'emergency_slots_reserved': count})
          .eq('id', availabilityId);
      return {'success': true, 'message': 'Emergency slots updated'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update: $e'};
    }
  }

  // ─── Helpers ───

  Future<List<Map<String, dynamic>>> getDoctorsForPicker() async {
    try {
      final response = await _supabase
          .from('doctors')
          .select('id, first_name, last_name')
          .order('last_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      return [];
    }
  }
}
