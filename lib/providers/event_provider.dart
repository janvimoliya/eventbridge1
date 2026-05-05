import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  EventProvider() {
    _bindEvents();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<EventModel> _events = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSubscription;
  EventCategory? _activeCategory;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _lastError;

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
