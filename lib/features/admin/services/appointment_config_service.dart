import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentConfigService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Appointment Types CRUD ───

  Future<List<Map<String, dynamic>>> getAppointmentTypes() async {
    try {
      final response = await _supabase
          .from('appointment_types')
          .select()
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching appointment types: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createAppointmentType({
    required String name,
    String? description,
    required int defaultDuration,
    double? price,
    String? color,
  }) async {
    try {
      await _supabase.from('appointment_types').insert({
        'name': name,
        'description': description,
        'default_duration': defaultDuration,
        'price': price,
        'color': color,
      });
      return {'success': true, 'message': 'Appointment type created successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create appointment type: $e'};
    }
  }

  Future<Map<String, dynamic>> updateAppointmentType(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _supabase
          .from('appointment_types')
          .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return {'success': true, 'message': 'Appointment type updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update appointment type: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAppointmentType(String id) async {
    try {
      // Check if any appointments use this type
      final usage = await _supabase
          .from('appointments')
          .select('id')
          .eq('appointment_type_id', id)
          .limit(1);

      if ((usage as List).isNotEmpty) {
        return {
          'success': false,
          'message': 'Cannot delete: this appointment type is in use by existing appointments',
        };
      }

      await _supabase.from('appointment_types').delete().eq('id', id);
      return {'success': true, 'message': 'Appointment type deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete appointment type: $e'};
    }
  }

  // ─── Recurring Templates CRUD ───

  Future<List<Map<String, dynamic>>> getRecurringTemplates() async {
    try {
      final response = await _supabase
          .from('recurring_appointment_templates')
          .select('''
            *,
            doctors(id, first_name, last_name),
            patients(id, first_name, last_name),
            appointment_types(id, name)
          ''')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching recurring templates: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createRecurringTemplate({
    required String doctorId,
    required String patientId,
    String? appointmentTypeId,
    required String dayOfWeek,
    required String timeOfDay,
    int duration = 30,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
  }) async {
    try {
      await _supabase.from('recurring_appointment_templates').insert({
        'doctor_id': doctorId,
        'patient_id': patientId,
        'appointment_type_id': appointmentTypeId,
        'day_of_week': dayOfWeek,
        'time_of_day': timeOfDay,
        'duration': duration,
        'frequency': frequency,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'notes': notes,
      });
      return {'success': true, 'message': 'Recurring template created successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create template: $e'};
    }
  }

  Future<Map<String, dynamic>> updateRecurringTemplate(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _supabase
          .from('recurring_appointment_templates')
          .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return {'success': true, 'message': 'Template updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update template: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteRecurringTemplate(String id) async {
    try {
      await _supabase
          .from('recurring_appointment_templates')
          .delete()
          .eq('id', id);
      return {'success': true, 'message': 'Template deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete template: $e'};
    }
  }

  Future<Map<String, dynamic>> toggleTemplateActive(String id, bool isActive) async {
    try {
      await _supabase
          .from('recurring_appointment_templates')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return {
        'success': true,
        'message': isActive ? 'Template activated' : 'Template deactivated',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to update template: $e'};
    }
  }

  // ─── Booking Rules (clinic_settings) ───

  Future<Map<String, dynamic>> getBookingRules() async {
    try {
      final response = await _supabase
          .from('clinic_settings')
          .select('''
            cancellation_deadline_hours,
            reschedule_deadline_hours,
            max_cancellations_per_month,
            cancellation_fee,
            allow_same_day_booking,
            default_slot_duration,
            max_advance_booking_days,
            default_appointment_buffer
          ''')
          .limit(1)
          .maybeSingle();

      return response ?? {
        'cancellation_deadline_hours': 24,
        'reschedule_deadline_hours': 12,
        'max_cancellations_per_month': 3,
        'cancellation_fee': 0,
        'allow_same_day_booking': true,
        'default_slot_duration': 30,
        'max_advance_booking_days': 90,
        'default_appointment_buffer': 0,
      };
    } catch (e) {
      debugPrint('Error fetching booking rules: $e');
      return {
        'cancellation_deadline_hours': 24,
        'reschedule_deadline_hours': 12,
        'max_cancellations_per_month': 3,
        'cancellation_fee': 0,
        'allow_same_day_booking': true,
        'default_slot_duration': 30,
        'max_advance_booking_days': 90,
        'default_appointment_buffer': 0,
      };
    }
  }

  Future<Map<String, dynamic>> updateBookingRules(Map<String, dynamic> rules) async {
    try {
      final existing = await _supabase
          .from('clinic_settings')
          .select('id')
          .limit(1)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('clinic_settings').insert({
          ...rules,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _supabase
            .from('clinic_settings')
            .update({
              ...rules,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      }

      return {'success': true, 'message': 'Booking rules updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update booking rules: $e'};
    }
  }

  // ─── Helper queries ───

  Future<List<Map<String, dynamic>>> getDoctorsForPicker() async {
    try {
      final response = await _supabase
          .from('doctors')
          .select('id, first_name, last_name')
          .eq('is_accepting_patients', true)
          .order('last_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching doctors for picker: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPatientsForPicker() async {
    try {
      final response = await _supabase
          .from('patients')
          .select('id, first_name, last_name')
          .order('last_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching patients for picker: $e');
      return [];
    }
  }
}
