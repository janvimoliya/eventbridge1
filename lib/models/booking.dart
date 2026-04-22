class BookingModel {
  const BookingModel({
    required this.id,
    required this.userName,
    required this.eventName,
    required this.tickets,
    required this.amount,
    required this.paymentStatus,
    required this.date,
    required this.qrData,
    this.isCancelled = false,
    this.isRefunded = false,
  });

  final String id;
  final String userName;
  final String eventName;
  final int tickets;
  final double amount;
  final String paymentStatus;
  final DateTime date;
  final String qrData;
  final bool isCancelled;
  final bool isRefunded;

  BookingModel copyWith({
    String? id,
    String? userName,
    String? eventName,
    int? tickets,
    double? amount,
    String? paymentStatus,
    DateTime? date,
    String? qrData,
    bool? isCancelled,
    bool? isRefunded,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      eventName: eventName ?? this.eventName,
      tickets: tickets ?? this.tickets,
      amount: amount ?? this.amount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      date: date ?? this.date,
      qrData: qrData ?? this.qrData,
      isCancelled: isCancelled ?? this.isCancelled,
      isRefunded: isRefunded ?? this.isRefunded,
    );
  }
}
