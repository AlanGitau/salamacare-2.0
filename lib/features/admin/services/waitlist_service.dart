import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WaitlistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Waitlist Queue ───

  Future<List<Map<String, dynamic>>> getActiveWaitlist({
    String? doctorId,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('waitlist')
          .select('''
            *,
            patients(id, first_name, last_name, phone),
            doctors(id, first_name, last_name),
            specialties(id, name)
          ''');

      if (doctorId != null) query = query.eq('doctor_id', doctorId);
      if (status != null) {
        query = query.eq('status', status);
      } else {
        query = query.eq('status', 'active');
      }

      final response = await query.order('priority').order('created_at');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching waitlist: $e');
      return [];
    }
  }

  Future<Map<String, int>> getWaitlistStats() async {
    try {
      final active = await _supabase.from('waitlist').select('id').eq('status', 'active').count(CountOption.exact);
      final fulfilled = await _supabase.from('waitlist').select('id').eq('status', 'fulfilled').count(CountOption.exact);
      final expired = await _supabase.from('waitlist').select('id').eq('status', 'expired').count(CountOption.exact);
      final cancelled = await _supabase.from('waitlist').select('id').eq('status', 'cancelled').count(CountOption.exact);

      return {
        'active': active.count,
        'fulfilled': fulfilled.count,
        'expired': expired.count,
        'cancelled': cancelled.count,
      };
    } catch (e) {
      debugPrint('Error fetching waitlist stats: $e');
      return {'active': 0, 'fulfilled': 0, 'expired': 0, 'cancelled': 0};
    }
  }

  Future<Map<String, dynamic>> updateWaitlistPriority(String id, int newPriority) async {
    try {
      await _supabase.from('waitlist').update({'priority': newPriority}).eq('id', id);
      return {'success': true, 'message': 'Priority updated'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update priority: $e'};
    }
  }

  Future<Map<String, dynamic>> updateWaitlistStatus(String id, String status) async {
    try {
      final updates = <String, dynamic>{'status': status};
      if (status == 'fulfilled') {
        updates['fulfilled_at'] = DateTime.now().toIso8601String();
      }
      await _supabase.from('waitlist').update(updates).eq('id', id);
      return {'success': true, 'message': 'Status updated to $status'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update status: $e'};
    }
  }

  Future<Map<String, dynamic>> expireOldEntries() async {
    try {
      final now = DateTime.now().toIso8601String().split('T')[0];
      await _supabase
          .from('waitlist')
          .update({'status': 'expired'})
          .eq('status', 'active')
          .lt('preferred_date_end', now);
      return {'success': true, 'message': 'Expired entries updated'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to expire entries: $e'};
    }
  }

  // ─── Waitlist Settings ───

  Future<Map<String, dynamic>> getWaitlistSettings() async {
    try {
      final response = await _supabase
          .from('clinic_settings')
          .select('''
            waitlist_enabled,
            waitlist_auto_book,
            waitlist_max_entries,
            waitlist_expiry_days,
            waitlist_notification_enabled
          ''')
          .limit(1)
          .maybeSingle();

      return response ?? {
        'waitlist_enabled': true,
        'waitlist_auto_book': false,
        'waitlist_max_entries': 50,
        'waitlist_expiry_days': 30,
        'waitlist_notification_enabled': true,
      };
    } catch (e) {
      debugPrint('Error fetching waitlist settings: $e');
      return {
        'waitlist_enabled': true,
        'waitlist_auto_book': false,
        'waitlist_max_entries': 50,
        'waitlist_expiry_days': 30,
        'waitlist_notification_enabled': true,
      };
    }
  }

  Future<Map<String, dynamic>> updateWaitlistSettings(Map<String, dynamic> settings) async {
    try {
      final existing = await _supabase.from('clinic_settings').select('id').limit(1).maybeSingle();

      if (existing == null) {
        await _supabase.from('clinic_settings').insert({
          ...settings,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _supabase
            .from('clinic_settings')
            .update({...settings, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', existing['id']);
      }
      return {'success': true, 'message': 'Waitlist settings updated'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update settings: $e'};
    }
  }
}
