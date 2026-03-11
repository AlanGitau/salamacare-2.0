import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementService {
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

  /// Returns whether the current user's role has [permissionKey] allowed in
  /// the role_permissions table.
  ///
  /// Defaults to [true] when no row exists for the (role, key) pair so that
  /// newly-added keys only restrict access once explicitly configured by an
  /// admin.  This makes the permissions system opt-in rather than opt-out,
  /// and means it has real effect rather than being purely decorative.
  Future<bool> checkPermission(String permissionKey) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final userRow = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (userRow == null) return false;
      final role = userRow['role'] as String;

      final perm = await _supabase
          .from('role_permissions')
          .select('is_allowed')
          .eq('role', role)
          .eq('permission_key', permissionKey)
          .maybeSingle();

      if (perm == null) return true; // not yet configured → permissive default
      return perm['is_allowed'] == true;
    } catch (e) {
      debugPrint('Permission check error: $e');
      return false;
    }
  }

  // ─── User CRUD ───

  /// Get all users with role profiles (paginated).
  ///
  /// Returns up to [pageSize] records starting at [page] * [pageSize].
  /// If the returned list is shorter than [pageSize] there are no more pages.
  Future<List<Map<String, dynamic>>> getAllUsersDetailed({
    int page = 0,
    int pageSize = 50,
  }) async {
    try {
      final from = page * pageSize;
      final to   = from + pageSize - 1;

      final response = await _supabase
          .from('users')
          .select('''
            *,
            patients(id, first_name, last_name, phone),
            doctors(id, first_name, last_name, phone, license_number, is_accepting_patients),
            admins(id, first_name, last_name, phone)
          ''')
          .order('created_at', ascending: false)
          .range(from, to);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAdminAccounts() async {
    try {
      final response = await _supabase
          .from('users')
          .select('''
            *,
            admins(id, first_name, last_name, phone)
          ''')
          .eq('role', 'admin')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching admin accounts: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createAdminAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      await _assertAdminRole();
      // Use Edge Function so the current admin session is NOT overwritten
      final response = await _supabase.functions.invoke(
        'create-user',
        body: {'email': email, 'password': password, 'role': 'admin'},
      );

      if (response.status != 200) {
        final err = response.data?['error'] ?? 'Unknown error';
        return {'success': false, 'message': 'Failed to create auth account: $err'};
      }

      final newUserId = response.data['user_id'] as String;

      // The handle_new_user trigger creates the users row.
      // Create the admin profile after a short delay to let the trigger run.
      await Future.delayed(const Duration(milliseconds: 500));
      await _supabase.from('admins').insert({
        'user_id': newUserId,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });

      return {'success': true, 'message': 'Admin account created successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create admin: $e'};
    }
  }

  /// Create a new doctor account (auth user + users row + doctors profile)
  Future<Map<String, dynamic>> createDoctorAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? licenseNumber,
    String? specialtyId,
    double? consultationFee,
    int? yearsOfExperience,
  }) async {
    try {
      await _assertAdminRole();
      // Use Edge Function so the current admin session is NOT overwritten
      final response = await _supabase.functions.invoke(
        'create-user',
        body: {'email': email, 'password': password, 'role': 'doctor'},
      );

      if (response.status != 200) {
        final err = response.data?['error'] ?? 'Unknown error';
        return {'success': false, 'message': 'Failed to create auth account: $err'};
      }

      final userId = response.data['user_id'] as String;

      // Allow the handle_new_user trigger to create the users row
      await Future.delayed(const Duration(milliseconds: 500));

      // Create doctor profile
      final doctorData = {
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (licenseNumber != null && licenseNumber.isNotEmpty) 'license_number': licenseNumber,
        if (consultationFee != null) 'consultation_fee': consultationFee,
        if (yearsOfExperience != null) 'years_of_experience': yearsOfExperience,
        'is_accepting_patients': true,
        'verification_status': 'verified',
      };

      final doctorResponse = await _supabase
          .from('doctors')
          .insert(doctorData)
          .select('id')
          .single();

      // Assign specialty if provided
      if (specialtyId != null && specialtyId.isNotEmpty) {
        await _supabase.from('doctor_specialties').insert({
          'doctor_id': doctorResponse['id'],
          'specialty_id': specialtyId,
          'is_primary': true,
        });
      }

      return {'success': true, 'message': 'Doctor account created successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create doctor: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserRole(String userId, String newRole) async {
    try {
      await _assertAdminRole();
      await _supabase
          .from('users')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return {'success': true, 'message': 'User role updated to $newRole'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update role: $e'};
    }
  }

  Future<Map<String, dynamic>> deactivateUser(String userId) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;
      // Prevent admins from locking themselves out of the system.
      if (adminId == userId) {
        return {'success': false, 'message': 'You cannot deactivate your own account'};
      }
      await _assertAdminRole();
      await _supabase
          .from('users')
          .update({
            'is_active': false,
            'deactivated_at': DateTime.now().toIso8601String(),
            'deactivated_by': adminId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return {'success': true, 'message': 'User account deactivated'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to deactivate user: $e'};
    }
  }

  Future<Map<String, dynamic>> reactivateUser(String userId) async {
    try {
      await _assertAdminRole();
      await _supabase
          .from('users')
          .update({
            'is_active': true,
            'deactivated_at': null,
            'deactivated_by': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return {'success': true, 'message': 'User account reactivated'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to reactivate user: $e'};
    }
  }

  Future<Map<String, dynamic>> sendPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return {'success': true, 'message': 'Password reset email sent to $email'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send reset email: $e'};
    }
  }

  // ─── Role Permissions ───

  Future<List<Map<String, dynamic>>> getRolePermissions() async {
    try {
      final response = await _supabase
          .from('role_permissions')
          .select()
          .order('role')
          .order('permission_key');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching role permissions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateRolePermission(
    String role,
    String permissionKey,
    bool isAllowed,
  ) async {
    try {
      await _assertAdminRole();
      await _supabase
          .from('role_permissions')
          .upsert({
            'role': role,
            'permission_key': permissionKey,
            'is_allowed': isAllowed,
          });
      return {'success': true, 'message': 'Permission updated'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update permission: $e'};
    }
  }

  Future<Map<String, dynamic>> addPermissionKey(String permissionKey) async {
    try {
      await _assertAdminRole();
      // Add this permission for all roles (defaulting to false for non-admin)
      final roles = ['admin', 'doctor', 'patient'];
      for (final role in roles) {
        await _supabase.from('role_permissions').upsert({
          'role': role,
          'permission_key': permissionKey,
          'is_allowed': role == 'admin',
        });
      }
      return {'success': true, 'message': 'Permission key added'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add permission: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePermissionKey(String permissionKey) async {
    try {
      await _assertAdminRole();
      await _supabase
          .from('role_permissions')
          .delete()
          .eq('permission_key', permissionKey);
      return {'success': true, 'message': 'Permission key removed'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to remove permission: $e'};
    }
  }

  // ─── Stats ───

  Future<Map<String, int>> getUserStats() async {
    try {
      final results = await Future.wait([
        _supabase.from('users').select('id').count(CountOption.exact),
        _supabase.from('users').select('id').eq('role', 'admin').count(CountOption.exact),
        _supabase.from('users').select('id').eq('role', 'doctor').count(CountOption.exact),
        _supabase.from('users').select('id').eq('role', 'patient').count(CountOption.exact),
      ]);

      return {
        'total':    results[0].count,
        'admins':   results[1].count,
        'doctors':  results[2].count,
        'patients': results[3].count,
      };
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
      return {'total': 0, 'admins': 0, 'doctors': 0, 'patients': 0};
    }
  }
}
