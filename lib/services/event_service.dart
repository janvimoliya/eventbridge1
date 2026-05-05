import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/event.dart';
import '../models/user.dart';

class EventService extends ChangeNotifier {
  EventService() {
    _bindFirestoreCollections();
    unawaited(_seedDefaultCategoryEvents());
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _bookingsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ticketsSubscription;
  String? _eventsError;
  String? _usersError;
  // Events are loaded exclusively from Firestore. Keep in-memory list empty
  // so the UI displays only documents present in the `events` collection.
  final List<EventModel> _events = [];

  // No static default events. Events must exist in Firestore.
  final List<EventModel> _defaultCategoryEvents = [];

  final List<AppUserModel> _users = [];

  // In-memory lists for dynamic data
  final List<BookingModel> _bookings = [];
  final List<BookingModel> _bookingsFromBookingsCollection = [];
  final List<BookingModel> _bookingsFromTicketsCollection = [];
  final List<String> _adminNotifications = [];

  void _bindFirestoreCollections() {
    _eventsSubscription = _firestore
        .collection('events')
        .snapshots()
        .listen(
          (snapshot) {
            final loaded = snapshot.docs
                .map((doc) => _eventFromMap(doc.id, doc.data()))
                .toList();

            _events
              ..clear()
              ..addAll(loaded);

            _eventsError = null;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to listen events collection: $error');
            if (error is FirebaseException) {
              _eventsError =
                  '${error.code}: ${error.message ?? 'Firestore error'}';
            } else {
              _eventsError = error.toString();
            }
            notifyListeners();
          },
        );

    _usersSubscription = _firestore
        .collection('users')
        .snapshots()
        .listen(
          (snapshot) {
            final loaded = snapshot.docs
                .map((doc) => _userFromMap(doc.id, doc.data()))
                .toList();

            _users
              ..clear()
              ..addAll(loaded);

            _usersError = null;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to listen users collection: $error');
            if (error is FirebaseException) {
              _usersError =
                  '${error.code}: ${error.message ?? 'Firestore error'}';
            } else {
              _usersError = error.toString();
            }
            notifyListeners();
          },
        );

    _bookingsSubscription = _firestore
        .collection('bookings')
        .snapshots()
        .listen(
          (snapshot) {
            _bookingsFromBookingsCollection
              ..clear()
              ..addAll(
                snapshot.docs.map(
                  (doc) =>
                      _bookingFromMap(doc.id, doc.data(), source: 'bookings'),
                ),
              );

            _syncMergedBookings();
          },
          onError: (error) {
            debugPrint('Failed to listen bookings collection: $error');
          },
        );

    _ticketsSubscription = _firestore
        .collection('tickets')
        .snapshots()
        .listen(
          (snapshot) {
            _bookingsFromTicketsCollection
              ..clear()
              ..addAll(
                snapshot.docs.map(
                  (doc) =>
                      _bookingFromMap(doc.id, doc.data(), source: 'tickets'),
                ),
              );

            _syncMergedBookings();
          },
          onError: (error) {
            debugPrint('Failed to listen tickets collection: $error');
          },
        );
  }

  void _syncMergedBookings() {
    final merged = <BookingModel>[];
    merged.addAll(_bookingsFromBookingsCollection);

    final existingKeys = merged.map((b) => b.id).toSet();
    for (final booking in _bookingsFromTicketsCollection) {
      if (existingKeys.contains(booking.id)) {
        continue;
      }
      merged.add(booking);
    }

    merged.sort((a, b) => b.date.compareTo(a.date));

    _bookings
      ..clear()
      ..addAll(merged);

    notifyListeners();
  }

  Future<void> _seedDefaultCategoryEvents() async {
    try {
      final eventsRef = _firestore.collection('events');
      final snapshot = await eventsRef.get();
      final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
      final batch = _firestore.batch();
      var writeCount = 0;

      // Combine any in-code events and default category events so they
      // are seeded into Firestore on first run. This ensures events are
      // available from the database instead of only statically in code.
      final toSeed = <EventModel>[];
      toSeed.addAll(_events);
      toSeed.addAll(_defaultCategoryEvents);

      for (final event in toSeed) {
        if (existingIds.contains(event.id)) {
          continue;
        }

        batch.set(eventsRef.doc(event.id), _eventPayload(event, true));
        writeCount += 1;
      }

      if (writeCount > 0) {
        await batch.commit();
      }
    } catch (error) {
      debugPrint('Failed to seed default category events: $error');
    }
  }

  List<EventModel> get events => List.unmodifiable(_events);
  List<AppUserModel> get users => List.unmodifiable(_users);
  List<BookingModel> get bookings => List.unmodifiable(_bookings);
  List<String> get adminNotifications => List.unmodifiable(_adminNotifications);
  String? get eventsError => _eventsError;
  String? get usersError => _usersError;

  int get totalEvents => _events.length;
  int get totalUsers => _users.length;
  int get totalBookings => _bookings.length;

  double get totalRevenue {
    return _bookings
        .where(
          (booking) =>
              booking.paymentStatus.toLowerCase() == 'paid' &&
              !booking.isRefunded &&
              !booking.isCancelled,
        )
        .fold<double>(0, (total, item) => total + item.amount);
  }

  double get adminCommissionRevenue => totalRevenue * 0.10;

  Map<String, double> get monthlyRevenue {
    final months = _lastNMonths(4);
    final result = <String, double>{};
    for (final month in months) {
      result[_monthLabel(month)] = 0;
    }

    for (final booking in _bookings) {
      if (booking.paymentStatus.toLowerCase() != 'paid' ||
          booking.isRefunded ||
          booking.isCancelled) {
        continue;
      }

      final key = _monthLabel(DateTime(booking.date.year, booking.date.month));
      if (result.containsKey(key)) {
        result[key] = (result[key] ?? 0) + booking.amount;
      }
    }

    return result;
  }

  Map<String, int> get monthlyBookings {
    final months = _lastNMonths(4);
    final result = <String, int>{};
    for (final month in months) {
      result[_monthLabel(month)] = 0;
    }

    for (final booking in _bookings) {
      if (booking.isCancelled) {
        continue;
      }

      final key = _monthLabel(DateTime(booking.date.year, booking.date.month));
      if (result.containsKey(key)) {
        result[key] = (result[key] ?? 0) + 1;
      }
    }

    return result;
  }

  Future<void> upsertEvent({
    String? eventId,
    required String title,
    required EventCategory category,
    required DateTime date,
    required String location,
    required double price,
    required String description,
    required String imageUrl,
    required int seatCapacity,
  }) async {
    final id = eventId ?? 'ad_${DateTime.now().millisecondsSinceEpoch}';
    final model = EventModel(
      id: id,
      title: title,
      category: category,
      date: date,
      location: location,
      price: price,
      imageUrl: imageUrl,
      description: description,
      schedule: ['Doors Open', 'Main Session'],
      attendees: ['Capacity: $seatCapacity'],
      ticketTypes: {'General': price},
      isTrending: false,
      reviews: const [],
      hasArVrPreview: false,
      organizerName: 'EventBridge Organizer',
      organizerVerified: true,
    );

    final existingIndex = _events.indexWhere((event) => event.id == id);
    if (existingIndex >= 0) {
      _events[existingIndex] = model;
    } else {
      _events.insert(0, model);
    }

    final payload = {
      'title': title,
      'category': category.name,
      'date': Timestamp.fromDate(date),
      'location': location,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'schedule': model.schedule,
      'attendees': model.attendees,
      'ticketTypes': model.ticketTypes,
      'isTrending': false,
      'hasArVrPreview': false,
      'organizerName': model.organizerName,
      'organizerVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (eventId == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    try {
      await _firestore
          .collection('events')
          .doc(id)
          .set(payload, SetOptions(merge: true));
      notifyListeners();
    } catch (error) {
      debugPrint('Failed to upsert event in Firestore: $error');
      rethrow;
    }
  }

  void deleteEvent(String id) {
    _events.removeWhere((event) => event.id == id);

    _firestore.collection('events').doc(id).delete().catchError((error) {
      debugPrint('Failed to delete event in Firestore: $error');
    });

    notifyListeners();
  }

  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index < 0) {
      return;
    }

    _bookings[index] = _bookings[index].copyWith(
      isCancelled: true,
      paymentStatus: 'Cancelled',
    );
    notifyListeners();
  }

  void refundBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index < 0) {
      return;
    }

    _bookings[index] = _bookings[index].copyWith(
      isRefunded: true,
      paymentStatus: 'Refunded',
    );
    notifyListeners();
  }

  void toggleUserBlocked(String userId) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index < 0) {
      return;
    }

    final newValue = !_users[index].isBlocked;
    _users[index] = _users[index].copyWith(isBlocked: newValue);

    _firestore
        .collection('users')
        .doc(userId)
        .set({
          'isBlocked': newValue,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((error) {
          debugPrint('Failed to update user block state: $error');
        });

    notifyListeners();
  }

  void toggleOrganizerVerification(String userId) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index < 0 || !_users[index].isOrganizer) {
      return;
    }

    final newValue = !_users[index].isVerifiedOrganizer;
    _users[index] = _users[index].copyWith(isVerifiedOrganizer: newValue);

    _firestore
        .collection('users')
        .doc(userId)
        .set({
          'isVerifiedOrganizer': newValue,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((error) {
          debugPrint('Failed to update organizer verification: $error');
        });

    notifyListeners();
  }

  void sendAdminNotification({required String title, required String message}) {
    if (title.trim().isEmpty || message.trim().isEmpty) {
      return;
    }

    _adminNotifications.insert(0, '$title: $message');
    notifyListeners();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _usersSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.dispose();
  }
}

List<DateTime> _lastNMonths(int count) {
  final now = DateTime.now();
  final months = <DateTime>[];
  for (var i = count - 1; i >= 0; i--) {
    months.add(DateTime(now.year, now.month - i));
  }
  return months;
}

String _monthLabel(DateTime monthDate) {
  const labels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return labels[monthDate.month - 1];
}

BookingModel _bookingFromMap(
  String id,
  Map<String, dynamic> data, {
  required String source,
}) {
  final userName = (data['userName'] ?? data['holderName'] ?? 'Unknown User')
      .toString();
  final eventName =
      (data['eventName'] ?? data['eventTitle'] ?? 'Untitled Event').toString();
  final tickets = _toInt(data['tickets']) ?? _toInt(data['quantity']) ?? 1;
  final amount = _toDouble(data['amount']) ?? 0;
  final paymentStatus = (data['paymentStatus'] ?? data['status'] ?? 'Paid')
      .toString();
  final date =
      _parseDate(data['date']) ??
      _parseDate(data['createdAt']) ??
      _parseDate(data['eventDate']) ??
      DateTime.now();

  final qrData = (data['qrData'] ?? data['qrCode'] ?? '${source}_$id')
      .toString();

  return BookingModel(
    id: id,
    userName: userName,
    eventName: eventName,
    tickets: tickets,
    amount: amount,
    paymentStatus: paymentStatus,
    date: date,
    qrData: qrData,
    isCancelled: _toBool(data['isCancelled']),
    isRefunded: _toBool(data['isRefunded']),
  );
}

EventModel _eventFromMap(String id, Map<String, dynamic> data) {
  final categoryText = (data['category'] ?? '').toString();
  final category = EventCategory.values.firstWhere(
    (value) => value.name.toLowerCase() == categoryText.toLowerCase(),
    orElse: () => EventCategory.conference,
  );

  return EventModel(
    id: id,
    title: (data['title'] ?? 'Untitled Event').toString(),
    category: category,
    date: _parseDate(data['date']) ?? DateTime.now(),
    location: (data['location'] ?? 'TBA').toString(),
    price: _toDouble(data['price']) ?? 0,
    imageUrl:
        (data['imageUrl'] ??
                'https://images.unsplash.com/photo-1511578314322-379afb476865')
            .toString(),
    description: (data['description'] ?? '').toString(),
    schedule: _toStringList(data['schedule']),
    attendees: _toStringList(data['attendees']),
    ticketTypes: _toTicketTypes(data['ticketTypes']),
    isTrending: _toBool(data['isTrending']),
    reviews: const [],
    hasArVrPreview: _toBool(data['hasArVrPreview']),
    organizerName: (data['organizerName'] ?? 'Event Organizer').toString(),
    organizerVerified: _toBool(data['organizerVerified']),
  );
}

AppUserModel _userFromMap(String id, Map<String, dynamic> data) {
  return AppUserModel(
    id: id,
    name: (data['name'] ?? 'Unknown User').toString(),
    email: (data['email'] ?? '').toString(),
    phone: (data['phone'] ?? '').toString(),
    totalBookings:
        _toInt(data['totalBookings']) ?? _toInt(data['eventsAttended']) ?? 0,
    totalSpent: _toDouble(data['totalSpent']) ?? 0,
    isBlocked: _toBool(data['isBlocked']),
    isOrganizer: _toBool(data['isOrganizer']),
    isVerifiedOrganizer: _toBool(data['isVerifiedOrganizer']),
  );
}

DateTime? _parseDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

double? _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

bool _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is String) {
    return value.toLowerCase() == 'true';
  }

  return false;
}

List<String> _toStringList(dynamic value) {
  if (value is Iterable) {
    return value.map((item) => item.toString()).toList();
  }

  if (value is String) {
    final trimmed = value.trim();

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Iterable) {
        return decoded.map((item) => item.toString()).toList();
      }
      if (decoded is String) {
        return decoded.isEmpty ? const [] : [decoded];
      }
    } catch (_) {
      // Fall through to non-JSON parsing.
    }

    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Iterable) {
          return decoded.map((item) => item.toString()).toList();
        }
      } catch (_) {
        return [value];
      }
    }

    return value.isEmpty ? const [] : [value];
  }

  return const [];
}

Map<String, double> _toTicketTypes(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), _toDouble(val) ?? 0),
    );
  }

  return const {'General': 0};
}

Map<String, dynamic> _eventPayload(EventModel event, bool isSeed) {
  final payload = <String, dynamic>{
    'title': event.title,
    'category': event.category.name,
    'date': Timestamp.fromDate(event.date),
    'location': event.location,
    'price': event.price,
    'imageUrl': event.imageUrl,
    'description': event.description,
    'schedule': event.schedule,
    'attendees': event.attendees,
    'ticketTypes': event.ticketTypes,
    'isTrending': event.isTrending,
    'hasArVrPreview': event.hasArVrPreview,
    'organizerName': event.organizerName,
    'organizerVerified': event.organizerVerified,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  if (isSeed) {
    payload['createdAt'] = FieldValue.serverTimestamp();
  }

  return payload;
}
