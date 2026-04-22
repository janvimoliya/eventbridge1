import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  EventProvider() {
    _bindEvents();
    unawaited(_seedDefaultCategoryEvents());
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<EventModel> _events = List<EventModel>.from(_seedEvents);
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSubscription;
  EventCategory? _activeCategory;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _lastError;

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

  bool get isLoading => _isLoading;
  EventCategory? get activeCategory => _activeCategory;
  String? get lastError => _lastError;

  void _bindEvents() {
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

            _lastError = null;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to listen events collection: $error');
            if (error is FirebaseException) {
              _lastError =
                  '${error.code}: ${error.message ?? 'Firestore error'}';
            } else {
              _lastError = error.toString();
            }
            _isLoading = false;
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
      var writes = 0;

      for (final event in _defaultCategoryEvents) {
        if (existingIds.contains(event.id)) {
          continue;
        }

        batch.set(eventsRef.doc(event.id), _eventPayload(event));
        writes += 1;
      }

      if (writes > 0) {
        await batch.commit();
      }
    } catch (error) {
      debugPrint('Failed to seed default category events: $error');
    }
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('events').get();
      final loaded = snapshot.docs
          .map((doc) => _eventFromMap(doc.id, doc.data()))
          .toList();

      _events
        ..clear()
        ..addAll(loaded);

      _lastError = null;
    } catch (error) {
      debugPrint('Failed to load events: $error');
      if (error is FirebaseException) {
        _lastError = '${error.code}: ${error.message ?? 'Firestore error'}';
      } else {
        _lastError = error.toString();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  List<EventModel> get events {
    final filteredByCategory = _activeCategory == null
        ? _events
        : _events.where((event) => event.category == _activeCategory).toList();

    if (_searchQuery.isEmpty) {
      return filteredByCategory;
    }

    return filteredByCategory
        .where(
          (event) =>
              event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              event.location.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<EventModel> get trendingEvents =>
      _events.where((event) => event.isTrending).toList();

  List<EventCategory> get categories => EventCategory.values;

  void setCategory(EventCategory? category) {
    _activeCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  EventModel findById(String id) =>
      _events.firstWhere((event) => event.id == id);

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }
}

EventModel _eventFromMap(String id, Map<String, dynamic> data) {
  final title = (data['title'] ?? 'Untitled Event').toString();
  final categoryText = (data['category'] ?? '').toString();
  final category = EventCategory.values.firstWhere(
    (value) => value.name.toLowerCase() == categoryText.toLowerCase(),
    orElse: () => EventCategory.conference,
  );

  return EventModel(
    id: id,
    title: title,
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

Map<String, dynamic> _eventPayload(EventModel event) {
  return {
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
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

final List<EventModel> _seedEvents = [
  EventModel(
    id: '1',
    title: 'Tech Innovators Summit',
    category: EventCategory.conference,
    date: DateTime.now().add(const Duration(days: 4)),
    location: 'Bengaluru International Center',
    price: 2499,
    imageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865',
    description:
        'A premium conference focused on AI, cloud, and product innovation.',
    schedule: [
      '09:00 AM - Keynote',
      '11:00 AM - Panel Discussion',
      '02:00 PM - Networking',
    ],
    attendees: ['Amit S.', 'Neha K.', 'Rahul P.'],
    ticketTypes: {'Standard': 2499, 'VIP': 4999},
    isTrending: true,
    reviews: const [
      EventReview(
        userName: 'Ira',
        rating: 4.8,
        comment: 'Excellent speakers and venue.',
      ),
      EventReview(
        userName: 'Dev',
        rating: 4.5,
        comment: 'Loved the networking quality.',
      ),
    ],
    hasArVrPreview: true,
    organizerName: 'BridgeX Events',
    organizerVerified: true,
  ),
  EventModel(
    id: '2',
    title: 'Royal Wedding Expo',
    category: EventCategory.wedding,
    date: DateTime.now().add(const Duration(days: 12)),
    location: 'Jaipur Grand Palace Lawns',
    price: 1599,
    imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552',
    description: 'Discover premium decorators, stylists, and wedding planners.',
    schedule: [
      '10:00 AM - Bridal Trends',
      '01:00 PM - Venue Showcase',
      '04:00 PM - Meet Experts',
    ],
    attendees: ['Mansi R.', 'Parth J.'],
    ticketTypes: {'General': 1599, 'Couple Pass': 2799},
    isTrending: false,
    reviews: const [
      EventReview(
        userName: 'Riya',
        rating: 4.6,
        comment: 'Great vendor collection.',
      ),
    ],
    hasArVrPreview: true,
    organizerName: 'WedAura',
    organizerVerified: true,
  ),
  EventModel(
    id: '3',
    title: 'Neon Nights Concert',
    category: EventCategory.concert,
    date: DateTime.now().add(const Duration(days: 2)),
    location: 'Mumbai Arena',
    price: 1999,
    imageUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea',
    description: 'Live performances by top artists with immersive light shows.',
    schedule: [
      '06:00 PM - Gates Open',
      '07:30 PM - Main Act',
      '10:30 PM - Finale',
    ],
    attendees: ['Kabir T.', 'Asha M.', 'Vivek B.', 'Nina L.'],
    ticketTypes: {'Silver': 1999, 'Gold': 3499, 'Platinum': 5999},
    isTrending: true,
    reviews: const [
      EventReview(
        userName: 'Aryan',
        rating: 4.9,
        comment: 'Sound quality was unreal!',
      ),
      EventReview(userName: 'Sara', rating: 4.7, comment: 'Worth every rupee.'),
    ],
    hasArVrPreview: false,
    organizerName: 'PulseLive',
    organizerVerified: true,
  ),
  EventModel(
    id: '4',
    title: 'ColorBeat Festival',
    category: EventCategory.festival,
    date: DateTime.now().add(const Duration(days: 20)),
    location: 'Ahmedabad Riverfront',
    price: 899,
    imageUrl: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3',
    description:
        'A vibrant festival with music, food, and culture from around the world.',
    schedule: [
      '11:00 AM - Opening Parade',
      '03:00 PM - Food Carnival',
      '07:00 PM - DJ Night',
    ],
    attendees: ['Rohan V.', 'Kriti D.'],
    ticketTypes: {'Entry': 899, 'Premium': 1699},
    isTrending: true,
    reviews: const [
      EventReview(
        userName: 'Pooja',
        rating: 4.3,
        comment: 'Fun, colorful, and family friendly.',
      ),
    ],
    hasArVrPreview: false,
    organizerName: 'Festiva India',
    organizerVerified: false,
  ),
  EventModel(
    id: '5',
    title: 'Flutter Masterclass Workshop',
    category: EventCategory.workshop,
    date: DateTime.now().add(const Duration(days: 7)),
    location: 'Hybrid - Online + Pune Campus',
    price: 1299,
    imageUrl: 'https://images.unsplash.com/photo-1515378791036-0648a3ef77b2',
    description:
        'Hands-on Flutter workshop with architecture and deployment modules.',
    schedule: [
      '09:30 AM - Setup',
      '11:00 AM - State Management',
      '02:00 PM - Deployment',
    ],
    attendees: ['Mehul P.', 'Jia N.', 'Harsh T.'],
    ticketTypes: {'Standard': 1299, 'Mentorship': 2499},
    isTrending: false,
    reviews: const [
      EventReview(
        userName: 'Nikhil',
        rating: 4.8,
        comment: 'Very practical session.',
      ),
    ],
    hasArVrPreview: false,
    organizerName: 'CodeBridge Academy',
    organizerVerified: true,
  ),
];
