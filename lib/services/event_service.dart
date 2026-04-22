import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
  String? _eventsError;
  String? _usersError;

  final List<EventModel> _events = [
    EventModel(
      id: 'ad_1',
      title: 'Startup Expo 2026',
      category: EventCategory.conference,
      date: DateTime.now().add(const Duration(days: 8)),
      location: 'Ahmedabad Convention Center',
      price: 1499,
      imageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865',
      description: 'Startup showcase with investors and founders.',
      schedule: const ['10:00 AM Keynote', '01:00 PM Demo Zone'],
      attendees: const ['Founders', 'Investors'],
      ticketTypes: const {'Standard': 1499, 'VIP': 2999},
      isTrending: true,
      reviews: const [],
      hasArVrPreview: false,
      organizerName: 'BridgeX Organizer',
      organizerVerified: true,
    ),
    EventModel(
      id: 'ad_2',
      title: 'Monsoon Music Fest',
      category: EventCategory.concert,
      date: DateTime.now().add(const Duration(days: 14)),
      location: 'Mumbai Open Grounds',
      price: 2200,
      imageUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea',
      description: 'Live music evening with top performers.',
      schedule: const ['06:30 PM Entry', '08:00 PM Live Show'],
      attendees: const ['Fans', 'Artists'],
      ticketTypes: const {'Silver': 2200, 'Gold': 4000},
      isTrending: true,
      reviews: const [],
      hasArVrPreview: true,
      organizerName: 'PulseLive',
      organizerVerified: true,
    ),
  ];

  final List<EventModel> _defaultCategoryEvents = [
    EventModel(
      id: 'seed_conference',
      title: 'Future of Product Summit',
      category: EventCategory.conference,
      date: DateTime.now().add(const Duration(days: 6)),
      location: 'Delhi Convention Center',
      price: 1899,
      imageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865',
      description:
          'Conference sessions for founders, builders, and product teams.',
      schedule: const [
        '09:30 AM Keynote',
        '12:00 PM Panels',
        '03:00 PM Networking',
      ],
      attendees: const ['Product teams', 'Startups', 'Investors'],
      ticketTypes: const {'Standard': 1899, 'VIP': 3499},
      isTrending: true,
      reviews: const [],
      hasArVrPreview: false,
      organizerName: 'EventBridge Summit',
      organizerVerified: true,
    ),
    EventModel(
      id: 'seed_wedding',
      title: 'Grand Wedding Showcase',
      category: EventCategory.wedding,
      date: DateTime.now().add(const Duration(days: 10)),
      location: 'Jaipur Palace Grounds',
      price: 1299,
      imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552',
      description: 'Venue and vendor showcase for modern wedding planning.',
      schedule: const [
        '11:00 AM Decor',
        '02:00 PM Styling',
        '05:00 PM Planning Desk',
      ],
      attendees: const ['Couples', 'Planners', 'Vendors'],
      ticketTypes: const {'Entry': 1299, 'Couple Pass': 2399},
      isTrending: false,
      reviews: const [],
      hasArVrPreview: false,
      organizerName: 'WedBridge',
      organizerVerified: true,
    ),
    EventModel(
      id: 'seed_concert',
      title: 'City Lights Concert',
      category: EventCategory.concert,
      date: DateTime.now().add(const Duration(days: 3)),
      location: 'Mumbai Arena',
      price: 2199,
      imageUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea',
      description:
          'Live concert featuring popular artists and immersive visuals.',
      schedule: const [
        '06:00 PM Gates',
        '07:30 PM Main Act',
        '10:00 PM Finale',
      ],
      attendees: const ['Music fans', 'Students', 'Creators'],
      ticketTypes: const {'Silver': 2199, 'Gold': 3999},
      isTrending: true,
      reviews: const [],
      hasArVrPreview: true,
      organizerName: 'PulseLive',
      organizerVerified: true,
    ),
    EventModel(
      id: 'seed_festival',
      title: 'ColorWave Festival',
      category: EventCategory.festival,
      date: DateTime.now().add(const Duration(days: 18)),
      location: 'Ahmedabad Riverfront',
      price: 899,
      imageUrl: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3',
      description:
          'A vibrant festival with music, food, and cultural showcases.',
      schedule: const [
        '11:00 AM Parade',
        '03:00 PM Food Lane',
        '07:00 PM DJ Night',
      ],
      attendees: const ['Families', 'Friends', 'Travelers'],
      ticketTypes: const {'General': 899, 'Premium': 1699},
      isTrending: true,
      reviews: const [],
      hasArVrPreview: false,
      organizerName: 'Festiva India',
      organizerVerified: false,
    ),
    EventModel(
      id: 'seed_workshop',
      title: 'Flutter Builder Workshop',
      category: EventCategory.workshop,
      date: DateTime.now().add(const Duration(days: 8)),
      location: 'Pune Tech Hub',
      price: 999,
      imageUrl: 'https://images.unsplash.com/photo-1515378791036-0648a3ef77b2',
      description: 'Hands-on workshop for mobile app building and deployment.',
      schedule: const ['09:30 AM Setup', '11:00 AM Coding', '02:30 PM Q&A'],
      attendees: const ['Developers', 'Students', 'Freelancers'],
      ticketTypes: const {'Standard': 999, 'Mentorship': 1999},
      isTrending: false,
      reviews: const [],
      hasArVrPreview: false,
      organizerName: 'CodeBridge Academy',
      organizerVerified: true,
    ),
  ];

  final List<AppUserModel> _users = [
    const AppUserModel(
      id: 'u_1',
      name: 'Rahul Sharma',
      email: 'rahul@eventbridge.app',
      phone: '9876543210',
      totalBookings: 5,
      totalSpent: 6200,
      isOrganizer: false,
    ),
    const AppUserModel(
      id: 'u_2',
      name: 'Priya Patel',
      email: 'priya@eventbridge.app',
      phone: '9123456780',
      totalBookings: 3,
      totalSpent: 2900,
      isOrganizer: true,
      isVerifiedOrganizer: false,
    ),
  ];

  final List<BookingModel> _bookings = [
    BookingModel(
      id: 'b_1',
      userName: 'Rahul Sharma',
      eventName: 'Monsoon Music Fest',
      tickets: 2,
      amount: 1500,
      paymentStatus: 'Paid',
      date: DateTime.now().subtract(const Duration(days: 2)),
      qrData: 'EB|b_1|Monsoon Music Fest|2',
    ),
    BookingModel(
      id: 'b_2',
      userName: 'Priya Patel',
      eventName: 'Startup Expo 2026',
      tickets: 1,
      amount: 500,
      paymentStatus: 'Paid',
      date: DateTime.now().subtract(const Duration(days: 1)),
      qrData: 'EB|b_2|Startup Expo 2026|1',
    ),
  ];

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
  }

  Future<void> _seedDefaultCategoryEvents() async {
    try {
      final eventsRef = _firestore.collection('events');
      final snapshot = await eventsRef.get();
      final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
      final batch = _firestore.batch();
      var writeCount = 0;

      for (final event in _defaultCategoryEvents) {
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
          (booking) => booking.paymentStatus == 'Paid' && !booking.isRefunded,
        )
        .fold<double>(0, (total, item) => total + item.amount);
  }

  double get adminCommissionRevenue => totalRevenue * 0.10;

  Map<String, double> get monthlyRevenue => {
    'Jan': 50000,
    'Feb': 70000,
    'Mar': 120000,
    'Apr': max(25000, totalRevenue),
  };

  Map<String, int> get monthlyBookings => {
    'Jan': 80,
    'Feb': 140,
    'Mar': 210,
    'Apr': max(40, _bookings.length),
  };

  void upsertEvent({
    String? eventId,
    required String title,
    required EventCategory category,
    required DateTime date,
    required String location,
    required double price,
    required String description,
    required String imageUrl,
    required int seatCapacity,
  }) {
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

    _firestore
        .collection('events')
        .doc(id)
        .set(payload, SetOptions(merge: true))
        .catchError((error) {
          debugPrint('Failed to upsert event in Firestore: $error');
        });

    notifyListeners();
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
    super.dispose();
  }
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
