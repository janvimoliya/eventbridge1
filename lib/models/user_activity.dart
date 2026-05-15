class UserActivity {
  const UserActivity({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.description,
    required this.timestamp,
    this.bookingId,
    this.eventId,
    this.details,
  });

  final String id;
  final String userId;
  final String activityType; // booking, event_view, login, wishlist_add, etc
  final String description;
  final DateTime timestamp;
  final String? bookingId;
  final String? eventId;
  final Map<String, dynamic>? details;

  UserActivity copyWith({
    String? id,
    String? userId,
    String? activityType,
    String? description,
    DateTime? timestamp,
    String? bookingId,
    String? eventId,
    Map<String, dynamic>? details,
  }) {
    return UserActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      bookingId: bookingId ?? this.bookingId,
      eventId: eventId ?? this.eventId,
      details: details ?? this.details,
    );
  }
}
