class AppNotificationModel {
  const AppNotificationModel({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
  });

  final String title;
  final String message;
  final DateTime timestamp;
  final String type;
}

class NotificationService {
  Future<List<AppNotificationModel>> fetchDefaultNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return [
      AppNotificationModel(
        title: 'Upcoming Event Reminder',
        message: 'Your workshop starts tomorrow at 10:00 AM.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'reminder',
      ),
      AppNotificationModel(
        title: 'Booking Confirmed',
        message: 'Your ticket has been generated successfully.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'confirmation',
      ),
      AppNotificationModel(
        title: 'Personalized Offer',
        message: 'Concert lovers get 15% cashback this weekend.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: 'offer',
      ),
    ];
  }
}
