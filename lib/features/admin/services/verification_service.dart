import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for doctor verification operations
class VerificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get doctors by verification status
  Future<List<Map<String, dynamic>>> getDoctorsByStatus(String status) async {
    try {
      final response = await _supabase
          .from('doctors')
          .select('''
            *,
            users!inner(email, created_at),
            doctor_specialties(
              is_primary,
              specialties(name)
            )
          ''')
          .eq('verification_status', status)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching doctors by status: $e');
      return [];
    }
  }

  /// Get all pending verification doctors
  Future<List<Map<String, dynamic>>> getPendingDoctors() async {
    return getDoctorsByStatus('pending');
  }

  /// Get all verified doctors
  Future<List<Map<String, dynamic>>> getVerifiedDoctors() async {
    return getDoctorsByStatus('verified');
  }

  /// Get all rejected doctors
  Future<List<Map<String, dynamic>>> getRejectedDoctors() async {
    return getDoctorsByStatus('rejected');
  }

  /// Get pending verification count
  Future<int> getPendingCount() async {
    try {
      final result = await _supabase
          .from('doctors')
          .select('id')
          .eq('verification_status', 'pending')
          .count(CountOption.exact);

      return result.count;
    } catch (e) {
      debugPrint('Error fetching pending count: $e');
      return 0;
    }
  }

  /// Verify a doctor
  Future<Map<String, dynamic>> verifyDoctor(String doctorId) async {
    try {
      // Get current admin ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      // Get admin ID from admins table
      final adminResponse = await _supabase
          .from('admins')
          .select('id')
          .eq('user_id', userId)
          .single();

      await _supabase
          .from('doctors')
          .update({
            'verification_status': 'verified',
            'verification_date': DateTime.now().toIso8601String(),
            'verified_by': adminResponse['id'],
            'rejection_reason': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId);

      return {
        'success': true,
        'message': 'Doctor verified successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify doctor: ${e.toString()}',
      };
    }
  }

  /// Reject a doctor
  Future<Map<String, dynamic>> rejectDoctor(
    String doctorId,
    String reason,
  ) async {
    try {
      // Get current admin ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      // Get admin ID from admins table
      final adminResponse = await _supabase
          .from('admins')
          .select('id')
          .eq('user_id', userId)
          .single();

      await _supabase
          .from('doctors')
          .update({
            'verification_status': 'rejected',
            'verification_date': DateTime.now().toIso8601String(),
            'verified_by': adminResponse['id'],
            'rejection_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId);

      return {
        'success': true,
        'message': 'Doctor rejected',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to reject doctor: ${e.toString()}',
      };
    }
  }

  /// Suspend a doctor
  Future<Map<String, dynamic>> suspendDoctor(
    String doctorId,
    String reason,
  ) async {
    try {
      await _supabase
          .from('doctors')
          .update({
            'verification_status': 'suspended',
            'rejection_reason': reason,
            'is_accepting_patients': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId);

      return {
        'success': true,
        'message': 'Doctor suspended',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to suspend doctor: ${e.toString()}',
      };
    }
  }

  /// Reinstate a suspended/rejected doctor to pending
  Future<Map<String, dynamic>> reinstateDoctor(String doctorId) async {
    try {
      await _supabase
          .from('doctors')
          .update({
            'verification_status': 'pending',
            'verification_date': null,
            'verified_by': null,
            'rejection_reason': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doctorId);

      return {
        'success': true,
        'message': 'Doctor status reset to pending',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to reinstate doctor: ${e.toString()}',
      };
    }
  }

  /// Get doctor details for review
  Future<Map<String, dynamic>?> getDoctorDetails(String doctorId) async {
    try {
      final response = await _supabase
          .from('doctors')
          .select('''
            *,
            users!inner(email, created_at),
            doctor_specialties(
              is_primary,
              specialties(name, description)
            ),
            doctor_availability(
              day_of_week,
              start_time,
              end_time,
              is_available
            )
          ''')
          .eq('id', doctorId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching doctor details: $e');
      return null;
    }
  }

  /// Get verification statistics
  Future<Map<String, int>> getVerificationStats() async {
    try {
      const statuses = ['pending', 'verified', 'rejected', 'suspended'];

      final results = await Future.wait([
        ...statuses.map((s) => _supabase.from('doctors').select('id').eq('verification_status', s).count(CountOption.exact)),
        _supabase.from('doctors').select('id').count(CountOption.exact), // total
      ]);

      return {
        for (var i = 0; i < statuses.length; i++) statuses[i]: results[i].count,
        'total': results[statuses.length].count,
      };
    } catch (e) {
      debugPrint('Error fetching verification stats: $e');
      return {
        'pending': 0, 'verified': 0, 'rejected': 0, 'suspended': 0, 'total': 0,
      };
    }
  }
}
