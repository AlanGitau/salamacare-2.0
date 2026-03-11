import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for analytics operations
class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get appointment trends for a date range
  Future<List<Map<String, dynamic>>> getAppointmentTrends({
    required DateTime startDate,
    required DateTime endDate,
    String groupBy = 'day', // 'day', 'week', 'month'
  }) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('id, appointment_date, status')
          .gte('appointment_date', startDate.toIso8601String())
          .lte('appointment_date', endDate.toIso8601String())
          .order('appointment_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching appointment trends: $e');
      return [];
    }
  }

  /// Get appointment count by status for a date range
  Future<Map<String, int>> getAppointmentsByStatus({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final statuses = ['scheduled', 'confirmed', 'completed', 'cancelled', 'no_show'];
      final stats = <String, int>{};

      for (var status in statuses) {
        var query = _supabase
            .from('appointments')
            .select('id')
            .eq('status', status);

        if (startDate != null) {
          query = query.gte('appointment_date', startDate.toIso8601String());
        }
        if (endDate != null) {
          query = query.lte('appointment_date', endDate.toIso8601String());
        }

        final result = await query.count(CountOption.exact);
        stats[status] = result.count;
      }

      return stats;
    } catch (e) {
      debugPrint('Error fetching appointment status stats: $e');
      return {};
    }
  }

  /// Get doctor performance metrics
  ///
  /// Uses 2 queries (doctors + all appointments) instead of 1+N.
  Future<List<Map<String, dynamic>>> getDoctorPerformanceMetrics({
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
            doctor_specialties(
              is_primary,
              specialties(name)
            )
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
        apptQuery = apptQuery.lte('appointment_date', endDate.toIso8601String());
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

      final List<Map<String, dynamic>> metrics = [];
      for (final doctor in doctors) {
        final doctorId = doctor['id'] as String;
        final counts = apptByDoctor[doctorId] ?? {'total': 0, 'completed': 0, 'cancelled': 0, 'no_show': 0};

        final total     = counts['total']!;
        final completed = counts['completed']!;
        final completionRate = total > 0 ? (completed / total * 100).toDouble() : 0.0;

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

        metrics.add({
          'doctor_id': doctorId,
          'name': 'Dr. ${doctor['first_name']} ${doctor['last_name']}',
          'specialty': specialty,
          'total_appointments': total,
          'completed': completed,
          'cancelled': counts['cancelled']!,
          'no_show': counts['no_show']!,
          'completion_rate': completionRate,
        });
      }

      metrics.sort((a, b) => (b['total_appointments'] as int)
          .compareTo(a['total_appointments'] as int));

      return metrics;
    } catch (e) {
      debugPrint('Error fetching doctor performance: $e');
      return [];
    }
  }

  /// Get patient demographics
  Future<Map<String, dynamic>> getPatientDemographics() async {
    try {
      final patients = await _supabase
          .from('patients')
          .select('gender, blood_group, date_of_birth');

      final patientList = List<Map<String, dynamic>>.from(patients);

      // Gender distribution
      final genderCounts = <String, int>{};
      for (var patient in patientList) {
        final gender = patient['gender']?.toString() ?? 'unknown';
        genderCounts[gender] = (genderCounts[gender] ?? 0) + 1;
      }

      // Blood group distribution
      final bloodGroupCounts = <String, int>{};
      for (var patient in patientList) {
        final bloodGroup = patient['blood_group']?.toString() ?? 'unknown';
        bloodGroupCounts[bloodGroup] = (bloodGroupCounts[bloodGroup] ?? 0) + 1;
      }

      // Age group distribution
      final ageGroupCounts = <String, int>{
        '0-17': 0,
        '18-30': 0,
        '31-45': 0,
        '46-60': 0,
        '60+': 0,
        'unknown': 0,
      };

      for (var patient in patientList) {
        if (patient['date_of_birth'] != null) {
          try {
            final dob = DateTime.parse(patient['date_of_birth']);
            final age = DateTime.now().difference(dob).inDays ~/ 365;

            if (age < 18) {
              ageGroupCounts['0-17'] = ageGroupCounts['0-17']! + 1;
            } else if (age <= 30) {
              ageGroupCounts['18-30'] = ageGroupCounts['18-30']! + 1;
            } else if (age <= 45) {
              ageGroupCounts['31-45'] = ageGroupCounts['31-45']! + 1;
            } else if (age <= 60) {
              ageGroupCounts['46-60'] = ageGroupCounts['46-60']! + 1;
            } else {
              ageGroupCounts['60+'] = ageGroupCounts['60+']! + 1;
            }
          } catch (_) {
            ageGroupCounts['unknown'] = ageGroupCounts['unknown']! + 1;
          }
        } else {
          ageGroupCounts['unknown'] = ageGroupCounts['unknown']! + 1;
        }
      }

      return {
        'total_patients': patientList.length,
        'gender_distribution': genderCounts,
        'blood_group_distribution': bloodGroupCounts,
        'age_group_distribution': ageGroupCounts,
      };
    } catch (e) {
      debugPrint('Error fetching patient demographics: $e');
      return {
        'total_patients': 0,
        'gender_distribution': {},
        'blood_group_distribution': {},
        'age_group_distribution': {},
      };
    }
  }

  /// Get revenue analytics (based on consultation fees)
  Future<Map<String, dynamic>> getRevenueAnalytics({
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
            doctors(consultation_fee)
          ''')
          .eq('status', 'completed');

      if (startDate != null) {
        query = query.gte('appointment_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('appointment_date', endDate.toIso8601String());
      }

      final appointments = await query;
      final appointmentList = List<Map<String, dynamic>>.from(appointments);

      double totalRevenue = 0;
      final revenueByMonth = <String, double>{};

      for (var appointment in appointmentList) {
        final fee = appointment['doctors']?['consultation_fee'] ?? 0;
        totalRevenue += (fee as num).toDouble();

        // Group by month
        final date = DateTime.parse(appointment['appointment_date']);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        revenueByMonth[monthKey] = (revenueByMonth[monthKey] ?? 0) + fee.toDouble();
      }

      return {
        'total_revenue': totalRevenue,
        'total_completed': appointmentList.length,
        'average_per_appointment': appointmentList.isNotEmpty
            ? totalRevenue / appointmentList.length
            : 0,
        'revenue_by_month': revenueByMonth,
      };
    } catch (e) {
      debugPrint('Error fetching revenue analytics: $e');
      return {
        'total_revenue': 0,
        'total_completed': 0,
        'average_per_appointment': 0,
        'revenue_by_month': {},
      };
    }
  }

  /// Get summary statistics for dashboard
  Future<Map<String, dynamic>> getDashboardSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Total patients
      final patientsCount = await _supabase
          .from('patients')
          .select('id')
          .count(CountOption.exact);

      // Total doctors
      final doctorsCount = await _supabase
          .from('doctors')
          .select('id')
          .count(CountOption.exact);

      // Verified doctors
      final verifiedDoctorsCount = await _supabase
          .from('doctors')
          .select('id')
          .eq('verification_status', 'verified')
          .count(CountOption.exact);

      // Pending verification
      final pendingVerificationCount = await _supabase
          .from('doctors')
          .select('id')
          .eq('verification_status', 'pending')
          .count(CountOption.exact);

      // Appointments query
      var appointmentsQuery = _supabase.from('appointments').select('id');
      if (startDate != null) {
        appointmentsQuery = appointmentsQuery.gte('appointment_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        appointmentsQuery = appointmentsQuery.lte('appointment_date', endDate.toIso8601String());
      }
      final appointmentsCount = await appointmentsQuery.count(CountOption.exact);

      // Today's appointments
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayAppointmentsCount = await _supabase
          .from('appointments')
          .select('id')
          .gte('appointment_date', todayStart.toIso8601String())
          .lt('appointment_date', todayEnd.toIso8601String())
          .count(CountOption.exact);

      // This week's appointments
      final weekStart = todayStart.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weekAppointmentsCount = await _supabase
          .from('appointments')
          .select('id')
          .gte('appointment_date', weekStart.toIso8601String())
          .lt('appointment_date', weekEnd.toIso8601String())
          .count(CountOption.exact);

      return {
        'total_patients': patientsCount.count,
        'total_doctors': doctorsCount.count,
        'verified_doctors': verifiedDoctorsCount.count,
        'pending_verification': pendingVerificationCount.count,
        'total_appointments': appointmentsCount.count,
        'today_appointments': todayAppointmentsCount.count,
        'week_appointments': weekAppointmentsCount.count,
      };
    } catch (e) {
      debugPrint('Error fetching dashboard summary: $e');
      return {
        'total_patients': 0,
        'total_doctors': 0,
        'verified_doctors': 0,
        'pending_verification': 0,
        'total_appointments': 0,
        'today_appointments': 0,
        'week_appointments': 0,
      };
    }
  }

  // ============================================================================
  // NO-SHOW ANALYTICS METHODS
  // ============================================================================

  /// Get no-show summary statistics
  Future<Map<String, dynamic>> getNoShowSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get all appointments in the date range
      final appointments = await _supabase
          .from('appointments')
          .select('id, status, appointment_date, cancelled_at, doctors(consultation_fee)')
          .gte('appointment_date', startDate.toIso8601String())
          .lte('appointment_date', endDate.toIso8601String());

      final appointmentList = List<Map<String, dynamic>>.from(appointments);
      final totalAppointments = appointmentList.length;

      // Count no-shows
      final noShows = appointmentList
          .where((a) => a['status'] == 'no_show')
          .length;

      // Count late cancellations: cancelled with fewer than 4 hours' notice.
      // Only counted when both cancelled_at and appointment_date are present.
      const lateCancellationThresholdHours = 4;
      int lateCancellations = 0;
      for (var appointment in appointmentList) {
        if (appointment['status'] == 'cancelled') {
          final cancelledAtStr = appointment['cancelled_at'] as String?;
          final apptDateStr    = appointment['appointment_date'] as String?;
          if (cancelledAtStr != null && apptDateStr != null) {
            final cancelTime = DateTime.parse(cancelledAtStr);
            final apptTime   = DateTime.parse(apptDateStr);
            final hoursNotice = apptTime.difference(cancelTime).inHours;
            if (hoursNotice < lateCancellationThresholdHours) {
              lateCancellations++;
            }
          }
        }
      }

      // Calculate no-show rate
      final noShowRate = totalAppointments > 0
          ? (noShows / totalAppointments * 100).toDouble()
          : 0.0;

      // Estimate cost impact (based on average consultation fee)
      double estimatedCost = 0;
      for (var appointment in appointmentList) {
        if (appointment['status'] == 'no_show') {
          final fee = appointment['doctors']?['consultation_fee'] ?? 50.0;
          estimatedCost += (fee as num).toDouble();
        }
      }

      return {
        'total_appointments': totalAppointments,
        'no_shows': noShows,
        'no_show_rate': noShowRate,
        'late_cancellations': lateCancellations,
        'estimated_cost': estimatedCost,
      };
    } catch (e) {
      debugPrint('Error fetching no-show summary: $e');
      return {
        'total_appointments': 0,
        'no_shows': 0,
        'no_show_rate': 0.0,
        'late_cancellations': 0,
        'estimated_cost': 0.0,
      };
    }
  }

  /// Get no-show trend data over time.
  /// Groups by week when the range exceeds 30 days to avoid 100% spikes
  /// from days with only 1-2 appointments.
  Future<List<Map<String, dynamic>>> getNoShowTrend({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final appointments = await _supabase
          .from('appointments')
          .select('id, status, appointment_date')
          .gte('appointment_date', startDate.toIso8601String())
          .lte('appointment_date', DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).toIso8601String())
          .order('appointment_date');

      final appointmentList = List<Map<String, dynamic>>.from(appointments);
      final groupByWeek = endDate.difference(startDate).inDays > 30;

      final Map<String, Map<String, int>> bucketStats = {};

      for (var appointment in appointmentList) {
        final date = DateTime.parse(appointment['appointment_date']);
        String bucketKey;
        if (groupByWeek) {
          // Use the Monday of the appointment's week as the bucket key
          final monday = date.subtract(Duration(days: date.weekday - 1));
          bucketKey = '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
        } else {
          bucketKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }

        bucketStats.putIfAbsent(bucketKey, () => {'total': 0, 'no_shows': 0});
        bucketStats[bucketKey]!['total'] = bucketStats[bucketKey]!['total']! + 1;
        if (appointment['status'] == 'no_show') {
          bucketStats[bucketKey]!['no_shows'] = bucketStats[bucketKey]!['no_shows']! + 1;
        }
      }

      final List<Map<String, dynamic>> trendData = [];
      bucketStats.forEach((date, stats) {
        final total = stats['total']!;
        final noShows = stats['no_shows']!;
        trendData.add({
          'date': date,
          'total': total,
          'no_shows': noShows,
          'rate': total > 0 ? (noShows / total * 100).toDouble() : 0.0,
        });
      });

      trendData.sort((a, b) => a['date'].compareTo(b['date']));
      return trendData;
    } catch (e) {
      debugPrint('Error fetching no-show trend: $e');
      return [];
    }
  }

  /// Get no-show breakdown by doctor
  Future<List<Map<String, dynamic>>> getNoShowByDoctor({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final appointments = await _supabase
          .from('appointments')
          .select('''
            id,
            status,
            doctors(
              id,
              first_name,
              last_name,
              doctor_specialties(
                is_primary,
                specialties(name)
              )
            )
          ''')
          .gte('appointment_date', startDate.toIso8601String())
          .lte('appointment_date', endDate.toIso8601String());

      final appointmentList = List<Map<String, dynamic>>.from(appointments);

      // Group by doctor
      final Map<String, Map<String, dynamic>> doctorStats = {};

      for (var appointment in appointmentList) {
        final doctor = appointment['doctors'];
        if (doctor == null) continue;

        final doctorId = doctor['id'];
        final doctorName = 'Dr. ${doctor['first_name']} ${doctor['last_name']}';

        if (!doctorStats.containsKey(doctorId)) {
          // Get primary specialty
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

          doctorStats[doctorId] = {
            'doctor_id': doctorId,
            'name': doctorName,
            'specialty': specialty,
            'total': 0,
            'no_shows': 0,
          };
        }

        doctorStats[doctorId]!['total'] = doctorStats[doctorId]!['total'] + 1;
        if (appointment['status'] == 'no_show') {
          doctorStats[doctorId]!['no_shows'] = doctorStats[doctorId]!['no_shows'] + 1;
        }
      }

      // Convert to list and calculate rates
      final List<Map<String, dynamic>> result = [];
      doctorStats.forEach((_, stats) {
        final total = stats['total'] as int;
        final noShows = stats['no_shows'] as int;
        final rate = total > 0 ? (noShows / total * 100).toDouble() : 0.0;

        result.add({
          ...stats,
          'rate': rate,
        });
      });

      // Sort by no_shows descending
      result.sort((a, b) => (b['no_shows'] as int).compareTo(a['no_shows'] as int));

      return result;
    } catch (e) {
      debugPrint('Error fetching no-show by doctor: $e');
      return [];
    }
  }

  /// Get no-show breakdown by day of week
  Future<List<Map<String, dynamic>>> getNoShowByDayOfWeek({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final appointments = await _supabase
          .from('appointments')
          .select('id, status, appointment_date')
          .gte('appointment_date', startDate.toIso8601String())
          .lte('appointment_date', endDate.toIso8601String());

      final appointmentList = List<Map<String, dynamic>>.from(appointments);

      // Initialize stats for each day of week
      final Map<int, Map<String, int>> dayStats = {
        1: {'total': 0, 'no_shows': 0}, // Monday
        2: {'total': 0, 'no_shows': 0}, // Tuesday
        3: {'total': 0, 'no_shows': 0}, // Wednesday
        4: {'total': 0, 'no_shows': 0}, // Thursday
        5: {'total': 0, 'no_shows': 0}, // Friday
        6: {'total': 0, 'no_shows': 0}, // Saturday
        7: {'total': 0, 'no_shows': 0}, // Sunday
      };

      const dayNames = {
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
        7: 'Sunday',
      };

      for (var appointment in appointmentList) {
        final date = DateTime.parse(appointment['appointment_date']);
        final dayOfWeek = date.weekday;

        dayStats[dayOfWeek]!['total'] = dayStats[dayOfWeek]!['total']! + 1;
        if (appointment['status'] == 'no_show') {
          dayStats[dayOfWeek]!['no_shows'] = dayStats[dayOfWeek]!['no_shows']! + 1;
        }
      }

      // Convert to list with rates
      final List<Map<String, dynamic>> result = [];
      dayStats.forEach((day, stats) {
        final total = stats['total']!;
        final noShows = stats['no_shows']!;
        final rate = total > 0 ? (noShows / total * 100).toDouble() : 0.0;

        result.add({
          'day': dayNames[day]!,
          'day_number': day,
          'total': total,
          'no_shows': noShows,
          'rate': rate,
        });
      });

      return result;
    } catch (e) {
      debugPrint('Error fetching no-show by day of week: $e');
      return [];
    }
  }

  /// Get no-show breakdown by time slot
  Future<List<Map<String, dynamic>>> getNoShowByTimeSlot({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final appointments = await _supabase
          .from('appointments')
          .select('id, status, appointment_date')
          .gte('appointment_date', startDate.toIso8601String())
          .lte('appointment_date', endDate.toIso8601String());

      final appointmentList = List<Map<String, dynamic>>.from(appointments);

      // Group by hour of day
      final Map<int, Map<String, int>> hourStats = {};

      for (var appointment in appointmentList) {
        final date = DateTime.parse(appointment['appointment_date']);
        final hour = date.hour;

        if (!hourStats.containsKey(hour)) {
          hourStats[hour] = {'total': 0, 'no_shows': 0};
        }

        hourStats[hour]!['total'] = hourStats[hour]!['total']! + 1;
        if (appointment['status'] == 'no_show') {
          hourStats[hour]!['no_shows'] = hourStats[hour]!['no_shows']! + 1;
        }
      }

      // Convert to list with rates
      final List<Map<String, dynamic>> result = [];
      hourStats.forEach((hour, stats) {
        final total = stats['total']!;
        final noShows = stats['no_shows']!;
        final rate = total > 0 ? (noShows / total * 100).toDouble() : 0.0;

        // Format time slot (e.g., "09:00 AM")
        final period = hour < 12 ? 'AM' : 'PM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final timeSlot = '${displayHour.toString().padLeft(2, '0')}:00 $period';

        result.add({
          'time_slot': timeSlot,
          'hour': hour,
          'total': total,
          'no_shows': noShows,
          'rate': rate,
        });
      });

      // Sort by hour
      result.sort((a, b) => (a['hour'] as int).compareTo(b['hour'] as int));

      return result;
    } catch (e) {
      debugPrint('Error fetching no-show by time slot: $e');
      return [];
    }
  }

  /// Get top no-show patients
  Future<List<Map<String, dynamic>>> getTopNoShowPatients({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final appointments = await _supabase
          .from('appointments')
          .select('''
            id,
            status,
            patients(
              id,
              first_name,
              last_name,
              phone,
              no_show_count
            )
          ''')
          .gte('appointment_date', startDate.toIso8601String())
          .lte('appointment_date', endDate.toIso8601String());

      final appointmentList = List<Map<String, dynamic>>.from(appointments);

      // Group by patient
      final Map<String, Map<String, dynamic>> patientStats = {};

      for (var appointment in appointmentList) {
        final patient = appointment['patients'];
        if (patient == null) continue;

        final patientId = patient['id'];
        final patientName = '${patient['first_name']} ${patient['last_name']}';
        final phone = patient['phone'] ?? 'N/A';
        final totalNoShowCount = patient['no_show_count'] ?? 0;

        if (!patientStats.containsKey(patientId)) {
          patientStats[patientId] = {
            'patient_id': patientId,
            'name': patientName,
            'phone': phone,
            'total_appointments': 0,
            'no_shows': 0,
            'total_no_show_count': totalNoShowCount,
          };
        }

        patientStats[patientId]!['total_appointments'] =
            patientStats[patientId]!['total_appointments'] + 1;
        if (appointment['status'] == 'no_show') {
          patientStats[patientId]!['no_shows'] =
              patientStats[patientId]!['no_shows'] + 1;
        }
      }

      // Convert to list and calculate rates
      final List<Map<String, dynamic>> result = [];
      patientStats.forEach((_, stats) {
        final total = stats['total_appointments'] as int;
        final noShows = stats['no_shows'] as int;
        final rate = total > 0 ? (noShows / total * 100).toDouble() : 0.0;

        // Determine risk level based on no-show rate and count
        String riskLevel;
        if (noShows >= 3 || rate >= 50) {
          riskLevel = 'high';
        } else if (noShows >= 2 || rate >= 30) {
          riskLevel = 'medium';
        } else {
          riskLevel = 'low';
        }

        result.add({
          ...stats,
          'rate': rate,
          'risk_level': riskLevel,
        });
      });

      // Sort by no_shows descending
      result.sort((a, b) => (b['no_shows'] as int).compareTo(a['no_shows'] as int));

      // Return top N
      return result.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching top no-show patients: $e');
      return [];
    }
  }

  /// Get reminder impact comparison (before/after reminder system)
  Future<Map<String, dynamic>> getReminderImpactComparison() async {
    try {
      final now = DateTime.now();

      // Determine when the reminder system went live by finding the earliest
      // reminder record in the database.  Falls back to 60 days ago so we
      // always have a valid comparison window even before any reminders exist.
      DateTime reminderSystemDate;
      try {
        final firstReminder = await _supabase
            .from('appointment_reminders')
            .select('created_at')
            .order('created_at')
            .limit(1)
            .maybeSingle();
        if (firstReminder != null && firstReminder['created_at'] != null) {
          reminderSystemDate =
              DateTime.parse(firstReminder['created_at'] as String);
        } else {
          reminderSystemDate = now.subtract(const Duration(days: 60));
        }
      } catch (_) {
        reminderSystemDate = now.subtract(const Duration(days: 60));
      }

      final periodLength = 30; // Compare 30 days before and after

      // Before reminder system
      final beforeStart = reminderSystemDate.subtract(Duration(days: periodLength));
      final beforeEnd = reminderSystemDate;

      // After reminder system
      final afterStart = reminderSystemDate;
      final afterEnd = reminderSystemDate.add(Duration(days: periodLength));

      // Don't go beyond current date
      final actualAfterEnd = afterEnd.isAfter(now) ? now : afterEnd;

      // Get stats before reminder system
      final beforeAppointments = await _supabase
          .from('appointments')
          .select('id, status')
          .gte('appointment_date', beforeStart.toIso8601String())
          .lte('appointment_date', beforeEnd.toIso8601String());

      final beforeList = List<Map<String, dynamic>>.from(beforeAppointments);
      final beforeTotal = beforeList.length;
      final beforeNoShows = beforeList.where((a) => a['status'] == 'no_show').length;
      final beforeRate = beforeTotal > 0
          ? (beforeNoShows / beforeTotal * 100).toDouble()
          : 0.0;

      // Get stats after reminder system
      final afterAppointments = await _supabase
          .from('appointments')
          .select('id, status')
          .gte('appointment_date', afterStart.toIso8601String())
          .lte('appointment_date', actualAfterEnd.toIso8601String());

      final afterList = List<Map<String, dynamic>>.from(afterAppointments);
      final afterTotal = afterList.length;
      final afterNoShows = afterList.where((a) => a['status'] == 'no_show').length;
      final afterRate = afterTotal > 0
          ? (afterNoShows / afterTotal * 100).toDouble()
          : 0.0;

      // Calculate improvement
      final improvement = beforeRate - afterRate;
      final improvementPercent = beforeRate > 0
          ? ((improvement / beforeRate) * 100).toDouble()
          : 0.0;

      return {
        'before': {
          'total': beforeTotal,
          'no_shows': beforeNoShows,
          'rate': beforeRate,
          'start_date': beforeStart.toIso8601String(),
          'end_date': beforeEnd.toIso8601String(),
        },
        'after': {
          'total': afterTotal,
          'no_shows': afterNoShows,
          'rate': afterRate,
          'start_date': afterStart.toIso8601String(),
          'end_date': actualAfterEnd.toIso8601String(),
        },
        'improvement': {
          'absolute': improvement,
          'percent': improvementPercent,
        },
      };
    } catch (e) {
      debugPrint('Error fetching reminder impact comparison: $e');
      return {
        'before': {'total': 0, 'no_shows': 0, 'rate': 0.0},
        'after': {'total': 0, 'no_shows': 0, 'rate': 0.0},
        'improvement': {'absolute': 0.0, 'percent': 0.0},
      };
    }
  }
}
