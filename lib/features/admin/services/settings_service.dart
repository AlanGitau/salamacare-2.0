import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for clinic settings operations
class SettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get clinic settings
  Future<Map<String, dynamic>?> getClinicSettings() async {
    try {
      final response = await _supabase
          .from('clinic_settings')
          .select()
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching clinic settings: $e');
      return null;
    }
  }

  /// Update clinic settings
  Future<Map<String, dynamic>> updateClinicSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      // Check if settings exist
      final existing = await getClinicSettings();

      if (existing == null) {
        // Create new settings
        await _supabase.from('clinic_settings').insert({
          ...settings,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing settings
        await _supabase
            .from('clinic_settings')
            .update({
              ...settings,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      }

      return {
        'success': true,
        'message': 'Settings updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update settings: ${e.toString()}',
      };
    }
  }

  /// Update clinic name
  Future<Map<String, dynamic>> updateClinicName(String name) async {
    return updateClinicSettings({'clinic_name': name});
  }

  /// Update clinic address
  Future<Map<String, dynamic>> updateClinicAddress(String address) async {
    return updateClinicSettings({'address': address});
  }

  /// Update clinic contact info
  Future<Map<String, dynamic>> updateContactInfo({
    String? phone,
    String? email,
  }) async {
    final updates = <String, dynamic>{};
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    return updateClinicSettings(updates);
  }

  /// Update operating hours
  Future<Map<String, dynamic>> updateOperatingHours({
    String? openingTime,
    String? closingTime,
    List<String>? operatingDays,
  }) async {
    final updates = <String, dynamic>{};
    if (openingTime != null) updates['opening_time'] = openingTime;
    if (closingTime != null) updates['closing_time'] = closingTime;
    if (operatingDays != null) updates['operating_days'] = operatingDays;
    return updateClinicSettings(updates);
  }

  /// Update booking settings
  Future<Map<String, dynamic>> updateBookingSettings({
    int? defaultSlotDuration,
    int? maxAdvanceBookingDays,
    bool? onlineBookingEnabled,
    String? cancellationPolicy,
  }) async {
    final updates = <String, dynamic>{};
    if (defaultSlotDuration != null) {
      updates['default_slot_duration'] = defaultSlotDuration;
    }
    if (maxAdvanceBookingDays != null) {
      updates['max_advance_booking_days'] = maxAdvanceBookingDays;
    }
    if (onlineBookingEnabled != null) {
      updates['online_booking_enabled'] = onlineBookingEnabled;
    }
    if (cancellationPolicy != null) {
      updates['cancellation_policy'] = cancellationPolicy;
    }
    return updateClinicSettings(updates);
  }

  /// Update notification settings
  Future<Map<String, dynamic>> updateNotificationSettings({
    bool? emailEnabled,
    bool? smsEnabled,
    bool? pushEnabled,
  }) async {
    try {
      final current = await getClinicSettings();
      final currentNotifications = current?['notification_settings'] ?? {
        'email': true,
        'sms': false,
        'push': true,
      };

      final notifications = {
        'email': emailEnabled ?? currentNotifications['email'] ?? true,
        'sms': smsEnabled ?? currentNotifications['sms'] ?? false,
        'push': pushEnabled ?? currentNotifications['push'] ?? true,
      };

      return updateClinicSettings({'notification_settings': notifications});
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update notification settings: ${e.toString()}',
      };
    }
  }

  /// Update clinic logo URL
  Future<Map<String, dynamic>> updateLogoUrl(String? logoUrl) async {
    return updateClinicSettings({'logo_url': logoUrl});
  }

  /// Get default settings template
  Map<String, dynamic> getDefaultSettings() {
    return {
      'clinic_name': 'SalamaCare Clinic',
      'address': '',
      'phone': '',
      'email': '',
      'opening_time': '08:00',
      'closing_time': '18:00',
      'operating_days': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      'default_slot_duration': 30,
      'max_advance_booking_days': 90,
      'online_booking_enabled': true,
      'cancellation_policy': 'Appointments can be cancelled up to 24 hours in advance without penalty.',
      'notification_settings': {
        'email': true,
        'sms': false,
        'push': true,
      },
      'logo_url': null,
    };
  }

  /// Reset settings to defaults
  Future<Map<String, dynamic>> resetToDefaults() async {
    return updateClinicSettings(getDefaultSettings());
  }
}
