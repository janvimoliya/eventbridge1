import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime timestamp;
}

class UserTicket {
  const UserTicket({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.holderName,
    required this.ticketType,
    required this.quantity,
    required this.amount,
    required this.eventDate,
  });

  final String id;
  final String eventId;
  final String eventTitle;
  final String holderName;
  final String ticketType;
  final int quantity;
  final double amount;
  final DateTime eventDate;

  String get qrPayload => '$id|$eventId|$holderName|$ticketType|$quantity';
}

class UserProvider extends ChangeNotifier {
  UserProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthUser? _currentUser;
  ThemeMode _themeMode = ThemeMode.light;
  String _languageCode = 'en';
  double _textScaleFactor = 1.0;
  double _walletBalance = 0;
  int _eventsAttended = 0;
  double _totalSpent = 0;
  EventCategory _favoriteCategory = EventCategory.concert;

  final List<String> _wishlistEventIds = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _wishlistSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _walletSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _transactionsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ticketsSubscription;

  final List<UserTicket> _tickets = [];
  final List<WalletTransaction> _transactions = [];
  List<AppNotificationModel> _notifications = [];

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  double get textScaleFactor => _textScaleFactor;
  double get walletBalance => _walletBalance;
  List<String> get wishlistEventIds => List.unmodifiable(_wishlistEventIds);
  List<UserTicket> get tickets => List.unmodifiable(_tickets);
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  List<AppNotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get eventsAttended => _eventsAttended;
  double get totalSpent => _totalSpent;
  EventCategory get favoriteCategory => _favoriteCategory;

  void login(AuthUser user) {
    _currentUser = user;
    _languageCode = _normalizeLanguageCode(user.languageCode);
    _bindWishlistForUser(user.uid);
    _bindWalletForUser(user.uid);
    _bindTicketsForUser(user.uid);
    _bindTransactionsForUser(user.uid);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String photoUrl,
    Uint8List? photoBytes,
    String? photoFileExtension,
    bool removePhoto = false,
  }) async {
    if (_currentUser == null) {
      throw Exception('No active user found. Please login again.');
    }

    final updatedUser = await _authService.updateProfile(
      name: name,
      phone: phone,
      photoUrl: photoUrl,
      photoBytes: photoBytes,
      photoFileExtension: photoFileExtension,
      removePhoto: removePhoto,
    );

    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } finally {
      _wishlistSubscription?.cancel();
      _wishlistSubscription = null;
      _walletSubscription?.cancel();
      _walletSubscription = null;
      _transactionsSubscription?.cancel();
      _transactionsSubscription = null;
      _ticketsSubscription?.cancel();
      _ticketsSubscription = null;
      _wishlistEventIds.clear();
      _tickets.clear();
      _transactions.clear();
      _currentUser = null;
      _walletBalance = 0;
      notifyListeners();
    }
  }

  void setThemeMode(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setTextScaleFactor(double factor) {
    _textScaleFactor = factor.clamp(0.9, 1.4);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    final normalized = _normalizeLanguageCode(languageCode);
    _languageCode = normalized;
    notifyListeners();

    try {
      await _authService.updateLanguagePreference(languageCode: normalized);
    } catch (_) {
      // Keep the in-memory locale change even if the preference cannot be saved.
    }
  }

  Future<void> toggleWishlist(EventModel event) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Please login to manage wishlist.');
    }

    final docId = _wishlistDocId(user.uid, event.id);
    final primaryDocRef = _wishlistCollectionForUser(user.uid).doc(event.id);
    final legacyDocRef = _firestore.collection('wishlists').doc(docId);

    if (_wishlistEventIds.contains(event.id)) {
      await _runWishlistWriteWithFallback(
        primaryWrite: () => primaryDocRef.delete(),
        legacyWrite: () => legacyDocRef.delete(),
      );
      return;
    }

    final payload = <String, dynamic>{
      'id': docId,
      'userId': user.uid,
      'eventId': event.id,
      'eventName': event.title,
      'eventCategory': event.category.name,
      'eventDate': Timestamp.fromDate(event.date),
      'eventImageUrl': event.imageUrl,
      'eventLocation': event.location,
      'eventPrice': event.price,
      'organizerId': _organizerIdFromEvent(event),
      'organizerName': event.organizerName,
      'priority': 'high',
      'notes': '',
      'reminderDays': 1,
      'reminderEnabled': false,
      'addedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _runWishlistWriteWithFallback(
      primaryWrite: () => primaryDocRef.set(payload, SetOptions(merge: true)),
      legacyWrite: () => legacyDocRef.set(payload, SetOptions(merge: true)),
    );
  }

  bool isWishlisted(String eventId) => _wishlistEventIds.contains(eventId);

  void addNotification(AppNotificationModel notification) {
    _notifications = [notification, ..._notifications];
    notifyListeners();
  }

  Future<void> initializeNotifications(NotificationService service) async {
    _notifications = await service.fetchDefaultNotifications();
    notifyListeners();
  }

  Future<void> topUpWallet(double amount) async {
    if (_currentUser == null) {
      throw Exception('Please login to top up wallet.');
    }

    try {
      final userId = _currentUser!.uid;
      final txnId = 'topup_${DateTime.now().millisecondsSinceEpoch}';
      final newBalance = _walletBalance + amount;

      // Update wallet balance in users collection
      await _firestore.collection('users').doc(userId).set({
        'walletBalance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add transaction record
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet_transactions')
          .doc(txnId)
          .set({
            'id': txnId,
            'title': 'Wallet Top-up',
            'amount': amount,
            'timestamp': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      _walletBalance = newBalance;
      notifyListeners();
    } catch (error) {
      debugPrint('Failed to top up wallet: $error');
      throw Exception('Failed to top up wallet: $error');
    }
  }

  Future<bool> spendFromWallet({
    required double amount,
    required String title,
  }) async {
    if (_currentUser == null) {
      throw Exception('Please login to spend from wallet.');
    }

    if (_walletBalance < amount) {
      return false;
    }

    try {
      final userId = _currentUser!.uid;
      final txnId = 'purchase_${DateTime.now().millisecondsSinceEpoch}';
      final newBalance = _walletBalance - amount;

      // Update wallet balance in users collection
      await _firestore.collection('users').doc(userId).set({
        'walletBalance': newBalance,
        'totalSpent': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add transaction record
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet_transactions')
          .doc(txnId)
          .set({
            'id': txnId,
            'title': title,
            'amount': -amount,
            'timestamp': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      _walletBalance = newBalance;
      _totalSpent += amount;
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('Failed to spend from wallet: $error');
      return false;
    }
  }

  Future<void> addTicket(UserTicket ticket, EventCategory category) async {
    if (_currentUser == null) {
      throw Exception('Please login to add ticket.');
    }

    try {
      final userId = _currentUser!.uid;

      // Save ticket to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tickets')
          .doc(ticket.id)
          .set({
            'id': ticket.id,
            'eventId': ticket.eventId,
            'eventTitle': ticket.eventTitle,
            'holderName': ticket.holderName,
            'ticketType': ticket.ticketType,
            'quantity': ticket.quantity,
            'amount': ticket.amount,
            'eventDate': Timestamp.fromDate(ticket.eventDate),
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Update user stats
      await _firestore.collection('users').doc(userId).set({
        'eventsAttended': FieldValue.increment(1),
        'favoriteCategory': category.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _tickets.insert(0, ticket);
      _eventsAttended += 1;
      _favoriteCategory = category;
      notifyListeners();
    } catch (error) {
      debugPrint('Failed to add ticket: $error');
      throw Exception('Failed to add ticket: $error');
    }
  }

  List<EventModel> personalizedRecommendations(List<EventModel> allEvents) {
    final preferred = allEvents
        .where((e) => e.category == _favoriteCategory)
        .toList();
    final fromWishlist = allEvents
        .where((e) => _wishlistEventIds.contains(e.id))
        .toList();

    final merged = <EventModel>{...preferred, ...fromWishlist};
    if (merged.isNotEmpty) {
      return merged.toList();
    }

    return allEvents.take(3).toList();
  }

  void _bindWishlistForUser(String userId) {
    _wishlistSubscription?.cancel();
    _bindWishlistFromUserSubcollection(userId);
  }

  void _bindWishlistFromUserSubcollection(String userId) {
    _wishlistSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlists')
        .snapshots()
        .listen(
          (snapshot) {
            _wishlistEventIds
              ..clear()
              ..addAll(
                snapshot.docs
                    .map((doc) => (doc.data()['eventId'] ?? '').toString())
                    .where((eventId) => eventId.isNotEmpty),
              );
            notifyListeners();
          },
          onError: (error) {
            if (_isPermissionDeniedError(error)) {
              _bindWishlistFromLegacyCollection(userId);
              return;
            }
            debugPrint('Failed to sync wishlist: $error');
          },
        );
  }

  void _bindWishlistFromLegacyCollection(String userId) {
    _wishlistSubscription?.cancel();
    _wishlistSubscription = _firestore
        .collection('wishlists')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) {
            _wishlistEventIds
              ..clear()
              ..addAll(
                snapshot.docs
                    .map((doc) => (doc.data()['eventId'] ?? '').toString())
                    .where((eventId) => eventId.isNotEmpty),
              );
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to sync wishlist: $error');
          },
        );
  }

  void _bindWalletForUser(String userId) {
    _walletSubscription?.cancel();
    _walletSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data() ?? {};
              _walletBalance = _toDouble(data['walletBalance']) ?? 0;
              _eventsAttended = _toInt(data['eventsAttended']) ?? 0;
              _totalSpent = _toDouble(data['totalSpent']) ?? 0;
              final favCatStr = (data['favoriteCategory'] ?? '').toString();
              if (favCatStr.isNotEmpty) {
                _favoriteCategory = EventCategory.values.firstWhere(
                  (cat) => cat.name == favCatStr,
                  orElse: () => EventCategory.concert,
                );
              }
              notifyListeners();
            }
          },
          onError: (error) {
            debugPrint('Failed to sync wallet: $error');
          },
        );
  }

  void _bindTransactionsForUser(String userId) {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('wallet_transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _transactions.clear();
            for (final doc in snapshot.docs) {
              final data = doc.data();
              _transactions.add(
                WalletTransaction(
                  id: (data['id'] ?? '').toString(),
                  title: (data['title'] ?? '').toString(),
                  amount: _toDouble(data['amount']) ?? 0,
                  timestamp:
                      _parseTimestamp(data['timestamp']) ?? DateTime.now(),
                ),
              );
            }
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to sync transactions: $error');
          },
        );
  }

  void _bindTicketsForUser(String userId) {
    _ticketsSubscription?.cancel();
    _ticketsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _tickets.clear();
            for (final doc in snapshot.docs) {
              final data = doc.data();
              _tickets.add(
                UserTicket(
                  id: (data['id'] ?? '').toString(),
                  eventId: (data['eventId'] ?? '').toString(),
                  eventTitle: (data['eventTitle'] ?? '').toString(),
                  holderName: (data['holderName'] ?? '').toString(),
                  ticketType: (data['ticketType'] ?? '').toString(),
                  quantity: _toInt(data['quantity']) ?? 1,
                  amount: _toDouble(data['amount']) ?? 0,
                  eventDate:
                      _parseTimestamp(data['eventDate']) ?? DateTime.now(),
                ),
              );
            }
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Failed to sync tickets: $error');
          },
        );
  }

  CollectionReference<Map<String, dynamic>> _wishlistCollectionForUser(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('wishlists');
  }

  Future<void> _runWishlistWriteWithFallback({
    required Future<void> Function() primaryWrite,
    required Future<void> Function() legacyWrite,
  }) async {
    try {
      await primaryWrite();
      return;
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
    }

    try {
      await legacyWrite();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw Exception(
          'Unable to update wishlist due to Firestore security rules. Allow signed-in users to write under users/{uid}/wishlists or wishlists where request.auth.uid matches the owner.',
        );
      }
      rethrow;
    }
  }

  bool _isPermissionDeniedError(Object error) {
    return error is FirebaseException && error.code == 'permission-denied';
  }

  String _wishlistDocId(String userId, String eventId) => '${userId}_$eventId';

  String _organizerIdFromEvent(EventModel event) {
    final source = event.organizerName.trim().toLowerCase();
    if (source.isEmpty) {
      return 'unknown_organizer';
    }
    return source
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  @override
  void dispose() {
    _wishlistSubscription?.cancel();
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.dispose();
  }
}

String _normalizeLanguageCode(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'hi':
      return 'hi';
    case 'gu':
      return 'gu';
    default:
      return 'en';
  }
}
