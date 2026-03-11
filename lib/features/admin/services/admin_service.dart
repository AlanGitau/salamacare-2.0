import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for admin operations in Supabase
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Auth helpers ───

  /// Throws if the currently authenticated user does not have role = 'admin'.
  ///
  /// Called at the top of every write method so that a misconfigured RLS
  /// policy alone cannot grant a non-admin access to privileged operations.
  Future<void> _assertAdminRole() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    final row = await _supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .single();
    if (row['role'] != 'admin') {
      throw Exception('Insufficient permissions: admin role required');
    }
  }

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];
      final tomorrowStr = today.add(const Duration(days: 1)).toIso8601String().split('T')[0];

      final results = await Future.wait([
        _supabase.from('patients').select('id').count(CountOption.exact),
        _supabase.from('doctors').select('id').count(CountOption.exact),
        _supabase.from('appointments').select('id').count(CountOption.exact),
        _supabase.from('appointments').select('id')
            .gte('appointment_date', todayStr)
            .lt('appointment_date', tomorrowStr)
            .count(CountOption.exact),
      ]);

      return {
        'total_patients':    results[0].count,
        'total_doctors':     results[1].count,
        'total_appointments': results[2].count,
        'today_appointments': results[3].count,
      };
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      return {
        'total_patients': 0,
        'total_doctors': 0,
        'total_appointments': 0,
        'today_appointments': 0,
      };
    }
  }

  /// Get all users with their roles
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('''
            *,
            patients(id, first_name, last_name, phone),
            doctors(id, first_name, last_name, phone, license_number, is_accepting_patients),
            admins(id, first_name, last_name)
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  /// Get all doctors with details (paginated).
  ///
  /// Returns up to [pageSize] records starting at [page] * [pageSize].
  /// If the returned list is shorter than [pageSize] there are no more pages.
  Future<List<Map<String, dynamic>>> getAllDoctors({
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final from = page * pageSize;
      final to   = from + pageSize - 1;

      final response = await _supabase
          .from('doctors')
          .select('''
            *,
            users(email, created_at),
            doctor_specialties(
              is_primary,
              specialties(name)
            )
          ''')
          .order('created_at', ascending: false)
          .range(from, to);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      return [];
    }
  }

  /// Get all patients with details (paginated).
  ///
  /// Returns up to [pageSize] records starting at [page] * [pageSize].
  /// If the returned list is shorter than [pageSize] there are no more pages.
  Future<List<Map<String, dynamic>>> getAllPatients({
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final from = page * pageSize;
      final to   = from + pageSize - 1;

      final response = await _supabase
          .from('patients')
          .select('''
            *,
            users(email, created_at)
          ''')
          .order('created_at', ascending: false)
          .range(from, to);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      return [];
    }
  }

  /// Get all appointments with filters
  Future<List<Map<String, dynamic>>> getAllAppointments({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('appointments')
          .select('''
            *,
            patients(first_name, last_name, phone),
            doctors(first_name, last_name),
            appointment_types(name, color)
          ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('appointment_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('appointment_date', endDate.toIso8601String());
      }

      final response = await query.order('appointment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      return [];
    }
  }

  /// Update doctor's accepting patients status
  Future<Map<String, dynamic>> updateDoctorStatus(
    String doctorId,
    bool isAcceptingPatients,
  ) async {
    try {
      await _assertAdminRole();
      await _supabase
          .from('doctors')
          .update({
            'is_accepting_patients': isAcceptingPatients,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId);

      return {
        'success': true,
        'message': 'Doctor status updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update status: ${e.toString()}',
      };
    }
  }

  /// Set a doctor's verification_status to 'verified'.
  Future<Map<String, dynamic>> verifyDoctor(String doctorId) async {
    try {
      await _assertAdminRole();
      await _supabase
          .from('doctors')
          .update({
            'verification_status': 'verified',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId);

      return {'success': true, 'message': 'Doctor verified successfully'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify doctor: ${e.toString()}',
      };
    }
  }

  /// Get appointment statistics by status
  Future<Map<String, int>> getAppointmentStatsByStatus() async {
    try {
      const statuses = ['scheduled', 'confirmed', 'completed', 'cancelled', 'no_show'];

      final results = await Future.wait(
        statuses.map((s) => _supabase.from('appointments').select('id').eq('status', s).count(CountOption.exact)),
      );

      return {for (var i = 0; i < statuses.length; i++) statuses[i]: results[i].count};
    } catch (e) {
      debugPrint('Error fetching appointment stats: $e');
      return {};
    }
  }

  /// Get recent activity (last 10 appointments)
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            patients(first_name, last_name),
            doctors(first_name, last_name)
          ''')
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching recent activity: $e');
      return [];
    }
  }

  /// Get all specialties
  Future<List<Map<String, dynamic>>> getAllSpecialties() async {
    try {
      final response = await _supabase
          .from('specialties')
          .select()
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching specialties: $e');
      return [];
    }
  }

  /// Add new specialty
  Future<Map<String, dynamic>> addSpecialty(String name, String? description) async {
    try {
      await _assertAdminRole();
      await _supabase.from('specialties').insert({
        'name': name,
        'description': description,
      });

      return {
        'success': true,
        'message': 'Specialty added successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add specialty: ${e.toString()}',
      };
    }
  }

  /// Delete specialty
  Future<Map<String, dynamic>> deleteSpecialty(String specialtyId) async {
    try {
      await _assertAdminRole();
      await _supabase
          .from('specialties')
          .delete()
          .eq('id', specialtyId);

      return {
        'success': true,
        'message': 'Specialty deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete specialty: ${e.toString()}',
      };
    }
  }

  /// Get monthly appointment trends (last 6 months)
  Future<List<Map<String, dynamic>>> getMonthlyTrends() async {
    try {
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

      final response = await _supabase
          .from('appointments')
          .select('appointment_date, status')
          .gte('appointment_date', sixMonthsAgo.toIso8601String())
          .order('appointment_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching monthly trends: $e');
      return [];
    }
  }

  /// Get doctor performance metrics
  Future<List<Map<String, dynamic>>> getDoctorPerformance() async {
    try {
      final response = await _supabase
          .from('doctors')
          .select('''
            id,
            first_name,
            last_name,
            appointments!inner(id, status)
          ''')
          .order('last_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching doctor performance: $e');
      return [];
    }
  }

  /// Search users by email or name
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('users')
          .select('''
            *,
            patients(first_name, last_name, phone),
            doctors(first_name, last_name, phone)
          ''')
          .or('email.ilike.%$query%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // ─── Doctor Management Methods ───

  /// Update doctor profile fields
  Future<Map<String, dynamic>> updateDoctorProfile(
    String doctorId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _assertAdminRole();
      await _supabase
          .from('doctors')
          .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', doctorId);
      return {'success': true, 'message': 'Doctor profile updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: $e'};
    }
  }

  /// Get doctor leave/blocked time history
  Future<List<Map<String, dynamic>>> getDoctorLeaveHistory(String doctorId) async {
    try {
      final response = await _supabase
          .from('blocked_time_slots')
          .select()
          .eq('doctor_id', doctorId)
          .order('start_time', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching doctor leave: $e');
      return [];
    }
  }

  /// Create doctor leave/blocked time
  Future<Map<String, dynamic>> createDoctorLeave(
    String doctorId,
    DateTime startTime,
    DateTime endTime,
    String reason,
  ) async {
    try {
      await _assertAdminRole();
      await _supabase.from('blocked_time_slots').insert({
        'doctor_id': doctorId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'reason': reason,
      });
      return {'success': true, 'message': 'Leave added successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add leave: $e'};
    }
  }

  /// Delete doctor leave/blocked time
  Future<Map<String, dynamic>> deleteDoctorLeave(String blockId) async {
    try {
      await _assertAdminRole();
      await _supabase.from('blocked_time_slots').delete().eq('id', blockId);
      return {'success': true, 'message': 'Leave removed successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to remove leave: $e'};
    }
  }

  /// Get doctor detailed performance
  Future<Map<String, dynamic>> getDoctorDetailedPerformance(
    String doctorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 90));
      final end = endDate ?? DateTime.now();

      final appointments = await _supabase
          .from('appointments')
          .select('id, status, appointment_date, duration')
          .eq('doctor_id', doctorId)
          .gte('appointment_date', start.toIso8601String())
          .lte('appointment_date', end.toIso8601String());

      final list = List<Map<String, dynamic>>.from(appointments);
      final total = list.length;
      final completed = list.where((a) => a['status'] == 'completed').length;
      final cancelled = list.where((a) => a['status'] == 'cancelled').length;
      final noShow = list.where((a) => a['status'] == 'no_show').length;

      // Get unique patient count
      final patientIds = await _supabase
          .from('appointments')
          .select('patient_id')
          .eq('doctor_id', doctorId)
          .gte('appointment_date', start.toIso8601String())
          .lte('appointment_date', end.toIso8601String());

      final uniquePatients = List<Map<String, dynamic>>.from(patientIds)
          .map((p) => p['patient_id'])
          .toSet()
          .length;

      return {
        'total_appointments': total,
        'completed': completed,
        'cancelled': cancelled,
        'no_show': noShow,
        'completion_rate': total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0',
        'unique_patients': uniquePatients,
        'appointments': list,
      };
    } catch (e) {
      debugPrint('Error fetching doctor performance: $e');
      return {
        'total_appointments': 0,
        'completed': 0,
        'cancelled': 0,
        'no_show': 0,
        'completion_rate': '0.0',
        'unique_patients': 0,
        'appointments': [],
      };
    }
  }

  /// Get doctor's weekly availability
  Future<List<Map<String, dynamic>>> getDoctorAvailability(String doctorId) async {
    try {
      final response = await _supabase
          .from('doctor_availability')
          .select()
          .eq('doctor_id', doctorId)
          .order('day_of_week');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching doctor availability: $e');
      return [];
    }
  }

  /// Get doctor appointments
  Future<List<Map<String, dynamic>>> getDoctorAppointments(
    String doctorId, {
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('appointments')
          .select('''
            *,
            patients(first_name, last_name, phone),
            appointment_types(name, color)
          ''')
          .eq('doctor_id', doctorId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('appointment_date', ascending: false).limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching doctor appointments: $e');
      return [];
    }
  }

  // ─── Patient Management Methods ───

  /// Find potential duplicate patients
  Future<List<List<Map<String, dynamic>>>> findPotentialDuplicates() async {
    try {
      final patients = await _supabase
          .from('patients')
          .select('id, first_name, last_name, date_of_birth, phone, users(email)')
          .order('last_name');

      final list = List<Map<String, dynamic>>.from(patients);
      final Map<String, List<Map<String, dynamic>>> groups = {};

      for (final p in list) {
        final key = '${p['first_name']}_${p['last_name']}_${p['date_of_birth'] ?? ''}'.toLowerCase();
        groups.putIfAbsent(key, () => []);
        groups[key]!.add(p);
      }

      return groups.values.where((g) => g.length > 1).toList();
    } catch (e) {
      debugPrint('Error finding duplicates: $e');
      return [];
    }
  }

  /// Merge [duplicateId] patient record into [primaryId], transferring all
  /// linked data (appointments, documents, etc.) via the merge_patients DB
  /// function.  Requires admin role; is irreversible.
  Future<Map<String, dynamic>> mergePatients(
    String primaryId,
    String duplicateId,
  ) async {
    try {
      await _assertAdminRole();
      await _supabase.rpc('merge_patients', params: {
        'primary_id': primaryId,
        'duplicate_id': duplicateId,
      });
      return {'success': true, 'message': 'Patients merged successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Merge failed: $e'};
    }
  }

  /// Get current admin profile
  Future<Map<String, dynamic>?> getCurrentAdminProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('admins')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching admin profile: $e');
      return null;
    }
  }
}
