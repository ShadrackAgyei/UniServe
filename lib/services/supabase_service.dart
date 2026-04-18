import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campus_issue.dart';
import '../models/lost_found_item.dart';
import '../models/campus_notification.dart';
import '../models/emergency_contact.dart';
import '../models/user_profile.dart';
import '../models/class_entry.dart';
import '../models/study_room.dart';
import '../models/study_room_booking.dart';
import '../models/campus_event.dart';
import '../models/event_rsvp.dart';
import '../models/check_in_response.dart';
import '../models/time_of_day_utils.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────

  static Future<UserProfile> signUp({
    required String email,
    required String password,
    required String studentId,
    required String name,
    String? phone,
    String? department,
    String? program,
  }) async {
    try {
      final existingStudentId = await _client
          .from('profiles')
          .select('id')
          .eq('student_id', studentId)
          .maybeSingle();
      if (existingStudentId != null) {
        throw Exception('That student ID is already registered. Try logging in instead.');
      }

      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw Exception('Could not create your account right now. Please try again.');

      await _client.from('profiles').insert({
        'id': user.id,
        'student_id': studentId,
        'name': name,
        'phone': phone,
        'department': department,
        'program': program,
      });

      return await getProfile();
    } catch (error) {
      throw Exception(_friendlyAuthMessage(error, isSignUp: true));
    }
  }

  static Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return await getProfile();
    } catch (error) {
      throw Exception(_friendlyAuthMessage(error, isSignUp: false));
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static String? get currentUserId => _client.auth.currentUser?.id;

  static Session? get currentSession => _client.auth.currentSession;

  // ── Profile ───────────────────────────────────────────

  static Future<UserProfile> getProfile() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    // Attach email from auth user
    data['email'] = _client.auth.currentUser!.email;
    return UserProfile.fromSupabase(data);
  }

  static Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? department,
    String? program,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (department != null) updates['department'] = department;
    if (program != null) updates['program'] = program;

    await _client.from('profiles').update(updates).eq('id', userId);
    return await getProfile();
  }

  static Future<String> uploadProfilePhoto(File file) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final path = '$userId/avatar.jpg';
    await _client.storage.from('profile-photos').upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    final url = _client.storage.from('profile-photos').getPublicUrl(path);

    await _client.from('profiles').update({
      'profile_photo_url': url,
    }).eq('id', userId);

    return url;
  }

  // ── Campus Issues ─────────────────────────────────────

  static Future<List<CampusIssue>> getIssues() async {
    final data = await _client
        .from('campus_issues')
        .select()
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(data);
    final reporterNames = await _fetchReporterNames(rows);
    return rows
        .map((row) => CampusIssue.fromSupabase({
              ...row,
              'reporter_name': reporterNames[row['user_id']],
            }))
        .toList();
  }

  static Future<CampusIssue> insertIssue({
    required String title,
    required String description,
    required String category,
    File? imageFile,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage('issue-images', imageFile);
    }

    final data = await _client.from('campus_issues').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'image_url': imageUrl,
    }).select().single();

    return CampusIssue.fromSupabase(data);
  }

  static Future<void> updateIssueStatus(int id, String status) async {
    await _assertOwnsRecord('campus_issues', id);
    await _client.from('campus_issues').update({
      'status': status,
    }).eq('id', id);
  }

  static Future<void> deleteIssue(int id) async {
    await _assertOwnsRecord('campus_issues', id);
    await _client.from('campus_issues').delete().eq('id', id);
  }

  // ── Lost & Found ──────────────────────────────────────

  static Future<List<LostFoundItem>> getLostFoundItems() async {
    final data = await _client
        .from('lost_found_items')
        .select()
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(data);
    final reporterNames = await _fetchReporterNames(rows);
    return rows
        .map((row) => LostFoundItem.fromSupabase({
              ...row,
              'reporter_name': reporterNames[row['user_id']],
            }))
        .toList();
  }

  static Future<LostFoundItem> insertLostFoundItem({
    required String title,
    required String description,
    required String type,
    required String location,
    required String contactInfo,
    File? imageFile,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage('lost-found-images', imageFile);
    }

    final data = await _client.from('lost_found_items').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'type': type,
      'location': location,
      'contact_info': contactInfo,
      'image_url': imageUrl,
    }).select().single();

    return LostFoundItem.fromSupabase(data);
  }

  static Future<void> resolveLostFoundItem(int id) async {
    await _assertOwnsRecord('lost_found_items', id);
    await _client.from('lost_found_items').update({
      'is_resolved': true,
    }).eq('id', id);
  }

  static Future<void> deleteLostFoundItem(int id) async {
    await _assertOwnsRecord('lost_found_items', id);
    await _client.from('lost_found_items').delete().eq('id', id);
  }

  // ── Notifications ─────────────────────────────────────

  static Future<List<CampusNotification>> getNotifications() async {
    final data = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false);
    return data.map((row) => CampusNotification.fromSupabase(row)).toList();
  }

  // ── Emergency Contacts ────────────────────────────────

  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    final data = await _client
        .from('emergency_contacts')
        .select()
        .order('sort_order');
    return data.map((row) => EmergencyContact.fromSupabase(row)).toList();
  }

  // ── Storage Helper ────────────────────────────────────

  static Future<String> _uploadImage(String bucket, File file) async {
    final userId = currentUserId!;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$timestamp.jpg';
    await _client.storage.from(bucket).upload(path, file);
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  static Future<Map<String, String>> _fetchReporterNames(
    List<Map<String, dynamic>> rows,
  ) async {
    final userIds = rows
        .map((row) => row['user_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    if (userIds.isEmpty) return const {};

    final data = await _client
        .from('profiles')
        .select('id, name')
        .inFilter('id', userIds);

    final names = <String, String>{};
    for (final row in data) {
      final map = row;
      final id = map['id'] as String?;
      final name = map['name'] as String?;
      if (id != null && name != null && name.trim().isNotEmpty) {
        names[id] = name;
      }
    }
    return names;
  }

  static Future<void> _assertOwnsRecord(String table, int id) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('You need to log in to do that.');

    final record = await _client
        .from(table)
        .select('user_id')
        .eq('id', id)
        .single();

    if (record['user_id'] != userId) {
      throw Exception('Only the person who reported this can update it.');
    }
  }

  static String _friendlyAuthMessage(
    Object error, {
    required bool isSignUp,
  }) {
    final rawMessage = error.toString().replaceFirst('Exception: ', '');
    final message = rawMessage.toLowerCase();

    if (message.contains('student id is already registered')) {
      return rawMessage;
    }

    if (!isSignUp) {
      if (message.contains('invalid login credentials') ||
          message.contains('invalid_credentials') ||
          message.contains('email not confirmed')) {
        return 'Those credentials do not match our records.';
      }
      return 'We could not log you in. Check your email and password and try again.';
    }

    if (message.contains('user already registered') ||
        message.contains('already registered') ||
        message.contains('already been registered') ||
        message.contains('duplicate key') ||
        message.contains('unique constraint')) {
      return 'An account with those details already exists. Try logging in instead.';
    }

    return 'We could not create your account right now. Please review your details and try again.';
  }

  // ── Class Schedule ────────────────────────────────────

  static Future<List<ClassEntry>> fetchClassSchedule() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');
    final data = await _client
        .from('class_schedule')
        .select()
        .eq('user_id', userId)
        .order('day_of_week')
        .order('start_time');
    return data.map((row) => ClassEntry.fromSupabase(row)).toList();
  }

  static Future<ClassEntry> insertClassEntry(ClassEntry entry) async {
    final data = await _client
        .from('class_schedule')
        .insert(entry.toSupabase())
        .select()
        .single();
    return ClassEntry.fromSupabase(data);
  }

  static Future<void> deleteClassEntry(String id) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('You need to log in to do that.');
    final record = await _client
        .from('class_schedule')
        .select('user_id')
        .eq('id', id)
        .single();
    if (record['user_id'] != userId) {
      throw Exception('Only the person who created this can delete it.');
    }
    await _client.from('class_schedule').delete().eq('id', id);
  }

  // ── Study Rooms ───────────────────────────────────────

  static Future<List<StudyRoom>> fetchStudyRooms() async {
    final data = await _client
        .from('study_rooms')
        .select()
        .order('building')
        .order('name');
    return data.map((row) => StudyRoom.fromSupabase(row)).toList();
  }

  static Future<List<StudyRoomBooking>> fetchRoomBookings(
    String roomId,
    DateTime date,
  ) async {
    final dateStr = formatDate(date);
    final data = await _client
        .from('study_room_bookings')
        .select()
        .eq('room_id', roomId)
        .eq('booking_date', dateStr);
    return data.map((row) => StudyRoomBooking.fromSupabase(row)).toList();
  }

  static Future<List<StudyRoomBooking>> fetchMyBookings() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');
    final data = await _client
        .from('study_room_bookings')
        .select()
        .eq('user_id', userId)
        .order('booking_date')
        .order('start_time');
    return data.map((row) => StudyRoomBooking.fromSupabase(row)).toList();
  }

  static Future<StudyRoomBooking> createRoomBooking({
    required String roomId,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');
    final dateStr = formatDate(date);
    final startStr = formatTimeOfDay(start);
    final endStr = formatTimeOfDay(end);
    final data = await _client
        .from('study_room_bookings')
        .insert({
          'room_id': roomId,
          'user_id': userId,
          'booking_date': dateStr,
          'start_time': startStr,
          'end_time': endStr,
        })
        .select()
        .single();
    return StudyRoomBooking.fromSupabase(data);
  }

  static Future<void> cancelRoomBooking(String id) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('You need to log in to do that.');
    final record = await _client
        .from('study_room_bookings')
        .select('user_id')
        .eq('id', id)
        .single();
    if (record['user_id'] != userId) {
      throw Exception('Only the person who booked this can cancel it.');
    }
    await _client.from('study_room_bookings').delete().eq('id', id);
  }

  // ── Campus Events ─────────────────────────────────────

  static Future<List<CampusEvent>> fetchEvents() async {
    final data = await _client
        .from('campus_events')
        .select()
        .order('event_date')
        .order('start_time');
    return data.map((row) => CampusEvent.fromSupabase(row)).toList();
  }

  static Future<List<EventRsvp>> fetchMyRsvps() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');
    final data = await _client
        .from('event_rsvps')
        .select()
        .eq('user_id', userId);
    return data.map((row) => EventRsvp.fromSupabase(row)).toList();
  }

  static Future<int> getRsvpCount(String eventId) async {
    final data = await _client
        .from('event_rsvps')
        .select('id')
        .eq('event_id', eventId);
    return data.length;
  }

  static Future<EventRsvp> createRsvp(String eventId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');
    final data = await _client
        .from('event_rsvps')
        .insert({'event_id': eventId, 'user_id': userId})
        .select()
        .single();
    return EventRsvp.fromSupabase(data);
  }

  static Future<void> cancelRsvp(String rsvpId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('You need to log in to do that.');
    final record = await _client
        .from('event_rsvps')
        .select('user_id')
        .eq('id', rsvpId)
        .single();
    if (record['user_id'] != userId) {
      throw Exception('Only the person who RSVPed can cancel it.');
    }
    await _client.from('event_rsvps').delete().eq('id', rsvpId);
  }

  // ── QR Check-in ───────────────────────────────────────

  static Future<CheckInResponse> validateAndCheckIn(String qrToken) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');
    final bookingRows = await _client
        .from('study_room_bookings')
        .select('id, checked_in, created_at, room_id')
        .eq('qr_token', qrToken);

    if (bookingRows.isNotEmpty) {
      final row = bookingRows.first;
      if (row['checked_in'] as bool) {
        return CheckInResponse(
          result: CheckInResultType.alreadyCheckedIn,
        );
      }
      await _client
          .from('study_room_bookings')
          .update({'checked_in': true}).eq('id', row['id'] as String);
      final roomRow = await _client
          .from('study_rooms')
          .select('name')
          .eq('id', row['room_id'] as String)
          .maybeSingle();
      return CheckInResponse(
        result: CheckInResultType.success,
        name: roomRow?['name'] as String?,
      );
    }

    final rsvpRows = await _client
        .from('event_rsvps')
        .select('id, checked_in, event_id')
        .eq('qr_token', qrToken);

    if (rsvpRows.isNotEmpty) {
      final row = rsvpRows.first;
      if (row['checked_in'] as bool) {
        return CheckInResponse(result: CheckInResultType.alreadyCheckedIn);
      }
      await _client
          .from('event_rsvps')
          .update({'checked_in': true}).eq('id', row['id'] as String);
      final eventRow = await _client
          .from('campus_events')
          .select('title')
          .eq('id', row['event_id'] as String)
          .maybeSingle();
      return CheckInResponse(
        result: CheckInResultType.success,
        name: eventRow?['title'] as String?,
      );
    }

    return CheckInResponse(result: CheckInResultType.invalid);
  }
}
