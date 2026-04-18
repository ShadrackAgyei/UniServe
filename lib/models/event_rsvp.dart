class EventRsvp {
  final String id;
  final String eventId;
  final String userId;
  final String qrToken;
  final bool checkedIn;

  EventRsvp({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.qrToken,
    required this.checkedIn,
  });

  factory EventRsvp.fromSupabase(Map<String, dynamic> json) {
    return EventRsvp(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      qrToken: json['qr_token'] as String,
      checkedIn: json['checked_in'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSupabase() => {
        'event_id': eventId,
        'user_id': userId,
      };
}
